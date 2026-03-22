from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
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
        elif user.role == 'user':
            return Consultation.objects.filter(patient__user=user)
        elif user.role == 'asha_worker':
            from apps.asha_workers.models import ASHAWorker
            try:
                asha = ASHAWorker.objects.get(user=user)
                return Consultation.objects.filter(patient__user__village=asha.assigned_village)
            except ASHAWorker.DoesNotExist:
                return Consultation.objects.none()
        return Consultation.objects.none()

    @action(detail=False, methods=['post'])
    def start(self, request):
        # Expected payload: doctor_user_id, optional patient_id (for ASHA), call_type
        doctor_user_id = request.data.get('doctor_user_id')
        if not doctor_user_id:
            return Response({'error': 'doctor_user_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            doctor = Doctor.objects.get(user__id=doctor_user_id)
        except Doctor.DoesNotExist:
            return Response({'error': 'Doctor not found'}, status=status.HTTP_404_NOT_FOUND)

        call_type = request.data.get('call_type', 'VIDEO')
        patient_id = request.data.get('patient_id')

        if request.user.role == 'user':
            try:
                patient = Patient.objects.get(user=request.user)
            except Patient.DoesNotExist:
                return Response({'error': 'Patient profile not found'}, status=status.HTTP_404_NOT_FOUND)
        elif request.user.role == 'asha_worker':
            if not patient_id:
                return Response({'error': 'patient_id is required when ASHA worker initiates consultation'}, status=status.HTTP_400_BAD_REQUEST)
            try:
                # Use user ID or patient ID? backend usually matches user__id for simplicity if profile is linked
                patient = Patient.objects.get(id=patient_id)
            except Patient.DoesNotExist:
                return Response({'error': 'Patient not found'}, status=status.HTTP_404_NOT_FOUND)
        elif request.user.role == 'doctor':
            if not patient_id:
                return Response({'error': 'patient_id is required for doctor to start call'}, status=status.HTTP_400_BAD_REQUEST)
            try:
                doctor = Doctor.objects.get(user=request.user)
                patient = Patient.objects.get(id=patient_id)
            except (Doctor.DoesNotExist, Patient.DoesNotExist):
                return Response({'error': 'Profile not found'}, status=status.HTTP_404_NOT_FOUND)
        else:
            return Response({'error': 'Unauthorized role to start consultation'}, status=status.HTTP_403_FORBIDDEN)

        meeting_link = f"https://meet.jit.si/CareSync-{uuid.uuid4().hex[:8]}" if call_type == 'VIDEO' else None

        consultation = Consultation.objects.create(
            patient=patient,
            doctor=doctor,
            call_type=call_type,
            status='PENDING',
            meeting_link=meeting_link
        )
        serializer = self.get_serializer(consultation)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def end(self, request, pk=None):
        from django.utils import timezone
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
