from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PatientViewSet, EmergencyContactViewSet

router = DefaultRouter()
router.register(r'emergency-contacts', EmergencyContactViewSet, basename='emergency-contacts')
router.register(r'', PatientViewSet, basename='patients')

urlpatterns = [
    path('', include(router.urls)),
]
