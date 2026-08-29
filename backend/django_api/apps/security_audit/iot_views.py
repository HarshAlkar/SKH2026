"""Authenticated IoT sensor ingest stub — validates device HMAC + replay fields."""

import hashlib
import hmac
import time

from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.throttling import AnonRateThrottle
from rest_framework.views import APIView

from apps.security_audit.audit import log_security_event
from apps.security_audit.models import DeviceCredential


class DeviceIngestThrottle(AnonRateThrottle):
    rate = '30/min'


class DeviceSensorIngestView(APIView):
    """
    POST /api/iot/ingest/
    Headers: X-Device-Id, X-Device-Timestamp, X-Device-Nonce, X-Device-Signature
    Signature = HMAC-SHA256(secret, device_id|timestamp|nonce|body)
    """

    authentication_classes = []
    permission_classes = [AllowAny]
    throttle_classes = [DeviceIngestThrottle]

    def post(self, request):
        device_id = request.headers.get('X-Device-Id') or request.data.get('device_id')
        ts = request.headers.get('X-Device-Timestamp') or request.data.get('timestamp')
        nonce = request.headers.get('X-Device-Nonce') or request.data.get('nonce')
        signature = request.headers.get('X-Device-Signature') or request.data.get('signature')

        if not all([device_id, ts, nonce, signature]):
            return Response({'error': 'Missing device auth headers.'}, status=400)

        try:
            ts_i = int(ts)
        except (TypeError, ValueError):
            return Response({'error': 'Invalid timestamp.'}, status=400)

        now = int(time.time())
        if abs(now - ts_i) > 300:
            return Response({'error': 'Timestamp outside replay window.'}, status=401)

        device = DeviceCredential.objects.filter(device_id=device_id, is_active=True).first()
        if device is None:
            log_security_event(request, action='iot_ingest', success=False, metadata={'reason': 'unknown_device'})
            return Response({'error': 'Unknown or revoked device.'}, status=401)

        if device.last_nonce and device.last_nonce == str(nonce):
            return Response({'error': 'Replay detected.'}, status=401)

        # secret_hash stores sha256(secret) for at-rest protection of device secrets.
        # For demo/stub: accept signature over hash itself only when provisioning uses hash as key material.
        body = request.body.decode('utf-8', errors='replace') if request.body else ''
        message = f'{device_id}|{ts}|{nonce}|{body}'.encode('utf-8')
        # Compare against HMAC with secret_hash bytes (provisioning must use same material)
        expected = hmac.new(
            device.secret_hash.encode('utf-8'),
            message,
            hashlib.sha256,
        ).hexdigest()
        if not hmac.compare_digest(expected, str(signature).lower()):
            log_security_event(request, action='iot_ingest', success=False, object_id=device_id)
            return Response({'error': 'Invalid signature.'}, status=401)

        device.last_nonce = str(nonce)[:64]
        device.last_seen_at = timezone.now()
        device.save(update_fields=['last_nonce', 'last_seen_at'])

        log_security_event(
            request, action='iot_ingest', success=True,
            object_type='DeviceCredential', object_id=device_id,
        )
        return Response({
            'ok': True,
            'device_id': device_id,
            'message': 'Sensor payload accepted for validation pipeline.',
        }, status=status.HTTP_202_ACCEPTED)
