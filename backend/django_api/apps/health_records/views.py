from rest_framework import viewsets, status, serializers
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import HealthRecord
from apps.asha_workers.models import ASHAWorker
from apps.patients.models import Patient

class HealthRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = HealthRecord
        fields = '__all__'

class HealthRecordViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = HealthRecordSerializer
    
    def get_queryset(self):
        user = self.request.user
        qs = HealthRecord.objects.all().order_by('-created_at')
        
        patient_id = self.request.query_params.get('patient_id')
        if patient_id:
            qs = qs.filter(patient_id=patient_id)
            
        if user.role == 'asha_worker':
            try:
                asha = ASHAWorker.objects.get(user=user)
                return qs.filter(patient__user__village=asha.assigned_village)
            except ASHAWorker.DoesNotExist:
                return HealthRecord.objects.none()
        elif user.role == 'doctor':
            return qs
        return qs.filter(patient__user=user)

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        data = []
        for record in queryset:
            data.append({
                "patientId": record.patient.id,
                "patientAge": record.patient.age,
                "patientName": record.patient.user.name or record.patient.user.username,
                "village": record.patient.user.village,
                "temperature": record.temperature or "--",
                "bloodPressure": record.blood_pressure or "--",
                "bloodSugar": record.blood_sugar or "--",
                "weight": record.weight or "--",
                "symptoms": record.symptoms or "No symptoms reported.",
                "lastUpdated": record.created_at.isoformat(),
                "riskLevel": record.risk_level
            })
        return Response(data, status=status.HTTP_200_OK)

    def create(self, request, *args, **kwargs):
        try:
            patient_id = request.data.get('patient_id')
            if not patient_id:
                return Response({"error": "patient_id is required"}, status=status.HTTP_400_BAD_REQUEST)
                
            try:
                patient = Patient.objects.get(user__id=patient_id)
            except Patient.DoesNotExist:
                return Response({"error": "Patient not found"}, status=status.HTTP_404_NOT_FOUND)
                
            notify_doctor = request.data.get('notify_doctor', False)
            risk_level = 'highRisk' if notify_doctor else 'normal'
            
            try:
                sugar = float(request.data.get('blood_sugar') or 0)
                if not notify_doctor and (sugar > 140 or sugar < 70) and sugar != 0:
                    risk_level = 'moderate'
            except Exception:
                pass
                    
            record = HealthRecord.objects.create(
                patient=patient,
                temperature=request.data.get('temperature'),
                blood_pressure=request.data.get('blood_pressure'),
                blood_sugar=request.data.get('blood_sugar'),
                weight=request.data.get('weight'),
                symptoms=request.data.get('symptoms'),
                risk_level=risk_level
            )
            
            return Response({"message": "Health record successfully tracked", "id": record.id}, status=status.HTTP_201_CREATED)
        except Exception as e:
            import traceback
            print(traceback.format_exc())
            return Response({"error": str(traceback.format_exc())}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
