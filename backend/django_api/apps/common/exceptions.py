"""Safe API error responses — no stack traces or secrets in production."""

from django.conf import settings
from rest_framework.views import exception_handler


def safe_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None and not settings.DEBUG:
        # Keep DRF structured errors; strip accidental internal detail dumps.
        data = response.data
        if isinstance(data, dict) and 'detail' in data:
            detail = str(data.get('detail', ''))
            lowered = detail.lower()
            if any(s in lowered for s in ('traceback', 'secret', 'password', 'token ', 'api_key')):
                response.data = {'detail': 'An error occurred.'}
    return response
