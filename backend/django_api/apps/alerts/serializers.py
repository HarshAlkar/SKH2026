from rest_framework import serializers
from .models import EmergencyAlert, AlertNotification, EmergencyReferral

class EmergencyAlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyAlert
        fields = '__all__'
        extra_kwargs = {'user': {'read_only': True}}

class AlertNotificationSerializer(serializers.ModelSerializer):
    patient_name = serializers.SerializerMethodField()
    patient_phone = serializers.CharField(source='patient.phone_number', read_only=True)
    patient_user_id = serializers.IntegerField(source='patient.id', read_only=True)
    village = serializers.CharField(source='patient.village', read_only=True)

    class Meta:
        model = AlertNotification
        fields = '__all__'
        extra_kwargs = {
            'patient': {'read_only': True},
            'doctor': {'read_only': True},
            'asha_worker': {'read_only': True},
        }

    def get_patient_name(self, obj):
        return obj.patient.name or obj.patient.username or 'Unknown'


class EmergencyReferralSerializer(serializers.ModelSerializer):
    patient_name = serializers.SerializerMethodField()
    village = serializers.CharField(source='patient.user.village', read_only=True)

    class Meta:
        model = EmergencyReferral
        fields = '__all__'
        extra_kwargs = {'asha_worker': {'read_only': True}}

    def get_patient_name(self, obj):
        return obj.patient.user.name or obj.patient.user.username


class EmergencyAlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyAlert
        fields = '__all__'
        extra_kwargs = {'user': {'read_only': True}}

class AlertNotificationSerializer(serializers.ModelSerializer):
    patient_name = serializers.SerializerMethodField()
    patient_phone = serializers.CharField(source='patient.phone_number', read_only=True)
    patient_user_id = serializers.IntegerField(source='patient.id', read_only=True)
    village = serializers.CharField(source='patient.village', read_only=True)

    class Meta:
        model = AlertNotification
        fields = '__all__'
        extra_kwargs = {
            'patient': {'read_only': True},
            'doctor': {'read_only': True},
            'asha_worker': {'read_only': True},
        }

    def get_patient_name(self, obj):
        return obj.patient.name or obj.patient.username or 'Unknown'
