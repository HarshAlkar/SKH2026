from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import HealthRecordViewSet

router = DefaultRouter()
router.register(r'', HealthRecordViewSet)

urlpatterns = [
    path('update/', HealthRecordViewSet.as_view({'post': 'update_record'})),
    path('<int:patient_id>/', HealthRecordViewSet.as_view({'get': 'by_patient'})),
    path('', include(router.urls)),
]
