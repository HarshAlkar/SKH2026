from django.db import models
from django.conf import settings

from apps.patients.models import Patient

class ASHAWorker(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, related_name='asha_profile', on_delete=models.CASCADE)
    worker_id = models.CharField(max_length=50, blank=True, null=True)
    district = models.CharField(max_length=100, blank=True, null=True)
    assigned_village = models.CharField(max_length=100)
    phc_center = models.CharField(max_length=200)

    def __str__(self):
        return f"ASHA Worker: {self.user.name or self.user.username} - {self.assigned_village}"

class VillageVisit(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('COMPLETED', 'Completed'),
        ('MISSED', 'Missed'),
    )
    
    asha_worker = models.ForeignKey(ASHAWorker, on_delete=models.CASCADE, related_name='visits')
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='visits')
    visit_date = models.DateField()
    visit_time = models.TimeField()
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='PENDING')
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Visit for {self.patient.user.name or self.patient.user.username} on {self.visit_date}"
