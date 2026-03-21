from rest_framework import serializers
from .models import Consultation
from apps.doctors.serializers import DoctorSerializer
from apps.patients.serializers import PatientSerializer

class ConsultationSerializer(serializers.ModelSerializer):
    doctor_details = DoctorSerializer(source='doctor', read_only=True)
    patient_details = PatientSerializer(source='patient', read_only=True)
    patient_name = serializers.CharField(source='patient.user.name', read_only=True)
    patient_age = serializers.IntegerField(source='patient.age', read_only=True)
    patient_village = serializers.CharField(source='patient.user.village', read_only=True)
    prescription_summary = serializers.ReadOnlyField()
    
    class Meta:
        model = Consultation
        fields = [
            'id', 'patient', 'doctor', 'doctor_details', 'patient_details',
            'patient_name', 'patient_age', 'patient_village', 'call_type', 
            'status', 'created_at', 'meeting_link', 'notes', 'prescription_summary'
        ]
        read_only_fields = ['status', 'created_at']
