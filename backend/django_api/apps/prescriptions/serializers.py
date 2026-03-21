from rest_framework import serializers
from .models import Prescription

class PrescriptionSerializer(serializers.ModelSerializer):
    doctor_name = serializers.CharField(source='doctor.user.name', read_only=True)
    patient_name = serializers.CharField(source='patient.user.name', read_only=True)

    class Meta:
        model = Prescription
        fields = ['id', 'patient', 'doctor', 'medications', 'dosage_instructions', 'notes', 'issued_at', 'consultation', 'doctor_name', 'patient_name']
