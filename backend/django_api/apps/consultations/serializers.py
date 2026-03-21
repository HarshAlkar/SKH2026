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
    recent_symptoms = serializers.SerializerMethodField()
    
    class Meta:
        model = Consultation
        fields = [
            'id', 'patient', 'doctor', 'doctor_details', 'patient_details',
            'patient_name', 'patient_age', 'patient_village', 'call_type', 
            'status', 'created_at', 'meeting_link', 'notes', 'prescription_summary',
            'recent_symptoms'
        ]
        read_only_fields = ['status', 'created_at']

    def get_recent_symptoms(self, obj):
        try:
            from apps.symptom_analysis.models import SymptomRecord
            recent_record = SymptomRecord.objects.filter(patient=obj.patient).order_by('-created_at').first()
            if recent_record and recent_record.symptoms_text:
                return recent_record.symptoms_text
            return "No recent symptoms reported."
        except Exception:
            return "No recent symptoms reported."
