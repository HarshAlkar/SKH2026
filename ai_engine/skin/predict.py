"""Skin-lesion CNN inference (TFLite). Screening only — not a diagnosis."""

from __future__ import annotations

import io
import json
import os

import numpy as np
from PIL import Image

from ai_engine.skin.labels import (
    INPUT_SIZE,
    SKIN_DISEASE_CODES,
    display_name,
    labels_payload,
    severity_for,
)
from ai_engine.utils import skin_labels_path, skin_tflite_path

_INTERPRETER = None
_INPUT_DETAILS = None
_OUTPUT_DETAILS = None
_LABELS = None

MODEL_MISSING_MESSAGE = (
    "Skin CNN is not trained yet. Run: python -m ai_engine.skin.train "
    "--data-dir \"mobile_app/lib/dataset/archive (1)/SkinDisease/SkinDisease\""
)


class SkinModelNotTrained(RuntimeError):
    pass


def _load_labels():
    global _LABELS
    if _LABELS is not None:
        return _LABELS
    path = skin_labels_path()
    if os.path.exists(path):
        with open(path, encoding="utf-8") as handle:
            _LABELS = json.load(handle)
    else:
        _LABELS = labels_payload()
    return _LABELS


def _make_interpreter(model_path):
    try:
        from tflite_runtime.interpreter import Interpreter

        return Interpreter(model_path=model_path)
    except ImportError:
        pass
    try:
        import tensorflow as tf

        return tf.lite.Interpreter(model_path=model_path)
    except ImportError as exc:
        raise RuntimeError(
            "Install tflite-runtime or tensorflow to run the skin CNN."
        ) from exc


def _load_interpreter():
    global _INTERPRETER, _INPUT_DETAILS, _OUTPUT_DETAILS
    if _INTERPRETER is not None:
        return _INTERPRETER
    path = skin_tflite_path()
    if not os.path.exists(path):
        raise SkinModelNotTrained(MODEL_MISSING_MESSAGE)
    interpreter = _make_interpreter(path)
    interpreter.allocate_tensors()
    _INPUT_DETAILS = interpreter.get_input_details()
    _OUTPUT_DETAILS = interpreter.get_output_details()
    _INTERPRETER = interpreter
    return _INTERPRETER


def _open_image(image_input):
    if hasattr(image_input, "read"):
        data = image_input.read()
        image_input.seek(0)
        return Image.open(io.BytesIO(data)).convert("RGB")
    if isinstance(image_input, (bytes, bytearray)):
        return Image.open(io.BytesIO(image_input)).convert("RGB")
    return Image.open(image_input).convert("RGB")


def preprocess_image(image_input):
    """Match Keras MobileNetV2/V3 preprocess_input (mode=tf): x/127.5 - 1."""
    size = int(_load_labels().get("input_size") or INPUT_SIZE)
    image = _open_image(image_input).resize((size, size))
    array = np.asarray(image, dtype=np.float32)
    array = (array / 127.5) - 1.0
    return np.expand_dims(array, axis=0)


def predict_skin(image_input, top_k=3):
    labels = _load_labels()
    codes = labels.get("classes") or SKIN_DISEASE_CODES
    display_map = labels.get("display_names") or {}
    severity_map = labels.get("severity") or {}
    interpreter = _load_interpreter()
    tensor = preprocess_image(image_input)
    input_detail = _INPUT_DETAILS[0]
    if input_detail["dtype"] == np.uint8:
        tensor = np.clip((tensor + 1.0) * 127.5, 0, 255).astype(np.uint8)
    interpreter.set_tensor(input_detail["index"], tensor)
    interpreter.invoke()
    probs = interpreter.get_tensor(_OUTPUT_DETAILS[0]["index"])[0]
    probs = np.asarray(probs, dtype=np.float32).reshape(-1)
    ranked = sorted(enumerate(probs.tolist()), key=lambda item: item[1], reverse=True)
    top_predictions = []
    for index, score in ranked[:top_k]:
        if index >= len(codes):
            continue
        code = codes[index]
        name = display_map.get(code) or display_name(code)
        top_predictions.append(
            {
                "code": code,
                "disease": name,
                "confidence": round(float(score), 3),
                "severity": severity_map.get(code) or severity_for(code),
            }
        )
    if not top_predictions:
        raise RuntimeError("Skin CNN returned an empty prediction.")
    best = top_predictions[0]
    return {
        "disease": best["disease"],
        "code": best["code"],
        "severity": best["severity"],
        "confidence": best["confidence"],
        "top_predictions": top_predictions,
        "source": "skin_cnn",
        "disclaimer": labels.get("disclaimer") or labels_payload()["disclaimer"],
        "message": (
            f"AI-assisted skin screening suggests possible elevated risk for {best['disease']}. "
            "Screening confidence is not a confirmed diagnosis. Professional evaluation recommended."
        ),
    }
