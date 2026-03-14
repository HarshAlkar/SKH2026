from django.db import models
from patients.models import Patient

class Consultation(models.Model):
    URGENCY_CHOICES = [
        ('LOW', 'Low'),
        ('MEDIUM', 'Medium'),
        ('HIGH', 'High'),
    ]
    
    STATUS_CHOICES = [
        ('REQUESTED', 'Requested'),
        ('APPROVED', 'Approved'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
    ]

    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='consultations')
    symptoms = models.TextField()
    urgency_level = models.CharField(max_length=20, choices=URGENCY_CHOICES)
    consultation_type = models.CharField(max_length=50) # e.g. Video Call, Audio Call
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='REQUESTED')
    doctor_advice = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Consultation for {self.patient.name} - {self.status}"
