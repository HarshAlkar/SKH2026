from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from django.utils import timezone
from .models import Consultation
from .serializers import ConsultationSerializer
from apps.patients.models import Patient
from apps.doctors.models import Doctor
from apps.asha_workers.models import ASHAWorker
import uuid


def _resolve_doctor(doctor_id):
    if not doctor_id:
        return None
    doctor = Doctor.objects.filter(pk=doctor_id).first()
    if not doctor:
        doctor = Doctor.objects.filter(user_id=doctor_id).first()
    return doctor


def _resolve_patient(patient_id):
    if not patient_id:
        return None
    patient = Patient.objects.filter(pk=patient_id).first()
    if not patient:
        patient = Patient.objects.filter(user_id=patient_id).first()
    return patient


def _resolve_asha(asha_id):
    if not asha_id:
        return None
    asha = ASHAWorker.objects.filter(pk=asha_id).first()
    if not asha:
        asha = ASHAWorker.objects.filter(user_id=asha_id).first()
    return asha


class ConsultationViewSet(viewsets.ModelViewSet):
    serializer_class = ConsultationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'doctor':
            return Consultation.objects.filter(
                Q(doctor__user=user) | Q(initiated_by=user)
            )
        if user.role == 'user':
            return Consultation.objects.filter(
                Q(patient__user=user) | Q(initiated_by=user)
            )
        if user.role == 'asha_worker':
            return Consultation.objects.filter(
                Q(asha_worker__user=user) | Q(initiated_by=user)
            )
        return Consultation.objects.none()

    @action(detail=False, methods=['post'])
    def start(self, request):
        doctor_id = request.data.get('doctor_id')
        patient_id = request.data.get('patient_id')
        asha_id = request.data.get('asha_id')
        call_type = request.data.get('call_type', 'VIDEO')
        is_emergency = bool(request.data.get('is_emergency'))
        user = request.user

        doctor = _resolve_doctor(doctor_id)
        patient = _resolve_patient(patient_id)
        asha = _resolve_asha(asha_id)

        if user.role == 'user':
            patient = Patient.objects.filter(user=user).first()
            if not patient:
                return Response(
                    {'error': 'Patient profile not found'},
                    status=status.HTTP_404_NOT_FOUND,
                )
            if not doctor and not asha:
                return Response(
                    {'error': 'doctor_id or asha_id is required'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        elif user.role == 'asha_worker':
            asha = getattr(user, 'asha_profile', None) or asha
            if not asha:
                return Response(
                    {'error': 'ASHA profile not found'},
                    status=status.HTTP_404_NOT_FOUND,
                )
            if not doctor and not patient:
                return Response(
                    {'error': 'doctor_id or patient_id is required'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        elif user.role == 'doctor':
            doctor = getattr(user, 'doctor_profile', None) or doctor
            if not doctor:
                return Response(
                    {'error': 'Doctor profile not found'},
                    status=status.HTTP_404_NOT_FOUND,
                )
            if not patient and not asha:
                return Response(
                    {'error': 'patient_id or asha_id is required'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        else:
            return Response(
                {'error': 'Invalid role for starting a consultation'},
                status=status.HTTP_403_FORBIDDEN,
            )

        meeting_link = (
            f"https://meet.jit.si/CareSync-{uuid.uuid4().hex[:8]}"
            if str(call_type).upper() == 'VIDEO'
            else None
        )

        consultation = Consultation.objects.create(
            patient=patient,
            doctor=doctor,
            asha_worker=asha,
            initiated_by=user,
            call_type=str(call_type).upper(),
            status='PENDING',
            meeting_link=meeting_link,
            is_emergency=is_emergency,
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
