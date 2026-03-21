from rest_framework import viewsets, permissions
from .models import Patient
from .serializers import PatientSerializer

class PatientViewSet(viewsets.ModelViewSet):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        # For doctors and asha workers, return all patients for now
        if user.role in ['doctor', 'asha_worker']:
            return self.queryset.all()
        # For regular users, only return their own patient profile
        return self.queryset.filter(user=user)
