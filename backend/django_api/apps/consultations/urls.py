from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ConsultationViewSet, AppointmentViewSet

router = DefaultRouter()
router.register(r'appointments', AppointmentViewSet, basename='appointment')
router.register(r'', ConsultationViewSet, basename='consultation')

urlpatterns = [
    path('', include(router.urls)),
]

