"""
Blackout: live clinical data wiped mid-operation → held in admin-only TEMP VAULT → restore to patients.

Two kinds of records:
  - Livestock / human screenings (One Health)
  - Doctor prescriptions
"""
from __future__ import annotations

import json
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

from django.conf import settings
from django.db import transaction
from django.utils import timezone

_LAST: dict[str, Any] = {
    'phase': 'idle',
    'message': 'Waiting for demo…',
    'live_count': 0,
    'vault_count': 0,
    'recovered': 0,
    'updated_at': None,
    'log': [],
}


def _vault_path() -> Path:
    base = Path(settings.BASE_DIR) / 'blackout_data'
    base.mkdir(parents=True, exist_ok=True)
    return base / 'temp_vault.json'


def _status_path() -> Path:
    base = Path(settings.BASE_DIR) / 'blackout_data'
    base.mkdir(parents=True, exist_ok=True)
    return base / 'status.json'


def _banner(lines: list[str]) -> None:
    bar = '=' * 64
    print(f'\n{bar}', flush=True)
    for line in lines:
        # Windows cp1252 consoles choke on arrows / fancy dashes.
        safe = (
            str(line)
            .replace('\u2192', '->')
            .replace('\u2014', '-')
            .replace('\u2013', '-')
            .replace('\u2026', '...')
            .replace('\u2019', "'")
            .replace('\u2018', "'")
        )
        try:
            print(f'  {safe}', flush=True)
        except UnicodeEncodeError:
            print(f'  {safe.encode("ascii", "replace").decode("ascii")}', flush=True)
    print(f'{bar}\n', flush=True)
    sys.stdout.flush()


def _push_log(msg: str) -> None:
    entry = f'{datetime.now().strftime("%H:%M:%S")}  {msg}'
    log = list(_LAST.get('log') or [])
    log.append(entry)
    _LAST['log'] = log[-40:]


def _load_vault() -> dict:
    path = _vault_path()
    if not path.exists():
        return {'screenings': [], 'prescriptions': []}
    try:
        data = json.loads(path.read_text(encoding='utf-8'))
        return {
            'screenings': list(data.get('screenings') or data.get('rows') or []),
            'prescriptions': list(data.get('prescriptions') or []),
        }
    except (OSError, json.JSONDecodeError):
        return {'screenings': [], 'prescriptions': []}


def _write_vault(screenings: list, prescriptions: list, reason: str) -> None:
    payload = {
        'saved_at': timezone.now().isoformat(),
        'reason': reason,
        'screenings': screenings,
        'prescriptions': prescriptions,
    }
    _vault_path().write_text(json.dumps(payload, indent=2, default=str), encoding='utf-8')


def _live_items(limit: int = 30) -> list[dict]:
    from apps.one_health.models import ScreeningEvent
    from apps.prescriptions.models import Prescription

    items = []
    for s in ScreeningEvent.objects.all().order_by('-id')[:limit]:
        held = getattr(s, 'status', '') == 'held'
        kind = 'Livestock screening' if s.domain == 'ANIMAL' else 'Human screening'
        if held:
            kind = f'{kind} (TEMP hold)'
        items.append({
            'kind': kind,
            'type': 'screening',
            'id': s.id,
            'title': s.possible_condition or 'Screening',
            'detail': (s.input_text or '')[:70],
            'severity': 'HELD-admin' if held else s.severity_level,
            'who': f'user #{s.user_id}',
            'created_at': s.created_at.isoformat() if s.created_at else None,
        })
    for p in Prescription.objects.all().order_by('-id')[:limit]:
        meds = (p.medications or '')[:70]
        held = p.status == 'held'
        items.append({
            'kind': 'Doctor prescription (TEMP hold)' if held else 'Doctor prescription',
            'type': 'prescription',
            'id': p.id,
            'title': meds or 'Prescription',
            'detail': (p.dosage_instructions or p.notes or '')[:70],
            'severity': 'HELD-admin' if held else (p.status or 'active'),
            'who': f'dr #{p.doctor_id} -> pt #{p.patient_id}',
            'created_at': p.issued_at.isoformat() if p.issued_at else None,
        })
    # newest first mix
    items.sort(key=lambda x: x.get('created_at') or '', reverse=True)
    return items[:limit]


def _vault_items() -> list[dict]:
    vault = _load_vault()
    items = []
    for s in vault['screenings']:
        kind = 'Livestock screening' if s.get('domain') == 'ANIMAL' else 'Human screening'
        items.append({
            'kind': kind,
            'type': 'screening',
            'id': s.get('id'),
            'title': s.get('possible_condition') or 'Screening',
            'detail': (s.get('input_text') or '')[:70],
            'severity': s.get('severity_level'),
            'who': f"user #{s.get('user_id')}",
            'created_at': s.get('created_at'),
            'holding': True,
        })
    for p in vault['prescriptions']:
        items.append({
            'kind': 'Doctor prescription',
            'type': 'prescription',
            'id': p.get('id'),
            'title': (p.get('medications') or 'Prescription')[:70],
            'detail': (p.get('dosage_instructions') or p.get('notes') or '')[:70],
            'severity': p.get('status') or 'active',
            'who': f"dr #{p.get('doctor_id')} -> pt #{p.get('patient_id')}",
            'created_at': p.get('issued_at'),
            'holding': True,
        })
    items.sort(key=lambda x: x.get('created_at') or '', reverse=True)
    return items[:40]


def _save_status(**kwargs) -> dict[str, Any]:
    from apps.one_health.models import ScreeningEvent
    from apps.prescriptions.models import Prescription

    _LAST.update(kwargs)
    _LAST['updated_at'] = timezone.now().isoformat()
    vault = _load_vault()
    live_n = ScreeningEvent.objects.count() + Prescription.objects.count()
    vault_n = len(vault['screenings']) + len(vault['prescriptions'])
    _LAST['live_count'] = live_n
    _LAST['vault_count'] = vault_n
    # back-compat for old UI fields
    _LAST['primary_count'] = live_n
    _LAST['shadow_count'] = vault_n
    _LAST['live_rows'] = _live_items()
    _LAST['vault_rows'] = _vault_items()
    _LAST['primary_rows'] = _LAST['live_rows']
    _LAST['shadow_rows'] = _LAST['vault_rows']
    _LAST['db_file'] = str(Path(settings.BASE_DIR) / 'db.sqlite3')
    _LAST['shadow_file'] = str(_vault_path())
    try:
        _status_path().write_text(json.dumps(_LAST, indent=2, default=str), encoding='utf-8')
    except OSError:
        pass
    return dict(_LAST)


def get_status() -> dict[str, Any]:
    if not _LAST.get('updated_at'):
        _LAST['phase'] = 'idle'
        _LAST['message'] = (
            'Story: livestock / Rx saved -> Blackout wipes LIVE -> '
            'TEMP VAULT (admin only) holds copy -> Restore sends back to patients'
        )
    return _save_status()


def snapshot_screenings(reason: str = 'manual') -> dict[str, Any]:
    """Alias used by screening_create hook + API."""
    return snapshot_all(reason=reason)


def snapshot_all(reason: str = 'manual') -> dict[str, Any]:
    """Copy live screenings + prescriptions into admin TEMP VAULT."""
    from apps.one_health.models import ScreeningEvent
    from apps.prescriptions.models import Prescription

    screenings = []
    for s in ScreeningEvent.objects.all().order_by('id'):
        screenings.append({
            'id': s.id,
            'domain': s.domain,
            'user_id': s.user_id,
            'livestock_case_id': s.livestock_case_id,
            'input_type': s.input_type,
            'input_text': s.input_text,
            'possible_condition': s.possible_condition,
            'severity_level': s.severity_level,
            'confidence': s.confidence,
            'advice': s.advice,
            'result_json': s.result_json or {},
            'client_id': s.client_id or '',
            'status': getattr(s, 'status', 'released') or 'released',
            'created_at': s.created_at.isoformat() if s.created_at else None,
        })

    prescriptions = []
    for p in Prescription.objects.all().order_by('id'):
        prescriptions.append({
            'id': p.id,
            'patient_id': p.patient_id,
            'doctor_id': p.doctor_id,
            'medications': p.medications or '',
            'dosage_instructions': p.dosage_instructions or '',
            'notes': p.notes or '',
            'consultation_id': p.consultation_id,
            'prescription_type': p.prescription_type,
            'status': p.status,
            'issued_at': p.issued_at.isoformat() if p.issued_at else None,
            # file path only — binary stays on disk for demo
            'file': p.file.name if p.file else '',
            'file_content_type': p.file_content_type or '',
            'file_size': p.file_size,
        })

    _write_vault(screenings, prescriptions, reason)
    total = len(screenings) + len(prescriptions)
    _banner([
        'TEMP VAULT UPDATED (admin-only holding area)',
        f'Screenings: {len(screenings)} | Prescriptions: {len(prescriptions)}',
        f'Reason: {reason}',
    ])
    _push_log(f'Vault snapshot: {len(screenings)} screenings + {len(prescriptions)} Rx ({reason})')
    return _save_status(
        phase='ready',
        message=(
            f'Saved to TEMP VAULT: {len(screenings)} livestock/human screenings + '
            f'{len(prescriptions)} doctor prescriptions. Next: simulate Blackout (wipe LIVE).'
        ),
        recovered=0,
    )


def wipe_primary() -> dict[str, Any]:
    """Blackout: wipe LIVE tables. Vault keeps the copy (admin-only)."""
    from apps.one_health.models import ScreeningEvent
    from apps.prescriptions.models import Prescription

    before_s = ScreeningEvent.objects.count()
    before_p = Prescription.objects.count()
    if before_s + before_p > 0:
        snapshot_all(reason='pre-wipe')
    vault = _load_vault()
    vault_n = len(vault['screenings']) + len(vault['prescriptions'])

    _banner([
        '!!! BLACKOUT - LIVE DATA WIPED !!!',
        'Patients/doctors lose live screenings + prescriptions',
        f'Deleted screenings={before_s}, prescriptions={before_p}',
        f'TEMP VAULT still holds {vault_n} (admin only)',
        'STOP - show EMPTY live board, then Restore & send to patients',
    ])
    _push_log(f'WIPE live: -{before_s} screenings, -{before_p} Rx. Vault={vault_n}')

    with transaction.atomic():
        ScreeningEvent.objects.all().delete()
        Prescription.objects.all().delete()

    return _save_status(
        phase='wiped',
        message=(
            'BLACKOUT: LIVE app database EMPTY. '
            f'TEMP VAULT (admin only) still has {vault_n} records. '
            'Click “Restore & send to patients”.'
        ),
        recovered=0,
    )


def recover_from_shadow() -> dict[str, Any]:
    """Restore from TEMP VAULT back to live DB (= send back to patients/doctors)."""
    from apps.one_health.models import ScreeningEvent, LivestockCase
    from apps.prescriptions.models import Prescription
    from apps.patients.models import Patient
    from apps.doctors.models import Doctor
    from django.contrib.auth import get_user_model

    User = get_user_model()
    vault = _load_vault()
    if not vault['screenings'] and not vault['prescriptions']:
        _push_log('Restore failed - vault empty')
        return _save_status(
            phase='wiped',
            message='TEMP VAULT empty - Snapshot / create screening or Rx first.',
            recovered=0,
        )

    _banner(['RESTORE FROM TEMP VAULT -> LIVE (patients see again)'])
    _push_log('Restore & send to patients starting...')
    _save_status(phase='restoring', message='Restoring from TEMP VAULT -> live app...')

    restored = 0
    skipped = 0

    for row in vault['screenings']:
        try:
            with transaction.atomic():
                user_id = row.get('user_id')
                if not user_id or not User.objects.filter(pk=user_id).exists():
                    skipped += 1
                    continue
                client_id = (row.get('client_id') or '').strip()
                if client_id:
                    existing = ScreeningEvent.objects.filter(client_id=client_id).first()
                    if existing:
                        # Release held livestock screening into user history
                        if existing.status == ScreeningEvent.STATUS_HELD:
                            existing.status = ScreeningEvent.STATUS_RELEASED
                            existing.save(update_fields=['status'])
                        restored += 1
                        continue
                case_id = row.get('livestock_case_id')
                if case_id and not LivestockCase.objects.filter(pk=case_id).exists():
                    case_id = None
                ScreeningEvent.objects.create(
                    domain=row.get('domain') or 'HUMAN',
                    user_id=user_id,
                    livestock_case_id=case_id,
                    input_type=row.get('input_type') or 'symptoms',
                    input_text=row.get('input_text') or '',
                    possible_condition=row.get('possible_condition') or '',
                    severity_level=row.get('severity_level') or 'Low',
                    confidence=float(row.get('confidence') or 0),
                    advice=row.get('advice') or '',
                    result_json=row.get('result_json') or {},
                    client_id=client_id,
                    status=ScreeningEvent.STATUS_RELEASED,
                )
                restored += 1
        except Exception as e:
            skipped += 1
            _push_log(f'Skip screening: {e}')

    for row in vault['prescriptions']:
        try:
            with transaction.atomic():
                patient_id = row.get('patient_id')
                doctor_id = row.get('doctor_id')
                if patient_id and not Patient.objects.filter(pk=patient_id).exists():
                    patient_id = None
                if doctor_id and not Doctor.objects.filter(pk=doctor_id).exists():
                    doctor_id = None
                p = Prescription(
                    patient_id=patient_id,
                    doctor_id=doctor_id,
                    medications=row.get('medications') or '',
                    dosage_instructions=row.get('dosage_instructions') or '',
                    notes=row.get('notes') or '',
                    prescription_type=row.get('prescription_type') or 'digital',
                    status=Prescription.STATUS_ACTIVE,
                    file_content_type=row.get('file_content_type') or '',
                    file_size=row.get('file_size'),
                )
                file_name = row.get('file') or ''
                if file_name:
                    p.file.name = file_name
                p.save()
                restored += 1
                try:
                    from apps.alerts.notify import notify_patient_prescription
                    notify_patient_prescription(p)
                except Exception:
                    pass
        except Exception as e:
            skipped += 1
            _push_log(f'Skip Rx: {e}')

    final = ScreeningEvent.objects.count() + Prescription.objects.count()
    _banner([
        'RESTORED TO PATIENTS',
        f'Recovered {restored} records into live DB (skipped {skipped})',
        f'Live count now = {final}',
    ])
    _push_log(f'Restored {restored} (skipped {skipped}) -> live={final}')
    return _save_status(
        phase='recovered',
        message=(
            f'Restored {restored} records from TEMP VAULT'
            + (f' ({skipped} skipped)' if skipped else '')
            + '. Live again for patients/doctors. Demo again: Snapshot -> Wipe -> Restore.'
        ),
        recovered=restored,
    )


def simulate_blackout() -> dict[str, Any]:
    wipe_primary()
    return recover_from_shadow()
