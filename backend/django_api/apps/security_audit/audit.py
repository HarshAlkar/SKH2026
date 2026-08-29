"""Audit logging helpers — never log secrets or PHI payloads."""

import logging

from .models import SecurityAuditLog

logger = logging.getLogger('apps.security_audit')

_BLOCKED_META_KEYS = {
    'password', 'token', 'refresh', 'otp', 'otp_code', 'api_key', 'authorization',
    'secret', 'gemini', 'access_token', 'refresh_token',
}


def _client_ip(request):
    if request is None:
        return None
    forwarded = request.META.get('HTTP_X_FORWARDED_FOR')
    if forwarded:
        return forwarded.split(',')[0].strip()
    return request.META.get('REMOTE_ADDR')


def _sanitize_metadata(metadata):
    if not metadata:
        return {}
    clean = {}
    for key, value in metadata.items():
        lk = str(key).lower()
        if lk in _BLOCKED_META_KEYS or any(b in lk for b in _BLOCKED_META_KEYS):
            continue
        if isinstance(value, (str, int, float, bool)) or value is None:
            clean[key] = value
        elif isinstance(value, (list, tuple)):
            clean[key] = [v for v in value if isinstance(v, (str, int, float, bool))][:20]
        else:
            clean[key] = str(type(value).__name__)
    return clean


def log_security_event(
    request=None,
    *,
    action: str,
    object_type: str = '',
    object_id: str = '',
    success: bool = True,
    metadata: dict | None = None,
    actor=None,
):
    user = actor
    if user is None and request is not None:
        user = getattr(request, 'user', None)
        if user is not None and not getattr(user, 'is_authenticated', False):
            user = None
    ua = ''
    if request is not None:
        ua = (request.META.get('HTTP_USER_AGENT') or '')[:256]
    try:
        SecurityAuditLog.objects.create(
            actor=user,
            action=action,
            object_type=object_type or '',
            object_id=str(object_id) if object_id is not None else '',
            success=success,
            ip_address=_client_ip(request),
            user_agent=ua,
            metadata=_sanitize_metadata(metadata),
        )
    except Exception:
        logger.exception('Failed to write security audit log for action=%s', action)
