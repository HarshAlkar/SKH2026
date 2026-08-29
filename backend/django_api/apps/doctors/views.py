from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from .models import Doctor, DoctorDocument
from .serializers import DoctorSerializer, DoctorDocumentSerializer

class DoctorViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Doctor.objects.all().order_by('-id')
    serializer_class = DoctorSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = super().get_queryset()
        status_param = self.request.query_params.get('status')
        if status_param:
            qs = qs.filter(verification_status=status_param)
        return qs

    @action(detail=False, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def upload_document(self, request):
        if request.user.role != 'doctor':
            return Response({'error': 'Only doctors can upload verification documents.'}, status=status.HTTP_403_FORBIDDEN)
        
        doctor = getattr(request.user, 'doctor_profile', None)
        if not doctor:
            return Response({'error': 'Doctor profile not found.'}, status=status.HTTP_404_NOT_FOUND)
        
        document_type = request.data.get('document_type')
        file = request.FILES.get('file')

        if not document_type or not file:
            return Response({'error': 'document_type and file are required.'}, status=status.HTTP_400_BAD_REQUEST)

        from apps.common.uploads import validate_document_upload, safe_upload_name
        from django.core.exceptions import ValidationError as DjangoValidationError
        try:
            ext = validate_document_upload(file, max_bytes=5 * 1024 * 1024)
            file.name = safe_upload_name(ext, prefix='doctor_doc')
        except DjangoValidationError as exc:
            return Response({'error': str(exc.message if hasattr(exc, 'message') else exc)}, status=400)

        doc = DoctorDocument.objects.filter(doctor=doctor, document_type=document_type).first()
        if doc:
            doc.file = file
            doc.save()
        else:
            doc = DoctorDocument.objects.create(
                doctor=doctor,
                document_type=document_type,
                file=file,
            )
        if doctor.verification_status == 'REJECTED':
            doctor.verification_status = 'INCOMPLETE'
            doctor.rejection_reason = None
            doctor.save(update_fields=['verification_status', 'rejection_reason'])
        from apps.security_audit.audit import log_security_event
        log_security_event(request, action='doctor_doc_upload', object_type='DoctorDocument', object_id=doc.pk)
        return Response(
            DoctorDocumentSerializer(doc, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=False, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def submit_verification(self, request):
        if request.user.role != 'doctor':
            return Response({'error': 'Only doctors can submit verification.'}, status=status.HTTP_403_FORBIDDEN)
        
        doctor = getattr(request.user, 'doctor_profile', None)
        if not doctor:
            return Response({'error': 'Doctor profile not found.'}, status=status.HTTP_404_NOT_FOUND)

        required_docs = ['license', 'id_proof']
        uploaded_docs = doctor.documents.values_list('document_type', flat=True)
        missing_docs = [doc for doc in required_docs if doc not in uploaded_docs]

        if missing_docs:
            return Response({'error': f'Missing required documents: {", ".join(missing_docs)}'}, status=status.HTTP_400_BAD_REQUEST)

        doctor.verification_status = 'PENDING_VERIFICATION'
        doctor.save()
        return Response({'status': 'Verification submitted successfully.'})

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def approve(self, request, pk=None):
        doctor = self.get_object()
        doctor.verification_status = 'VERIFIED'
        doctor.verified_at = timezone.now()
        doctor.verified_by = request.user
        doctor.rejection_reason = None
        doctor.save()
        return Response({'status': 'Doctor verified successfully.'})

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def reject(self, request, pk=None):
        doctor = self.get_object()
        reason = request.data.get('reason')
        if not reason:
            return Response({'error': 'Reason is required for rejection.'}, status=status.HTTP_400_BAD_REQUEST)
        
        doctor.verification_status = 'REJECTED'
        doctor.rejection_reason = reason
        doctor.save()
        return Response({'status': 'Doctor verification rejected.'})
