from rest_framework import serializers
from .models import MedicineSchedule, MedicineRecord

class MedicineScheduleSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedicineSchedule
        fields = '__all__'
        read_only_fields = ('patient',)

class MedicineRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedicineRecord
        fields = '__all__'
