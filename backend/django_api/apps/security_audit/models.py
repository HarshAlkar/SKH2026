from django.conf import settings
from django.db import models


class SecurityAuditLog(models.Model):
    """
    Security-relevant audit trail.
    Do NOT store passwords, tokens, OTP, API keys, or full clinical payloads.
    """

    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='security_audit_logs',
    )
    action = models.CharField(max_length=64, db_index=True)
    object_type = models.CharField(max_length=64, blank=True, default='')
    object_id = models.CharField(max_length=64, blank=True, default='')
    success = models.BooleanField(default=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.CharField(max_length=256, blank=True, default='')
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['action', 'created_at']),
        ]

    def __str__(self):
        return f'{self.action} by {self.actor_id} @ {self.created_at}'


class DeviceCredential(models.Model):
    """Future IoT/LoRa device identity — unique ID, revocable, no shared defaults."""

    device_id = models.CharField(max_length=64, unique=True, db_index=True)
    secret_hash = models.CharField(max_length=128)
    label = models.CharField(max_length=128, blank=True, default='')
    firmware_version = models.CharField(max_length=64, blank=True, default='')
    is_active = models.BooleanField(default=True)
    revoked_at = models.DateTimeField(null=True, blank=True)
    last_seen_at = models.DateTimeField(null=True, blank=True)
    last_nonce = models.CharField(max_length=64, blank=True, default='')
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='iot_devices',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.device_id}'
