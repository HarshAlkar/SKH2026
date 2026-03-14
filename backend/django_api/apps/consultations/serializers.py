from rest_framework import serializers
from .models import Consultation
from apps.doctors.serializers import DoctorSerializer

class ConsultationSerializer(serializers.ModelSerializer):
    doctor_details = DoctorSerializer(source='doctor', read_only=True)
    patient_name = serializers.CharField(source='patient.user.name', read_only=True)
    
    class Meta:
        model = Consultation
        fields = [
            'id', 'patient', 'doctor', 'doctor_details', 'patient_name',
            'call_type', 'status', 'created_at', 'meeting_link', 'notes'
        ]
        read_only_fields = ['status', 'created_at']
