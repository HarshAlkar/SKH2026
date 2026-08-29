from rest_framework import viewsets, permissions, status
from rest_framework.views import APIView
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from django.utils import timezone

from apps.patients.models import Patient
from apps.alerts.models import AlertNotification
from .models import ASHAWorker, VillageVisit, ASHADocument
from .serializers import VillageVisitSerializer, ASHAWorkerSerializer, ASHADocumentSerializer


def _asha_or_none(user):
    return getattr(user, 'asha_profile', None)


class ASHAWorkerViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = ASHAWorker.objects.all().order_by('-id')
    serializer_class = ASHAWorkerSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = super().get_queryset()
        status_param = self.request.query_params.get('status')
        if status_param:
            qs = qs.filter(verification_status=status_param)
        return qs

    @action(detail=False, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def upload_document(self, request):
        if request.user.role != 'asha_worker':
            return Response({'error': 'Only ASHA workers can upload verification documents.'}, status=status.HTTP_403_FORBIDDEN)

        asha = _asha_or_none(request.user)
        if not asha:
            return Response({'error': 'ASHA profile not found.'}, status=status.HTTP_404_NOT_FOUND)

        document_type = request.data.get('document_type')
        file = request.FILES.get('file')
        if not document_type or not file:
            return Response({'error': 'document_type and file are required.'}, status=status.HTTP_400_BAD_REQUEST)

        doc = ASHADocument.objects.filter(asha_worker=asha, document_type=document_type).first()
        if doc:
            doc.file = file
            doc.save()
        else:
            doc = ASHADocument.objects.create(
                asha_worker=asha,
                document_type=document_type,
                file=file,
            )
        if asha.verification_status == 'REJECTED':
            asha.verification_status = 'INCOMPLETE'
            asha.rejection_reason = None
            asha.save(update_fields=['verification_status', 'rejection_reason'])
        return Response(
            ASHADocumentSerializer(doc, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=False, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def submit_verification(self, request):
        if request.user.role != 'asha_worker':
            return Response({'error': 'Only ASHA workers can submit verification.'}, status=status.HTTP_403_FORBIDDEN)

        asha = _asha_or_none(request.user)
        if not asha:
            return Response({'error': 'ASHA profile not found.'}, status=status.HTTP_404_NOT_FOUND)

        required_docs = ['id_proof', 'assignment_proof']
        uploaded_docs = asha.documents.values_list('document_type', flat=True)
        missing_docs = [doc for doc in required_docs if doc not in uploaded_docs]
        if missing_docs:
            return Response(
                {'error': f'Missing required documents: {", ".join(missing_docs)}'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        asha.verification_status = 'PENDING_VERIFICATION'
        asha.save()
        return Response({'status': 'Verification submitted successfully.'})

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def approve(self, request, pk=None):
        asha = self.get_object()
        asha.verification_status = 'VERIFIED'
        asha.verified_at = timezone.now()
        asha.verified_by = request.user
        asha.rejection_reason = None
        asha.save()
        return Response({'status': 'ASHA worker verified successfully.'})

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def reject(self, request, pk=None):
        asha = self.get_object()
        reason = request.data.get('reason')
        if not reason:
            return Response({'error': 'Reason is required for rejection.'}, status=status.HTTP_400_BAD_REQUEST)
        asha.verification_status = 'REJECTED'
        asha.rejection_reason = reason
        asha.save()
        return Response({'status': 'ASHA worker verification rejected.'})


class VillageVisitViewSet(viewsets.ModelViewSet):
    serializer_class = VillageVisitSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        asha = _asha_or_none(self.request.user)
        if asha is None:
            return VillageVisit.objects.none()
        return VillageVisit.objects.filter(asha_worker=asha).order_by('-visit_date', '-visit_time')

    def perform_create(self, serializer):
        asha = _asha_or_none(self.request.user)
        if asha is None:
            raise PermissionDenied('ASHA profile required')
        serializer.save(asha_worker=asha)


class ASHAWorkerDashboardView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role != 'asha_worker':
            return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        asha = _asha_or_none(request.user)
        if asha is None:
            return Response({'error': 'ASHA profile not found'}, status=status.HTTP_404_NOT_FOUND)

        village = asha.assigned_village
        total_patients = Patient.objects.filter(user__village__iexact=village).count()
        pending_visits = VillageVisit.objects.filter(asha_worker=asha, status='PENDING').count()
        alerts = AlertNotification.objects.filter(asha_worker=asha)
        high_risk = alerts.filter(severity__in=['High', 'Critical']).count()

        recent = []
        for visit in VillageVisit.objects.filter(asha_worker=asha).order_by('-created_at')[:5]:
            recent.append({
                'id': f'visit_{visit.id}',
                'patient_name': visit.patient.user.name or visit.patient.user.username,
                'disease': 'Village Visit',
                'severity': visit.status,
            })

        return Response({
            'worker_name': request.user.name or request.user.username,
            'village': village,
            'phc_center': asha.phc_center,
            'stats': {
                'total_patients': total_patients,
                'high_risk_alerts': high_risk,
                'pending_visits': pending_visits,
                'new_alerts': alerts.count(),
            },
            'recent_activity': recent,
        })
