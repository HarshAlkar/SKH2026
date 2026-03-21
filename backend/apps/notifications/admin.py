from django.contrib import admin
from .models import Notification

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('message', 'type', 'status', 'created_at')
    list_filter = ('type', 'status')
