from django.db import models
from apps.patients.models import Patient

from django.utils import timezone
import datetime

class MedicineSchedule(models.Model):
    patient = models.ForeignKey(Patient, related_name='medicine_schedules', on_delete=models.CASCADE)
    medicine_name = models.CharField(max_length=255)
    dosage = models.CharField(max_length=100)
    frequency = models.CharField(max_length=100) # e.g., 'Daily', 'Twice a day'
    start_date = models.DateField(default=timezone.now)
    end_date = models.DateField(default=timezone.now)
    reminder_time = models.TimeField(default=datetime.time(9, 0))
    instructions = models.TextField(blank=True, null=True)
    is_taken = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.medicine_name} - {self.patient.user.username}"

class MedicineRecord(models.Model):
    """Tracks actual intake instances"""
    schedule = models.ForeignKey(MedicineSchedule, on_delete=models.CASCADE)
    taken_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, default='Taken') # Taken, Skipped, Snoozed
