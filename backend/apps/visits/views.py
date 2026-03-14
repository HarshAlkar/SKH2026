from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Visit
from .serializers import VisitSerializer

class VisitViewSet(viewsets.ModelViewSet):
    queryset = Visit.objects.all()
    serializer_class = VisitSerializer

    def perform_create(self, serializer):
        serializer.save(asha_worker=self.request.user)

    @action(detail=True, methods=['put'])
    def complete(self, request, pk=None):
        visit = self.get_object()
        visit.status = 'COMPLETED'
        visit.save()
        return Response({'status': 'visit completed'})
        
    @action(detail=False, methods=['post'], url_path='schedule')
    def schedule(self, request):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            self.perform_create(serializer)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
