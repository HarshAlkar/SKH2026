from rest_framework import serializers
from .models import Doctor, DoctorDocument

class DoctorDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoctorDocument
        fields = ['id', 'document_type', 'file', 'uploaded_at']

class DoctorSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()
    phone_number = serializers.CharField(source='user.phone_number', read_only=True)
    documents = serializers.SerializerMethodField()

    def get_full_name(self, obj):
        return obj.user.name or obj.user.username or f"Doctor #{obj.id}"

    def get_documents(self, obj):
        request = self.context.get('request')
        viewer = getattr(request, 'user', None) if request else None
        if not viewer or not viewer.is_authenticated:
            return []
        if viewer.is_staff or viewer.pk == obj.user_id:
            return DoctorDocumentSerializer(obj.documents.all(), many=True, context=self.context).data
        return []

    class Meta:
        model = Doctor
        fields = [
            'id', 'user_id', 'full_name', 'phone_number', 'specialization',
            'qualification', 'experience_years', 'hospital_name', 'bio',
            'is_available', 'is_veterinarian', 'verification_status',
            'rejection_reason', 'documents'
        ]
