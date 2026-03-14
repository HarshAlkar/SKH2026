from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PrescriptionViewSet

router = DefaultRouter()
router.register(r'list', PrescriptionViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
