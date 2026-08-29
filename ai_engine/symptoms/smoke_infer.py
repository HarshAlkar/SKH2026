"""10+ smoke inference cases for human symptom TFLite + sklearn bundles."""

from __future__ import annotations

import json
import os
import sys

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if ROOT not in sys.path:
    sys.path.insert(0, ROOT)

from ai_engine.common.paths import flutter_models_dir, models_dir
from ai_engine.predict import predict_symptoms


CASES = [
    ["fatigue", "vomiting", "high_fever", "loss_of_appetite", "nausea", "headache", "abdominal_pain", "yellowish_skin", "yellowing_of_eyes", "chills"],
    ["itching", "skin_rash", "nodal_skin_eruptions"],
    ["continuous_sneezing", "cough", "high_fever"],
    ["chest_pain", "breathlessness", "sweating"],
    ["headache", "nausea", "vomiting"],
    ["fever", "cough", "fatigue"],
    ["joint_pain", "muscle_pain", "fatigue"],
    ["diarrhoea", "vomiting", "abdominal_pain", "dehydration"],
    ["burning_micturition", "bladder_discomfort"],
    ["weight_loss", "fatigue", "high_fever", "night_sweats"],
    ["high_fever", "headache", "vomiting"],
    ["stomach_pain", "acidity", "vomiting"],
]


def _tflite_predict(tokens, features, classes, tflite_path, temperature=1.0):
    import tensorflow as tf

    vec = np.zeros((1, len(features)), dtype=np.float32)
    present = {t.replace(" ", "_") for t in tokens}
    for i, f in enumerate(features):
        if f in present:
            vec[0, i] = 1.0
    interp = tf.lite.Interpreter(model_path=tflite_path)
    interp.allocate_tensors()
    inp = interp.get_input_details()[0]
    out = interp.get_output_details()[0]
    interp.set_tensor(inp["index"], vec)
    interp.invoke()
    probs = interp.get_tensor(out["index"])[0].astype(np.float64)
    if temperature and abs(temperature - 1.0) > 1e-6:
        probs = np.power(np.clip(probs, 1e-12, 1.0), 1.0 / temperature)
        probs = probs / probs.sum()
    ranked = np.argsort(probs)[::-1][:3]
    return [
        {"disease": classes[i], "probability": float(probs[i])}
        for i in ranked
    ]


def main():
    labels_path = os.path.join(flutter_models_dir(), "symptom_labels.json")
    tflite_path = os.path.join(flutter_models_dir(), "symptom_mlp.tflite")
    if not os.path.exists(labels_path):
        labels_path = os.path.join(models_dir(), "symptom_labels.json")
        tflite_path = os.path.join(models_dir(), "symptom_mlp.tflite")
    labels = json.loads(open(labels_path, encoding="utf-8").read())
    features = labels["features"]
    classes = labels["classes"]
    temperature = float(labels.get("temperature") or 1.0)

    print(f"TFLite: {tflite_path}")
    print(f"temperature={temperature} features={len(features)} classes={len(classes)}")
    print("=" * 72)
    for idx, tokens in enumerate(CASES, 1):
        top = _tflite_predict(tokens, features, classes, tflite_path, temperature)
        server = predict_symptoms(tokens)
        print(f"\nCASE {idx}: {tokens}")
        print("  TFLite top3:")
        for row in top:
            print(f"    {row['disease']}: {row['probability']:.4f} ({row['probability']*100:.1f}%)")
        print(
            f"  server_ml: {server.get('disease')} "
            f"conf={server.get('confidence')} src={server.get('source')}"
        )
        sev = labels.get("severity", {}).get(top[0]["disease"], "?")
        print(f"  risk(top1): {sev}  source: symptom_mlp_tflite")


if __name__ == "__main__":
    main()
