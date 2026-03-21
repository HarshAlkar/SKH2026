from django.db import models
from apps.patients.models import Patient
from apps.doctors.models import Doctor
from apps.consultations.models import Consultation

class Prescription(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='prescriptions', null=True, blank=True)
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE, related_name='prescriptions', null=True, blank=True)
    medications = models.TextField() # List of meds
    dosage_instructions = models.TextField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    issued_at = models.DateTimeField(auto_now_add=True)
    consultation = models.OneToOneField(Consultation, on_delete=models.SET_NULL, null=True, blank=True)

    def __str__(self):
        return f"Prescription for {self.patient.user.name or self.patient.user.username} by Dr. {self.doctor.user.name or self.doctor.user.username}"
