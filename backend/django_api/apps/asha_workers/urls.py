from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ASHAWorkerDashboardView, VillageVisitViewSet

router = DefaultRouter()
router.register('visits', VillageVisitViewSet, basename='village-visits')

urlpatterns = [
    path('dashboard/', ASHAWorkerDashboardView.as_view(), name='asha-dashboard'),
    path('', include(router.urls)),
]
