from django.db import models
from django.conf import settings

class Doctor(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, related_name='doctor_profile', on_delete=models.CASCADE)
    specialization = models.CharField(max_length=100)
    experience_years = models.IntegerField()
    hospital_name = models.CharField(max_length=200)
    license_number = models.CharField(max_length=50, null=True, blank=True)
    qualification = models.CharField(max_length=200, null=True, blank=True)
    bio = models.TextField(null=True, blank=True)
    is_available = models.BooleanField(default=True)

    def __str__(self):
        return f"Dr. {self.user.name or self.user.username} ({self.specialization})"
