from django.db import models
from django.conf import settings
from apps.patients.models import Patient
from apps.doctors.models import Doctor
from apps.asha_workers.models import ASHAWorker


class Consultation(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('ONGOING', 'Ongoing'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
    )
    CALL_TYPE_CHOICES = (
        ('AUDIO', 'Audio'),
        ('VIDEO', 'Video'),
    )

    patient = models.ForeignKey(
        Patient,
        on_delete=models.CASCADE,
        related_name='consultations',
        null=True,
        blank=True,
    )
    doctor = models.ForeignKey(
        Doctor,
        on_delete=models.CASCADE,
        related_name='consultations',
        null=True,
        blank=True,
    )
    asha_worker = models.ForeignKey(
        ASHAWorker,
        on_delete=models.SET_NULL,
        related_name='consultations',
        null=True,
        blank=True,
    )
    initiated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='started_consultations',
    )
    call_type = models.CharField(max_length=10, choices=CALL_TYPE_CHOICES, default='VIDEO')
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='PENDING')
    created_at = models.DateTimeField(auto_now_add=True)
    end_time = models.DateTimeField(null=True, blank=True)
    meeting_link = models.URLField(blank=True, null=True)
    notes = models.TextField(blank=True)
    is_emergency = models.BooleanField(default=False)

    def __str__(self):
        return f"Consultation {self.id} ({self.call_type})"
