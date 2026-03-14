from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import EmergencyAlertViewSet, NotificationViewSet

router = DefaultRouter()
router.register(r'emergencies', EmergencyAlertViewSet)
router.register(r'notifications', NotificationViewSet, basename='alert-notifications')

urlpatterns = [
    path('', include(router.urls)),
]
