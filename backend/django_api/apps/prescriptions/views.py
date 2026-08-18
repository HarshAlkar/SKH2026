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
        qs = Prescription.objects.all().order_by('-issued_at')
        try:
            if user.role == 'doctor':
                return qs.filter(doctor=user.doctor_profile)
            if user.role == 'user':
                return qs.filter(patient=user.patient_profile)
            if user.role == 'asha_worker':
                village = user.asha_profile.assigned_village
                return qs.filter(patient__user__village=village)
        except Exception:
            return qs.none()
        return qs.none()

    def perform_create(self, serializer):
        extras = {}
        user = self.request.user
        if user.role == 'doctor' and hasattr(user, 'doctor_profile'):
            extras['doctor'] = user.doctor_profile
        serializer.save(**extras)

    @action(detail=False, methods=['get'], url_path='user')
    def user_prescriptions(self, request):
        if request.user.role != 'user':
            return Response({"error": "Only patients can access this"}, status=status.HTTP_403_FORBIDDEN)
        if not hasattr(request.user, 'patient_profile'):
            return Response([], status=status.HTTP_200_OK)
        prescriptions = Prescription.objects.filter(patient=request.user.patient_profile)
        serializer = self.get_serializer(prescriptions, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='asha')
    def asha_prescriptions(self, request):
        if request.user.role != 'asha_worker':
            return Response({"error": "Only ASHA workers can access this"}, status=status.HTTP_403_FORBIDDEN)
        if not hasattr(request.user, 'asha_profile'):
            return Response([], status=status.HTTP_200_OK)
        village = request.user.asha_profile.assigned_village
        prescriptions = Prescription.objects.filter(patient__user__village=village)
        serializer = self.get_serializer(prescriptions, many=True)
        return Response(serializer.data)
