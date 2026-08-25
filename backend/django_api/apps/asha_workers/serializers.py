from rest_framework import serializers
from .models import VillageVisit


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
