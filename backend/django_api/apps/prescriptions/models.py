from django.db import models
from apps.consultations.models import Consultation

class Prescription(models.Model):
    consultation = models.OneToOneField(Consultation, on_delete=models.CASCADE, related_name='prescription')
    diagnosis = models.TextField(blank=True)
    notes = models.TextField(blank=True)
    issued_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Prescription for {self.consultation}"

class Medication(models.Model):
    prescription = models.ForeignKey(Prescription, related_name='medications', on_delete=models.CASCADE)
    name = models.CharField(max_length=255)
    purpose = models.CharField(max_length=255, blank=True)
    dosage = models.CharField(max_length=100)
    route = models.CharField(max_length=100, default='Oral')
    duration = models.CharField(max_length=100)
    instructions = models.TextField(blank=True)
    timing = models.CharField(max_length=100, blank=True) # e.g., "Before Breakfast"

    def __str__(self):
        return f"{self.name} for {self.prescription}"
