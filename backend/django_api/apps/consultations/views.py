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
        if user.role == 'doctor':
            return Consultation.objects.filter(doctor__user=user)
        elif user.role == 'user':
            return Consultation.objects.filter(patient__user=user)
        return Consultation.objects.none()

    @action(detail=False, methods=['post'])
    def start(self, request):
        doctor_id = request.data.get('doctor_id')
        call_type = request.data.get('call_type', 'VIDEO')
        
        try:
            patient = Patient.objects.get(user=request.user)
        except Patient.DoesNotExist:
            return Response({'error': 'Patient profile not found'}, status=status.HTTP_404_NOT_FOUND)
            
        import uuid
        meeting_link = f"https://meet.jit.si/CareSync-{uuid.uuid4().hex[:8]}" if call_type == 'VIDEO' else None
        
        consultation = Consultation.objects.create(
            patient=patient,
            doctor_id=doctor_id,
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
