from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Prescription
from .serializers import PrescriptionSerializer

class PrescriptionViewSet(viewsets.ModelViewSet):
    queryset = Prescription.objects.all().order_by('-issued_at')
    serializer_class = PrescriptionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'doctor':
            return self.queryset.filter(doctor=user.doctor_profile)
        elif user.role == 'user':
            return self.queryset.filter(patient=user.patient_profile)
        elif user.role == 'asha_worker':
            return self.queryset.filter(patient__user__village=user.asha_profile.assigned_village)
        return self.queryset.none()

    @action(detail=False, methods=['get'], url_path='user')
    def user_prescriptions(self, request):
        if request.user.role != 'user':
            return Response({"error": "Only patients can access this"}, status=status.HTTP_403_FORBIDDEN)
        
        prescriptions = self.queryset.filter(patient=request.user.patient_profile)
        serializer = self.get_serializer(prescriptions, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='asha')
    def asha_prescriptions(self, request):
        if request.user.role != 'asha_worker':
            return Response({"error": "Only ASHA workers can access this"}, status=status.HTTP_403_FORBIDDEN)
        
        village = request.user.asha_profile.assigned_village
        prescriptions = self.queryset.filter(patient__user__village=village)
        serializer = self.get_serializer(prescriptions, many=True)
        return Response(serializer.data)
