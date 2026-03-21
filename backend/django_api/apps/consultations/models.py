from django.db import models
from apps.patients.models import Patient
from apps.doctors.models import Doctor

class Consultation(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('ONGOING', 'Ongoing'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
    )
    CALL_TYPE_CHOICES = (
        ('AUDIO', 'Audio'),
        ('VIDEO', 'Video'),
    )
    
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='consultations')
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE, related_name='consultations')
    call_type = models.CharField(max_length=10, choices=CALL_TYPE_CHOICES, default='VIDEO')
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='PENDING')
    created_at = models.DateTimeField(auto_now_add=True)
    end_time = models.DateTimeField(null=True, blank=True)
    meeting_link = models.URLField(blank=True, null=True)
    notes = models.TextField(blank=True)

    def __str__(self):
        return f"Consultation {self.id}: {self.patient} with {self.doctor} ({self.call_type})"
