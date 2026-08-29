"""Shared evaluation helpers and report writers."""

from __future__ import annotations

import json
import os
import time
from typing import Any

import numpy as np


def classification_report_dict(y_true, y_pred, labels, target_names):
    from sklearn.metrics import (
        accuracy_score,
        classification_report,
        confusion_matrix,
        f1_score,
        precision_score,
        recall_score,
    )

    return {
        "accuracy": float(accuracy_score(y_true, y_pred)),
        "precision_macro": float(
            precision_score(y_true, y_pred, average="macro", zero_division=0)
        ),
        "recall_macro": float(
            recall_score(y_true, y_pred, average="macro", zero_division=0)
        ),
        "f1_macro": float(f1_score(y_true, y_pred, average="macro", zero_division=0)),
        "precision_weighted": float(
            precision_score(y_true, y_pred, average="weighted", zero_division=0)
        ),
        "recall_weighted": float(
            recall_score(y_true, y_pred, average="weighted", zero_division=0)
        ),
        "f1_weighted": float(
            f1_score(y_true, y_pred, average="weighted", zero_division=0)
        ),
        "per_class": classification_report(
            y_true,
            y_pred,
            labels=labels,
            target_names=target_names,
            output_dict=True,
            zero_division=0,
        ),
        "confusion_matrix": confusion_matrix(
            y_true, y_pred, labels=labels
        ).tolist(),
    }


def recall_for_names(y_true, y_pred, encoder, names: list[str]) -> dict[str, float]:
    from sklearn.metrics import recall_score

    out = {}
    classes = list(encoder.classes_)
    for name in names:
        if name not in classes:
            continue
        idx = classes.index(name)
        mask = np.array(y_true) == idx
        if not mask.any():
            continue
        out[name] = float(
            recall_score(
                np.array(y_true) == idx,
                np.array(y_pred) == idx,
                zero_division=0,
            )
        )
    if out:
        out["_mean"] = float(np.mean(list(out.values())))
    return out


def timed_predict(predict_fn, X, repeats: int = 20) -> float:
    if len(X) == 0:
        return 0.0
    sample = X[: min(32, len(X))]
    predict_fn(sample)
    t0 = time.perf_counter()
    for _ in range(repeats):
        predict_fn(sample)
    return (time.perf_counter() - t0) / repeats / max(len(sample), 1) * 1000.0


def write_report(path: str, payload: dict[str, Any]) -> str:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, default=str)
    md_path = os.path.splitext(path)[0] + ".md"
    lines = [f"# {payload.get('title', 'ML Evaluation Report')}", ""]
    for key in (
        "dataset",
        "n_samples",
        "n_classes",
        "split",
        "best_model",
        "model_size_bytes",
        "inference_ms_approx",
        "offline_compatible",
        "limitations",
    ):
        if key in payload:
            lines.append(f"- **{key}**: {payload[key]}")
    metrics = payload.get("test_metrics") or payload.get("metrics") or {}
    if metrics:
        lines.append("")
        lines.append("## Test metrics")
        for k in (
            "accuracy",
            "precision_macro",
            "recall_macro",
            "f1_macro",
            "roc_auc_ovr",
        ):
            if k in metrics:
                lines.append(f"- **{k}**: {metrics[k]}")
    if payload.get("model_comparison"):
        lines.append("")
        lines.append("## Model comparison (validation)")
        for row in payload["model_comparison"]:
            lines.append(
                f"- {row.get('name')}: f1_macro={row.get('f1_macro')}, "
                f"high_risk_recall={row.get('high_risk_recall')}, "
                f"accuracy={row.get('accuracy')}"
            )
    lines.append("")
    with open(md_path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines))
    return path
