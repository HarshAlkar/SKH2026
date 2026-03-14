from rest_framework import serializers
from .models import Prescription
from apps.consultations.models import Consultation

class PrescriptionSerializer(serializers.ModelSerializer):
    doctor_name = serializers.CharField(source='consultation.doctor.user.get_full_name', read_only=True)
    patient_name = serializers.CharField(source='consultation.patient.user.get_full_name', read_only=True)

    class Meta:
        model = Prescription
        fields = '__all__'
