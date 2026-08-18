from rest_framework import serializers
from .models import Consultation
from apps.doctors.serializers import DoctorSerializer


class ConsultationSerializer(serializers.ModelSerializer):
    doctor_details = DoctorSerializer(source='doctor', read_only=True)
    patient_name = serializers.SerializerMethodField()
    patient_user_id = serializers.SerializerMethodField()

    class Meta:
        model = Consultation
        fields = [
            'id', 'patient', 'doctor', 'doctor_details', 'patient_name',
            'patient_user_id', 'initiated_by', 'call_type', 'status',
            'created_at', 'end_time', 'meeting_link', 'notes',
        ]
        read_only_fields = ['status', 'created_at', 'initiated_by']

    def get_patient_name(self, obj):
        if obj.patient and obj.patient.user:
            return obj.patient.user.name or obj.patient.user.username
        if obj.initiated_by:
            return obj.initiated_by.name or obj.initiated_by.username
        return 'Unknown'

    def get_patient_user_id(self, obj):
        if obj.patient and obj.patient.user:
            return obj.patient.user_id
        if obj.initiated_by:
            return obj.initiated_by_id
        return None
