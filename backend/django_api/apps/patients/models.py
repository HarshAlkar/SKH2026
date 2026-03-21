from django.db import models
from django.conf import settings

class Patient(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, related_name='patient_profile', on_delete=models.CASCADE)
    age = models.IntegerField(default=0)
    gender = models.CharField(max_length=20, default="Not Set")
    blood_group = models.CharField(max_length=10, blank=True)
    address = models.TextField(blank=True)
    medical_history = models.TextField(blank=True)
    
    def __str__(self):
        return f"Patient: {self.user.username}"

class FamilyMember(models.Model):
    patient = models.ForeignKey(Patient, related_name='family_members', on_delete=models.CASCADE)
    name = models.CharField(max_length=255)
    relationship = models.CharField(max_length=100) # e.g., Sister, Mother, Spouse
    age = models.IntegerField(default=0)
    phone_number = models.CharField(max_length=15, blank=True)
    
    def __str__(self):
        return f"{self.name} ({self.relationship} of {self.patient.user.username})"

class EmergencyContact(models.Model):
    patient = models.OneToOneField(Patient, related_name='emergency_contact', on_delete=models.CASCADE)
    contact_name = models.CharField(max_length=255, blank=True)
    relationship = models.CharField(max_length=100, blank=True)
    phone_number = models.CharField(max_length=15, blank=True)
    alternative_phone = models.CharField(max_length=15, blank=True)
    blood_group = models.CharField(max_length=10, blank=True)
    medical_notes = models.TextField(blank=True)   # NEW: medical conditions / notes
    allergies = models.TextField(blank=True)       # NEW: allergy information
    
    def __str__(self):
        return f"Emergency: {self.contact_name} for {self.patient.user.username}"

