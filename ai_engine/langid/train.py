"""Train EN/HI/MR language ID from Kaggle Indian Language Identification.

Downloads processvenue/indian-language-identification when kagglehub is
available, otherwise uses a bundled bootstrap corpus so the app still ships
a detector. Exports TFLite + JSON weights for on-device Flutter inference.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import sys

import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import train_test_split

from ai_engine.common.paths import flutter_models_dir, models_dir, reports_dir
from ai_engine.common.metrics import write_report
from ai_engine.langid.features import (
    DIM,
    LABELS,
    NAME_TO_CODE,
    N_MAX,
    N_MIN,
    vectorize,
)


BOOTSTRAP = [
    ("en", "fever for three days headache and vomiting please help"),
    ("en", "the child has a cough and mild fever since yesterday"),
    ("en", "drinking water is good for health wash hands with soap"),
    ("en", "please consult a qualified healthcare professional"),
    ("en", "livestock not eating and has difficulty breathing"),
    ("en", "I have chest pain and shortness of breath"),
    ("en", "whatsapp says antibiotics cure dengue in two days"),
    ("en", "take the medicine after food twice daily"),
    ("en", "how are you feeling today check your symptoms"),
    ("en", "this is screening only not a medical diagnosis"),
    ("en", "the cow has swollen udder and drop in milk"),
    ("en", "book an appointment with the village doctor"),
    ("hi", "तीन दिन से तेज बुखार है सिरदर्द और उल्टी भी हो रही है"),
    ("hi", "मुझे खांसी और सांस फूलना है कृपया डॉक्टर से मिलें"),
    ("hi", "यह केवल स्क्रीनिंग है चिकित्सा निदान नहीं है"),
    ("hi", "बच्चे को बुखार है और भूख नहीं लग रही"),
    ("hi", "पानी पिएँ और आराम करें लक्षणों पर नज़र रखें"),
    ("hi", "आप कैसे महसूस कर रहे हैं आज"),
    ("hi", "मेरे सीने में दर्द है और मैं थका हुआ हूँ"),
    ("hi", "व्हाट्सएप कहता है कि एंटीबायोटिक डेंगू ठीक कर देते हैं"),
    ("hi", "दवा खाने के बाद दिन में दो बार लें"),
    ("hi", "गाँव के डॉक्टर से अपॉइंटमेंट बुक करें"),
    ("hi", "आशा कार्यकर्ता और डॉक्टर को सूचित किया गया है"),
    ("hi", "कृपया योग्य स्वास्थ्य पेशेवर से सलाह लें"),
    ("mr", "तीन दिवस पासून ताप आहे डोकेदुखी आणि उलटी होते"),
    ("mr", "मला खोकला आहे आणि श्वास घेण्यास त्रास होतो"),
    ("mr", "हे फक्त स्क्रीनिंग आहे वैद्यकीय निदान नाही"),
    ("mr", "मुलाला ताप आहे आणि भूक लागलेली नाही"),
    ("mr", "पाणी प्या आणि विश्रांती घ्या लक्षणांकडे लक्ष द्या"),
    ("mr", "तुम्हाला आज कसे वाटते"),
    ("mr", "माझ्या छातीत दुखते आणि मला थकवा आहे"),
    ("mr", "व्हॉट्सअॅप म्हणतो की अँटीबायोटिक डेंग्यू बरा करतात"),
    ("mr", "जेवल्यानंतर औषध दिवसातून दोनदा घ्या"),
    ("mr", "गावातील डॉक्टरांकडे अपॉइंटमेंट बुक करा"),
    ("mr", "आशा कार्यकर्ता आणि डॉक्टरांना कळवले आहे"),
    ("mr", "कृपया पात्र आरोग्य तज्ज्ञांचा सल्ला घ्या"),
]


def _load_kaggle_rows():
    try:
        import kagglehub
    except Exception:
        return []

    try:
        path = kagglehub.dataset_download("processvenue/indian-language-identification")
    except Exception as exc:
        print(f"kagglehub download skipped: {exc}")
        return []

    rows = []
    for root, _, files in os.walk(path):
        for name in files:
            if not name.lower().endswith((".csv", ".tsv")):
                continue
            full = os.path.join(root, name)
            delim = "\t" if name.lower().endswith(".tsv") else ","
            try:
                with open(full, encoding="utf-8", errors="ignore") as handle:
                    reader = csv.DictReader(handle, delimiter=delim)
                    for rec in reader:
                        text = (rec.get("Headline") or rec.get("text") or rec.get("Text") or "").strip()
                        lang = (rec.get("Language") or rec.get("language") or rec.get("label") or "").strip()
                        code = NAME_TO_CODE.get(lang.lower())
                        if text and code:
                            rows.append((code, text))
            except Exception:
                continue
    print(f"Loaded {len(rows)} EN/HI/MR rows from {path}")
    return rows


def _matrix(pairs):
    x = np.stack([vectorize(t) for _, t in pairs])
    y = np.array([LABELS.index(code) for code, _ in pairs], dtype=np.int32)
    return x, y


def _try_tflite(coef, intercept, out_path: str) -> bool:
    try:
        import tensorflow as tf
    except Exception as exc:
        print(f"tensorflow not available for TFLite export: {exc}")
        return False

    dim = coef.shape[1]
    n_class = coef.shape[0]
    inputs = tf.keras.Input(shape=(dim,), name="ngrams")
    dense = tf.keras.layers.Dense(n_class, activation="softmax", name="lang")
    model = tf.keras.Model(inputs, dense(inputs))
    dense.set_weights([coef.T.astype(np.float32), intercept.astype(np.float32)])

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = []
    blob = converter.convert()
    with open(out_path, "wb") as handle:
        handle.write(blob)
    return True


def train(seed: int = 42):
    pairs = list(BOOTSTRAP)
    kaggle_rows = _load_kaggle_rows()
    if kaggle_rows:
        pairs.extend(kaggle_rows)

    # Cap to keep training snappy on laptops
    rng = np.random.default_rng(seed)
    if len(pairs) > 40000:
        idx = rng.choice(len(pairs), size=40000, replace=False)
        pairs = [pairs[i] for i in idx]

    x, y = _matrix(pairs)
    x_train, x_test, y_train, y_test = train_test_split(
        x, y, test_size=0.2, random_state=seed, stratify=y
    )
    clf = LogisticRegression(
        max_iter=400,
        solver="lbfgs",
        C=2.0,
    )
    clf.fit(x_train, y_train)
    pred = clf.predict(x_test)
    acc = float(accuracy_score(y_test, pred))
    print(classification_report(y_test, pred, target_names=list(LABELS)))

    os.makedirs(models_dir(), exist_ok=True)
    os.makedirs(flutter_models_dir(), exist_ok=True)
    labels_payload = {
        "classes": list(LABELS),
        "dim": DIM,
        "n_min": N_MIN,
        "n_max": N_MAX,
        "coef": clf.coef_.astype(float).tolist(),
        "intercept": clf.intercept_.astype(float).tolist(),
        "accuracy": acc,
        "n_samples": int(len(pairs)),
        "source": "kaggle+bootstrap" if kaggle_rows else "bootstrap",
        "lexicon": {
            "hi": ["है", "हैं", "आप", "नहीं", "कैसे", "मुझे", "मैं", "कृपया", "लक्षण"],
            "mr": ["आहे", "आहेत", "तुम्ही", "नाही", "कसे", "मला", "तुम्हाला", "कृपया", "लक्षणे"],
        },
    }
    labels_path = os.path.join(models_dir(), "langid_labels.json")
    with open(labels_path, "w", encoding="utf-8") as handle:
        json.dump(labels_payload, handle, ensure_ascii=False, indent=2)

    tflite_path = os.path.join(models_dir(), "langid.tflite")
    tflite_ok = _try_tflite(clf.coef_, clf.intercept_, tflite_path)

    flutter_dir = flutter_models_dir()
    import shutil

    shutil.copy2(labels_path, os.path.join(flutter_dir, "langid_labels.json"))
    if tflite_ok:
        shutil.copy2(tflite_path, os.path.join(flutter_dir, "langid.tflite"))

    report = {
        "title": "Indian language identification (EN/HI/MR)",
        "dataset": "processvenue/indian-language-identification (filtered) + bootstrap",
        "n_samples": len(pairs),
        "n_kaggle": len(kaggle_rows),
        "accuracy": acc,
        "tflite": tflite_ok,
        "artifacts": {
            "labels": labels_path,
            "tflite": tflite_path if tflite_ok else None,
        },
    }
    write_report(os.path.join(reports_dir(), "langid_eval.json"), report)
    print(f"LID accuracy={acc:.3f} tflite={tflite_ok}")
    return report


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args(argv)
    train(seed=args.seed)


if __name__ == "__main__":
    main(sys.argv[1:])
