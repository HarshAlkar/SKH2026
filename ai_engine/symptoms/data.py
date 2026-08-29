"""Load and clean the 41-disease human symptom CSV."""

from __future__ import annotations

import os

import pandas as pd

from ai_engine.common.paths import (
    human_description_csv,
    human_precaution_csv,
    human_symptom_csv,
)
from ai_engine.utils import normalize_symptom


def load_precautions() -> dict[str, list[str]]:
    path = human_precaution_csv()
    if not os.path.exists(path):
        return {}
    df = pd.read_csv(path)
    out = {}
    for _, row in df.iterrows():
        disease = str(row.iloc[0]).strip()
        tips = [
            str(v).strip()
            for v in row.iloc[1:]
            if pd.notna(v) and str(v).strip()
        ]
        out[disease] = tips
    return out


def load_descriptions() -> dict[str, str]:
    path = human_description_csv()
    if not os.path.exists(path):
        return {}
    df = pd.read_csv(path)
    return {
        str(row.iloc[0]).strip(): str(row.iloc[1]).strip()
        for _, row in df.iterrows()
        if pd.notna(row.iloc[0])
    }


def load_symptom_matrix(dedupe: bool = True):
    """Return X (list of multi-hot), y (disease names), feature names."""
    df = pd.read_csv(human_symptom_csv())
    rows = []
    all_symptoms = set()
    for _, row in df.iterrows():
        disease = str(row.iloc[0]).strip()
        symptoms = []
        for val in row.iloc[1:]:
            if pd.notna(val) and str(val).strip():
                symptom = normalize_symptom(val)
                if symptom:
                    symptoms.append(symptom)
                    all_symptoms.add(symptom)
        if symptoms:
            rows.append((disease, tuple(sorted(set(symptoms)))))

    if dedupe:
        rows = list(dict.fromkeys(rows))

    features = sorted(all_symptoms)
    X = []
    y = []
    for disease, symptoms in rows:
        present = set(symptoms)
        X.append([1 if f in present else 0 for f in features])
        y.append(disease)
    return X, y, features, {
        "n_raw": int(len(df)),
        "n_after_dedupe": len(rows),
        "n_features": len(features),
        "n_classes": len(set(y)),
    }
