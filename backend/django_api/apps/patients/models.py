from django.db import models
from django.conf import settings

class Patient(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, related_name='patient_profile', on_delete=models.CASCADE)
    age = models.IntegerField()
    gender = models.CharField(max_length=10)
    blood_group = models.CharField(max_length=5, blank=True)
    address = models.TextField()
    medical_history = models.TextField(blank=True)
    allergies = models.TextField(blank=True, null=True)
    emergency_notes = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"Patient: {self.user.username}"

class PatientReport(models.Model):
    patient = models.ForeignKey(Patient, related_name='reports', on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    report_file = models.FileField(upload_to='reports/', null=True, blank=True)
    report_image = models.ImageField(upload_to='report_images/', null=True, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Report: {self.title} for {self.patient.user.username}"

class FamilyMember(models.Model):
    patient = models.ForeignKey(Patient, related_name='family_members', on_delete=models.CASCADE)
    name = models.CharField(max_length=255)
    relationship = models.CharField(max_length=100)
    phone_number = models.CharField(max_length=15)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.relationship}) - for {self.patient.user.username}"
