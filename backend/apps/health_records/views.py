from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import HealthRecord
from .serializers import HealthRecordSerializer
from alerts.models import Alert
from notifications.models import Notification

class HealthRecordViewSet(viewsets.ModelViewSet):
    queryset = HealthRecord.objects.all()
    serializer_class = HealthRecordSerializer

    def perform_create(self, serializer):
        record = serializer.save()
        self.check_for_alerts(record)

    def check_for_alerts(self, record):
        # Temperature > 102 -> critical alert
        if record.temperature > 102:
            alert = Alert.objects.create(
                patient=record.patient,
                alert_type='HIGH_TEMPERATURE',
                severity='CRITICAL',
                message=f'Critical temperature detected: {record.temperature}°F'
            )
            Notification.objects.create(
                patient=record.patient,
                message=alert.message,
                type='Risk alert'
            )

        # Blood pressure > 140/90 -> moderate alert
        # Simple string splitting for BP
        try:
            systolic, diastolic = map(int, record.blood_pressure.split('/'))
            if systolic > 140 or diastolic > 90:
                alert = Alert.objects.create(
                    patient=record.patient,
                    alert_type='HIGH_BP',
                    severity='MODERATE',
                    message=f'Moderate BP detected: {record.blood_pressure}'
                )
                Notification.objects.create(
                    patient=record.patient,
                    message=alert.message,
                    type='Risk alert'
                )
        except ValueError:
            pass

    @action(detail=False, methods=['get'], url_path='by-patient/(?P<patient_id>[^/.]+)')
    def by_patient(self, request, patient_id=None):
        records = HealthRecord.objects.filter(patient_id=patient_id)
        serializer = self.get_serializer(records, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'], url_path='update')
    def update_record(self, request):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            self.perform_create(serializer)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
