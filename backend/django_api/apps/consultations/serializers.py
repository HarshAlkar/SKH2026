from rest_framework import serializers
from .models import Consultation
from apps.doctors.serializers import DoctorSerializer


class ConsultationSerializer(serializers.ModelSerializer):
    doctor_details = DoctorSerializer(source='doctor', read_only=True)
    doctor_name = serializers.SerializerMethodField()
    patient_name = serializers.SerializerMethodField()
    patient_user_id = serializers.SerializerMethodField()
    asha_user_id = serializers.SerializerMethodField()
    asha_name = serializers.SerializerMethodField()

    class Meta:
        model = Consultation
        fields = [
            'id', 'patient', 'doctor', 'asha_worker', 'doctor_details',
            'doctor_name', 'patient_name', 'patient_user_id', 'asha_user_id',
            'asha_name', 'initiated_by', 'call_type', 'status',
            'created_at', 'end_time', 'meeting_link', 'notes', 'is_emergency',
        ]
        read_only_fields = ['status', 'created_at', 'initiated_by']

    def get_doctor_name(self, obj):
        if obj.doctor and obj.doctor.user:
            return obj.doctor.user.name or obj.doctor.user.username
        return None

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


class AppointmentSerializer(serializers.ModelSerializer):
    patient_name = serializers.SerializerMethodField()
    patient_user_id = serializers.SerializerMethodField()
    patient_age = serializers.SerializerMethodField()
    patient_gender = serializers.SerializerMethodField()
    patient_village = serializers.SerializerMethodField()
    patient_phone = serializers.SerializerMethodField()
    patient_blood_group = serializers.SerializerMethodField()
    history_summary = serializers.SerializerMethodField()
    last_prescription = serializers.SerializerMethodField()
    doctor_name = serializers.SerializerMethodField()

    class Meta:
        from .models import Appointment
        model = Appointment
        fields = [
            'id', 'patient', 'doctor', 'doctor_name',
            'patient_name', 'patient_user_id', 'patient_age', 'patient_gender',
            'patient_village', 'patient_phone', 'patient_blood_group',
            'appointment_date', 'appointment_time', 'consultation_type',
            'status', 'notes', 'history_summary', 'last_prescription', 'created_at',
        ]
        read_only_fields = ['created_at']

    def get_patient_name(self, obj):
        if obj.patient and obj.patient.user:
            return obj.patient.user.name or obj.patient.user.username
        return 'Patient'

    def get_patient_user_id(self, obj):
        if obj.patient and obj.patient.user:
            return obj.patient.user_id
        return None

    def get_patient_age(self, obj):
        if obj.patient:
            return obj.patient.age
        return None

    def get_patient_gender(self, obj):
        if obj.patient:
            return obj.patient.gender
        return 'Not set'

    def get_patient_village(self, obj):
        if obj.patient and obj.patient.user:
            return obj.patient.user.village or obj.patient.address or '—'
        return '—'

    def get_patient_phone(self, obj):
        if obj.patient and obj.patient.user:
            return obj.patient.user.phone_number or ''
        return ''

    def get_patient_blood_group(self, obj):
        if obj.patient:
            return obj.patient.blood_group or 'Not set'
        return 'Not set'

    def get_doctor_name(self, obj):
        if obj.doctor and obj.doctor.user:
            return obj.doctor.user.name or obj.doctor.user.username
        return 'Doctor'

    def get_history_summary(self, obj):
        if not obj.patient:
            return 'No previous health history available'
        # Check latest HealthRecord
        from apps.health_records.models import HealthRecord
        record = HealthRecord.objects.filter(patient=obj.patient).order_by('-created_at').first()
        if record and record.symptoms:
            date_str = record.created_at.strftime('%b %d, %Y')
            return f"{record.symptoms}\nLast record: {date_str}"
        if obj.patient.medical_history:
            return obj.patient.medical_history
        return 'No previous health history on file.'

    def get_last_prescription(self, obj):
        if not obj.patient:
            return None
        from apps.prescriptions.models import Prescription
        rx = Prescription.objects.filter(patient=obj.patient).order_by('-issued_at').first()
        if rx:
            dosage = f" - {rx.dosage_instructions}" if rx.dosage_instructions else ""
            return f"{rx.medications}{dosage}"
        return None

