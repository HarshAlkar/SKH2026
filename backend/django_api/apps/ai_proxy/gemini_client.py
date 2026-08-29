"""Shared Gemini generateContent helper with model fallbacks."""

from __future__ import annotations

import json
import re
import urllib.error
import urllib.request

from django.conf import settings

# gemini-2.0-flash / 2.5-flash are retired for many keys; prefer current flash models.
DEFAULT_MODELS = (
    'gemini-3.5-flash',
    'gemini-flash-latest',
    'gemini-3.6-flash',
    'gemini-3.1-flash-lite',
)


def configured_api_key() -> str:
    return (getattr(settings, 'GEMINI_API_KEY', '') or '').strip()


def preferred_models(requested: str | None = None) -> list[str]:
    env_default = (getattr(settings, 'GEMINI_MODEL', '') or '').strip()
    ordered: list[str] = []
    for name in (requested, env_default, *DEFAULT_MODELS):
        if not name:
            continue
        if not re.fullmatch(r'[a-zA-Z0-9._-]{3,64}', name):
            continue
        if name not in ordered:
            ordered.append(name)
    return ordered or list(DEFAULT_MODELS)


def extract_text(payload: dict) -> str:
    """Join candidate text parts; ignore empty / signature-only blobs."""
    chunks: list[str] = []
    for cand in payload.get('candidates') or []:
        content = cand.get('content') or {}
        for part in content.get('parts') or []:
            if not isinstance(part, dict):
                continue
            text = (part.get('text') or '').strip()
            if text:
                chunks.append(text)
        if chunks:
            break
    return '\n'.join(chunks).strip()


def generate_content(
    *,
    system: str,
    user_text: str | None = None,
    contents: list[dict] | None = None,
    model: str | None = None,
    temperature: float = 0.4,
    max_output_tokens: int = 4096,
    timeout: int = 60,
) -> tuple[str, str]:
    """
    Call Gemini generateContent.
    Returns (reply_text, model_used).
    Raises RuntimeError with a safe message on failure.
    """
    api_key = configured_api_key()
    if not api_key:
        raise RuntimeError('AI assistant is not configured on the server.')

    if contents is None:
        if not user_text:
            raise RuntimeError('message is required')
        contents = [{'role': 'user', 'parts': [{'text': user_text}]}]

    last_error = 'Upstream AI request failed.'
    for model_name in preferred_models(model):
        url = (
            f'https://generativelanguage.googleapis.com/v1beta/models/'
            f'{model_name}:generateContent?key={api_key}'
        )
        body = {
            'systemInstruction': {'parts': [{'text': system}]},
            'contents': contents,
            'generationConfig': {
                'temperature': temperature,
                'maxOutputTokens': max_output_tokens,
            },
        }
        req = urllib.request.Request(
            url,
            data=json.dumps(body).encode('utf-8'),
            headers={'Content-Type': 'application/json'},
            method='POST',
        )
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                payload = json.loads(resp.read().decode('utf-8'))
        except urllib.error.HTTPError as exc:
            detail = ''
            try:
                detail = exc.read().decode('utf-8', errors='replace')[:400]
            except Exception:
                detail = ''
            # Retired / missing model → try next candidate.
            if exc.code in (404, 400) and (
                'no longer available' in detail
                or 'not found' in detail.lower()
                or 'not supported' in detail.lower()
            ):
                last_error = f'Model {model_name} unavailable.'
                continue
            if exc.code in (401, 403):
                raise RuntimeError(
                    'Gemini API key rejected. Set a valid GEMINI_API_KEY from Google AI Studio.'
                ) from exc
            last_error = 'Upstream AI request failed. Check server GEMINI_API_KEY and model name.'
            continue
        except Exception as exc:
            last_error = 'AI request failed.'
            continue

        text = extract_text(payload)
        if text:
            return text, model_name
        last_error = 'Empty AI response.'

    raise RuntimeError(last_error)
