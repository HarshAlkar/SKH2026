import os
import pickle
import re

import pandas as pd

from ai_engine.utils import dataset_path, model_path, normalize_symptom

_MODEL_BUNDLE = None

SYMPTOM_ALIASES = {
    "fever": "high_fever",
    "temp": "high_fever",
    "temperature": "high_fever",
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
    "breath": "breathlessness",
    "breathing": "breathlessness",
    "diarrhea": "diarrhoea",
    "diarrhoea": "diarrhoea",
    "cold": "continuous_sneezing",
    "sneeze": "continuous_sneezing",
    "pain": "abdominal_pain",
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
    ],
    "Critical": ["Heart attack", "paralysis"],
    "Moderate": [
        "Fungal infection",
        "Hypertension",
        "Diabetes",
        "Migraine",
        "Bronchial Asthma",
        "GERD",
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
    for item in symptoms_list or []:
        token = normalize_symptom(item)
        if not token:
            continue
        normalized.append(token)
        if token in SYMPTOM_ALIASES:
            normalized.append(SYMPTOM_ALIASES[token])
        for part in token.split("_"):
            if part in SYMPTOM_ALIASES:
                normalized.append(SYMPTOM_ALIASES[part])
    return list(dict.fromkeys(normalized))


def _severity_for(disease):
    lowered = disease.lower()
    for level, diseases in SEVERITY_MAP.items():
        if any(name.lower() in lowered for name in diseases):
            return level
    return "Low"


def _match_features(tokens, features):
    vector = []
    matched = 0
    for feature in features:
        hit = any(token in feature or feature in token for token in tokens)
        vector.append(1 if hit else 0)
        if hit:
            matched += 1
    return vector, matched


def _csv_fallback(tokens):
    csv_path = dataset_path()
    if not os.path.exists(csv_path):
        return {"disease": "Unknown (Dataset not found)", "severity": "Low", "confidence": 0.0}

    df = pd.read_csv(csv_path)
    disease_scores = {}
    for _, row in df.iterrows():
        disease = str(row.iloc[0]).strip()
        disease_symptoms = [
            normalize_symptom(val)
            for val in row.iloc[1:]
            if pd.notna(val) and str(val).strip()
        ]
        matches = 0
        for token in tokens:
            if any(token in symptom or symptom in token for symptom in disease_symptoms):
                matches += 1
        if matches > 0:
            disease_scores[disease] = max(disease_scores.get(disease, 0), matches)

    if not disease_scores:
        return {"disease": "Undetermined", "severity": "Low", "confidence": 0.0}

    prediction = max(disease_scores, key=disease_scores.get)
    max_score = disease_scores[prediction]
    confidence = round(min(1.0, max_score / max(len(tokens), 1)), 3)
    return {
        "disease": prediction,
        "severity": _severity_for(prediction),
        "confidence": confidence,
    }


def predict_symptoms(symptoms_list):
    tokens = _normalize_inputs(symptoms_list)
    if not tokens:
        return {"disease": "Undetermined", "severity": "Low", "confidence": 0.0}

    bundle = _load_bundle()
    if bundle:
        try:
            features = bundle["features"]
            model = bundle["model"]
            encoder = bundle["encoder"]
            vector, matched = _match_features(tokens, features)
            if matched:
                proba = model.predict_proba([vector])[0]
                index = int(proba.argmax())
                disease = str(encoder.inverse_transform([index])[0])
                confidence = round(float(proba[index]), 3)
                return {
                    "disease": disease,
                    "severity": _severity_for(disease),
                    "confidence": confidence,
                }
        except Exception:
            pass

    return _csv_fallback(tokens)
