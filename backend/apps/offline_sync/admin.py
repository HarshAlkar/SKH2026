from django.contrib import admin
from .models import SyncLog

@admin.register(SyncLog)
class SyncLogAdmin(admin.ModelAdmin):
    list_display = ('asha_worker', 'created_at')
    readonly_fields = ('asha_worker', 'payload', 'created_at')
