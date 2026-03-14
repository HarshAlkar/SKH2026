from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import DoctorViewSet

router = DefaultRouter()
router.register(r'list', DoctorViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
