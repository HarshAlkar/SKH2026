from django.urls import path
from .views import HealthRecordViewSet

record_list = HealthRecordViewSet.as_view({'get': 'list', 'post': 'create'})

urlpatterns = [
    path('', record_list, name='health-records'),
]
