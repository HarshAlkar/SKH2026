"""Expiring DRF token authentication (not JWT)."""

from datetime import timedelta

from django.conf import settings
from django.utils import timezone
from rest_framework.authentication import TokenAuthentication
from rest_framework.exceptions import AuthenticationFailed


class ExpiringTokenAuthentication(TokenAuthentication):
    """
    Standard DRF Token auth with optional TTL via TOKEN_TTL_HOURS.
    Tokens are opaque session credentials — not JWTs.
    """

    def authenticate_credentials(self, key):
        model = self.get_model()
        try:
            token = model.objects.select_related('user').get(key=key)
        except model.DoesNotExist:
            raise AuthenticationFailed('Invalid token.')

        if not token.user.is_active:
            raise AuthenticationFailed('User inactive or deleted.')

        ttl_hours = getattr(settings, 'TOKEN_TTL_HOURS', 0) or 0
        if ttl_hours > 0 and token.created:
            if token.created < timezone.now() - timedelta(hours=ttl_hours):
                token.delete()
                raise AuthenticationFailed('Token has expired. Please log in again.')

        return (token.user, token)


def rotate_token(user):
    """Delete existing tokens and issue a fresh one (login/OTP)."""
    from rest_framework.authtoken.models import Token

    Token.objects.filter(user=user).delete()
    return Token.objects.create(user=user)
