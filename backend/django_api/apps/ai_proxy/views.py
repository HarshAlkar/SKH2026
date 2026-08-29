"""Server-side Gemini proxy — API key never leaves the backend."""

from __future__ import annotations

import json
import re
import urllib.error
import urllib.request

from django.conf import settings
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.security_audit.audit import log_security_event

DOMAIN_PROMPTS = {
    'human': (
        'You are a decision-support assistant for rural primary care. '
        'Do not diagnose. Encourage consulting a qualified clinician. '
        'Never ask for or repeat phone numbers, Aadhaar, passwords, or tokens.'
    ),
    'skin': (
        'You assist with general skin-health education only. '
        'This is not dermatological diagnosis. Urge professional evaluation for lesions.'
    ),
    'livestock': (
        'You assist with livestock health education for One Health workflows. '
        'Not a veterinary diagnosis. Suggest contacting a veterinarian for serious signs.'
    ),
    'child': (
        'You provide general child-development and wellness education only. '
        'Not a pediatric diagnosis. Urge caregivers to seek professional care when concerned.'
    ),
}

_PII_PATTERNS = [
    re.compile(r'\b\d{10}\b'),
    re.compile(r'\b\d{12}\b'),
    re.compile(r'(?i)(password|token|otp|aadhaar|api[_-]?key)\s*[:=]\s*\S+'),
]


def _sanitize_user_text(text: str, max_len: int = 4000) -> str:
    cleaned = (text or '').strip()[:max_len]
    for pat in _PII_PATTERNS:
        cleaned = pat.sub('[REDACTED]', cleaned)
    return cleaned


class GeminiStatusView(APIView):
    """SAFE diagnostic — never returns the API key."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        key = getattr(settings, 'GEMINI_API_KEY', '') or ''
        return Response({'gemini_configured': bool(key.strip())})


class GeminiChatProxyView(APIView):
    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'gemini'

    def post(self, request):
        api_key = getattr(settings, 'GEMINI_API_KEY', '') or ''
        if not api_key:
            return Response(
                {
                    'error': 'AI assistant is not configured on the server.',
                    'result_state': 'AI_CHAT_UNAVAILABLE',
                    'gemini_configured': False,
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        message = _sanitize_user_text(request.data.get('message') or request.data.get('prompt') or '')
        if not message:
            return Response({'error': 'message is required'}, status=400)

        domain = (request.data.get('domain') or 'human').lower()
        if domain not in DOMAIN_PROMPTS:
            domain = 'human'

        severity = (request.data.get('severity') or '').strip()
        system = DOMAIN_PROMPTS[domain] + (
            ' Always state that VitalReach AI is decision-support only, not a substitute for clinical care.'
            ' Never say the user "has" a disease — say screening suggested elevated risk for discussion.'
        )
        if severity.lower() in ('high', 'critical'):
            system += (
                ' The screening risk is High/Critical: reinforce that professional evaluation '
                '(ASHA / doctor for humans, veterinarian for livestock) is recommended. '
                'Do not override that escalation advice.'
            )

        model = (request.data.get('model') or 'gemini-2.0-flash').strip()
        if not re.fullmatch(r'[a-zA-Z0-9._-]{3,64}', model):
            model = 'gemini-2.0-flash'

        url = (
            f'https://generativelanguage.googleapis.com/v1beta/models/'
            f'{model}:generateContent?key={api_key}'
        )
        body = {
            'systemInstruction': {'parts': [{'text': system}]},
            'contents': [{'role': 'user', 'parts': [{'text': message}]}],
            'generationConfig': {
                'temperature': 0.4,
                'maxOutputTokens': 1024,
            },
        }
        req = urllib.request.Request(
            url,
            data=json.dumps(body).encode('utf-8'),
            headers={'Content-Type': 'application/json'},
            method='POST',
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                payload = json.loads(resp.read().decode('utf-8'))
        except urllib.error.HTTPError as exc:
            log_security_event(
                request, action='gemini_proxy', success=False,
                metadata={'domain': domain, 'http_status': exc.code},
            )
            # Never echo upstream body (may contain secrets / internals)
            return Response(
                {
                    'error': 'Upstream AI request failed. Check server GEMINI_API_KEY and model name.',
                    'result_state': 'AI_CHAT_UNAVAILABLE',
                },
                status=502,
            )
        except Exception:
            log_security_event(request, action='gemini_proxy', success=False, metadata={'domain': domain})
            return Response(
                {'error': 'AI request failed.', 'result_state': 'AI_CHAT_UNAVAILABLE'},
                status=502,
            )

        text = ''
        try:
            candidates = payload.get('candidates') or []
            parts = (candidates[0].get('content') or {}).get('parts') or []
            text = ''.join(p.get('text', '') for p in parts if isinstance(p, dict))
        except Exception:
            text = ''

        text = _sanitize_user_text(text, max_len=8000)
        log_security_event(
            request, action='gemini_proxy', success=True,
            metadata={'domain': domain, 'chars': len(message)},
        )
        return Response({
            'reply': text,
            'domain': domain,
            'disclaimer': 'Decision-support only. Not a medical or veterinary diagnosis.',
            'gemini_configured': True,
        })
