from django.contrib import admin
from .models import Alert

@admin.register(Alert)
class AlertAdmin(admin.ModelAdmin):
    list_display = ('patient', 'alert_type', 'severity', 'created_at')
    list_filter = ('severity', 'alert_type')
