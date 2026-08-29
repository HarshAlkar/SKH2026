"""Train MobileNetV3-Small on archive(1) SkinDisease 22-class set; export TFLite."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys

import numpy as np

from ai_engine.common.metrics import classification_report_dict, write_report
from ai_engine.common.paths import flutter_models_dir, reports_dir, skin_archive1_dir
from ai_engine.skin.labels import INPUT_SIZE, SKIN_DISEASE_CODES, labels_payload
from ai_engine.utils import engine_dir, skin_keras_path, skin_labels_path, skin_tflite_path


def _require_tensorflow():
    try:
        import tensorflow as tf  # noqa: F401
    except ImportError as exc:
        raise SystemExit(
            "TensorFlow is required. Install with: pip install -r requirements-ai.txt"
        ) from exc
    return __import__("tensorflow")


def _class_counts(split_dir):
    counts = {}
    for code in SKIN_DISEASE_CODES:
        folder = os.path.join(split_dir, code)
        if not os.path.isdir(folder):
            raise FileNotFoundError(f"Missing class folder: {folder}")
        n = sum(
            1
            for name in os.listdir(folder)
            if name.lower().endswith((".jpg", ".jpeg", ".png", ".webp"))
        )
        counts[code] = n
    return counts


def _make_datasets(tf, data_dir, batch_size):
    train_dir = os.path.join(data_dir, "train")
    test_dir = os.path.join(data_dir, "test")
    _class_counts(train_dir)
    _class_counts(test_dir)

    train_ds = tf.keras.utils.image_dataset_from_directory(
        train_dir,
        labels="inferred",
        class_names=list(SKIN_DISEASE_CODES),
        image_size=(INPUT_SIZE, INPUT_SIZE),
        batch_size=batch_size,
        shuffle=True,
        seed=42,
    )
    # Carve a validation split from training via take/skip after cache
    # Use official test folder as held-out test; val = 10% of train via subset
    val_ds = tf.keras.utils.image_dataset_from_directory(
        train_dir,
        labels="inferred",
        class_names=list(SKIN_DISEASE_CODES),
        image_size=(INPUT_SIZE, INPUT_SIZE),
        batch_size=batch_size,
        shuffle=True,
        seed=42,
        validation_split=0.1,
        subset="validation",
    )
    train_ds = tf.keras.utils.image_dataset_from_directory(
        train_dir,
        labels="inferred",
        class_names=list(SKIN_DISEASE_CODES),
        image_size=(INPUT_SIZE, INPUT_SIZE),
        batch_size=batch_size,
        shuffle=True,
        seed=42,
        validation_split=0.1,
        subset="training",
    )
    test_ds = tf.keras.utils.image_dataset_from_directory(
        test_dir,
        labels="inferred",
        class_names=list(SKIN_DISEASE_CODES),
        image_size=(INPUT_SIZE, INPUT_SIZE),
        batch_size=batch_size,
        shuffle=False,
    )

    aug = tf.keras.Sequential(
        [
            tf.keras.layers.RandomFlip("horizontal"),
            tf.keras.layers.RandomRotation(0.08),
            tf.keras.layers.RandomZoom(0.1),
            tf.keras.layers.RandomContrast(0.1),
        ]
    )

    def preprocess(image, label, training=False):
        image = tf.cast(image, tf.float32)
        if training:
            image = aug(image)
        image = tf.keras.applications.mobilenet_v3.preprocess_input(image)
        return image, label

    autotune = tf.data.AUTOTUNE
    train_ds = (
        train_ds.map(lambda x, y: preprocess(x, y, True), num_parallel_calls=autotune)
        .prefetch(autotune)
    )
    val_ds = (
        val_ds.map(lambda x, y: preprocess(x, y, False), num_parallel_calls=autotune)
        .prefetch(autotune)
    )
    test_ds = (
        test_ds.map(lambda x, y: preprocess(x, y, False), num_parallel_calls=autotune)
        .prefetch(autotune)
    )
    return train_ds, val_ds, test_ds


def build_model(tf, n_classes):
    try:
        base = tf.keras.applications.MobileNetV3Small(
            input_shape=(INPUT_SIZE, INPUT_SIZE, 3),
            include_top=False,
            weights="imagenet",
        )
        arch = "MobileNetV3Small"
    except Exception:
        base = tf.keras.applications.MobileNetV2(
            input_shape=(INPUT_SIZE, INPUT_SIZE, 3),
            include_top=False,
            weights="imagenet",
        )
        arch = "MobileNetV2"
    base.trainable = False
    inputs = tf.keras.Input(shape=(INPUT_SIZE, INPUT_SIZE, 3))
    x = base(inputs, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.3)(x)
    outputs = tf.keras.layers.Dense(n_classes, activation="softmax")(x)
    model = tf.keras.Model(inputs, outputs)
    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    return model, base, arch


def _class_weights_from_counts(counts):
    total = sum(counts.values())
    n = len(counts)
    return {
        i: (total / (n * max(counts[code], 1)))
        for i, code in enumerate(SKIN_DISEASE_CODES)
    }


def export_tflite(tf, model, tflite_path):
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    os.makedirs(os.path.dirname(tflite_path), exist_ok=True)
    with open(tflite_path, "wb") as handle:
        handle.write(tflite_model)


def copy_to_flutter(tflite_path, labels_path):
    dest_dir = flutter_models_dir()
    os.makedirs(dest_dir, exist_ok=True)
    shutil.copy2(tflite_path, os.path.join(dest_dir, "skin_cnn.tflite"))
    shutil.copy2(labels_path, os.path.join(dest_dir, "skin_labels.json"))
    return dest_dir


def _evaluate(model, test_ds):
    ys, preds = [], []
    for batch_x, batch_y in test_ds:
        proba = model.predict(batch_x, verbose=0)
        preds.extend(np.argmax(proba, axis=1).tolist())
        ys.extend(batch_y.numpy().tolist())
    labels = list(range(len(SKIN_DISEASE_CODES)))
    metrics = classification_report_dict(
        ys, preds, labels=labels, target_names=SKIN_DISEASE_CODES
    )
    # High-risk recall
    high = ["SkinCancer", "Actinic_Keratosis", "Lupus", "Vasculitis", "Bullous"]
    from sklearn.metrics import recall_score

    hr = {}
    for name in high:
        idx = SKIN_DISEASE_CODES.index(name)
        mask = np.array(ys) == idx
        if mask.any():
            hr[name] = float(
                recall_score(np.array(ys) == idx, np.array(preds) == idx, zero_division=0)
            )
    metrics["high_risk_recall"] = hr
    return metrics


def train(data_dir, epochs=6, batch_size=32, fine_tune_epochs=3):
    tf = _require_tensorflow()
    train_ds, val_ds, test_ds = _make_datasets(tf, data_dir, batch_size)
    counts = _class_counts(os.path.join(data_dir, "train"))
    class_weight = _class_weights_from_counts(counts)
    model, base, arch = build_model(tf, len(SKIN_DISEASE_CODES))

    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_accuracy", patience=2, restore_best_weights=True
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss", factor=0.5, patience=1, min_lr=1e-6
        ),
    ]
    model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=epochs,
        class_weight=class_weight,
        callbacks=callbacks,
    )

    if fine_tune_epochs > 0:
        base.trainable = True
        # Freeze early layers
        for layer in base.layers[:-40]:
            layer.trainable = False
        model.compile(
            optimizer=tf.keras.optimizers.Adam(1e-5),
            loss="sparse_categorical_crossentropy",
            metrics=["accuracy"],
        )
        model.fit(
            train_ds,
            validation_data=val_ds,
            epochs=fine_tune_epochs,
            class_weight=class_weight,
            callbacks=callbacks,
        )

    test_metrics = _evaluate(model, test_ds)

    keras_path = skin_keras_path()
    tflite_path = skin_tflite_path()
    labels_path = skin_labels_path()
    os.makedirs(os.path.dirname(keras_path), exist_ok=True)
    model.save(keras_path)
    export_tflite(tf, model, tflite_path)
    payload = labels_payload()
    payload["architecture"] = arch
    with open(labels_path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)
    flutter_dir = copy_to_flutter(tflite_path, labels_path)

    report = {
        "title": "Skin Screening CNN Evaluation",
        "dataset": "archive (1) SkinDisease 22-class (NOT HAM10000)",
        "n_samples": sum(counts.values()) + sum(
            _class_counts(os.path.join(data_dir, "test")).values()
        ),
        "n_classes": len(SKIN_DISEASE_CODES),
        "classes": SKIN_DISEASE_CODES,
        "split": "train 90% + val 10% from train/; held-out test/ folder",
        "best_model": arch,
        "test_metrics": test_metrics,
        "model_size_bytes": os.path.getsize(tflite_path),
        "offline_compatible": True,
        "artifacts": {
            "tflite": tflite_path,
            "keras": keras_path,
            "labels": labels_path,
            "flutter_dir": flutter_dir,
        },
        "limitations": (
            "Clinical photo dataset may not match field lighting/skin tones. "
            "Not a diagnosis. High-risk classes (SkinCancer etc.) require clinician review."
        ),
    }
    write_report(os.path.join(reports_dir(), "skin_eval.json"), report)
    print(f"Test accuracy={test_metrics['accuracy']:.3f} F1={test_metrics['f1_macro']:.3f}")
    print(f"Saved TFLite: {tflite_path} -> {flutter_dir}")
    return tflite_path


def main(argv=None):
    parser = argparse.ArgumentParser(description="Train SkinDisease 22-class CNN")
    parser.add_argument("--data-dir", default=skin_archive1_dir())
    parser.add_argument("--epochs", type=int, default=6)
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--fine-tune-epochs", type=int, default=3)
    args = parser.parse_args(argv)
    if not os.path.isdir(args.data_dir):
        raise SystemExit(f"Data directory not found: {args.data_dir}")
    train(
        args.data_dir,
        epochs=args.epochs,
        batch_size=args.batch_size,
        fine_tune_epochs=args.fine_tune_epochs,
    )


if __name__ == "__main__":
    main(sys.argv[1:])
