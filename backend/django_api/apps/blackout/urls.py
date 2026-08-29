from django.urls import path

from .views import (
    BlackoutRecoverView,
    BlackoutSimulateView,
    BlackoutSnapshotView,
    BlackoutStatusView,
    BlackoutWipeView,
    display_page,
)

urlpatterns = [
    path('display/', display_page, name='blackout-display'),
    path('status/', BlackoutStatusView.as_view(), name='blackout-status'),
    path('snapshot/', BlackoutSnapshotView.as_view(), name='blackout-snapshot'),
    path('wipe/', BlackoutWipeView.as_view(), name='blackout-wipe'),
    path('recover/', BlackoutRecoverView.as_view(), name='blackout-recover'),
    path('simulate/', BlackoutSimulateView.as_view(), name='blackout-simulate'),
]
