from rest_framework import viewsets, permissions
from rest_framework.response import Response
from rest_framework import serializers

from apps.common.ownership import patients_queryset_for
from .models import Patient


class PatientSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source='user.name', required=False)
    village = serializers.CharField(source='user.village', required=False)
    phone_number = serializers.CharField(source='user.phone_number', read_only=True)
    user_id = serializers.IntegerField(source='user.id', read_only=True)

    class Meta:
        model = Patient
        fields = [
            'id', 'user_id', 'name', 'age', 'village', 'gender',
            'blood_group', 'address', 'medical_history', 'phone_number',
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
        return patients_queryset_for(self.request.user)

    def list(self, request, *args, **kwargs):
        data = []
        for patient in self.get_queryset():
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
                'status': 'Active',
            })
        return Response(data)
