"""Train and compare human symptom screening models; export pickle + TFLite."""

from __future__ import annotations

import argparse
import json
import os
import pickle
import shutil
import sys
import time

import numpy as np
from sklearn.ensemble import GradientBoostingClassifier, RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import StratifiedKFold, cross_val_score, train_test_split
from sklearn.preprocessing import LabelEncoder

from ai_engine.common.metrics import (
    classification_report_dict,
    recall_for_names,
    timed_predict,
    write_report,
)
from ai_engine.common.paths import flutter_models_dir, models_dir, reports_dir
from ai_engine.common.risk import (
    HUMAN_CRITICAL,
    HUMAN_DISCLAIMER,
    HUMAN_HIGH,
    severity_for_human_disease,
)
from ai_engine.symptoms.data import load_descriptions, load_precautions, load_symptom_matrix
from ai_engine.utils import model_path


HIGH_RISK_NAMES = list(dict.fromkeys(HUMAN_HIGH + HUMAN_CRITICAL))


def _try_import_boosters():
    models = {}
    try:
        from xgboost import XGBClassifier

        models["xgboost"] = XGBClassifier(
            n_estimators=120,
            max_depth=6,
            learning_rate=0.08,
            subsample=0.9,
            colsample_bytree=0.9,
            eval_metric="mlogloss",
            random_state=42,
            n_jobs=-1,
        )
    except Exception:
        pass
    try:
        from lightgbm import LGBMClassifier

        models["lightgbm"] = LGBMClassifier(
            n_estimators=120,
            max_depth=6,
            learning_rate=0.08,
            random_state=42,
            n_jobs=-1,
            verbose=-1,
        )
    except Exception:
        pass
    return models


def _candidate_models():
    models = {
        "logistic_regression": LogisticRegression(
            max_iter=2000,
            class_weight="balanced",
            multi_class="auto",
            random_state=42,
        ),
        "random_forest": RandomForestClassifier(
            n_estimators=200,
            max_depth=None,
            class_weight="balanced_subsample",
            random_state=42,
            n_jobs=-1,
        ),
        "gradient_boosting": GradientBoostingClassifier(
            n_estimators=100,
            max_depth=3,
            learning_rate=0.08,
            random_state=42,
        ),
    }
    models.update(_try_import_boosters())
    return models


def _score_model(name, model, X_train, y_train, X_val, y_val, encoder):
    model.fit(X_train, y_train)
    pred = model.predict(X_val)
    from sklearn.metrics import accuracy_score, f1_score

    f1 = float(f1_score(y_val, pred, average="macro", zero_division=0))
    acc = float(accuracy_score(y_val, pred))
    hr = recall_for_names(y_val, pred, encoder, HIGH_RISK_NAMES)
    # Selection score: macro-F1 + bonus for high-risk mean recall
    hr_mean = float(hr.get("_mean", 0.0))
    score = f1 + 0.35 * hr_mean
    return {
        "name": name,
        "f1_macro": f1,
        "accuracy": acc,
        "high_risk_recall": hr_mean,
        "high_risk_per_class": {k: v for k, v in hr.items() if k != "_mean"},
        "selection_score": score,
        "model": model,
    }


def _export_tflite(features, classes, X_train, y_train, X_val, y_val, out_tflite):
    try:
        import tensorflow as tf
    except ImportError:
        print("TensorFlow not available — skipping symptom TFLite export")
        return None, None, 1.0, {}

    n_features = len(features)
    n_classes = len(classes)
    model = tf.keras.Sequential(
        [
            tf.keras.layers.Input(shape=(n_features,)),
            tf.keras.layers.Dense(128, activation="relu"),
            tf.keras.layers.Dropout(0.3),
            tf.keras.layers.Dense(64, activation="relu"),
            tf.keras.layers.Dropout(0.2),
            tf.keras.layers.Dense(n_classes, activation="softmax"),
        ]
    )
    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    from sklearn.utils.class_weight import compute_class_weight

    cw = compute_class_weight("balanced", classes=np.unique(y_train), y=y_train)
    class_weight = {int(i): float(w) for i, w in zip(np.unique(y_train), cw)}
    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss", patience=6, restore_best_weights=True
        )
    ]
    model.fit(
        np.asarray(X_train, dtype=np.float32),
        np.asarray(y_train),
        validation_data=(np.asarray(X_val, dtype=np.float32), np.asarray(y_val)),
        epochs=60,
        batch_size=32,
        class_weight=class_weight,
        callbacks=callbacks,
        verbose=0,
    )

    # Temperature scaling on validation logits (approx via softening probs).
    val_probs = model.predict(np.asarray(X_val, dtype=np.float32), verbose=0)
    temperature = _fit_temperature(val_probs, y_val)
    # For screening UX, never sharpen below 1.0 (avoids peaky fake-certainty on device).
    temperature = max(float(temperature), 1.0)

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    os.makedirs(os.path.dirname(out_tflite), exist_ok=True)
    with open(out_tflite, "wb") as handle:
        handle.write(tflite_model)

    mlp_pred = np.argmax(model.predict(np.asarray(X_val, dtype=np.float32), verbose=0), axis=1)
    from sklearn.metrics import accuracy_score, f1_score

    mlp_metrics = {
        "val_accuracy": float(accuracy_score(y_val, mlp_pred)),
        "val_f1_macro": float(f1_score(y_val, mlp_pred, average="macro", zero_division=0)),
        "temperature": float(temperature),
    }
    return out_tflite, model, temperature, mlp_metrics


def _fit_temperature(probs, y_true, grid=None):
    """Pick T that minimizes NLL on validation softmax outputs."""
    grid = grid or [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0]
    y = np.asarray(y_true)
    best_t, best_nll = 1.0, float("inf")
    for t in grid:
        softened = np.power(np.clip(probs, 1e-12, 1.0), 1.0 / t)
        softened = softened / softened.sum(axis=1, keepdims=True)
        nll = -np.mean(np.log(softened[np.arange(len(y)), y] + 1e-12))
        if nll < best_nll:
            best_nll = nll
            best_t = t
    return best_t


def train(seed: int = 42):
    X, y, features, meta = load_symptom_matrix(dedupe=True)
    encoder = LabelEncoder()
    y_enc = encoder.fit_transform(y)
    X = np.asarray(X, dtype=np.float32)

    # 70 / 15 / 15 stratified
    X_temp, X_test, y_temp, y_test = train_test_split(
        X, y_enc, test_size=0.15, random_state=seed, stratify=y_enc
    )
    X_train, X_val, y_train, y_val = train_test_split(
        X_temp, y_temp, test_size=0.1765, random_state=seed, stratify=y_temp
    )  # ~15% of total

    comparisons = []
    best = None
    for name, model in _candidate_models().items():
        try:
            row = _score_model(name, model, X_train, y_train, X_val, y_val, encoder)
        except Exception as exc:
            comparisons.append({"name": name, "error": str(exc)})
            continue
        comparisons.append({k: v for k, v in row.items() if k != "model"})
        if best is None or row["selection_score"] > best["selection_score"]:
            best = row

    if best is None:
        raise RuntimeError("No symptom model trained successfully")

    # Refit best on train+val
    best_model = best["model"]
    X_tv = np.vstack([X_train, X_val])
    y_tv = np.concatenate([y_train, y_val])
    best_model.fit(X_tv, y_tv)

    y_pred = best_model.predict(X_test)
    labels = list(range(len(encoder.classes_)))
    test_metrics = classification_report_dict(
        y_test, y_pred, labels=labels, target_names=list(encoder.classes_)
    )
    test_metrics["high_risk_recall"] = recall_for_names(
        y_test, y_pred, encoder, HIGH_RISK_NAMES
    )
    try:
        if hasattr(best_model, "predict_proba"):
            from sklearn.metrics import roc_auc_score

            proba = best_model.predict_proba(X_test)
            test_metrics["roc_auc_ovr"] = float(
                roc_auc_score(y_test, proba, multi_class="ovr", average="macro")
            )
    except Exception:
        pass

    inf_ms = timed_predict(best_model.predict, X_test)

    # CV on train+val for honesty
    cv = StratifiedKFold(n_splits=min(5, max(2, int(np.min(np.bincount(y_tv))))), shuffle=True, random_state=seed)
    try:
        cv_scores = cross_val_score(best_model.__class__(**best_model.get_params()), X_tv, y_tv, cv=cv, scoring="f1_macro")
        cv_f1 = float(np.mean(cv_scores))
    except Exception:
        cv_f1 = None

    precautions = load_precautions()
    descriptions = load_descriptions()
    severity = {name: severity_for_human_disease(name) for name in encoder.classes_}

    bundle = {
        "model": best_model,
        "features": features,
        "encoder": encoder,
        "accuracy": test_metrics["accuracy"],
        "metrics": test_metrics,
        "best_model_name": best["name"],
        "disclaimer": HUMAN_DISCLAIMER,
    }
    pkl_path = model_path()
    os.makedirs(os.path.dirname(pkl_path), exist_ok=True)
    with open(pkl_path, "wb") as handle:
        pickle.dump(bundle, handle)

    tflite_path = os.path.join(models_dir(), "symptom_mlp.tflite")
    labels_path = os.path.join(models_dir(), "symptom_labels.json")
    _, mlp_keras, temperature, mlp_metrics = _export_tflite(
        features, list(encoder.classes_), X_train, y_train, X_val, y_val, tflite_path
    )

    # Evaluate MLP on held-out test for honest offline model metrics
    mlp_test_metrics = {}
    if mlp_keras is not None:
        test_probs = mlp_keras.predict(np.asarray(X_test, dtype=np.float32), verbose=0)
        # apply temperature
        softened = np.power(np.clip(test_probs, 1e-12, 1.0), 1.0 / max(temperature, 1e-6))
        softened = softened / softened.sum(axis=1, keepdims=True)
        mlp_pred = np.argmax(softened, axis=1)
        mlp_test_metrics = classification_report_dict(
            y_test, mlp_pred, labels=labels, target_names=list(encoder.classes_)
        )
        mlp_test_metrics["high_risk_recall"] = recall_for_names(
            y_test, mlp_pred, encoder, HIGH_RISK_NAMES
        )
        mlp_test_metrics["temperature"] = temperature

    labels_payload = {
        "classes": list(encoder.classes_),
        "features": features,
        "severity": severity,
        "precautions": {k: precautions.get(k, []) for k in encoder.classes_},
        "descriptions": {k: descriptions.get(k, "") for k in encoder.classes_},
        "disclaimer": HUMAN_DISCLAIMER,
        "input_type": "multi_hot_symptoms",
        "temperature": temperature,
        "screening_wording": (
            "Screening result indicates elevated risk for {condition}. "
            "This is not a diagnosis. Please consult a qualified healthcare professional."
        ),
    }
    with open(labels_path, "w", encoding="utf-8") as handle:
        json.dump(labels_payload, handle, indent=2)

    flutter_dir = flutter_models_dir()
    os.makedirs(flutter_dir, exist_ok=True)
    if os.path.exists(tflite_path):
        shutil.copy2(tflite_path, os.path.join(flutter_dir, "symptom_mlp.tflite"))
    shutil.copy2(labels_path, os.path.join(flutter_dir, "symptom_labels.json"))

    report = {
        "title": "Human Symptom Screening Evaluation",
        "dataset": "disease/dataset.csv (deduplicated)",
        "n_samples": meta["n_after_dedupe"],
        "n_raw_samples": meta["n_raw"],
        "n_classes": meta["n_classes"],
        "n_features": meta["n_features"],
        "split": "70/15/15 stratified on deduped rows",
        "best_sklearn_model": best["name"],
        "offline_model": "keras_mlp_tflite",
        "model_comparison": comparisons,
        "test_metrics_sklearn": test_metrics,
        "test_metrics_mlp_tflite": mlp_test_metrics,
        "mlp_val_metrics": mlp_metrics,
        "cv_f1_macro_trainval": cv_f1,
        "model_size_bytes": os.path.getsize(pkl_path) if os.path.exists(pkl_path) else None,
        "tflite_size_bytes": os.path.getsize(tflite_path) if os.path.exists(tflite_path) else None,
        "inference_ms_approx": inf_ms,
        "offline_compatible": True,
        "artifacts": {
            "pickle": pkl_path,
            "tflite": tflite_path if os.path.exists(tflite_path) else None,
            "labels": labels_path,
        },
        "limitations": (
            "Source CSV is highly duplicated/synthetic; near-perfect sklearn scores on "
            "held-out unique rows do NOT prove clinical accuracy. Offline Flutter uses "
            "the MLP TFLite model (see test_metrics_mlp_tflite). Never present as diagnosis."
        ),
        # keep legacy key for older readers
        "best_model": best["name"],
        "test_metrics": mlp_test_metrics or test_metrics,
    }
    write_report(os.path.join(reports_dir(), "human_symptoms_eval.json"), report)
    print(f"Best sklearn: {best['name']} test F1={test_metrics['f1_macro']:.3f}")
    if mlp_test_metrics:
        print(
            f"MLP TFLite test F1={mlp_test_metrics['f1_macro']:.3f} "
            f"acc={mlp_test_metrics['accuracy']:.3f} T={temperature}"
        )
    print(f"Saved {pkl_path}")
    return report


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args(argv)
    train(seed=args.seed)


if __name__ == "__main__":
    main(sys.argv[1:])
