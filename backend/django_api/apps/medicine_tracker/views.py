from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from django.db.models import Q
import datetime
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
        if not user.is_authenticated:
            return self.queryset.none()

        patient = getattr(user, 'patient_profile', None)
        if not patient:
            patient = Patient.objects.filter(user=user).first()
        if not patient:
            return self.queryset.none()

        qs = self.queryset.filter(patient=patient)

        date_param = self.request.query_params.get('date')
        if date_param:
            try:
                target_date = datetime.datetime.strptime(date_param.strip(), '%Y-%m-%d').date()
                qs = qs.filter(
                    (Q(frequency__iexact='Once') & Q(start_date=target_date)) |
                    (~Q(frequency__iexact='Once') & Q(start_date__lte=target_date) & Q(end_date__gte=target_date))
                )
            except ValueError:
                pass

        return qs

    def perform_create(self, serializer):
        patient = getattr(self.request.user, 'patient_profile', None)
        if not patient:
            patient, _ = Patient.objects.get_or_create(
                user=self.request.user,
                defaults={'age': 0, 'gender': 'Not Set', 'address': 'Not Set'}
            )
        
        # If frequency is Once, ensure end_date matches start_date
        frequency = serializer.validated_data.get('frequency', '')
        start_date = serializer.validated_data.get('start_date')
        if frequency.lower() == 'once' and start_date:
            serializer.save(patient=patient, end_date=start_date)
        else:
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
            (Q(frequency__iexact='Once') & Q(start_date=today_date)) |
            (~Q(frequency__iexact='Once') & Q(start_date__lte=today_date) & Q(end_date__gte=today_date))
        )
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
