from rest_framework import serializers
from .models import EmergencyReferral
from patients.models import Patient
from asha_worker.models import AshaWorker

class EmergencyReferralSerializer(serializers.ModelSerializer):
    patient_name = serializers.ReadOnlyField(source='patient.name')
    asha_worker_name = serializers.ReadOnlyField(source='asha_worker.name')

    class Meta:
        model = EmergencyReferral
        fields = '__all__'
