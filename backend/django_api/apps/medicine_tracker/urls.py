from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import MedicineTrackerViewSet

router = DefaultRouter()
router.register(r'', MedicineTrackerViewSet, basename='medicine-tracker')

urlpatterns = [
    path('', include(router.urls)),
]
