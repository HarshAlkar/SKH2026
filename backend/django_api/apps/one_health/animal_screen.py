"""Rule-based livestock symptom screening (decision-support only)."""
from __future__ import annotations

import re
from typing import Any

# Keyword → (condition, severity, advice)
ANIMAL_RULES: list[tuple[list[str], str, str, str]] = [
    (
        ['bloody', 'diarrhea', 'diarrhoea', 'dysentery', 'blood stool'],
        'Suspected hemorrhagic enteritis (screening)',
        'Critical',
        'Isolate animal, withhold feed briefly, provide clean water. Contact a veterinarian immediately.',
    ),
    (
        ['cannot stand', 'downer', 'paralysis', 'collapse', 'unconscious'],
        'Recumbency / neurological concern (screening)',
        'Critical',
        'Do not force animal to stand. Keep shaded and calm. Call a veterinarian urgently.',
    ),
    (
        ['difficulty breathing', 'laboured breathing', 'panting', 'gasping', 'respiratory distress'],
        'Respiratory distress (screening)',
        'Critical',
        'Ensure fresh air, reduce crowding. Seek veterinary care immediately.',
    ),
    (
        ['sudden death', 'dead flock', 'mass mortality'],
        'Possible outbreak / acute illness (screening)',
        'Critical',
        'Report to local animal husbandry officer. Quarantine remaining animals.',
    ),
    (
        ['foot', 'mouth', 'blister', 'vesicle', 'lameness', 'salivation'],
        'Possible FMD-like signs (screening)',
        'High',
        'Isolate from other animals. Do not move livestock. Notify veterinarian / AH department.',
    ),
    (
        ['mastitis', 'swollen udder', 'hard udder', 'clotted milk', 'hot udder'],
        'Possible mastitis (screening)',
        'High',
        'Milk carefully, keep udder clean. Consult veterinarian for treatment guidance.',
    ),
    (
        ['fever', 'high temperature', 'hot body', 'shivering'],
        'Fever / systemic illness (screening)',
        'High',
        'Provide shade and water. Monitor appetite. Consult a veterinarian if fever persists.',
    ),
    (
        ['cough', 'nasal discharge', 'sneezing', 'runny nose'],
        'Respiratory infection signs (screening)',
        'Moderate',
        'Separate from healthy animals. Improve ventilation. Seek vet advice if worsening.',
    ),
    (
        ['diarrhea', 'diarrhoea', 'loose stool', 'scours', 'watery dung'],
        'Digestive upset (screening)',
        'Moderate',
        'Ensure clean water, consider oral rehydration for young animals. Call vet if bloody or lasting >24h.',
    ),
    (
        ['tick', 'mites', 'itching', 'skin lesions', 'mange', 'alopecia', 'hair loss'],
        'Skin / ectoparasite concern (screening)',
        'Moderate',
        'Check for parasites. Keep bedding clean. Veterinary review if widespread.',
    ),
    (
        ['not eating', 'anorexia', 'off feed', 'loss of appetite', 'weakness', 'lethargy'],
        'Reduced appetite / weakness (screening)',
        'Moderate',
        'Check feed and water quality. Escalate to veterinarian if lasting over a day.',
    ),
    (
        ['lameness', 'limping', 'swollen joint', 'hoof'],
        'Lameness / hoof concern (screening)',
        'Moderate',
        'Rest animal, inspect hoof. Veterinary exam if non-weight-bearing.',
    ),
    (
        ['low milk', 'drop in milk', 'reduced yield'],
        'Production drop (screening)',
        'Low',
        'Review nutrition and milking hygiene. Screen for mastitis if udder abnormal.',
    ),
]

DISCLAIMER = (
    'Livestock screening indicates decision support only and is not a veterinary diagnosis. '
    'Consult a qualified veterinarian.'
)

_SEVERITY_RANK = {'Low': 0, 'Moderate': 1, 'High': 2, 'Critical': 3}


def _tokens(text: str) -> str:
    return ' '.join(re.findall(r'[\w\u0900-\u097F]+', (text or '').lower()))


def _rule_screen(symptoms_text: str, species: str) -> dict[str, Any]:
    blob = _tokens(symptoms_text)
    if not blob.strip():
        return {
            'possible_condition': 'Insufficient information',
            'severity': 'Low',
            'confidence': 0.0,
            'advice': 'Describe observed signs (appetite, dung, breathing, movement).',
            'disclaimer': DISCLAIMER,
            'domain': 'ANIMAL',
            'species': species,
            'top_predictions': [],
            'source': 'rules',
        }

    matches: list[tuple[str, str, str, float]] = []
    for keywords, condition, severity, advice in ANIMAL_RULES:
        hits = sum(1 for k in keywords if k in blob)
        if hits:
            conf = min(0.92, 0.45 + 0.12 * hits)
            matches.append((condition, severity, advice, conf))

    if not matches:
        return {
            'possible_condition': 'Non-specific livestock signs (screening)',
            'severity': 'Low',
            'confidence': 0.35,
            'advice': (
                'Monitor feed, water, dung, and activity for 12–24 hours. '
                'Escalate to a veterinarian if signs worsen.'
            ),
            'disclaimer': DISCLAIMER,
            'domain': 'ANIMAL',
            'species': species,
            'top_predictions': [
                {
                    'disease': 'Non-specific livestock signs (screening)',
                    'severity': 'Low',
                    'confidence': 0.35,
                }
            ],
            'source': 'rules',
        }

    matches.sort(key=lambda m: (_SEVERITY_RANK.get(m[1], 0), m[3]), reverse=True)
    best = matches[0]
    top = [
        {'disease': c, 'severity': s, 'confidence': round(conf, 3)}
        for c, s, _, conf in matches[:3]
    ]
    return {
        'possible_condition': best[0],
        'disease': best[0],
        'severity': best[1],
        'confidence': round(best[3], 3),
        'advice': best[2],
        'disclaimer': DISCLAIMER,
        'domain': 'ANIMAL',
        'species': species,
        'top_predictions': top,
        'source': 'rules',
    }


def screen_animal_symptoms(symptoms_text: str, species: str = 'CATTLE', language: str = 'en') -> dict[str, Any]:
    """ML condition-family screening with Critical/High keyword safety override."""
    rules = _rule_screen(symptoms_text, species)
    ml = None
    try:
        from ai_engine.livestock.predict import predict_livestock

        ml = predict_livestock({'symptoms': symptoms_text, 'species': species})
    except Exception:
        ml = None

    if ml is None:
        return _localize_animal(rules, language)

    # Prefer rule engine when it flags Critical or High (safety net).
    if _SEVERITY_RANK.get(rules.get('severity'), 0) >= _SEVERITY_RANK['High']:
        out = dict(rules)
        out['ml_suggestion'] = {
            'condition': ml.get('condition'),
            'severity': ml.get('severity'),
            'confidence': ml.get('confidence'),
            'family': ml.get('family'),
        }
        out['source'] = 'rules_override_ml'
        out['message'] = (
            f"Livestock screening indicates elevated risk for {out.get('possible_condition')}. "
            "This result is decision support and not a veterinary diagnosis."
        )
        return _localize_animal(out, language)

    out = {
        'possible_condition': ml.get('condition') or ml.get('possible_condition'),
        'disease': ml.get('condition'),
        'severity': ml.get('severity') or 'Moderate',
        'confidence': ml.get('confidence') or 0.4,
        'advice': ml.get('advice') or rules.get('advice'),
        'disclaimer': DISCLAIMER,
        'domain': 'ANIMAL',
        'species': species,
        'top_predictions': [
            {
                'disease': p.get('condition') or p.get('family'),
                'severity': p.get('severity'),
                'confidence': p.get('confidence'),
            }
            for p in (ml.get('top_predictions') or [])
        ],
        'family': ml.get('family'),
        'source': ml.get('source') or 'livestock_ml',
        'message': ml.get('message')
        or (
            f"Livestock screening indicates elevated risk for {ml.get('condition')}. "
            "This result is decision support and not a veterinary diagnosis."
        ),
    }
    return _localize_animal(out, language)


def _localize_animal(result: dict[str, Any], language: str) -> dict[str, Any]:
    lang = (language or 'en').lower()
    out = dict(result)
    out['language'] = 'mr' if lang.startswith('mr') else ('hi' if lang.startswith('hi') else 'en')
    if out['language'] == 'hi':
        out['disclaimer'] = (
            'स्क्रीनिंग से जोखिम का संकेत — योग्य पशुचिकित्सक से सलाह लें। यह पशु चिकित्सा निदान नहीं है।'
        )
        out['severity_display'] = {
            'Low': 'कम', 'Moderate': 'मध्यम', 'High': 'उच्च', 'Critical': 'गंभीर',
        }.get(str(out.get('severity') or ''), out.get('severity'))
        out['disease_display'] = out.get('possible_condition')
        if not out.get('advice'):
            out['advice'] = 'पशु को छाया और पानी दें। बिगड़ने पर पशुचिकित्सक से संपर्क करें।'
    elif out['language'] == 'mr':
        out['disclaimer'] = (
            'स्क्रीनिंगमुळे धोका दिसतो — पात्र पशुवैद्यांचा सल्ला घ्या. हे पशुवैद्यकीय निदान नाही.'
        )
        out['severity_display'] = {
            'Low': 'कमी', 'Moderate': 'मध्यम', 'High': 'उच्च', 'Critical': 'गंभीर',
        }.get(str(out.get('severity') or ''), out.get('severity'))
        out['disease_display'] = out.get('possible_condition')
        if not out.get('advice'):
            out['advice'] = 'पशुला सावली आणि पाणी द्या. बिघडल्यास पशुवैद्यकाशी संपर्क करा.'
    else:
        out['disclaimer'] = DISCLAIMER
        out['severity_display'] = out.get('severity')
        out['disease_display'] = out.get('possible_condition')
    return out
