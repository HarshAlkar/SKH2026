from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import SyncLog
from .serializers import SyncLogSerializer

class SyncLogViewSet(viewsets.ModelViewSet):
    queryset = SyncLog.objects.all()
    serializer_class = SyncLogSerializer

    @action(detail=False, methods=['post'], url_path='offline-data')
    def offline_data(self, request):
        # In a real app, we would loop through the payload 
        # and update/create models for patients, visits, health_records, etc.
        # For now, we just log the payload as requested.
        
        sync_log = SyncLog.objects.create(
            asha_worker=request.user,
            payload=request.data
        )
        return Response({
            'status': 'offline data synced successfully',
            'sync_id': sync_log.id
        }, status=status.HTTP_201_CREATED)
