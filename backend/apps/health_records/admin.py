from django.contrib import admin
from .models import HealthRecord

@admin.register(HealthRecord)
class HealthRecordAdmin(admin.ModelAdmin):
    list_display = ('patient', 'temperature', 'blood_pressure', 'created_at')
    list_filter = ('created_at',)
