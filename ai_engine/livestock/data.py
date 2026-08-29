"""Load animal CSV and collapse sparse disease labels into condition families."""

from __future__ import annotations

import re

import numpy as np
import pandas as pd

from ai_engine.common.paths import animal_csv

BINARY_COLS = [
    "Appetite_Loss",
    "Vomiting",
    "Diarrhea",
    "Coughing",
    "Labored_Breathing",
    "Lameness",
    "Skin_Lesions",
    "Nasal_Discharge",
    "Eye_Discharge",
]

# Keyword → condition family (order matters: first match wins)
FAMILY_RULES: list[tuple[list[str], str]] = [
    (
        ["tuberculosis", "fmd", "foot-and-mouth", "foot and mouth", "anthrax", "brucell", "rabies"],
        "Zoonotic_HighRisk",
    ),
    (
        ["mastitis", "udder"],
        "Mastitis_Udder",
    ),
    (
        [
            "influenza",
            "respiratory",
            "pneumonia",
            "cough",
            "rhino",
            "kennel",
            "distemper",
            "bronch",
        ],
        "Respiratory",
    ),
    (
        [
            "parvo",
            "gastro",
            "diarrhea",
            "diarrhoea",
            "enteritis",
            "colic",
            "bloat",
            "scours",
        ],
        "Gastrointestinal",
    ),
    (
        ["mange", "dermat", "skin", "ringworm", "lice", "tick", "scabies", "alopecia"],
        "Skin_Parasite",
    ),
    (
        [
            "encephal",
            "neuro",
            "paralysis",
            "seizure",
            "tetanus",
            "scrapie",
            "arthritis",
            "ataxia",
        ],
        "Neurological",
    ),
    (
        ["anemia", "anemia", "leukemia", "sepsis", "fever", "systemic", "viral"],
        "Systemic_Infectious",
    ),
]

FAMILY_SEVERITY = {
    "Zoonotic_HighRisk": "Critical",
    "Neurological": "High",
    "Respiratory": "High",
    "Mastitis_Udder": "High",
    "Gastrointestinal": "Moderate",
    "Skin_Parasite": "Moderate",
    "Systemic_Infectious": "High",
    "Other": "Moderate",
}


def collapse_disease(name: str) -> str:
    text = (name or "").lower()
    for keywords, family in FAMILY_RULES:
        if any(k in text for k in keywords):
            return family
    return "Other"


def _yes_no(val) -> int:
    s = str(val).strip().lower()
    return 1 if s in {"yes", "y", "true", "1"} else 0


def _parse_temp(val) -> float:
    if pd.isna(val):
        return 0.0
    m = re.search(r"([\d.]+)", str(val))
    return float(m.group(1)) if m else 0.0


def _parse_hr(val) -> float:
    try:
        return float(val)
    except Exception:
        return 0.0


def load_animal_matrix(dedupe: bool = True):
    df = pd.read_csv(animal_csv())
    if dedupe:
        df = df.drop_duplicates().reset_index(drop=True)

    species = sorted(df["Animal_Type"].astype(str).unique())
    families = []
    X = []
    meta_rows = []
    for _, row in df.iterrows():
        family = collapse_disease(str(row["Disease_Prediction"]))
        families.append(family)
        species_oh = [1 if str(row["Animal_Type"]) == s else 0 for s in species]
        binaries = [_yes_no(row[c]) for c in BINARY_COLS]
        temp = _parse_temp(row.get("Body_Temperature"))
        hr = _parse_hr(row.get("Heart_Rate"))
        age = float(row["Age"]) if pd.notna(row["Age"]) else 0.0
        weight = float(row["Weight"]) if pd.notna(row["Weight"]) else 0.0
        # Normalize vitals roughly
        vec = species_oh + binaries + [age / 20.0, weight / 100.0, temp / 45.0, hr / 200.0]
        X.append(vec)
        meta_rows.append(
            {
                "animal_type": str(row["Animal_Type"]),
                "disease": str(row["Disease_Prediction"]),
                "family": family,
            }
        )

    feature_names = (
        [f"species_{s}" for s in species]
        + BINARY_COLS
        + ["age_norm", "weight_norm", "temp_norm", "hr_norm"]
    )
    counts = pd.Series(families).value_counts().to_dict()
    return (
        np.asarray(X, dtype=np.float32),
        families,
        feature_names,
        species,
        {
            "n_samples": len(families),
            "family_counts": counts,
            "n_families": len(counts),
            "n_raw_diseases": int(df["Disease_Prediction"].nunique()),
        },
        meta_rows,
    )


def severity_for_family(family: str, feature_row: dict | None = None) -> str:
    base = FAMILY_SEVERITY.get(family, "Moderate")
    if feature_row:
        if feature_row.get("Labored_Breathing"):
            if base in {"Low", "Moderate"}:
                base = "High"
        if feature_row.get("Diarrhea") and feature_row.get("Vomiting") and feature_row.get("Appetite_Loss"):
            if base == "Low":
                base = "Moderate"
    return base
