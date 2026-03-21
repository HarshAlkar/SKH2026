from django.db.models.signals import post_save
from django.dispatch import receiver
from apps.prescriptions.models import Medication
from .models import MedicineSchedule
from django.utils import timezone
import datetime
import re

@receiver(post_save, sender=Medication)
def sync_medication_to_schedule(sender, instance, created, **kwargs):
    if created:
        prescription = instance.prescription
        patient = prescription.consultation.patient
        
        # Parse duration to get end date (e.g., "3 days" -> current + 3)
        duration_days = 7 # Default
        if instance.duration:
            match = re.search(r'(\d+)', instance.duration)
            if match:
                duration_days = int(match.group(1))

        # Default values for sync from Medication fields
        MedicineSchedule.objects.create(
            patient=patient,
            medicine_name=instance.name,
            dosage=instance.dosage,
            frequency=instance.timing or "As prescribed",
            start_date=timezone.now().date(),
            end_date=timezone.now().date() + datetime.timedelta(days=duration_days),
            reminder_time=datetime.time(9, 0), # Default 9 AM
            instructions=instance.instructions
        )
