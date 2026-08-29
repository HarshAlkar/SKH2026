from rest_framework import serializers
from .models import Doctor, DoctorDocument

class DoctorDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoctorDocument
        fields = ['id', 'document_type', 'file', 'uploaded_at']

class DoctorSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()
    phone_number = serializers.CharField(source='user.phone_number', read_only=True)
    documents = DoctorDocumentSerializer(many=True, read_only=True)

    def get_full_name(self, obj):
        return obj.user.name or obj.user.username or f"Doctor #{obj.id}"
    
    class Meta:
        model = Doctor
        fields = [
            'id', 'user_id', 'full_name', 'phone_number', 'specialization', 
            'qualification', 'experience_years', 'hospital_name', 'bio', 
            'is_available', 'verification_status', 'rejection_reason', 'documents'
        ]
