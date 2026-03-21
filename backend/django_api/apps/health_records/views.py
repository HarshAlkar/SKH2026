from rest_framework import viewsets, permissions, status, parsers
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import serializers
from .models import Report
from apps.patients.models import Patient


class ReportSerializer(serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()
    patient_name = serializers.SerializerMethodField()

    class Meta:
        model = Report
        fields = ['id', 'title', 'description', 'file_url', 'created_at', 'report_type', 'patient', 'patient_name']
        read_only_fields = ['created_at', 'file_url', 'patient_name']

    def get_file_url(self, obj):
        request = self.context.get('request')
        if obj.file_path and request:
            return request.build_absolute_uri(obj.file_path.url)
        return None

    def get_patient_name(self, obj):
        return obj.patient.user.name or obj.patient.user.username


class ReportViewSet(viewsets.ModelViewSet):
    queryset = Report.objects.all().order_by('-created_at')
    serializer_class = ReportSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [parsers.MultiPartParser, parsers.FormParser, parsers.JSONParser]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'user' and hasattr(user, 'patient_profile'):
            return self.queryset.filter(patient=user.patient_profile)
        elif user.role == 'doctor':
            # Doctors can see reports of all their patients
            return self.queryset.all()
        elif user.role == 'asha_worker' and hasattr(user, 'asha_profile'):
            village = user.asha_profile.assigned_village
            return self.queryset.filter(patient__user__village=village)
        return self.queryset.none()

    def perform_create(self, serializer):
        user = self.request.user
        if user.role == 'user' and hasattr(user, 'patient_profile'):
            serializer.save(patient=user.patient_profile)
        else:
            # Doctor/ASHA uploading on behalf of a patient
            patient_id = self.request.data.get('patient')
            if patient_id:
                serializer.save()
            else:
                raise ValueError("patient field is required for doctors/asha uploading reports")

    @action(detail=False, methods=['get'], url_path='my-reports')
    def my_reports(self, request):
        """Shortcut endpoint for the user to get their own reports."""
        if not hasattr(request.user, 'patient_profile'):
            return Response({"error": "Only patients can access this"}, status=403)
        reports = self.queryset.filter(patient=request.user.patient_profile)
        serializer = self.get_serializer(reports, many=True, context={'request': request})
        return Response(serializer.data)
