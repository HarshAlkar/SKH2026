from django.db import models
from apps.patients.models import Patient

class HealthRecord(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='health_records')
    temperature = models.CharField(max_length=10, blank=True, null=True)
    blood_pressure = models.CharField(max_length=20, blank=True, null=True)
    blood_sugar = models.CharField(max_length=10, blank=True, null=True)
    weight = models.CharField(max_length=10, blank=True, null=True)
    symptoms = models.TextField(blank=True, null=True)
    risk_level = models.CharField(max_length=20, default='normal', choices=(
        ('normal', 'Normal'),
        ('moderate', 'Moderate'),
        ('highRisk', 'High Risk')
    ))
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Record for {self.patient.user.name or self.patient.user.username}"
