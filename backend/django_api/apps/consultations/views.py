from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from .models import Consultation
from .serializers import ConsultationSerializer
from apps.patients.models import Patient
from apps.doctors.models import Doctor
import uuid


class ConsultationViewSet(viewsets.ModelViewSet):
    serializer_class = ConsultationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'doctor':
            return Consultation.objects.filter(doctor__user=user)
        if user.role == 'user':
            return Consultation.objects.filter(patient__user=user)
        if user.role == 'asha_worker':
            return Consultation.objects.filter(initiated_by=user)
        return Consultation.objects.none()

    @action(detail=False, methods=['post'])
    def start(self, request):
        doctor_id = request.data.get('doctor_id')
        patient_id = request.data.get('patient_id')
        call_type = request.data.get('call_type', 'VIDEO')
        user = request.user

        doctor = None
        if doctor_id:
            doctor = Doctor.objects.filter(pk=doctor_id).first()
            if not doctor:
                doctor = Doctor.objects.filter(user_id=doctor_id).first()
        if user.role == 'doctor':
            doctor = getattr(user, 'doctor_profile', None) or doctor
        if not doctor:
            return Response({'error': 'Doctor not found'}, status=status.HTTP_404_NOT_FOUND)

        patient = None
        if user.role == 'user':
            patient = Patient.objects.filter(user=user).first()
            if not patient:
                return Response({'error': 'Patient profile not found'}, status=status.HTTP_404_NOT_FOUND)
        elif user.role == 'asha_worker':
            if patient_id:
                patient = Patient.objects.filter(pk=patient_id).first()
                if not patient:
                    patient = Patient.objects.filter(user_id=patient_id).first()
        elif user.role == 'doctor':
            if not patient_id:
                return Response({'error': 'patient_id is required'}, status=status.HTTP_400_BAD_REQUEST)
            patient = Patient.objects.filter(pk=patient_id).first()
            if not patient:
                patient = Patient.objects.filter(user_id=patient_id).first()
            if not patient:
                return Response({'error': 'Patient not found'}, status=status.HTTP_404_NOT_FOUND)
        else:
            return Response({'error': 'Invalid role for starting a consultation'}, status=status.HTTP_403_FORBIDDEN)

        meeting_link = f"https://meet.jit.si/CareSync-{uuid.uuid4().hex[:8]}" if str(call_type).upper() == 'VIDEO' else None

        consultation = Consultation.objects.create(
            patient=patient,
            doctor=doctor,
            initiated_by=user,
            call_type=str(call_type).upper(),
            status='PENDING',
            meeting_link=meeting_link,
        )

        serializer = self.get_serializer(consultation)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def end(self, request, pk=None):
        consultation = self.get_object()
        consultation.status = 'COMPLETED'
        consultation.end_time = timezone.now()
        consultation.save()
        return Response({'status': 'Consultation ended'})

    @action(detail=False, methods=['get'])
    def history(self, request):
        queryset = self.get_queryset().order_by('-created_at')
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
