from django.db import models
from apps.consultations.models import Consultation

class Prescription(models.Model):
    consultation = models.OneToOneField(Consultation, on_delete=models.CASCADE)
    medications = models.TextField() # Standardized format or JSON string
    dosage_instructions = models.TextField()
    issued_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Prescription for {self.consultation}"
