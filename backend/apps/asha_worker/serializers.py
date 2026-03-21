from rest_framework import serializers
from .models import AshaWorker

class AshaWorkerSerializer(serializers.ModelSerializer):
    class Meta:
        model = AshaWorker
        fields = ('id', 'name', 'worker_id', 'phone_number', 'district', 'village', 'password', 'created_at')
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        user = AshaWorker.objects.create_user(**validated_data)
        return user
