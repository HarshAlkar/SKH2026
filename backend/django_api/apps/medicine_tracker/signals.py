from django.db.models.signals import post_save
from django.dispatch import receiver
from apps.prescriptions.models import Prescription
from .models import MedicineSchedule
from django.utils import timezone
import datetime
import json

@receiver(post_save, sender=Prescription)
def sync_prescription_to_schedule(sender, instance, created, **kwargs):
    if not created:
        return

    patient = instance.patient
    if patient is None and instance.consultation is not None:
        patient = instance.consultation.patient
    if patient is None:
        return

    medications_text = instance.medications or ""

    try:
        meds = json.loads(medications_text)
        if not isinstance(meds, list):
            meds = [medications_text]
    except Exception:
        meds = medications_text.replace(',', '\n').split('\n')

    for med_raw in meds:
        med_name = str(med_raw).strip()
        if not med_name:
            continue

        MedicineSchedule.objects.create(
            patient=patient,
            medicine_name=med_name[:120],
            dosage="As prescribed",
            frequency="Daily",
            start_date=timezone.now().date(),
            end_date=timezone.now().date() + datetime.timedelta(days=7),
            reminder_time=datetime.time(9, 0),
            instructions=instance.dosage_instructions or "",
        )
