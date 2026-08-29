"""Inspect all VitalReach screening datasets and write a JSON/MD report."""

from __future__ import annotations

import json
import os
from collections import Counter
from pathlib import Path

import pandas as pd

from ai_engine.common.paths import (
    animal_csv,
    human_description_csv,
    human_precaution_csv,
    human_symptom_csv,
    reports_dir,
    skin_archive1_dir,
)
from ai_engine.utils import normalize_symptom


def _inspect_human():
    path = human_symptom_csv()
    df = pd.read_csv(path)
    # Build symptom-set fingerprint per row for dedupe stats
    fingerprints = []
    for _, row in df.iterrows():
        disease = str(row.iloc[0]).strip()
        symptoms = tuple(
            sorted(
                {
                    normalize_symptom(v)
                    for v in row.iloc[1:]
                    if pd.notna(v) and str(v).strip()
                }
            )
        )
        fingerprints.append((disease, symptoms))
    unique = set(fingerprints)
    return {
        "name": "disease/dataset.csv (Kaggle-style 41-disease symptom table)",
        "path": path,
        "n_records": int(len(df)),
        "n_unique_disease_symptom_sets": len(unique),
        "n_duplicate_rows": int(len(df) - len(unique)),
        "n_diseases": int(df.iloc[:, 0].nunique()),
        "class_counts": df.iloc[:, 0].value_counts().to_dict(),
        "missing_cells": int(df.isna().sum().sum()),
        "features": "Disease + Symptom_1..Symptom_17 (sparse string lists)",
        "target": "Disease",
        "suitable_for_symptom_screening": True,
        "notes": (
            "High duplicate rate; train on deduplicated rows. "
            "Synthetic/balanced 120 rows per disease before dedupe."
        ),
        "precaution_csv_exists": os.path.exists(human_precaution_csv()),
        "description_csv_exists": os.path.exists(human_description_csv()),
    }


def _inspect_animal():
    path = animal_csv()
    df = pd.read_csv(path)
    vc = df["Disease_Prediction"].value_counts()
    return {
        "name": "cleaned_animal_disease_prediction.csv",
        "path": path,
        "n_records": int(len(df)),
        "n_duplicate_rows": int(df.duplicated().sum()),
        "missing_cells": int(df.isna().sum().sum()),
        "animal_types": df["Animal_Type"].value_counts().to_dict(),
        "n_diseases": int(df["Disease_Prediction"].nunique()),
        "diseases_with_lt3_samples": int((vc < 3).sum()),
        "diseases_with_1_sample": int((vc == 1).sum()),
        "top_diseases": vc.head(20).to_dict(),
        "columns": list(df.columns),
        "suitable_for_fine_grained_disease_ml": False,
        "suitable_for_condition_family_screening": True,
        "notes": (
            "139 diseases on 431 rows is too sparse for reliable disease ID; "
            "collapse to condition families + severity."
        ),
    }


def _inspect_skin():
    root = Path(skin_archive1_dir())
    train_dir = root / "train"
    test_dir = root / "test"
    classes = sorted([p.name for p in train_dir.iterdir() if p.is_dir()]) if train_dir.exists() else []
    train_counts = {}
    test_counts = {}
    corrupt = 0
    sample_sizes = []
    for split, bucket in ((train_dir, train_counts), (test_dir, test_counts)):
        if not split.exists():
            continue
        for cls in classes:
            files = [
                p
                for p in (split / cls).iterdir()
                if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}
            ]
            bucket[cls] = len(files)
            for p in files[:3]:
                try:
                    from PIL import Image

                    with Image.open(p) as im:
                        sample_sizes.append({"path": str(p.name), "size": im.size, "mode": im.mode})
                except Exception:
                    corrupt += 1
    return {
        "name": "archive (1) SkinDisease 22-class clinical set",
        "path": str(root),
        "is_ham10000": False,
        "n_classes": len(classes),
        "classes": classes,
        "train_counts": train_counts,
        "test_counts": test_counts,
        "n_train": sum(train_counts.values()),
        "n_test": sum(test_counts.values()),
        "sample_image_sizes": sample_sizes[:10],
        "corrupt_samples_checked": corrupt,
        "suitable_for_image_screening": True,
    }


def main():
    report = {
        "title": "VitalReach Dataset Inspection",
        "human_symptoms": _inspect_human(),
        "livestock": _inspect_animal(),
        "skin": _inspect_skin(),
    }
    out_dir = reports_dir()
    os.makedirs(out_dir, exist_ok=True)
    json_path = os.path.join(out_dir, "dataset_inspection.json")
    with open(json_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    md_path = os.path.join(out_dir, "dataset_inspection.md")
    lines = ["# VitalReach Dataset Inspection", ""]
    for section in ("human_symptoms", "livestock", "skin"):
        block = report[section]
        lines.append(f"## {section}")
        lines.append(f"- name: {block.get('name')}")
        for k, v in block.items():
            if k in {"name", "class_counts", "top_diseases", "train_counts", "test_counts", "sample_image_sizes"}:
                continue
            lines.append(f"- {k}: {v}")
        lines.append("")
    with open(md_path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines))
    print(f"Wrote {json_path}")
    print(f"Wrote {md_path}")
    return report


if __name__ == "__main__":
    main()
