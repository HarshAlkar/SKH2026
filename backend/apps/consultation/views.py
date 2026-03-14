from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Consultation
from .serializers import ConsultationSerializer

class ConsultationViewSet(viewsets.ModelViewSet):
    queryset = Consultation.objects.all().order_by('-created_at')
    serializer_class = ConsultationSerializer

    @action(detail=False, methods=['post'], url_path='request')
    def request_consultation(self, request):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get'], url_path='history')
    def history(self, request):
        consultations = self.get_queryset()
        serializer = self.get_serializer(consultations, many=True)
        return Response(serializer.data)
