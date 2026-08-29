from django.contrib import admin

from .models import SecurityAuditLog, DeviceCredential


@admin.register(SecurityAuditLog)
class SecurityAuditLogAdmin(admin.ModelAdmin):
    list_display = ('created_at', 'action', 'actor', 'object_type', 'object_id', 'success', 'ip_address')
    list_filter = ('action', 'success', 'object_type')
    search_fields = ('object_id', 'action', 'actor__phone_number', 'actor__username')
    readonly_fields = (
        'actor', 'action', 'object_type', 'object_id', 'success',
        'ip_address', 'user_agent', 'metadata', 'created_at',
    )

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False


@admin.register(DeviceCredential)
class DeviceCredentialAdmin(admin.ModelAdmin):
    list_display = ('device_id', 'label', 'is_active', 'firmware_version', 'last_seen_at', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('device_id', 'label')
    readonly_fields = ('last_seen_at', 'last_nonce', 'created_at', 'revoked_at')
