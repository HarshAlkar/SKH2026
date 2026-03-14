from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from .models import MedicineSchedule, MedicineRecord
from .serializers import MedicineScheduleSerializer, MedicineRecordSerializer
from apps.patients.models import Patient
from django.contrib.auth import get_user_model

User = get_user_model()

class MedicineTrackerViewSet(viewsets.ModelViewSet):
    queryset = MedicineSchedule.objects.all()
    serializer_class = MedicineScheduleSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_authenticated:
            # Look for patient profile
            patient = Patient.objects.filter(user=user).first()
            if patient:
                return self.queryset.filter(patient=patient)
        return self.queryset.none()

    def perform_create(self, serializer):
        patient, _ = Patient.objects.get_or_create(user=self.request.user)
        serializer.save(patient=patient)

    @action(detail=False, methods=['get'], url_path='user')
    def user_medicines(self, request):
        """GET /api/medicines/user"""
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'], url_path='add')
    def add_medicine(self, request):
        """POST /api/medicines/add"""
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            self.perform_create(serializer)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['put', 'patch'], url_path='update')
    def update_medicine(self, request, pk=None):
        """PUT /api/medicines/update/<pk>"""
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['delete'], url_path='remove')
    def remove_medicine(self, request, pk=None):
        """DELETE /api/medicines/remove/<pk>"""
        instance = self.get_object()
        instance.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['get'])
    def today(self, request):
        """Helper for today's medicines"""
        today_date = timezone.now().date()
        queryset = self.get_queryset().filter(
            start_date__lte=today_date,
            end_date__gte=today_date
        )
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
