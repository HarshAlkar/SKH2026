from django.db import models
from django.conf import settings
from apps.patients.models import Patient

class SymptomRecord(models.Model):
    patient = models.ForeignKey(Patient, related_name='symptom_records', on_delete=models.CASCADE)
    symptoms_text = models.TextField()
    analysis_result = models.JSONField(blank=True, null=True)
    severity_score = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Analysis for {self.patient.user.username} - {self.created_at.date()}"

class VoiceSymptomInput(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    recognized_text = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Voice: {self.recognized_text[:20]}... by {self.user.username}"

class SymptomAnalysis(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    symptoms_text = models.TextField()
    predicted_disease = models.CharField(max_length=100)
    severity_level = models.CharField(max_length=50) # Low, Moderate, High, Critical
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.predicted_disease} ({self.severity_level}) - {self.user.username}"
