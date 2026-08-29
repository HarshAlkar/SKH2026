from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from rest_framework import serializers

from .models import Patient, EmergencyContact


class EmergencyContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyContact
        fields = ['id', 'patient', 'name', 'phone', 'relationship', 'created_at', 'updated_at']
        read_only_fields = ['id', 'patient', 'created_at', 'updated_at']


class EmergencyContactViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = EmergencyContactSerializer
    http_method_names = ['get', 'post', 'put', 'patch', 'delete']

    def get_queryset(self):
        user = self.request.user
        if hasattr(user, 'patient_profile'):
            return EmergencyContact.objects.filter(patient=user.patient_profile)
        return EmergencyContact.objects.none()

    def perform_create(self, serializer):
        patient, _ = Patient.objects.get_or_create(
            user=self.request.user,
            defaults={
                'age': 0,
                'gender': 'Not Set',
                'address': self.request.user.village or 'Not Set',
            }
        )
        serializer.save(patient=patient)


class PatientSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source='user.name', required=False)
    village = serializers.CharField(source='user.village', required=False)
    phone_number = serializers.CharField(source='user.phone_number', read_only=True)
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    emergency_contacts = EmergencyContactSerializer(many=True, read_only=True)

    class Meta:
        model = Patient
        fields = [
            'id', 'user_id', 'name', 'age', 'village', 'gender',
            'blood_group', 'address', 'medical_history', 'phone_number',
            'emergency_contact_name', 'emergency_contact_phone',
            'emergency_contacts',
        ]

    def update(self, instance, validated_data):
        user_data = validated_data.pop('user', {})
        if user_data:
            user = instance.user
            if 'name' in user_data:
                user.name = user_data['name']
            if 'village' in user_data:
                user.village = user_data['village']
            user.save()
        return super().update(instance, validated_data)


class PatientViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = PatientSerializer
    http_method_names = ['get', 'patch', 'put']

    def get_queryset(self):
        user = self.request.user
        if user.role == 'asha_worker':
            asha = getattr(user, 'asha_profile', None)
            if asha is None:
                return Patient.objects.none()
            return Patient.objects.filter(user__village__iexact=asha.assigned_village)
        if user.role == 'doctor':
            return Patient.objects.all()
        return Patient.objects.filter(user=user)

    def list(self, request, *args, **kwargs):
        data = []
        for patient in self.get_queryset():
            contacts = [
                {
                    'id': c.id,
                    'name': c.name,
                    'phone': c.phone,
                    'relationship': c.relationship,
                }
                for c in patient.emergency_contacts.all()
            ]
            data.append({
                'id': patient.id,
                'user_id': patient.user_id,
                'patient_id': patient.id,
                'name': patient.user.name or patient.user.username,
                'age': patient.age,
                'village': patient.user.village or 'Unknown',
                'phone_number': patient.user.phone_number,
                'gender': patient.gender,
                'blood_group': patient.blood_group,
                'address': patient.address,
                'medical_history': patient.medical_history,
                'emergency_contact_name': patient.emergency_contact_name,
                'emergency_contact_phone': patient.emergency_contact_phone,
                'emergency_contacts': contacts,
                'status': 'Active',
            })
        return Response(data)
