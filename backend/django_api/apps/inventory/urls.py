from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import (
    DashboardView,
    CatalogViewSet,
    BatchViewSet,
    SupplierViewSet,
    FacilityViewSet,
    HistoryView,
    ExpiryView,
    LowStockView,
    AdjustStockView,
    SyncStockView,
    AvailabilityView,
    FacilitiesMapView,
)

router = DefaultRouter()
router.register(r'catalog', CatalogViewSet, basename='stock-catalog')
router.register(r'batches', BatchViewSet, basename='stock-batches')
router.register(r'suppliers', SupplierViewSet, basename='stock-suppliers')
router.register(r'facilities', FacilityViewSet, basename='stock-facilities')

urlpatterns = [
    path('dashboard/', DashboardView.as_view(), name='stock-dashboard'),
    path('adjust/', AdjustStockView.as_view(), name='stock-adjust'),
    path('sync/', SyncStockView.as_view(), name='stock-sync'),
    path('expiry/', ExpiryView.as_view(), name='stock-expiry'),
    path('low-stock/', LowStockView.as_view(), name='stock-low'),
    path('history/', HistoryView.as_view(), name='stock-history'),
    path('availability/', AvailabilityView.as_view(), name='stock-availability'),
    path('map/', FacilitiesMapView.as_view(), name='stock-map'),
    path('', include(router.urls)),
]
