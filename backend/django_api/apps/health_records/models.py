from django.db import models
from apps.patients.models import Patient


class Report(models.Model):
    patient = models.ForeignKey(Patient, related_name='reports', on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    file_path = models.FileField(upload_to='health_reports/')
    created_at = models.DateTimeField(auto_now_add=True)
    report_type = models.CharField(max_length=50, default='Lab Report')
    
    def __str__(self):
        return f"{self.title} for {self.patient.user.username}"
