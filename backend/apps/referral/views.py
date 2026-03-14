from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny # For demo purposes, adjust as needed
from .models import EmergencyReferral
from .serializers import EmergencyReferralSerializer
from alerts.models import Alert
from patients.models import Patient
import json

class EmergencyReferralViewSet(viewsets.ModelViewSet):
    queryset = EmergencyReferral.objects.all().order_by('-created_at')
    serializer_class = EmergencyReferralSerializer
    permission_classes = [AllowAny] # Using AllowAny to simplify Flutter integration for now

    @action(detail=False, methods=['post'], url_path='create')
    def create_referral(self, request):
        data = request.data
        try:
            patient = Patient.objects.get(id=data.get('patient_id'))
            
            # Create the referral
            referral = EmergencyReferral.objects.create(
                patient=patient,
                asha_worker_id=data.get('asha_worker_id'),
                patient_id_display=data.get('patient_id_display', f"PAT-{patient.id}"),
                symptoms=data.get('symptoms', []),
                severity=data.get('severity', 'normal'),
                notes=data.get('notes', ''),
                status='sent'
            )
            
            # Create alert if severity is critical
            if referral.severity == 'critical':
                Alert.objects.create(
                    patient=patient,
                    alert_type='Emergency Referral',
                    severity='CRITICAL',
                    message=f"Critical emergency referral submitted for {patient.name}."
                )
            
            return Response({
                "message": "Referral sent successfully",
                "referral_id": referral.id,
                "status": referral.status
            }, status=status.HTTP_201_CREATED)
            
        except Patient.DoesNotExist:
            return Response({"error": "Patient not found"}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get'], url_path='patient/(?P<patient_id>[^/.]+)')
    def get_patient_referrals(self, request, patient_id=None):
        referrals = EmergencyReferral.objects.filter(patient_id=patient_id).order_by('-created_at')
        serializer = self.get_serializer(referrals, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='asha/(?P<asha_worker_id>[^/.]+)')
    def get_asha_referrals(self, request, asha_worker_id=None):
        referrals = EmergencyReferral.objects.filter(asha_worker_id=asha_worker_id).order_by('-created_at')
        serializer = self.get_serializer(referrals, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='pending')
    def get_pending_referrals(self, request):
        # Doctors see referrals that are 'sent' or 'pending'
        referrals = EmergencyReferral.objects.filter(status__in=['sent', 'pending']).order_by('-created_at')
        serializer = self.get_serializer(referrals, many=True)
        return Response(serializer.data)
