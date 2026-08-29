from datetime import timedelta

from django.db.models import Q
from django.utils import timezone

from apps.asha_workers.models import ASHAWorker
from apps.doctors.models import Doctor

from .models import AlertNotification


def find_asha_for_village(village):
    village = (village or "").strip()
    if not village:
        return None
    qs = ASHAWorker.objects.select_related("user")
    exact = qs.filter(
        Q(assigned_village__iexact=village) | Q(user__village__iexact=village)
    ).first()
    if exact:
        return exact
    return qs.filter(
        Q(assigned_village__icontains=village) | Q(user__village__icontains=village)
    ).first()


def notify_village_care_team(patient_user, disease, severity, dedupe_minutes=30):
    """Create (or reuse) an AlertNotification for the patient's village ASHA and a doctor."""
    if patient_user is None:
        return None, False

    cutoff = timezone.now() - timedelta(minutes=dedupe_minutes)
    existing = (
        AlertNotification.objects.filter(
            patient=patient_user,
            disease=disease,
            created_at__gte=cutoff,
        )
        .order_by("-created_at")
        .first()
    )
    if existing:
        return existing, False

    village = getattr(patient_user, "village", None)
    asha = find_asha_for_village(village)

    doctor = Doctor.objects.filter(is_available=True).first() or Doctor.objects.first()
    notification = AlertNotification.objects.create(
        patient=patient_user,
        doctor=doctor,
        asha_worker=asha,
        disease=disease or "Health alert",
        severity=severity or "Moderate",
    )
    return notification, True


def notify_livestock_care_team(owner_user, condition, severity, species='', dedupe_minutes=30):
    """Escalate animal screening High/Critical to ASHA + veterinarian (or any doctor)."""
    if owner_user is None:
        return None, False

    label = f"[Livestock/{species or 'ANIMAL'}] {condition}"
    cutoff = timezone.now() - timedelta(minutes=dedupe_minutes)
    existing = (
        AlertNotification.objects.filter(
            patient=owner_user,
            disease=label,
            created_at__gte=cutoff,
        )
        .order_by("-created_at")
        .first()
    )
    if existing:
        return existing, False

    village = getattr(owner_user, "village", None)
    asha = find_asha_for_village(village)
    vet = (
        Doctor.objects.filter(is_veterinarian=True, is_available=True).first()
        or Doctor.objects.filter(is_veterinarian=True).first()
        or Doctor.objects.filter(specialization__icontains='veterinar').first()
        or Doctor.objects.filter(is_available=True).first()
        or Doctor.objects.first()
    )
    notification = AlertNotification.objects.create(
        patient=owner_user,
        doctor=vet,
        asha_worker=asha,
        disease=label[:200],
        severity=severity or "Moderate",
    )
    return notification, True
