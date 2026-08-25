from rest_framework import serializers
from .models import Consultation
from apps.doctors.serializers import DoctorSerializer


class ConsultationSerializer(serializers.ModelSerializer):
    doctor_details = DoctorSerializer(source='doctor', read_only=True)
    patient_name = serializers.SerializerMethodField()
    patient_user_id = serializers.SerializerMethodField()
    asha_user_id = serializers.SerializerMethodField()
    asha_name = serializers.SerializerMethodField()

    class Meta:
        model = Consultation
        fields = [
            'id', 'patient', 'doctor', 'asha_worker', 'doctor_details',
            'patient_name', 'patient_user_id', 'asha_user_id', 'asha_name',
            'initiated_by', 'call_type', 'status',
            'created_at', 'end_time', 'meeting_link', 'notes', 'is_emergency',
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

    def get_asha_user_id(self, obj):
        if obj.asha_worker:
            return obj.asha_worker.user_id
        return None

    def get_asha_name(self, obj):
        if obj.asha_worker and obj.asha_worker.user:
            return obj.asha_worker.user.name or obj.asha_worker.user.username
        return None
