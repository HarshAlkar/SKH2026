from rest_framework import viewsets, permissions
from .models import Prescription
from .serializers import PrescriptionSerializer

class PrescriptionViewSet(viewsets.ModelViewSet):
    queryset = Prescription.objects.all()
    serializer_class = PrescriptionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if hasattr(user, 'patient_profile'):
            return self.queryset.filter(consultation__patient=user.patient_profile).order_by('-issued_at')
        elif hasattr(user, 'doctor_profile'):
            return self.queryset.filter(consultation__doctor=user.doctor_profile).order_by('-issued_at')
        return self.queryset.none()
