from rest_framework import viewsets, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied

from apps.patients.models import Patient
from apps.alerts.models import AlertNotification
from .models import ASHAWorker, VillageVisit
from .serializers import VillageVisitSerializer


def _asha_or_none(user):
    return getattr(user, 'asha_profile', None)


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
