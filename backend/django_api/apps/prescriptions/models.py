from django.db import models
from apps.patients.models import Patient
from apps.doctors.models import Doctor
from apps.consultations.models import Consultation


class Prescription(models.Model):
    TYPE_DIGITAL = 'digital'
    TYPE_HANDWRITTEN = 'handwritten'
    TYPE_CHOICES = [
        (TYPE_DIGITAL, 'Digital'),
        (TYPE_HANDWRITTEN, 'Handwritten'),
    ]

    STATUS_ACTIVE = 'active'
    STATUS_CHOICES = [
        (STATUS_ACTIVE, 'Active'),
    ]

    patient = models.ForeignKey(
        Patient, on_delete=models.CASCADE, related_name='prescriptions', null=True, blank=True
    )
    doctor = models.ForeignKey(
        Doctor, on_delete=models.CASCADE, related_name='prescriptions', null=True, blank=True
    )
    medications = models.TextField(blank=True, default='')
    dosage_instructions = models.TextField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    issued_at = models.DateTimeField(auto_now_add=True)
    consultation = models.OneToOneField(
        Consultation, on_delete=models.SET_NULL, null=True, blank=True
    )
    prescription_type = models.CharField(
        max_length=32, choices=TYPE_CHOICES, default=TYPE_DIGITAL, db_index=True
    )
    file = models.FileField(upload_to='prescription_documents/', null=True, blank=True)
    file_content_type = models.CharField(max_length=64, blank=True, default='')
    file_size = models.PositiveIntegerField(null=True, blank=True)
    status = models.CharField(
        max_length=32, choices=STATUS_CHOICES, default=STATUS_ACTIVE, db_index=True
    )

    def __str__(self):
        patient_label = 'unknown'
        doctor_label = 'unknown'
        if self.patient_id and self.patient and self.patient.user_id:
            patient_label = self.patient.user.name or self.patient.user.username
        if self.doctor_id and self.doctor and self.doctor.user_id:
            doctor_label = self.doctor.user.name or self.doctor.user.username
        return f"Prescription for {patient_label} by Dr. {doctor_label}"
