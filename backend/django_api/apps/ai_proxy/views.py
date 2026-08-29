"""Server-side Gemini proxy — API key never leaves the backend."""

from __future__ import annotations

import json
import re

from django.conf import settings
from rest_framework import status
from rest_framework.permissions import IsAdminUser, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.security_audit.audit import log_security_event

from .gemini_client import configured_api_key, generate_content

DOMAIN_PROMPTS = {
    'human': (
        'You are a decision-support assistant for rural primary care (VitalReach). '
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
    'general': (
        'You are VitalReach health education assistant for rural India. '
        'Answer clearly in simple language. Do not diagnose. '
        'Encourage ASHA / doctor / veterinarian when care is needed.'
    ),
}

EVIDENCE_RULES = (
    ' Always answer the user question using Gemini knowledge, then add an "Evidence" section '
    'with 2–4 short bullet points (guidelines, WHO/MoHFW-style public health facts, or '
    'well-known clinical education points). If evidence is uncertain, say so and mark status '
    'as educational only. Never invent specific study IDs or fake URLs. '
    'Always state that VitalReach AI is decision-support only, not a substitute for clinical care. '
    'Never say the user "has" a disease — say screening suggested elevated risk for discussion.'
)

_LANG_INSTRUCT = {
    'hi': ' Respond entirely in simple Hindi using Devanagari script. Use short rural-friendly words.',
    'mr': ' Respond entirely in simple Marathi using Devanagari script. Use short rural-friendly words.',
    'en': ' Respond in clear simple English.',
}

_DISCLAIMER = {
    'en': 'Decision-support only. Not a medical or veterinary diagnosis.',
    'hi': 'केवल निर्णय-सहायता। यह चिकित्सा या पशु चिकित्सा निदान नहीं है।',
    'mr': 'फक्त निर्णय-समर्थन. हे वैद्यकीय किंवा पशुवैद्यकीय निदान नाही.',
}


def _normalize_lang(raw) -> str:
    lang = (raw or 'en').strip().lower()
    if lang.startswith('hi'):
        return 'hi'
    if lang.startswith('mr'):
        return 'mr'
    return 'en'

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


def _build_contents(message: str, history) -> list[dict]:
    contents: list[dict] = []
    if isinstance(history, list):
        for turn in history[-8:]:
            if not isinstance(turn, dict):
                continue
            role = (turn.get('role') or '').lower()
            text = _sanitize_user_text(turn.get('text') or turn.get('content') or '', 2000)
            if not text:
                continue
            if role in ('user', 'human'):
                contents.append({'role': 'user', 'parts': [{'text': text}]})
            elif role in ('assistant', 'model', 'ai'):
                contents.append({'role': 'model', 'parts': [{'text': text}]})
    contents.append({'role': 'user', 'parts': [{'text': message}]})
    return contents


class GeminiStatusView(APIView):
    """SAFE diagnostic — never returns the API key."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        key = configured_api_key()
        return Response({
            'gemini_configured': bool(key),
            'default_model': (getattr(settings, 'GEMINI_MODEL', '') or 'gemini-3.5-flash'),
        })


class GeminiChatProxyView(APIView):
    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'gemini'

    def post(self, request):
        if not configured_api_key():
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
            domain = 'general'

        severity = (request.data.get('severity') or '').strip()
        language = _normalize_lang(request.data.get('language'))
        system = DOMAIN_PROMPTS[domain] + EVIDENCE_RULES + _LANG_INSTRUCT[language]
        if severity.lower() in ('high', 'critical'):
            system += (
                ' The screening risk is High/Critical: reinforce that professional evaluation '
                '(ASHA / doctor for humans, veterinarian for livestock) is recommended. '
                'Do not override that escalation advice.'
            )

        model = (request.data.get('model') or '').strip() or None
        contents = _build_contents(message, request.data.get('history'))

        try:
            text, model_used = generate_content(
                system=system,
                contents=contents,
                model=model,
                max_output_tokens=4096,
            )
        except RuntimeError as exc:
            log_security_event(
                request, action='gemini_proxy', success=False,
                metadata={'domain': domain},
            )
            msg = str(exc)
            code = 503 if 'not configured' in msg.lower() else 502
            return Response(
                {'error': msg, 'result_state': 'AI_CHAT_UNAVAILABLE'},
                status=code,
            )

        text = _sanitize_user_text(text, max_len=8000)
        log_security_event(
            request, action='gemini_proxy', success=True,
            metadata={'domain': domain, 'chars': len(message), 'model': model_used},
        )
        return Response({
            'reply': text,
            'domain': domain,
            'model': model_used,
            'evidence_included': 'Evidence' in text or 'evidence' in text.lower(),
            'disclaimer': _DISCLAIMER[language],
            'language': language,
            'gemini_configured': True,
        })


class GeminiReportAnalysisView(APIView):
    """Generate a Gemini narrative report from stats / screening / village payload."""

    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'gemini'

    def post(self, request):
        if not configured_api_key():
            return Response(
                {
                    'error': 'AI assistant is not configured on the server.',
                    'gemini_configured': False,
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        report_type = (request.data.get('report_type') or 'network').lower()
        focus = _sanitize_user_text(request.data.get('focus') or '', 500)
        raw_context = request.data.get('context') or request.data.get('stats') or {}
        if not isinstance(raw_context, dict):
            raw_context = {'raw': str(raw_context)[:2000]}

        # Keep payload small and free of secrets.
        safe_context = {}
        for key, value in list(raw_context.items())[:40]:
            if isinstance(value, (str, int, float, bool)) or value is None:
                safe_context[str(key)[:64]] = value if not isinstance(value, str) else value[:500]
            elif isinstance(value, list):
                safe_context[str(key)[:64]] = value[:12]
            elif isinstance(value, dict):
                safe_context[str(key)[:64]] = {
                    str(k)[:40]: (v if not isinstance(v, str) else v[:200])
                    for k, v in list(value.items())[:12]
                }

        if report_type == 'symptom':
            system = (
                'You are a clinical decision-support analyst for VitalReach. '
                'Write a clear AI analysis of one symptom screening. '
                'Do not diagnose. Structure with: Summary, What the numbers suggest, '
                'Risks to watch, Recommended next steps, Evidence (2–4 public-health bullets). '
                'Use plain language suitable for ASHA supervisors.'
            )
        elif report_type == 'village':
            system = (
                'You are a village public-health analyst for VitalReach. '
                'Write a short village health situation report from the given counts. '
                'Structure: Overview, Priority concerns, Suggested ASHA actions, Evidence. '
                'Do not invent patients or outbreaks not supported by the data.'
            )
        else:
            system = (
                'You are VitalReach network analytics assistant. '
                'From the admin stats JSON, generate a supervisor briefing: '
                'Network health overview, Hotspots / pressure points, AI screening load, '
                'Recommended supervisor actions this week, Evidence / rationale. '
                'Be concise and actionable. Do not invent data not present in the JSON.'
            )
        system += EVIDENCE_RULES
        language = _normalize_lang(request.data.get('language'))
        system += _LANG_INSTRUCT[language]

        prompt = (
            f'Report type: {report_type}\n'
            f'Focus: {focus or "general briefing"}\n'
            f'Data (JSON):\n{json.dumps(safe_context, ensure_ascii=True)[:6000]}\n\n'
            'Generate the AI analysis report now.'
        )

        try:
            text, model_used = generate_content(
                system=system,
                user_text=prompt,
                max_output_tokens=4096,
                temperature=0.35,
            )
        except RuntimeError as exc:
            log_security_event(request, action='gemini_report', success=False)
            msg = str(exc)
            code = 503 if 'not configured' in msg.lower() else 502
            return Response({'error': msg}, status=code)

        text = _sanitize_user_text(text, max_len=10000)
        log_security_event(
            request, action='gemini_report', success=True,
            metadata={'report_type': report_type, 'model': model_used},
        )
        return Response({
            'report': text,
            'report_type': report_type,
            'model': model_used,
            'disclaimer': _DISCLAIMER[language],
            'language': language,
            'gemini_configured': True,
        })


class AdminGeminiReportView(GeminiReportAnalysisView):
    """Admin-only alias for report generation."""

    permission_classes = [IsAdminUser]


class DetectLanguageView(APIView):
    """EN/HI/MR language ID — on-device is preferred; this is a server fallback."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        text = (request.data.get('text') or '')[:4000]
        fallback = _normalize_lang(request.data.get('fallback') or request.data.get('language'))
        detected = fallback
        try:
            from ai_engine.langid.features import LABELS, vectorize
            import json as json_lib
            from pathlib import Path
            labels_path = Path(settings.BASE_DIR).parent.parent / 'ai_engine' / 'models' / 'langid_labels.json'
            payload = json_lib.loads(labels_path.read_text(encoding='utf-8'))
            coef = payload['coef']
            intercept = payload['intercept']
            vec = vectorize(text)
            import math
            logits = []
            for i, row in enumerate(coef):
                s = intercept[i]
                for j, w in enumerate(row):
                    s += w * float(vec[j])
                logits.append(s)
            m = max(logits)
            exps = [math.exp(v - m) for v in logits]
            total = sum(exps) or 1.0
            probs = [e / total for e in exps]
            idx = max(range(len(probs)), key=lambda i: probs[i])
            if probs[idx] >= 0.55:
                detected = LABELS[idx]
        except Exception:
            if any('\u0900' <= ch <= '\u097f' for ch in text):
                mr_hits = sum(1 for w in ('आहे', 'तुम्ही', 'नाही', 'कसे', 'मला') if w in text)
                hi_hits = sum(1 for w in ('है', 'आप', 'नहीं', 'कैसे', 'मुझे') if w in text)
                if mr_hits > hi_hits:
                    detected = 'mr'
                elif hi_hits > mr_hits:
                    detected = 'hi'
            elif sum(ch.isascii() and ch.isalpha() for ch in text) >= 8:
                detected = 'en'
        return Response({'language': detected, 'fallback': fallback})

