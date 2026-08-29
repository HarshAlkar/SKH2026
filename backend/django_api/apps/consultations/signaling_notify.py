"""Notify the Node signaling server so web admin/pharmacy can refresh live."""
from __future__ import annotations

import json
import logging
import os
import urllib.error
import urllib.request

logger = logging.getLogger(__name__)


def notify_signaling(room: str, event: str, payload: dict | None = None) -> None:
    url = (os.environ.get('SIGNALING_NOTIFY_URL') or '').strip()
    if not url:
        return
    body = json.dumps({
        'room': room,
        'event': event,
        'payload': payload or {},
    }).encode('utf-8')
    req = urllib.request.Request(
        url,
        data=body,
        headers={'Content-Type': 'application/json'},
        method='POST',
    )
    try:
        with urllib.request.urlopen(req, timeout=2) as resp:
            resp.read()
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        logger.debug('Signaling notify failed: %s', exc)
