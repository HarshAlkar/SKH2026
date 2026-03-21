from rest_framework import serializers
from .models import Patient
from apps.users.models import User

class PatientSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source='user.name', read_only=True)
    username = serializers.CharField(source='user.username', read_only=True)
    village = serializers.CharField(source='user.village', read_only=True)
    phone_number = serializers.CharField(source='user.phone_number', read_only=True)

    class Meta:
        model = Patient
        fields = ['id', 'user', 'name', 'username', 'age', 'gender', 'blood_group', 'village', 'phone_number', 'address', 'medical_history']
        read_only_fields = ['id', 'user']
