from django.db import models
from django.conf import settings

class Patient(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, related_name='patient_profile', on_delete=models.CASCADE)
    age = models.IntegerField()
    gender = models.CharField(max_length=10)
    blood_group = models.CharField(max_length=5, blank=True)
    address = models.TextField()
    medical_history = models.TextField(blank=True)
    emergency_contact_name = models.CharField(max_length=100, blank=True, default='')
    emergency_contact_phone = models.CharField(max_length=20, blank=True, default='')

    def __str__(self):
        return f"Patient: {self.user.username}"


class EmergencyContact(models.Model):
    patient = models.ForeignKey(Patient, related_name='emergency_contacts', on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    phone = models.CharField(max_length=20)
    relationship = models.CharField(max_length=50, blank=True, default='Other')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} ({self.relationship}) - {self.phone}"
