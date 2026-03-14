from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from .models import Doctor
from .serializers import DoctorSerializer

class DoctorViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Doctor.objects.all()
    serializer_class = DoctorSerializer
    permission_classes = [AllowAny]

    @action(detail=False, methods=['get'], url_path='on-call')
    def on_call(self, request):
        doctors = Doctor.objects.all() # For demo, return all doctors or filter by is_on_call
        serializer = self.get_serializer(doctors, many=True)
        return Response(serializer.data)
