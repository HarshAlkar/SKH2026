import mimetypes
import os

from django.core.exceptions import ValidationError as DjangoValidationError
from django.http import FileResponse
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response

from apps.alerts.notify import notify_patient_prescription
from apps.common.ownership import doctor_can_prescribe, strip_client_identity_fields
from apps.common.uploads import safe_upload_name, validate_document_upload
from apps.security_audit.audit import log_security_event
from .models import Prescription
from .serializers import PrescriptionSerializer

_EXT_CONTENT_TYPE = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
    '.gif': 'image/gif',
    '.pdf': 'application/pdf',
}


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
            if user.is_staff:
                return qs
        except Exception:
            return qs.none()
        return qs.none()

    def create(self, request, *args, **kwargs):
        if getattr(request.user, 'role', None) != 'doctor' or not hasattr(request.user, 'doctor_profile'):
            return Response({'error': 'Only doctors can create prescriptions.'}, status=403)

        prescription_type = (
            request.data.get('prescription_type') or Prescription.TYPE_DIGITAL
        ).strip().lower()
        upload = request.FILES.get('file')

        if prescription_type == Prescription.TYPE_HANDWRITTEN or upload:
            return self._create_handwritten(request)

        return super().create(request, *args, **kwargs)

    def _create_handwritten(self, request):
        data = strip_client_identity_fields(request.data)
        patient_id = data.get('patient')
        upload = request.FILES.get('file')
        notes = data.get('notes') or ''

        if not patient_id:
            return Response({'error': 'patient is required.'}, status=status.HTTP_400_BAD_REQUEST)
        if not upload:
            return Response({'error': 'file is required for handwritten prescriptions.'}, status=status.HTTP_400_BAD_REQUEST)

        from apps.patients.models import Patient

        try:
            patient = Patient.objects.get(pk=patient_id)
        except (Patient.DoesNotExist, ValueError, TypeError):
            return Response({'error': 'Patient not found.'}, status=status.HTTP_404_NOT_FOUND)

        if not doctor_can_prescribe(request.user, patient):
            log_security_event(
                request,
                action='prescription_handwritten_upload',
                object_type='Prescription',
                success=False,
                metadata={'reason': 'unauthorized_patient'},
            )
            return Response(
                {'error': 'You are not authorized to prescribe for this patient.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            ext = validate_document_upload(upload, max_bytes=5 * 1024 * 1024)
            upload.name = safe_upload_name(ext, prefix='rx_scan')
        except DjangoValidationError as exc:
            msg = str(exc.message if hasattr(exc, 'message') else exc)
            log_security_event(
                request,
                action='prescription_handwritten_upload',
                object_type='Prescription',
                success=False,
                metadata={'reason': 'invalid_file'},
            )
            return Response({'error': msg}, status=status.HTTP_400_BAD_REQUEST)

        content_type = _EXT_CONTENT_TYPE.get(ext.lower()) or mimetypes.guess_type(upload.name)[0] or 'application/octet-stream'
        file_size = getattr(upload, 'size', None)

        prescription = Prescription.objects.create(
            patient=patient,
            doctor=request.user.doctor_profile,
            medications='',
            notes=notes[:2000] if notes else '',
            prescription_type=Prescription.TYPE_HANDWRITTEN,
            file=upload,
            file_content_type=content_type[:64],
            file_size=file_size,
            status=Prescription.STATUS_ACTIVE,
        )

        log_security_event(
            request,
            action='prescription_handwritten_upload',
            object_type='Prescription',
            object_id=prescription.pk,
            success=True,
            metadata={
                'prescription_type': Prescription.TYPE_HANDWRITTEN,
                'file_size': file_size,
                'content_type': content_type,
            },
        )
        notify_patient_prescription(prescription)

        serializer = self.get_serializer(prescription)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def perform_create(self, serializer):
        user = self.request.user
        patient = serializer.validated_data.get('patient')
        if not patient:
            raise PermissionDenied('patient is required.')
        if not doctor_can_prescribe(user, patient):
            log_security_event(
                self.request,
                action='prescription_create',
                object_type='Prescription',
                success=False,
                metadata={'reason': 'unauthorized_patient'},
            )
            raise PermissionDenied('You are not authorized to prescribe for this patient.')

        meds = serializer.validated_data.get('medications')
        if meds is None or (isinstance(meds, str) and not meds.strip()):
            raise ValidationError({'medications': 'medications are required for digital prescriptions.'})

        prescription = serializer.save(
            doctor=user.doctor_profile,
            prescription_type=Prescription.TYPE_DIGITAL,
            status=Prescription.STATUS_ACTIVE,
        )
        log_security_event(
            self.request,
            action='prescription_create',
            object_type='Prescription',
            object_id=prescription.pk,
        )
        notify_patient_prescription(prescription)

    def perform_update(self, serializer):
        if getattr(self.request.user, 'role', None) != 'doctor':
            raise PermissionDenied('Only doctors can update prescriptions.')
        instance = serializer.save()
        log_security_event(
            self.request,
            action='prescription_update',
            object_type='Prescription',
            object_id=instance.pk,
        )

    def destroy(self, request, *args, **kwargs):
        if not request.user.is_staff:
            return Response(
                {'error': 'Prescription records cannot be deleted. Upload a new version instead.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        instance = self.get_object()
        log_security_event(
            request,
            action='prescription_delete',
            object_type='Prescription',
            object_id=instance.pk,
        )
        return super().destroy(request, *args, **kwargs)

    @action(detail=True, methods=['get'], url_path='file')
    def download_file(self, request, pk=None):
        try:
            prescription = self.get_object()
        except Exception:
            log_security_event(
                request,
                action='prescription_file_view',
                object_type='Prescription',
                object_id=pk,
                success=False,
                metadata={'reason': 'not_found_or_denied'},
            )
            raise

        if not prescription.file:
            return Response({'error': 'No file attached.'}, status=status.HTTP_404_NOT_FOUND)

        try:
            file_handle = prescription.file.open('rb')
        except Exception:
            log_security_event(
                request,
                action='prescription_file_view',
                object_type='Prescription',
                object_id=prescription.pk,
                success=False,
                metadata={'reason': 'file_unavailable'},
            )
            return Response({'error': 'File unavailable.'}, status=status.HTTP_404_NOT_FOUND)

        content_type = prescription.file_content_type or 'application/octet-stream'
        filename = os.path.basename(prescription.file.name) or f'prescription_{prescription.pk}'
        log_security_event(
            request,
            action='prescription_file_view',
            object_type='Prescription',
            object_id=prescription.pk,
            success=True,
            metadata={'content_type': content_type},
        )
        response = FileResponse(file_handle, content_type=content_type)
        response['Content-Disposition'] = f'inline; filename="{filename}"'
        if prescription.file_size:
            response['Content-Length'] = prescription.file_size
        return response

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
