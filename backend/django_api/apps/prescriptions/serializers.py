from rest_framework import serializers
from .models import Prescription


class PrescriptionSerializer(serializers.ModelSerializer):
    doctor_name = serializers.CharField(source='doctor.user.name', read_only=True)
    patient_name = serializers.CharField(source='patient.user.name', read_only=True)
    has_file = serializers.SerializerMethodField()
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = Prescription
        fields = [
            'id',
            'patient',
            'doctor',
            'medications',
            'dosage_instructions',
            'notes',
            'issued_at',
            'consultation',
            'doctor_name',
            'patient_name',
            'prescription_type',
            'file_content_type',
            'file_size',
            'status',
            'has_file',
            'file_url',
        ]
        read_only_fields = [
            'doctor',
            'issued_at',
            'file_content_type',
            'file_size',
            'status',
            'has_file',
            'file_url',
        ]

    def get_has_file(self, obj):
        return bool(obj.file)

    def get_file_url(self, obj):
        if not obj.file:
            return None
        return f'/api/prescriptions/{obj.pk}/file/'
