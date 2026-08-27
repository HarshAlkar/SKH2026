from django.db import models
from django.conf import settings

class EmergencyAlert(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    alert_type = models.CharField(max_length=50, default='General Emergency')
    location = models.CharField(max_length=255, blank=True, null=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    assigned_doctor = models.ForeignKey(
        'doctors.Doctor',
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='assigned_emergencies',
    )
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


class EmergencyReferral(models.Model):
    SEVERITY_CHOICES = [
        ('normal', 'Normal'),
        ('moderate', 'Moderate'),
        ('critical', 'Critical'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('sent', 'Sent'),
        ('accepted', 'Accepted'),
        ('completed', 'Completed'),
    ]

    patient = models.ForeignKey('patients.Patient', on_delete=models.CASCADE, related_name='emergency_referrals')
    asha_worker = models.ForeignKey(
        'asha_workers.ASHAWorker',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='emergency_referrals',
    )
    symptoms = models.TextField(blank=True)
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES, default='moderate')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='sent')
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Referral {self.patient_id} ({self.severity})"
