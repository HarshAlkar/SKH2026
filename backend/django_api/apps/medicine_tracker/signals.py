from django.db.models.signals import post_save
from django.dispatch import receiver
from apps.prescriptions.models import Prescription
from .models import MedicineSchedule
from django.utils import timezone
import datetime
import json

@receiver(post_save, sender=Prescription)
def sync_prescription_to_schedule(sender, instance, created, **kwargs):
    if created:
        patient = instance.consultation.patient
        medications_text = instance.medications
        
        # Try to parse if it's JSON list
        try:
            meds = json.loads(medications_text)
            if not isinstance(meds, list):
                meds = [medications_text]
        except:
            # Not JSON, split by lines or commas
            meds = medications_text.replace(',', '\n').split('\n')

        for med_raw in meds:
            med_name = med_raw.strip()
            if not med_name:
                continue
                
            # Default values for sync
            MedicineSchedule.objects.create(
                patient=patient,
                medicine_name=med_name,
                dosage="As prescribed",
                frequency="Daily",
                start_date=timezone.now().date(),
                end_date=timezone.now().date() + datetime.timedelta(days=7), # Default 1 week
                reminder_time=datetime.time(9, 0), # Default 9 AM
                instructions=instance.dosage_instructions
            )
