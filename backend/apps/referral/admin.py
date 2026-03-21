from django.contrib import admin
from .models import EmergencyReferral

@admin.register(EmergencyReferral)
class EmergencyReferralAdmin(admin.ModelAdmin):
    list_display = ('patient', 'severity', 'status', 'asha_worker', 'created_at')
    list_filter = ('severity', 'status')
    search_fields = ('patient__name', 'patient_id_display')

