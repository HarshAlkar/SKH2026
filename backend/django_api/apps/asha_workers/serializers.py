from rest_framework import serializers
from .models import VillageVisit, ASHAWorker, ASHADocument


class VillageVisitSerializer(serializers.ModelSerializer):
    patient_name = serializers.SerializerMethodField()
    village = serializers.CharField(source='patient.user.village', read_only=True)
    patient_id = serializers.IntegerField(source='patient.id', read_only=True)

    class Meta:
        model = VillageVisit
        fields = [
            'id', 'patient', 'patient_id', 'patient_name', 'village',
            'visit_date', 'visit_time', 'status', 'notes', 'created_at',
        ]
        extra_kwargs = {'patient': {'write_only': True}}

    def get_patient_name(self, obj):
        return obj.patient.user.name or obj.patient.user.username


class ASHADocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = ASHADocument
        fields = ['id', 'document_type', 'file', 'uploaded_at']


class ASHAWorkerSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()
    phone_number = serializers.CharField(source='user.phone_number', read_only=True)
    documents = ASHADocumentSerializer(many=True, read_only=True)

    def get_full_name(self, obj):
        return obj.user.name or obj.user.username or f"ASHA #{obj.id}"

    class Meta:
        model = ASHAWorker
        fields = [
            'id', 'user_id', 'full_name', 'phone_number', 'assigned_village',
            'phc_center', 'worker_id', 'district', 'verification_status',
            'rejection_reason', 'documents',
        ]
