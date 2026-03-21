from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Consultation
from .serializers import ConsultationSerializer
from apps.patients.models import Patient

class ConsultationViewSet(viewsets.ModelViewSet):
    serializer_class = ConsultationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        print(f"DEBUG: get_queryset for user={user.username}, role={user.role}")
        if user.role == 'doctor':
            return Consultation.objects.filter(doctor__user=user)
        elif user.role == 'user':
            return Consultation.objects.filter(patient__user=user)
        return Consultation.objects.none()

    @action(detail=False, methods=['post'])
    def start(self, request):
        doctor_id = request.data.get('doctor_id')
        patient_id = request.data.get('patient_id')
        call_type = request.data.get('call_type', 'VIDEO')
        
        user = request.user
        
        if user.role == 'doctor':
            # Doctor starting a consultation for a patient
            if not patient_id:
                return Response({'error': 'patient_id is required for doctors'}, status=status.HTTP_400_BAD_REQUEST)
            try:
                patient = Patient.objects.get(id=patient_id)
            except Patient.DoesNotExist:
                return Response({'error': 'Patient not found'}, status=status.HTTP_404_NOT_FOUND)
            
            doctor = user.doctor_profile
        else:
            # Patient starting a consultation with a doctor
            try:
                patient = Patient.objects.get(user=user)
            except Patient.DoesNotExist:
                return Response({'error': 'Patient profile not found'}, status=status.HTTP_404_NOT_FOUND)
            
            if not doctor_id:
                return Response({'error': 'doctor_id is required for patients'}, status=status.HTTP_400_BAD_REQUEST)
            from apps.doctors.models import Doctor
            try:
                doctor = Doctor.objects.get(id=doctor_id)
            except Doctor.DoesNotExist:
                return Response({'error': 'Doctor not found'}, status=status.HTTP_404_NOT_FOUND)

        consultation = Consultation.objects.create(
            patient=patient,
            doctor=doctor,
            call_type=call_type,
            status='PENDING'
        )
        
        serializer = self.get_serializer(consultation)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def end(self, request, pk=None):
        from django.utils import timezone
        consultation = self.get_object()
        new_status = request.data.get('status', 'COMPLETED')
        if new_status not in dict(Consultation.STATUS_CHOICES):
            return Response({'error': 'Invalid status'}, status=status.HTTP_400_BAD_REQUEST)
        
        consultation.status = new_status
        if new_status == 'COMPLETED':
            consultation.ended_at = timezone.now()
        consultation.save()
        return Response({'status': f'Consultation ended with status: {new_status}'})

    @action(detail=False, methods=['get'])
    def history(self, request):
        queryset = self.get_queryset().filter(status='COMPLETED').order_by('-created_at')
        print(f"DEBUG: history action found {queryset.count()} records for user {request.user.username}")
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def pending(self, request):
        queryset = self.get_queryset().filter(status='PENDING').order_by('-created_at')
        print(f"DEBUG: pending action found {queryset.count()} records for user {request.user.username}")
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def accepted(self, request):
        queryset = self.get_queryset().filter(status='ACCEPTED').order_by('-created_at')
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def rejected(self, request):
        queryset = self.get_queryset().filter(status='REJECTED').order_by('-created_at')
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def accept_request(self, request, pk=None):
        consultation = self.get_object()
        if consultation.status != 'PENDING':
            return Response({'error': 'Only pending requests can be accepted'}, status=status.HTTP_400_BAD_REQUEST)
        consultation.status = 'ACCEPTED'
        consultation.save()
        return Response({'status': 'Request accepted'})

    @action(detail=True, methods=['post'])
    def reject_request(self, request, pk=None):
        consultation = self.get_object()
        if consultation.status != 'PENDING':
            return Response({'error': 'Only pending requests can be rejected'}, status=status.HTTP_400_BAD_REQUEST)
        consultation.status = 'REJECTED'
        consultation.save()
        return Response({'status': 'Request rejected'})
