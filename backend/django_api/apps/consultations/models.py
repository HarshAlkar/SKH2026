from django.db import models
from apps.patients.models import Patient
from apps.doctors.models import Doctor

class Consultation(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('ONGOING', 'Ongoing'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
        ('FOLLOW_UP', 'Follow-up'),
    )
    CALL_TYPE_CHOICES = (
        ('AUDIO', 'Audio'),
        ('VIDEO', 'Video'),
    )
    
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='consultations')
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE, related_name='consultations')
    call_type = models.CharField(max_length=10, choices=CALL_TYPE_CHOICES, default='VIDEO')
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='PENDING')
    created_at = models.DateTimeField(auto_now_add=True)
    meeting_link = models.URLField(blank=True, null=True)
    notes = models.TextField(blank=True)

    @property
    def prescription_summary(self):
        try:
            prescription = self.prescription
            medications = prescription.medications.all()
            if not medications:
                return "No medication prescribed."
            
            summaries = []
            for med in medications:
                summaries.append(f"{med.name} {med.dosage}")
            
            # Combine summaries and truncate if too long
            summary_str = ", ".join(summaries)
            if len(summary_str) > 100:
                return summary_str[:97] + "..."
            return summary_str
        except Exception:
            return "No prescription summary available."

    def __str__(self):
        return f"Consultation {self.id}: {self.patient} with {self.doctor} ({self.call_type})"
