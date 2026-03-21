from rest_framework import serializers
from .models import Doctor

class DoctorSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(source='user.name', required=False, allow_blank=True)
    phone_number = serializers.CharField(source='user.phone_number', required=False, allow_blank=True)
    email = serializers.EmailField(source='user.email', required=False, allow_blank=True)

    class Meta:
        model = Doctor
        fields = [
            'id', 'user_id', 'full_name', 'phone_number', 'email',
            'specialization', 'qualification', 'experience_years',
            'hospital_name', 'bio', 'is_available',
            'consultation_mode', 'clinic_location', 'working_hours',
            'profile_photo'
        ]

    def update(self, instance, validated_data):
        user_data = validated_data.pop('user', {})
        
        # Update User model
        if 'name' in user_data:
            instance.user.name = user_data['name']
        if 'phone_number' in user_data:
            instance.user.phone_number = user_data['phone_number']
        if 'email' in user_data:
            instance.user.email = user_data['email']
        if user_data:
            instance.user.save()

        # Update Doctor model
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        return instance
