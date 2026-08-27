from django.contrib import admin

from .models import (
    HealthcareFacility,
    MedicalStaffProfile,
    MedicineCatalog,
    Supplier,
    StockBatch,
    StockMovement,
)


@admin.register(HealthcareFacility)
class HealthcareFacilityAdmin(admin.ModelAdmin):
    list_display = ('name', 'facility_type', 'village', 'district', 'is_active')
    list_filter = ('facility_type', 'is_active')
    search_fields = ('name', 'village', 'district')


@admin.register(MedicalStaffProfile)
class MedicalStaffProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'facility', 'designation')
    search_fields = ('user__username', 'user__name')


@admin.register(MedicineCatalog)
class MedicineCatalogAdmin(admin.ModelAdmin):
    list_display = ('sku', 'name', 'strength', 'category', 'unit', 'is_active')
    list_filter = ('category', 'is_active')
    search_fields = ('sku', 'name')


@admin.register(Supplier)
class SupplierAdmin(admin.ModelAdmin):
    list_display = ('name', 'contact', 'is_active')
    search_fields = ('name',)


@admin.register(StockBatch)
class StockBatchAdmin(admin.ModelAdmin):
    list_display = ('batch_no', 'catalog', 'facility', 'quantity', 'expiry_date', 'reorder_level')
    list_filter = ('facility',)
    search_fields = ('batch_no', 'catalog__name')


@admin.register(StockMovement)
class StockMovementAdmin(admin.ModelAdmin):
    list_display = ('action', 'batch', 'quantity', 'actor', 'client_id', 'created_at')
    list_filter = ('action',)
    search_fields = ('client_id', 'invoice_no', 'reason')
