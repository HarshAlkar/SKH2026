from django.urls import path
from .views import HealthRecordListView

urlpatterns = [
    path("", HealthRecordListView.as_view(), name="health-records"),
]
