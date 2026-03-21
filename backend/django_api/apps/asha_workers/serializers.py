from rest_framework import serializers
from .models import VillageVisit, ASHAWorker

class VillageVisitSerializer(serializers.ModelSerializer):
    patient_name = serializers.CharField(source='patient.user.name', read_only=True)
    village = serializers.CharField(source='patient.user.village', read_only=True)

    class Meta:
        model = VillageVisit
        fields = ['id', 'patient', 'patient_name', 'village', 'visit_date', 'visit_time', 'status', 'notes', 'created_at']
        read_only_fields = ['id', 'created_at']
