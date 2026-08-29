"""Predict livestock condition family from structured features or free text."""

from __future__ import annotations

import os
import pickle
import re

import numpy as np

from ai_engine.common.paths import models_dir
from ai_engine.common.risk import ANIMAL_DISCLAIMER, max_severity, screening_wording
from ai_engine.livestock.data import BINARY_COLS, severity_for_family

_BUNDLE = None


def livestock_model_path():
    return os.path.join(models_dir(), "livestock_model.pkl")


def _load():
    global _BUNDLE
    if _BUNDLE is not None:
        return _BUNDLE
    path = livestock_model_path()
    if not os.path.exists(path):
        return None
    with open(path, "rb") as handle:
        _BUNDLE = pickle.load(handle)
    return _BUNDLE


def _vector_from_structured(payload: dict, bundle) -> np.ndarray:
    species = bundle["species"]
    animal = str(payload.get("species") or payload.get("animal_type") or "").title()
    # normalize common mobile values
    mapping = {
        "CATTLE": "Cow",
        "BUFFALO": "Cow",
        "GOAT": "Goat",
        "SHEEP": "Sheep",
        "POULTRY": "Pig",  # no poultry in train set; nearest farm default avoided — use Other path
        "OTHER": "Dog",
    }
    if animal.upper() in mapping:
        animal = mapping[animal.upper()]
    # Try exact match ignoring case
    matched = None
    for s in species:
        if s.lower() == animal.lower():
            matched = s
            break
    species_oh = [1 if s == matched else 0 for s in species]
    binaries = []
    for col in BINARY_COLS:
        raw = payload.get(col) or payload.get(col.lower())
        if raw is None:
            # derive from free text
            text = str(payload.get("symptoms") or payload.get("text") or "").lower()
            key = col.lower().replace("_", " ")
            binaries.append(1 if key in text or col.split("_")[0].lower() in text else 0)
        else:
            binaries.append(1 if str(raw).lower() in {"yes", "y", "true", "1"} else 0)
    age = float(payload.get("age_months") or payload.get("age") or 0) / 12.0 / 20.0
    weight = float(payload.get("weight") or 0) / 100.0
    temp = float(payload.get("temperature") or payload.get("temp") or 0) / 45.0
    hr = float(payload.get("heart_rate") or 0) / 200.0
    # If age_months provided, convert better
    if payload.get("age_months") is not None:
        age = float(payload["age_months"]) / 12.0 / 20.0
    return np.asarray(species_oh + binaries + [age, weight, temp, hr], dtype=np.float32)


def _text_flags(text: str) -> dict:
    t = text.lower()
    return {
        "Appetite_Loss": any(k in t for k in ["not eating", "off feed", "anorexia", "appetite"]),
        "Vomiting": "vomit" in t,
        "Diarrhea": any(k in t for k in ["diarrhea", "diarrhoea", "scours", "loose stool"]),
        "Coughing": "cough" in t,
        "Labored_Breathing": any(
            k in t for k in ["breath", "panting", "gasping", "respiratory distress"]
        ),
        "Lameness": any(k in t for k in ["lame", "limp", "hoof"]),
        "Skin_Lesions": any(k in t for k in ["skin", "mange", "lesion", "itch"]),
        "Nasal_Discharge": any(k in t for k in ["nasal", "runny nose", "snot"]),
        "Eye_Discharge": "eye" in t and "discharge" in t,
    }


def predict_livestock(payload: dict) -> dict:
    """Return screening result compatible with AnimalScreeningView."""
    text = str(payload.get("symptoms") or payload.get("text") or "")
    flags = _text_flags(text)
    for k, v in flags.items():
        payload.setdefault(k, "Yes" if v else "No")

    bundle = _load()
    if not bundle:
        return {
            "condition": "Undetermined",
            "severity": "Low",
            "confidence": 0.2,
            "advice": "Consult a qualified veterinarian. AI model not loaded.",
            "disclaimer": ANIMAL_DISCLAIMER,
            "source": "livestock_ml_unavailable",
        }

    vec = _vector_from_structured(payload, bundle)
    model = bundle["model"]
    encoder = bundle["encoder"]
    display = {
        "Zoonotic_HighRisk": "Possible zoonotic / high-risk infectious signs",
        "Respiratory": "Respiratory illness signs",
        "Gastrointestinal": "Digestive / GI illness signs",
        "Skin_Parasite": "Skin / parasite concern",
        "Neurological": "Neurological concern",
        "Mastitis_Udder": "Udder / mastitis concern",
        "Systemic_Infectious": "Systemic infectious signs",
        "Other": "Non-specific illness signs",
    }
    if hasattr(model, "predict_proba"):
        proba = model.predict_proba([vec])[0]
        ranked = sorted(enumerate(proba), key=lambda x: x[1], reverse=True)[:3]
    else:
        pred = int(model.predict([vec])[0])
        ranked = [(pred, 0.55)]

    top = []
    for idx, score in ranked:
        family = str(encoder.inverse_transform([idx])[0])
        sev = severity_for_family(family, flags)
        top.append(
            {
                "family": family,
                "condition": display.get(family, family),
                "confidence": round(float(score), 3),
                "severity": sev,
            }
        )
    best = top[0]
    advice_map = {
        "Critical": "Isolate animal if possible and contact a veterinarian urgently.",
        "High": "Contact a veterinarian promptly. Monitor appetite, breathing, and hydration.",
        "Moderate": "Improve husbandry (shade, water, hygiene). Seek vet advice if worsening.",
        "Low": "Continue monitoring. Consult a veterinarian if new signs appear.",
    }
    return {
        "condition": best["condition"],
        "possible_condition": best["condition"],
        "family": best["family"],
        "severity": best["severity"],
        "confidence": best["confidence"],
        "top_predictions": top,
        "advice": advice_map.get(best["severity"], advice_map["Moderate"]),
        "message": screening_wording(best["condition"], "ANIMAL"),
        "disclaimer": ANIMAL_DISCLAIMER,
        "source": "livestock_ml",
    }
