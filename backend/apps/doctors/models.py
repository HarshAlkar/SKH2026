from django.db import models

class Doctor(models.Model):
    name = models.CharField(max_length=255)
    specialization = models.CharField(max_length=100)
    phone_number = models.CharField(max_length=15)
    is_on_call = models.BooleanField(default=True)
    hospital_name = models.CharField(max_length=255)

    def __str__(self):
        return f"Dr. {self.name} ({self.specialization})"
