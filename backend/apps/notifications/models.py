from django.db import models
from patients.models import Patient

class Notification(models.Model):
    STATUS_CHOICES = [
        ('UNREAD', 'Unread'),
        ('READ', 'Read'),
    ]

    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='notifications', null=True, blank=True)
    message = models.TextField()
    type = models.CharField(max_length=50) # AI alert, Risk alert, Consultant update
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='UNREAD')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Notification: {self.type} - {self.status}"
