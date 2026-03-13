from django.db import models
from django.conf import settings

class Doctor(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, related_name='doctor_profile', on_delete=models.CASCADE)
    specialization = models.CharField(max_length=100)
    qualification = models.CharField(max_length=100)
    experience_years = models.IntegerField()
    bio = models.TextField(blank=True)
    is_available = models.BooleanField(default=True)

    def __str__(self):
        return f"Dr. {self.user.last_name} ({self.specialization})"
