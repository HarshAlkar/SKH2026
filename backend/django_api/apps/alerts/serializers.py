from rest_framework import serializers
from .models import EmergencyAlert, AlertNotification

class EmergencyAlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyAlert
        fields = '__all__'

class AlertNotificationSerializer(serializers.ModelSerializer):
    patient_name = serializers.CharField(source='patient.name', read_only=True)
    patient_phone = serializers.CharField(source='patient.phone_number', read_only=True)
    
    class Meta:
        model = AlertNotification
        fields = '__all__'
