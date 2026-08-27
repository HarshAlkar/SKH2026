from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import (
    AdminLoginView,
    AdminStatsView,
    AdminMapMarkersView,
    AdminUserViewSet,
    AdminPatientViewSet,
    AdminDoctorViewSet,
    AdminAshaViewSet,
    AdminConsultationViewSet,
    AdminPrescriptionViewSet,
    AdminEmergencyViewSet,
    AdminNotificationViewSet,
    AdminReferralViewSet,
    AdminRecordViewSet,
    AdminMedicineViewSet,
    AdminVisitViewSet,
    AdminSymptomViewSet,
    AdminChatViewSet,
    AdminFacilityViewSet,
    AdminCatalogViewSet,
    AdminSupplierViewSet,
    AdminStockBatchViewSet,
    AdminStockMovementViewSet,
    AdminInventoryStatsView,
)

router = DefaultRouter()
router.register(r'users', AdminUserViewSet, basename='admin-users')
router.register(r'patients', AdminPatientViewSet, basename='admin-patients')
router.register(r'doctors', AdminDoctorViewSet, basename='admin-doctors')
router.register(r'asha-workers', AdminAshaViewSet, basename='admin-asha')
router.register(r'consultations', AdminConsultationViewSet, basename='admin-consultations')
router.register(r'prescriptions', AdminPrescriptionViewSet, basename='admin-prescriptions')
router.register(r'emergencies', AdminEmergencyViewSet, basename='admin-emergencies')
router.register(r'notifications', AdminNotificationViewSet, basename='admin-notifications')
router.register(r'referrals', AdminReferralViewSet, basename='admin-referrals')
router.register(r'records', AdminRecordViewSet, basename='admin-records')
router.register(r'medicines', AdminMedicineViewSet, basename='admin-medicines')
router.register(r'visits', AdminVisitViewSet, basename='admin-visits')
router.register(r'symptoms', AdminSymptomViewSet, basename='admin-symptoms')
router.register(r'chat', AdminChatViewSet, basename='admin-chat')
router.register(r'facilities', AdminFacilityViewSet, basename='admin-facilities')
router.register(r'catalog', AdminCatalogViewSet, basename='admin-catalog')
router.register(r'suppliers', AdminSupplierViewSet, basename='admin-suppliers')
router.register(r'stock-batches', AdminStockBatchViewSet, basename='admin-stock-batches')
router.register(r'stock-movements', AdminStockMovementViewSet, basename='admin-stock-movements')

urlpatterns = [
    path('login/', AdminLoginView.as_view(), name='admin-login'),
    path('stats/', AdminStatsView.as_view(), name='admin-stats'),
    path('map-markers/', AdminMapMarkersView.as_view(), name='admin-map-markers'),
    path('inventory-stats/', AdminInventoryStatsView.as_view(), name='admin-inventory-stats'),
    path('', include(router.urls)),
]
