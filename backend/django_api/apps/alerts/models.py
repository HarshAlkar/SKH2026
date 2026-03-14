from django.db import models
from django.conf import settings

class EmergencyAlert(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    alert_type = models.CharField(max_length=50, default='General Emergency')
    location = models.CharField(max_length=255, blank=True, null=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    is_resolved = models.BooleanField(default=False)

    def __str__(self):
        return f"Alert from {self.user.username} - {self.alert_type}"

class AlertNotification(models.Model):
    patient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    doctor = models.ForeignKey('doctors.Doctor', on_delete=models.SET_NULL, null=True, blank=True)
    asha_worker = models.ForeignKey('asha_workers.ASHAWorker', on_delete=models.SET_NULL, null=True, blank=True)
    disease = models.CharField(max_length=100)
    severity = models.CharField(max_length=50)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Severity Alert ({self.severity}): {self.disease} for {self.patient.username}"
