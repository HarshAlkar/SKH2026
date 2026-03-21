from django.db import models
from patients.models import Patient
from asha_worker.models import AshaWorker

class EmergencyReferral(models.Model):
    SEVERITY_CHOICES = [
        ('normal', 'Normal'),
        ('moderate', 'Moderate'),
        ('critical', 'Critical'),
    ]
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('sent', 'Sent'),
        ('accepted', 'Accepted'),
        ('completed', 'Completed'),
    ]

    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='emergency_referrals')
    asha_worker = models.ForeignKey(AshaWorker, on_delete=models.CASCADE, related_name='emergency_referrals')
    patient_id_display = models.CharField(max_length=50) # e.g. ASHA-2023-4491
    symptoms = models.JSONField(default=list) # List of symptoms
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    notes = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Emergency Referral for {self.patient.name} - {self.severity}"

