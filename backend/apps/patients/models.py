from django.db import models
from asha_worker.models import AshaWorker

class Patient(models.Model):
    GENDER_CHOICES = [
        ('M', 'Male'),
        ('F', 'Female'),
        ('O', 'Other'),
    ]
    
    name = models.CharField(max_length=255)
    age = models.IntegerField()
    gender = models.CharField(max_length=1, choices=GENDER_CHOICES)
    village = models.CharField(max_length=100)
    phone_number = models.CharField(max_length=15)
    blood_group = models.CharField(max_length=5)
    existing_disease = models.TextField(blank=True, null=True)
    created_by = models.ForeignKey(AshaWorker, on_delete=models.CASCADE, related_name='patients')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name
