from django.db import models
from django.conf import settings

class Patient(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, related_name='patient_profile', on_delete=models.CASCADE)
    age = models.IntegerField()
    gender = models.CharField(max_length=10)
    blood_group = models.CharField(max_length=5, blank=True)
    address = models.TextField()
    medical_history = models.TextField(blank=True)

    def __str__(self):
        return f"Patient: {self.user.username}"
