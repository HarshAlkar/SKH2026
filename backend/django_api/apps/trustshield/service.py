"""Curated-knowledge claim matcher. LLM is never the source of truth."""
from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

_DISCLAIMER = (
    'AI-assisted verification only. This is not a medical diagnosis. '
    'VitalReach does not claim 100% certainty. Consult a qualified healthcare professional.'
)

_REPORTS: list[dict[str, Any]] = []


def _kb_path() -> Path:
    return Path(__file__).resolve().parent / 'data' / 'curated_claims.json'


def _load_kb() -> dict[str, Any]:
    path = _kb_path()
    return json.loads(path.read_text(encoding='utf-8'))


def _banner(lines: list[str]) -> None:
    bar = '=' * 64
    print(f'\n{bar}', flush=True)
    for line in lines:
        safe = str(line).encode('ascii', 'replace').decode('ascii')
        print(f'  {safe}', flush=True)
    print(f'{bar}\n', flush=True)
    sys.stdout.flush()


def _normalize(text: str) -> str:
    cleaned = re.sub(r'\s+', ' ', (text or '').strip().lower())
    # Common WhatsApp typos / short forms
    replacements = {
        'drinkin ': 'drinking ',
        'drinkin': 'drinking',
        'drinkingwater': 'drinking water',
        'goodfor': 'good for',
    }
    for src, dst in replacements.items():
        cleaned = cleaned.replace(src, dst)
    return cleaned


def _groups_match(text: str, groups: list[list[str]]) -> bool:
    for group in groups:
        if not any(token.lower() in text for token in group):
            return False
    return True if groups else False


def _looks_like_health_claim(text: str) -> bool:
    cues = [
        'cure', 'antibiotic', 'medicine', 'treatment', 'whatsapp', 'dengue',
        'diabetes', 'fever', 'ors', 'handwash', 'vaccine', 'scheme', 'doctor said',
        'guaranteed', 'livestock', 'cattle', 'cow', 'infection',
        'इलाज', 'दवा', 'डेंगू', 'मधुमेह', 'बुखार', 'टीका',
        'उपचार', 'औषध', 'डेंग्यू', 'ताप', 'लसीकरण',
    ]
    return any(c in text for c in cues) or len(text) > 20


def verify_claim(claim: str, context: str = 'healthcare', offline: bool = False, language: str = 'en') -> dict[str, Any]:
    raw = (claim or '').strip()
    now = datetime.now(timezone.utc).isoformat()
    text = _normalize(raw)

    if not raw:
        return _localize_trust({
            'claim': '',
            'status': 'UNVERIFIED',
            'riskLevel': 'LOW',
            'confidence': 0.0,
            'explanation': 'No claim text was provided.',
            'recommendedAction': 'Paste a WhatsApp or community health message to verify.',
            'sources': [],
            'verifiedAt': now,
            'disclaimer': _DISCLAIMER,
            'offline': offline,
            'correctedGuidance': '',
            'kbLabel': '',
        }, language)

    kb = _load_kb()
    best: dict[str, Any] | None = None
    for entry in kb.get('entries') or []:
        groups = entry.get('keyword_groups') or []
        if groups and _groups_match(text, groups):
            best = entry
            break
        # Fallback: at least 2 keyword hits
        hits = sum(1 for k in (entry.get('keywords') or []) if k.lower() in text)
        if hits >= 2:
            best = entry
            break

    if best:
        status = best.get('status') or 'UNVERIFIED'
        risk = best.get('riskLevel') or 'LOW'
        if status == 'MISLEADING' and risk == 'HIGH':
            display_status = 'MISLEADING'
        else:
            display_status = status
        result = {
            'claim': best.get('claim_normalized') or raw,
            'status': display_status,
            'riskLevel': risk,
            'confidence': float(best.get('confidence') or 0.8),
            'explanation': best.get('explanation') or '',
            'recommendedAction': best.get('recommendedAction') or '',
            'sources': best.get('sources') or [],
            'verifiedAt': now,
            'disclaimer': _DISCLAIMER,
            'offline': offline,
            'correctedGuidance': best.get('correctedGuidance') or '',
            'kbLabel': kb.get('label') or 'curated',
            'matchedId': best.get('id'),
        }
        _banner([
            'TRUSTSHIELD VERIFY',
            f'Status={result["status"]} risk={result["riskLevel"]}',
            f'Claim={result["claim"][:80]}',
            f'Source=curated KB ({result.get("matchedId")})',
        ])
        return _localize_trust(result, language)

    # No KB hit — never invent VERIFIED
    if not _looks_like_health_claim(text):
        explanation = (
            'This message was not clearly identified as a specific health claim '
            'with matching trusted evidence.'
        )
    else:
        explanation = (
            'VitalReach could not find enough trusted evidence in the curated '
            'knowledge base to verify this claim.'
        )

    result = {
        'claim': raw,
        'status': 'UNVERIFIED',
        'riskLevel': 'MODERATE',
        'confidence': 0.35,
        'explanation': explanation,
        'recommendedAction': (
            'Do not act on this message as medical advice. '
            'Consult a qualified healthcare professional if concerned.'
        ),
        'sources': [
            {
                'name': 'VitalReach local verified database',
                'type': 'LOCAL_VERIFIED_DATABASE',
                'reference': 'local://trustshield/no_match',
            }
        ],
        'verifiedAt': now,
        'disclaimer': _DISCLAIMER,
        'offline': offline,
        'correctedGuidance': (
            'Health information check from VitalReach:\n\n'
            'We could not verify this forwarded health message against trusted information.\n'
            'Please do not self-medicate based on unverified claims.\n'
            'Consult a qualified healthcare professional when needed.'
        ),
        'kbLabel': kb.get('label') or 'curated',
        'matchedId': None,
    }
    _banner([
        'TRUSTSHIELD VERIFY',
        'Status=UNVERIFIED (no curated match — fail safe)',
        f'Claim={raw[:80]}',
    ])
    return _localize_trust(result, language)


def _localize_trust(result: dict[str, Any], language: str) -> dict[str, Any]:
    lang = (language or 'en').lower()
    out = dict(result)
    if lang.startswith('hi'):
        out['language'] = 'hi'
        out['disclaimer'] = (
            'AI-सहायता जाँच मात्र। यह चिकित्सा निदान नहीं है। योग्य स्वास्थ्य पेशेवर से सलाह लें।'
        )
        if not out.get('claim'):
            out['explanation'] = 'कोई दावा पाठ नहीं दिया गया।'
            out['recommendedAction'] = 'जाँच के लिए व्हाट्सएप या स्वास्थ्य संदेश पेस्ट करें।'
        elif not out.get('matchedId'):
            out['explanation'] = (
                'विश्वसनीय ज्ञान आधार में इस दावे को सत्यापित करने के लिए पर्याप्त प्रमाण नहीं मिला।'
            )
            out['recommendedAction'] = (
                'इस संदेश को चिकित्सा सलाह न मानें। चिंतित हों तो योग्य चिकित्सक से मिलें।'
            )
    elif lang.startswith('mr'):
        out['language'] = 'mr'
        out['disclaimer'] = (
            'AI-सहाय्यित तपासणी फक्त. हे वैद्यकीय निदान नाही. पात्र आरोग्य तज्ज्ञांचा सल्ला घ्या.'
        )
        if not out.get('claim'):
            out['explanation'] = 'दाव्याचा मजकूर दिला नाही.'
            out['recommendedAction'] = 'तपासणीसाठी व्हॉट्सअॅप किंवा आरोग्य संदेश पेस्ट करा.'
        elif not out.get('matchedId'):
            out['explanation'] = (
                'विश्वसनीय ज्ञान आधारात हा दावा पडताळण्यासाठी पुरेसा पुरावा सापडला नाही.'
            )
            out['recommendedAction'] = (
                'हा संदेश वैद्यकीय सल्ला समजू नका. काळजी असल्यास पात्र डॉक्टरांना भेटा.'
            )
    else:
        out['language'] = 'en'
    return out


def add_report(payload: dict[str, Any]) -> dict[str, Any]:
    entry = {
        **payload,
        'reportedAt': datetime.now(timezone.utc).isoformat(),
        'id': len(_REPORTS) + 1,
    }
    _REPORTS.append(entry)
    _banner(['TRUSTSHIELD REPORT', f'id={entry["id"]}', f'claim={(payload.get("claim") or "")[:60]}'])
    return entry


def list_reports() -> list[dict[str, Any]]:
    return list(reversed(_REPORTS[-50:]))
