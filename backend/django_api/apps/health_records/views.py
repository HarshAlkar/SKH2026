from rest_framework import viewsets, permissions, status, serializers
from rest_framework.response import Response

from apps.patients.models import Patient
from apps.alerts.notify import notify_village_care_team
from apps.common.ownership import user_can_access_patient, patients_queryset_for
from apps.security_audit.audit import log_security_event
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
        allowed_patients = patients_queryset_for(user)
        qs = HealthRecord.objects.filter(patient__in=allowed_patients).order_by('-created_at')
        patient_id = self.request.query_params.get('patient_id')
        if patient_id:
            qs = qs.filter(patient_id=patient_id)
        return qs

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

        if not user_can_access_patient(request.user, patient):
            return Response({'error': 'Not allowed to create records for this patient.'}, status=403)

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
        log_security_event(
            request, action='health_record_create',
            object_type='HealthRecord', object_id=record.pk,
        )
        if risk_level == 'highRisk' or notify_doctor:
            notify_village_care_team(
                patient.user,
                disease=record.symptoms or 'Abnormal vitals',
                severity='High',
            )
        serializer = self.get_serializer(record)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
