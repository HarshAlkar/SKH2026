import os
import pickle
import re

import pandas as pd

from ai_engine.utils import dataset_path, model_path, normalize_symptom

_MODEL_BUNDLE = None

CONFIDENCE_FLOOR = 0.35

# Map user language to dataset tokens. Do not upgrade plain fever to high_fever.
SYMPTOM_ALIASES = {
    "temp": "fever",
    "temperature": "fever",
    "cough": "cough",
    "rash": "skin_rash",
    "itch": "itching",
    "itching": "itching",
    "headache": "headache",
    "vomit": "vomiting",
    "vomiting": "vomiting",
    "nausea": "nausea",
    "fatigue": "fatigue",
    "tired": "fatigue",
    "chest": "chest_pain",
    "chest_pain": "chest_pain",
    "breath": "breathlessness",
    "breathing": "breathlessness",
    "diarrhea": "diarrhoea",
    "diarrhoea": "diarrhoea",
    "cold": "continuous_sneezing",
    "sneeze": "continuous_sneezing",
    "high_fever": "high_fever",
}

COMMON_RESPIRATORY = {
    "fever",
    "cough",
    "headache",
    "fatigue",
    "continuous_sneezing",
    "high_fever",
    "mild_fever",
}

# Rare / stigmatizing labels need distinctive co-symptoms, not fever alone.
RARE_REQUIREMENTS = {
    "aids": {"extra_marital_contacts", "patches_in_throat", "muscle_wasting"},
    "hiv": {"extra_marital_contacts", "patches_in_throat", "muscle_wasting"},
    "tuberculosis": {"blood_in_sputum", "weight_loss", "night_sweats", "sweating"},
    "heart attack": {"chest_pain", "sweating", "breathlessness"},
    "paralysis": {"weakness_of_one_body_side", "loss_of_balance", "unsteadiness"},
    "paralysis (brain hemorrhage)": {"weakness_of_one_body_side", "loss_of_balance"},
}

SEVERITY_MAP = {
    "High": [
        "Pneumonia",
        "Heart attack",
        "Jaundice",
        "Malaria",
        "Dengue",
        "Typhoid",
        "Tuberculosis",
        "hepatitis",
        "AIDS",
        "paralysis",
    ],
    "Critical": ["Heart attack", "paralysis"],
    "Moderate": [
        "Fungal infection",
        "Hypertension",
        "Diabetes",
        "Migraine",
        "Bronchial Asthma",
        "GERD",
        "Common Cold",
        "Possible viral illness",
    ],
}


def _load_bundle():
    global _MODEL_BUNDLE
    if _MODEL_BUNDLE is not None:
        return _MODEL_BUNDLE
    path = model_path()
    if not os.path.exists(path):
        try:
            from ai_engine.services.train_model import train_model
            train_model()
        except Exception:
            return None
    if not os.path.exists(path):
        return None
    with open(path, "rb") as handle:
        _MODEL_BUNDLE = pickle.load(handle)
    return _MODEL_BUNDLE


def _normalize_inputs(symptoms_list):
    if isinstance(symptoms_list, str):
        symptoms_list = re.findall(r"[\w]+", symptoms_list.lower())
    normalized = []
    raw = [normalize_symptom(item) for item in (symptoms_list or []) if str(item).strip()]
    # Rebuild "chest pain" style pairs that were split into words.
    joined = list(raw)
    for i in range(len(raw) - 1):
        pair = f"{raw[i]}_{raw[i + 1]}"
        if pair in SYMPTOM_ALIASES or pair in {"chest_pain", "high_fever", "skin_rash"}:
            joined.append(pair)
    for token in joined:
        if not token:
            continue
        normalized.append(token)
        if token in SYMPTOM_ALIASES:
            normalized.append(SYMPTOM_ALIASES[token])
        for part in token.split("_"):
            if part in SYMPTOM_ALIASES and SYMPTOM_ALIASES[part] != "abdominal_pain":
                normalized.append(SYMPTOM_ALIASES[part])
    return list(dict.fromkeys(normalized))


def _severity_for(disease):
    lowered = disease.lower()
    for level, diseases in SEVERITY_MAP.items():
        if any(name.lower() in lowered for name in diseases):
            return level
    return "Low"


def _match_features(tokens, features):
    """Exact feature hits only — substring matching activated mild_fever from fever."""
    token_set = {t.replace(" ", "_") for t in tokens}
    vector = []
    matched = 0
    for feature in features:
        key = str(feature).replace(" ", "_")
        hit = key in token_set
        vector.append(1 if hit else 0)
        if hit:
            matched += 1
    return vector, matched


def _token_set(tokens):
    return {t.replace(" ", "_") for t in tokens}


def _meets_rare_requirements(disease, tokens):
    key = disease.lower().strip()
    required = RARE_REQUIREMENTS.get(key)
    if required is None:
        for name, reqs in RARE_REQUIREMENTS.items():
            if name in key:
                required = reqs
                break
    if not required:
        return True
    present = _token_set(tokens)
    return bool(present & required)


def _undetermined(tokens, extras=None):
    present = _token_set(tokens)
    if present and present.issubset(COMMON_RESPIRATORY | {"vomiting", "nausea"}):
        disease = "Possible viral illness"
        severity = "Moderate" if "fever" in present or "high_fever" in present else "Low"
        confidence = 0.42
    else:
        disease = "Undetermined"
        severity = "Low"
        confidence = 0.2
    payload = {
        "disease": disease,
        "severity": severity,
        "confidence": confidence,
        "top_predictions": [
            {"disease": disease, "confidence": confidence, "severity": severity},
        ],
    }
    if extras:
        payload.update(extras)
    return payload


def _sanitize(result, tokens):
    predictions = list(result.get("top_predictions") or [])
    if result.get("disease") and not predictions:
        predictions = [
            {
                "disease": result["disease"],
                "confidence": result.get("confidence") or 0,
                "severity": result.get("severity") or _severity_for(result["disease"]),
            }
        ]

    safe = []
    for row in predictions:
        name = str(row.get("disease") or "")
        score = float(row.get("confidence") or 0)
        if score < CONFIDENCE_FLOOR:
            continue
        if not _meets_rare_requirements(name, tokens):
            continue
        row = dict(row)
        row["severity"] = _severity_for(name)
        safe.append(row)

    present = _token_set(tokens)
    only_common = bool(present) and present.issubset(COMMON_RESPIRATORY)

    if only_common:
        return _undetermined(tokens)

    if not safe:
        return _undetermined(tokens)

    best = safe[0]
    return {
        "disease": best["disease"],
        "severity": best["severity"],
        "confidence": best["confidence"],
        "top_predictions": safe[:3],
    }


def _csv_fallback(tokens):
    csv_path = dataset_path()
    if not os.path.exists(csv_path):
        return _undetermined(tokens)

    df = pd.read_csv(csv_path)
    disease_scores = {}
    present = _token_set(tokens)
    for _, row in df.iterrows():
        disease = str(row.iloc[0]).strip()
        disease_symptoms = [
            normalize_symptom(val)
            for val in row.iloc[1:]
            if pd.notna(val) and str(val).strip()
        ]
        if not disease_symptoms:
            continue
        matches = len(present & set(disease_symptoms))
        if matches > 0:
            coverage = matches / max(len(set(disease_symptoms)), 1)
            disease_scores[disease] = max(disease_scores.get(disease, 0), coverage)

    if not disease_scores:
        return _undetermined(tokens)

    ranked = sorted(disease_scores.items(), key=lambda item: item[1], reverse=True)[:5]
    top_predictions = [
        {
            "disease": name,
            "confidence": round(float(score), 3),
            "severity": _severity_for(name),
        }
        for name, score in ranked
    ]
    raw = {
        "disease": top_predictions[0]["disease"],
        "severity": top_predictions[0]["severity"],
        "confidence": top_predictions[0]["confidence"],
        "top_predictions": top_predictions,
    }
    return _sanitize(raw, tokens)


def predict_symptoms(symptoms_list):
    tokens = _normalize_inputs(symptoms_list)
    if not tokens:
        return _undetermined(tokens)

    bundle = _load_bundle()
    if bundle:
        try:
            features = bundle["features"]
            model = bundle["model"]
            encoder = bundle["encoder"]
            vector, matched = _match_features(tokens, features)
            if matched:
                proba = model.predict_proba([vector])[0]
                ranked = sorted(enumerate(proba), key=lambda item: item[1], reverse=True)[:5]
                top_predictions = []
                for index, score in ranked:
                    name = str(encoder.inverse_transform([index])[0])
                    top_predictions.append({
                        "disease": name,
                        "confidence": round(float(score), 3),
                        "severity": _severity_for(name),
                    })
                raw = {
                    "disease": top_predictions[0]["disease"],
                    "severity": top_predictions[0]["severity"],
                    "confidence": top_predictions[0]["confidence"],
                    "top_predictions": top_predictions,
                }
                return _sanitize(raw, tokens)
        except Exception:
            pass

    return _csv_fallback(tokens)
