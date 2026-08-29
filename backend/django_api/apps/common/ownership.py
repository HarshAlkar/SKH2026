"""Object-level ownership helpers — never trust client-supplied user/role IDs."""

from django.db.models import Q


def asha_assigned_village(user):
    asha = getattr(user, 'asha_profile', None)
    if asha is None:
        return ''
    return (asha.assigned_village or user.village or '').strip().lower()


def patient_in_asha_village(patient, user):
    village = asha_assigned_village(user)
    if not village:
        return False
    patient_village = (getattr(patient, 'village', None) or '').strip().lower()
    if not patient_village and hasattr(patient, 'user'):
        patient_village = (getattr(patient.user, 'village', None) or '').strip().lower()
    return patient_village == village


def user_can_access_patient(actor, patient):
    """Return True if actor may read/write records for this patient."""
    if not actor or not actor.is_authenticated or patient is None:
        return False
    if actor.is_staff:
        return True
    role = getattr(actor, 'role', None)
    patient_user_id = getattr(patient, 'user_id', None) or getattr(getattr(patient, 'user', None), 'id', None)

    if role == 'user':
        return patient_user_id == actor.id

    if role == 'asha_worker':
        return patient_in_asha_village(patient, actor)

    if role == 'doctor':
        from apps.consultations.models import Appointment
        from apps.alerts.models import EmergencyReferral

        if Appointment.objects.filter(doctor__user=actor, patient_id=patient.id).exists():
            return True
        if EmergencyReferral.objects.filter(patient_id=patient.id).exists():
            # Village doctors may see referred patients in open referral queue
            return True
        return Appointment.objects.filter(
            doctor__user=actor,
            patient__user_id=patient_user_id,
        ).exists()

    return False


def patients_queryset_for(actor):
    """Scoped Patient queryset — prevents listing all patients."""
    from apps.patients.models import Patient

    if not actor or not actor.is_authenticated:
        return Patient.objects.none()
    if actor.is_staff:
        return Patient.objects.all()

    role = getattr(actor, 'role', None)
    if role == 'user':
        return Patient.objects.filter(user=actor)

    if role == 'asha_worker':
        village = asha_assigned_village(actor)
        if not village:
            return Patient.objects.none()
        return Patient.objects.filter(
            Q(user__village__iexact=village)
        )

    if role == 'doctor':
        from apps.consultations.models import Appointment
        from apps.alerts.models import EmergencyReferral, EmergencyAlert

        appt_ids = list(
            Appointment.objects.filter(doctor__user=actor).values_list('patient_id', flat=True)
        )
        ref_ids = list(EmergencyReferral.objects.values_list('patient_id', flat=True)[:500])
        alert_user_ids = list(
            EmergencyAlert.objects.filter(
                Q(assigned_doctor__user=actor) | Q(is_resolved=False)
            ).values_list('user_id', flat=True)[:500]
        )
        return Patient.objects.filter(
            Q(id__in=appt_ids) | Q(id__in=ref_ids) | Q(user_id__in=alert_user_ids)
        ).distinct()

    if role == 'medical_staff':
        return Patient.objects.none()

    return Patient.objects.none()


def strip_client_identity_fields(data):
    """Remove fields that must be derived server-side."""
    if not hasattr(data, 'copy'):
        return data
    cleaned = data.copy()
    for key in (
        'user', 'user_id', 'role', 'doctor', 'doctor_id', 'vet', 'vet_id',
        'asha_worker', 'asha_worker_id', 'is_staff', 'is_superuser',
    ):
        if key in cleaned:
            cleaned.pop(key)
    return cleaned


def validate_client_timestamp(value, max_skew_days=30):
    """
    Reject absurd future/past timestamps for sync replay hygiene.
    Returns (ok: bool, error: str|None).
    """
    from datetime import timedelta
    from django.utils import timezone
    from django.utils.dateparse import parse_datetime

    if value is None or value == '':
        return True, None
    if hasattr(value, 'tzinfo'):
        dt = value
    else:
        dt = parse_datetime(str(value))
        if dt is None:
            return False, 'Invalid timestamp.'
    if timezone.is_naive(dt):
        dt = timezone.make_aware(dt, timezone.get_current_timezone())
    now = timezone.now()
    if dt > now + timedelta(hours=1):
        return False, 'Timestamp is in the future.'
    if dt < now - timedelta(days=max_skew_days):
        return False, 'Timestamp is too old.'
    return True, None
