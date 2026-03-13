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
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE)
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE)
    scheduled_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='PENDING')
    meeting_link = models.URLField(blank=True, null=True)
    notes = models.TextField(blank=True)

    def __str__(self):
        return f"Consultation: {self.patient} with {self.doctor}"
