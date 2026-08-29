"""Return a small JSON 400 when the Host header is not in ALLOWED_HOSTS."""

from django.core.exceptions import DisallowedHost
from django.http import JsonResponse


class JsonDisallowedHostMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        try:
            request.get_host()
        except DisallowedHost:
            return JsonResponse(
                {
                    'error': (
                        'This device address is not in ALLOWED_HOSTS. '
                        'Add the PC LAN IP (or * while DEBUG=True) and restart Django.'
                    )
                },
                status=400,
            )
        return self.get_response(request)
