from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework import viewsets, permissions
from .models import ASHAWorker, VillageVisit
from .serializers import VillageVisitSerializer
from apps.patients.models import Patient
from apps.consultations.models import Consultation

class VillageVisitViewSet(viewsets.ModelViewSet):
    serializer_class = VillageVisitSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        try:
            asha_worker = ASHAWorker.objects.get(user=user)
            return VillageVisit.objects.filter(asha_worker=asha_worker).order_by('-visit_date', '-visit_time')
        except ASHAWorker.DoesNotExist:
            return VillageVisit.objects.none()

    def perform_create(self, serializer):
        try:
            asha_worker = ASHAWorker.objects.get(user=self.request.user)
            serializer.save(asha_worker=asha_worker)
        except ASHAWorker.DoesNotExist:
            pass

class ASHAWorkerDashboardView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if request.user.role != 'asha_worker':
            return Response({"error": "Unauthorized access"}, status=status.HTTP_403_FORBIDDEN)
            
        try:
            asha_worker = ASHAWorker.objects.get(user=request.user)
        except ASHAWorker.DoesNotExist:
            return Response({"error": "ASHA profile not found"}, status=status.HTTP_404_NOT_FOUND)

        village = asha_worker.assigned_village
        
        total_patients = Patient.objects.filter(user__village=village).count()
        
        # Pending visits -> scheduled village visits for this ASHA
        pending_visits = VillageVisit.objects.filter(
            asha_worker=asha_worker,
            status='PENDING'
        ).count()
        
        # Recent activity only includes visits now
        recent_activities = []
        
        recent_visits = VillageVisit.objects.filter(
            asha_worker=asha_worker
        ).order_by('-created_at')[:5]
        
        for visit in recent_visits:
            recent_activities.append({
                "id": f"visit_{visit.id}",
                "patientName": visit.patient.user.name or visit.patient.user.username,
                "activityType": "Village Visit",
                "description": f"Scheduled visit on {visit.visit_date}",
                "timestamp": visit.created_at.isoformat(),
                "icon_type": "info"
            })

        return Response({
            "worker_name": request.user.name or request.user.username,
            "village": village,
            "phc_center": asha_worker.phc_center,
            "stats": {
                "total_patients": total_patients,
                "high_risk_alerts": 0,
                "pending_visits": pending_visits,
                "new_alerts": 0,
            },
            "recent_activity": recent_activities
        }, status=status.HTTP_200_OK)
