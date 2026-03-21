from rest_framework import serializers
from .models import Prescription, Medication
from apps.consultations.models import Consultation

class MedicationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Medication
        fields = ['id', 'name', 'purpose', 'dosage', 'route', 'duration', 'instructions', 'timing']

class PrescriptionSerializer(serializers.ModelSerializer):
    doctor_name = serializers.CharField(source='consultation.doctor.user.name', read_only=True)
    doctor_phone = serializers.CharField(source='consultation.doctor.user.phone_number', read_only=True)
    doctor_email = serializers.CharField(source='consultation.doctor.user.email', read_only=True)
    patient_name = serializers.CharField(source='consultation.patient.user.name', read_only=True)
    patient_age = serializers.IntegerField(source='consultation.patient.age', read_only=True)
    patient_gender = serializers.CharField(source='consultation.patient.gender', read_only=True)
    patient_village = serializers.CharField(source='consultation.patient.village', read_only=True)
    prescription_summary = serializers.CharField(source='consultation.prescription_summary', read_only=True)
    medications = MedicationSerializer(many=True)
    symptoms = serializers.SerializerMethodField()

    class Meta:
        model = Prescription
        fields = [
            'id', 'consultation', 'doctor_name', 'doctor_phone', 'doctor_email',
            'patient_name', 'patient_age', 'patient_gender', 'patient_village',
            'symptoms', 'diagnosis', 'notes', 'medications', 
            'issued_at', 'prescription_summary'
        ]
    
    def create(self, validated_data):
        medications_data = validated_data.pop('medications')
        prescription = Prescription.objects.create(**validated_data)
        for med_data in medications_data:
            Medication.objects.create(prescription=prescription, **med_data)
            
        # Update consultation status
        consultation = prescription.consultation
        consultation.status = 'COMPLETED'
        consultation.save()
        
        return prescription

    def get_symptoms(self, obj):
        try:
            from apps.symptom_analysis.models import SymptomRecord
            record = SymptomRecord.objects.filter(
                patient=obj.consultation.patient,
                created_at__lte=obj.issued_at
            ).order_by('-created_at').first()
            return record.symptoms_text if record else "Not recorded"
        except Exception:
            return "Not recorded"
