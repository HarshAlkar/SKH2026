from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import VillageVisitViewSet, ASHAWorkerDashboardView, ASHAWorkerViewSet

router = DefaultRouter()
router.register(r'visits', VillageVisitViewSet, basename='village-visits')
router.register(r'', ASHAWorkerViewSet, basename='asha-worker')

urlpatterns = [
    path('dashboard/', ASHAWorkerDashboardView.as_view(), name='asha-dashboard'),
    path('', include(router.urls)),
]
