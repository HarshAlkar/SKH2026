from django.urls import path

from .iot_views import DeviceSensorIngestView

urlpatterns = [
    path('ingest/', DeviceSensorIngestView.as_view(), name='iot_ingest'),
]
