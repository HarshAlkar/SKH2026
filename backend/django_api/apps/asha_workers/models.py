from django.db import models
from django.conf import settings

from apps.patients.models import Patient


class ASHAWorker(models.Model):
    VERIFICATION_CHOICES = (
        ('INCOMPLETE', 'Incomplete'),
        ('PENDING_VERIFICATION', 'Pending Verification'),
        ('VERIFIED', 'Verified'),
        ('REJECTED', 'Rejected'),
    )

    user = models.OneToOneField(settings.AUTH_USER_MODEL, related_name='asha_profile', on_delete=models.CASCADE)
    assigned_village = models.CharField(max_length=100)
    phc_center = models.CharField(max_length=200)
    worker_id = models.CharField(max_length=50, blank=True, default='')
    district = models.CharField(max_length=100, blank=True, default='')

    verification_status = models.CharField(max_length=20, choices=VERIFICATION_CHOICES, default='INCOMPLETE')
    rejection_reason = models.TextField(null=True, blank=True)
    verified_at = models.DateTimeField(null=True, blank=True)
    verified_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name='verified_asha_workers',
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
    )

    def __str__(self):
        return f"ASHA Worker: {self.user.name or self.user.username} - {self.assigned_village} ({self.verification_status})"


class ASHADocument(models.Model):
    asha_worker = models.ForeignKey(ASHAWorker, related_name='documents', on_delete=models.CASCADE)
    document_type = models.CharField(max_length=50)
    file = models.FileField(upload_to='asha_documents/')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.asha_worker.user.name} - {self.document_type}"


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
