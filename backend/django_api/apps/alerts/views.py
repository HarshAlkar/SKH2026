from rest_framework import viewsets, permissions
from .models import EmergencyAlert, AlertNotification
from .serializers import EmergencyAlertSerializer, AlertNotificationSerializer

class EmergencyAlertViewSet(viewsets.ModelViewSet):
    queryset = EmergencyAlert.objects.all()
    serializer_class = EmergencyAlertSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class NotificationViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = AlertNotificationSerializer
    http_method_names = ['get']

    def get_queryset(self):
        user = self.request.user
        if user.role == 'doctor':
            return AlertNotification.objects.filter(doctor__user=user)
        elif user.role == 'asha_worker':
            return AlertNotification.objects.filter(asha_worker__user=user)
        return AlertNotification.objects.filter(patient=user)
