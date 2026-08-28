from django.db import models
from django.conf import settings

class Doctor(models.Model):
    VERIFICATION_CHOICES = (
        ('INCOMPLETE', 'Incomplete'),
        ('PENDING_VERIFICATION', 'Pending Verification'),
        ('VERIFIED', 'Verified'),
        ('REJECTED', 'Rejected'),
    )

    user = models.OneToOneField(settings.AUTH_USER_MODEL, related_name='doctor_profile', on_delete=models.CASCADE)
    specialization = models.CharField(max_length=100)
    experience_years = models.IntegerField()
    hospital_name = models.CharField(max_length=200)
    license_number = models.CharField(max_length=50, null=True, blank=True)
    qualification = models.CharField(max_length=200, null=True, blank=True)
    bio = models.TextField(null=True, blank=True)
    is_available = models.BooleanField(default=True)

    # Verification Fields
    verification_status = models.CharField(max_length=20, choices=VERIFICATION_CHOICES, default='INCOMPLETE')
    rejection_reason = models.TextField(null=True, blank=True)
    verified_at = models.DateTimeField(null=True, blank=True)
    verified_by = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='verified_doctors', null=True, blank=True, on_delete=models.SET_NULL)

    def __str__(self):
        return f"Dr. {self.user.name or self.user.username} ({self.specialization}) - {self.verification_status}"


class DoctorDocument(models.Model):
    doctor = models.ForeignKey(Doctor, related_name='documents', on_delete=models.CASCADE)
    document_type = models.CharField(max_length=50) # e.g. 'license', 'degree', 'id_proof'
    file = models.FileField(upload_to='doctor_documents/')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.doctor.user.name} - {self.document_type}"
