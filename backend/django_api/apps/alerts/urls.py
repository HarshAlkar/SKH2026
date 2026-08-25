from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import EmergencyAlertViewSet, NotificationViewSet, EmergencyReferralViewSet

router = DefaultRouter()
router.register(r'emergencies', EmergencyAlertViewSet)
router.register(r'notifications', NotificationViewSet, basename='alert-notifications')
router.register(r'referrals', EmergencyReferralViewSet, basename='emergency-referrals')

urlpatterns = [
    path('', include(router.urls)),
]
