from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from django.utils import timezone
from datetime import timedelta
from django.db.models import Avg, F, ExpressionWrapper, fields, Count
from apps.consultations.models import Consultation
from rest_framework.response import Response
from .models import Doctor
from .serializers import DoctorSerializer

class DoctorViewSet(viewsets.ModelViewSet):
    queryset = Doctor.objects.all().order_by('-id')
    serializer_class = DoctorSerializer
    permission_classes = [permissions.AllowAny] # Allow viewing doctors without login for now

    @action(detail=False, methods=['get', 'put', 'patch'], permission_classes=[permissions.IsAuthenticated])
    def me(self, request):
        try:
            doctor = Doctor.objects.get(user=request.user)
        except Doctor.DoesNotExist:
            return Response({"detail": "Doctor profile not found."}, status=status.HTTP_404_NOT_FOUND)

        if request.method == 'GET':
            serializer = self.get_serializer(doctor)
            return Response(serializer.data)
        
        # for PUT and PATCH
        serializer = self.get_serializer(doctor, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def dashboard_stats(self, request):
        try:
            doctor = Doctor.objects.get(user=request.user)
        except Doctor.DoesNotExist:
            return Response({"detail": "Doctor profile not found."}, status=status.HTTP_404_NOT_FOUND)

        today = timezone.now().date()
        
        pending_count = Consultation.objects.filter(doctor=doctor, status='PENDING').count()
        appointments_today = Consultation.objects.filter(doctor=doctor, status='ACCEPTED', created_at__date=today).count()
        total_patients = Consultation.objects.filter(doctor=doctor).values('patient').distinct().count()
        emergency_count = Consultation.objects.filter(doctor=doctor, is_emergency=True, status__in=['PENDING', 'ACCEPTED', 'ONGOING']).count()

        return Response({
            "pending_count": pending_count,
            "appointments_today": appointments_today,
            "total_patients": total_patients,
            "emergency_count": emergency_count
        })

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def reports_stats(self, request):
        try:
            doctor = Doctor.objects.get(user=request.user)
        except Doctor.DoesNotExist:
            return Response({"detail": "Doctor profile not found."}, status=status.HTTP_404_NOT_FOUND)

        now = timezone.now()
        today = now.date()
        this_month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        last_month_end = this_month_start - timedelta(seconds=1)
        last_month_start = last_month_end.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

        def get_trend(current, previous):
            if previous == 0:
                return "+100%" if current > 0 else "0%"
            diff = ((current - previous) / previous) * 100
            return f"{'+' if diff >= 0 else ''}{int(diff)}%"

        # 1. Total Patients
        this_month_patients = Consultation.objects.filter(doctor=doctor, created_at__gte=this_month_start).values('patient').distinct().count()
        last_month_patients = Consultation.objects.filter(doctor=doctor, created_at__gte=last_month_start, created_at__lte=last_month_end).values('patient').distinct().count()
        total_patients_overall = Consultation.objects.filter(doctor=doctor).values('patient').distinct().count()

        # 2. Critical Alerts
        this_month_critical = Consultation.objects.filter(doctor=doctor, is_emergency=True, created_at__gte=this_month_start).count()
        last_month_critical = Consultation.objects.filter(doctor=doctor, is_emergency=True, created_at__gte=last_month_start, created_at__lte=last_month_end).count()
        resolved_today = Consultation.objects.filter(doctor=doctor, is_emergency=True, status='COMPLETED', ended_at__date=today).count()

        # 3. Avg Consultation Duration
        def get_avg_duration(qs):
            completed = qs.filter(status='COMPLETED', ended_at__isnull=False, created_at__isnull=False)
            if not completed.exists():
                return 0
            durations = completed.annotate(
                duration=ExpressionWrapper(F('ended_at') - F('created_at'), output_field=fields.DurationField())
            ).aggregate(Avg('duration'))['duration__avg']
            return durations.total_seconds() / 60 if durations else 0

        this_month_avg = get_avg_duration(Consultation.objects.filter(doctor=doctor, created_at__gte=this_month_start))
        last_month_avg = get_avg_duration(Consultation.objects.filter(doctor=doctor, created_at__gte=last_month_start, created_at__lte=last_month_end))

        return Response({
            "total_patients": {
                "value": f"{total_patients_overall:,}",
                "indicator": get_trend(this_month_patients, last_month_patients),
                "subtext": "From last month",
                "is_positive": this_month_patients >= last_month_patients
            },
            "critical_alerts": {
                "value": f"{this_month_critical:02d}",
                "indicator": get_trend(this_month_critical, last_month_critical),
                "subtext": f"{resolved_today} resolved today",
                "is_positive": this_month_critical <= last_month_critical # Lower critical alerts is positive
            },
            "avg_consultation": {
                "value": f"{int(this_month_avg)}m",
                "indicator": get_trend(this_month_avg, last_month_avg),
                "subtext": "Efficiency stable",
                "is_positive": this_month_avg <= last_month_avg # Lower duration might be positive for efficiency
            }
        })

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def today_appointments(self, request):
        try:
            doctor = Doctor.objects.get(user=request.user)
        except Doctor.DoesNotExist:
            return Response({"detail": "Doctor profile not found."}, status=status.HTTP_404_NOT_FOUND)

        today = timezone.now().date()
        appointments = Consultation.objects.filter(
            doctor=doctor,
            created_at__date=today
        ).order_by('created_at')

        data = []
        for appt in appointments:
            data.append({
                "id": appt.id,
                "patient_name": appt.patient.user.get_full_name() or appt.patient.user.username,
                "patient_id": appt.patient.id,
                "age": appt.patient.age if hasattr(appt.patient, 'age') else "N/A",
                "village": appt.patient.village if hasattr(appt.patient, 'village') else "N/A",
                "time": appt.created_at.strftime("%I:%M %p"),
                "type": appt.call_type, # AUDIO, VIDEO
                "status": appt.status,
                "notes": appt.notes,
                "is_emergency": appt.is_emergency,
                "history_summary": appt.prescription_summary
            })

        return Response(data)
