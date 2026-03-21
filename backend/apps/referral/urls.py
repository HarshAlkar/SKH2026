from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import EmergencyReferralViewSet

router = DefaultRouter()
router.register(r'', EmergencyReferralViewSet, basename='referral')

urlpatterns = [
    path('', include(router.urls)),
]
