"""Train livestock condition-family screening models; export pickle + TFLite."""

from __future__ import annotations

import argparse
import json
import os
import pickle
import shutil
import sys

import numpy as np
from sklearn.ensemble import GradientBoostingClassifier, RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

from ai_engine.common.metrics import classification_report_dict, timed_predict, write_report
from ai_engine.common.paths import flutter_models_dir, models_dir, reports_dir
from ai_engine.common.risk import ANIMAL_DISCLAIMER
from ai_engine.livestock.data import (
    BINARY_COLS,
    FAMILY_SEVERITY,
    load_animal_matrix,
    severity_for_family,
)


def _try_boosters():
    models = {}
    try:
        from xgboost import XGBClassifier

        models["xgboost"] = XGBClassifier(
            n_estimators=100,
            max_depth=4,
            learning_rate=0.1,
            eval_metric="mlogloss",
            random_state=42,
            n_jobs=-1,
        )
    except Exception:
        pass
    try:
        from lightgbm import LGBMClassifier

        models["lightgbm"] = LGBMClassifier(
            n_estimators=100,
            max_depth=4,
            learning_rate=0.1,
            random_state=42,
            verbose=-1,
        )
    except Exception:
        pass
    return models


def _candidates():
    models = {
        "logistic_regression": LogisticRegression(
            max_iter=2000, class_weight="balanced", random_state=42
        ),
        "random_forest": RandomForestClassifier(
            n_estimators=200,
            class_weight="balanced_subsample",
            random_state=42,
            n_jobs=-1,
        ),
        "gradient_boosting": GradientBoostingClassifier(
            n_estimators=80, max_depth=3, random_state=42
        ),
    }
    models.update(_try_boosters())
    return models


def _high_risk_indices(encoder):
    names = ["Zoonotic_HighRisk", "Neurological", "Respiratory", "Mastitis_Udder"]
    return [i for i, n in enumerate(encoder.classes_) if n in names]


def _export_tflite(n_features, n_classes, X_train, y_train, path):
    try:
        import tensorflow as tf
    except ImportError:
        return None
    from sklearn.utils.class_weight import compute_class_weight

    model = tf.keras.Sequential(
        [
            tf.keras.layers.Input(shape=(n_features,)),
            tf.keras.layers.Dense(64, activation="relu"),
            tf.keras.layers.Dropout(0.2),
            tf.keras.layers.Dense(32, activation="relu"),
            tf.keras.layers.Dense(n_classes, activation="softmax"),
        ]
    )
    model.compile(
        optimizer="adam",
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    cw = compute_class_weight("balanced", classes=np.unique(y_train), y=y_train)
    class_weight = {int(i): float(w) for i, w in zip(np.unique(y_train), cw)}
    model.fit(
        np.asarray(X_train, dtype=np.float32),
        np.asarray(y_train),
        epochs=50,
        batch_size=16,
        class_weight=class_weight,
        verbose=0,
    )
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    blob = converter.convert()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as handle:
        handle.write(blob)
    return path


def train(seed: int = 42):
    X, y, features, species, meta, _ = load_animal_matrix(dedupe=True)
    encoder = LabelEncoder()
    y_enc = encoder.fit_transform(y)

    # Some families may be rare — stratify if possible
    counts = np.bincount(y_enc)
    stratify = y_enc if counts.min() >= 2 else None
    X_temp, X_test, y_temp, y_test = train_test_split(
        X, y_enc, test_size=0.2, random_state=seed, stratify=stratify
    )
    stratify2 = y_temp if np.bincount(y_temp).min() >= 2 else None
    X_train, X_val, y_train, y_val = train_test_split(
        X_temp, y_temp, test_size=0.25, random_state=seed, stratify=stratify2
    )

    from sklearn.metrics import accuracy_score, f1_score, recall_score

    comparisons = []
    best = None
    hr_idx = _high_risk_indices(encoder)
    for name, model in _candidates().items():
        try:
            model.fit(X_train, y_train)
            pred = model.predict(X_val)
            f1 = float(f1_score(y_val, pred, average="macro", zero_division=0))
            acc = float(accuracy_score(y_val, pred))
            # High-risk recall: mean recall over high-risk family indices present in val
            hr_recalls = []
            for idx in hr_idx:
                mask = y_val == idx
                if mask.any():
                    hr_recalls.append(
                        float(recall_score(y_val == idx, pred == idx, zero_division=0))
                    )
            hr_mean = float(np.mean(hr_recalls)) if hr_recalls else 0.0
            score = f1 + 0.4 * hr_mean
            row = {
                "name": name,
                "f1_macro": f1,
                "accuracy": acc,
                "high_risk_recall": hr_mean,
                "selection_score": score,
                "model": model,
            }
            comparisons.append({k: v for k, v in row.items() if k != "model"})
            if best is None or score > best["selection_score"]:
                best = row
        except Exception as exc:
            comparisons.append({"name": name, "error": str(exc)})

    if best is None:
        raise RuntimeError("No livestock model trained")

    model = best["model"]
    X_tv = np.vstack([X_train, X_val])
    y_tv = np.concatenate([y_train, y_val])
    model.fit(X_tv, y_tv)
    y_pred = model.predict(X_test)
    labels = list(range(len(encoder.classes_)))
    test_metrics = classification_report_dict(
        y_test, y_pred, labels=labels, target_names=list(encoder.classes_)
    )
    hr_recalls = []
    for idx in hr_idx:
        mask = y_test == idx
        if mask.any():
            hr_recalls.append(
                float(recall_score(y_test == idx, y_pred == idx, zero_division=0))
            )
    test_metrics["high_risk_recall_mean"] = float(np.mean(hr_recalls)) if hr_recalls else None
    inf_ms = timed_predict(model.predict, X_test)

    pkl_path = os.path.join(models_dir(), "livestock_model.pkl")
    os.makedirs(models_dir(), exist_ok=True)
    bundle = {
        "model": model,
        "features": features,
        "encoder": encoder,
        "species": species,
        "binary_cols": BINARY_COLS,
        "severity_by_family": FAMILY_SEVERITY,
        "metrics": test_metrics,
        "best_model_name": best["name"],
        "disclaimer": ANIMAL_DISCLAIMER,
    }
    with open(pkl_path, "wb") as handle:
        pickle.dump(bundle, handle)

    tflite_path = os.path.join(models_dir(), "livestock_mlp.tflite")
    _export_tflite(len(features), len(encoder.classes_), X_tv, y_tv, tflite_path)

    labels_payload = {
        "classes": list(encoder.classes_),
        "features": features,
        "species": species,
        "binary_cols": BINARY_COLS,
        "severity": {c: severity_for_family(c) for c in encoder.classes_},
        "disclaimer": ANIMAL_DISCLAIMER,
        "screening_wording": (
            "Livestock screening indicates elevated risk for {condition}. "
            "This result is decision support and not a veterinary diagnosis. "
            "Consult a qualified veterinarian."
        ),
        "display_names": {
            "Zoonotic_HighRisk": "Possible zoonotic / high-risk infectious signs",
            "Respiratory": "Respiratory illness signs",
            "Gastrointestinal": "Digestive / GI illness signs",
            "Skin_Parasite": "Skin / parasite concern",
            "Neurological": "Neurological concern",
            "Mastitis_Udder": "Udder / mastitis concern",
            "Systemic_Infectious": "Systemic infectious signs",
            "Other": "Non-specific illness signs",
        },
    }
    labels_path = os.path.join(models_dir(), "livestock_labels.json")
    with open(labels_path, "w", encoding="utf-8") as handle:
        json.dump(labels_payload, handle, indent=2)

    flutter = flutter_models_dir()
    os.makedirs(flutter, exist_ok=True)
    if os.path.exists(tflite_path):
        shutil.copy2(tflite_path, os.path.join(flutter, "livestock_mlp.tflite"))
    shutil.copy2(labels_path, os.path.join(flutter, "livestock_labels.json"))

    report = {
        "title": "Livestock Condition-Family Screening Evaluation",
        "dataset": "cleaned_animal_disease_prediction.csv (deduped, collapsed families)",
        "n_samples": meta["n_samples"],
        "n_classes": meta["n_families"],
        "family_counts": meta["family_counts"],
        "n_raw_diseases": meta["n_raw_diseases"],
        "split": "60/20/20 approx stratified where possible",
        "best_model": best["name"],
        "model_comparison": comparisons,
        "test_metrics": test_metrics,
        "model_size_bytes": os.path.getsize(pkl_path),
        "tflite_size_bytes": os.path.getsize(tflite_path) if os.path.exists(tflite_path) else None,
        "inference_ms_approx": inf_ms,
        "offline_compatible": True,
        "limitations": (
            "Original 139 disease labels are too sparse; predictions are condition-family "
            "screening only. Critical keyword rules remain as safety override. "
            "Not a veterinary diagnosis."
        ),
    }
    write_report(os.path.join(reports_dir(), "livestock_eval.json"), report)
    print(f"Best: {best['name']} F1={test_metrics['f1_macro']:.3f}")
    return report


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args(argv)
    train(seed=args.seed)


if __name__ == "__main__":
    main(sys.argv[1:])
