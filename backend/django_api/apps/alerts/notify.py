from datetime import timedelta

from django.utils import timezone

from apps.asha_workers.models import ASHAWorker
from apps.doctors.models import Doctor

from .models import AlertNotification


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

    asha = None
    village = getattr(patient_user, "village", None)
    if village:
        asha = ASHAWorker.objects.filter(assigned_village__iexact=village).first()

    doctor = Doctor.objects.filter(is_available=True).first() or Doctor.objects.first()
    notification = AlertNotification.objects.create(
        patient=patient_user,
        doctor=doctor,
        asha_worker=asha,
        disease=disease or "Health alert",
        severity=severity or "Moderate",
    )
    return notification, True
