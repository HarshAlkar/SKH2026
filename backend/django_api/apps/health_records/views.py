from rest_framework import viewsets, permissions, status, serializers
from rest_framework.response import Response

from apps.patients.models import Patient
from apps.alerts.notify import notify_village_care_team
from .models import HealthRecord


class HealthRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = HealthRecord
        fields = '__all__'


class HealthRecordViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = HealthRecordSerializer

    def get_queryset(self):
        user = self.request.user
        qs = HealthRecord.objects.all().order_by('-created_at')
        patient_id = self.request.query_params.get('patient_id')
        if patient_id:
            qs = qs.filter(patient_id=patient_id)
        if user.role == 'asha_worker':
            asha = getattr(user, 'asha_profile', None)
            if asha is None:
                return HealthRecord.objects.none()
            return qs.filter(patient__user__village__iexact=asha.assigned_village)
        if user.role == 'doctor':
            return qs
        return qs.filter(patient__user=user)

    def list(self, request, *args, **kwargs):
        data = []
        for record in self.get_queryset():
            data.append({
                'id': record.id,
                'patientId': record.patient.id,
                'patientName': record.patient.user.name or record.patient.user.username,
                'village': record.patient.user.village,
                'temperature': record.temperature or '--',
                'bloodPressure': record.blood_pressure or '--',
                'bloodSugar': record.blood_sugar or '--',
                'weight': record.weight or '--',
                'symptoms': record.symptoms or 'No symptoms reported.',
                'lastUpdated': record.created_at.isoformat(),
                'riskLevel': record.risk_level,
            })
        return Response(data)

    def create(self, request, *args, **kwargs):
        patient_id = request.data.get('patient_id')
        if not patient_id:
            return Response({'error': 'patient_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        patient = Patient.objects.filter(pk=patient_id).first()
        if patient is None:
            patient = Patient.objects.filter(user_id=patient_id).first()
        if patient is None:
            return Response({'error': 'Patient not found'}, status=status.HTTP_404_NOT_FOUND)

        notify_doctor = bool(request.data.get('notify_doctor'))
        risk_level = 'highRisk' if notify_doctor else 'normal'
        try:
            sugar = float(request.data.get('blood_sugar') or 0)
            if not notify_doctor and sugar not in (0,):
                if sugar > 140 or sugar < 70:
                    risk_level = 'highRisk'
                elif sugar > 120:
                    risk_level = 'moderate'
        except (TypeError, ValueError):
            pass

        record = HealthRecord.objects.create(
            patient=patient,
            temperature=request.data.get('temperature') or '',
            blood_pressure=request.data.get('blood_pressure') or '',
            blood_sugar=request.data.get('blood_sugar') or '',
            weight=request.data.get('weight') or '',
            symptoms=request.data.get('symptoms') or '',
            risk_level=risk_level,
        )
        if risk_level == 'highRisk' or notify_doctor:
            notify_village_care_team(
                patient.user,
                disease=record.symptoms or 'Abnormal vitals',
                severity='High',
            )
        serializer = self.get_serializer(record)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
