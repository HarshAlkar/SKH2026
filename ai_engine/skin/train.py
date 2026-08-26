"""Train MobileNetV2 on HAM10000-style folders and export Keras + TFLite.

Expected layout:
  <data-dir>/train/<class>/*.jpg
  <data-dir>/val/<class>/*.jpg

Classes (all required): akiec bcc bkl df nv mel vasc

Example:
  python -m ai_engine.skin.train --data-dir ai_engine/data/ham10000
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys

from ai_engine.skin.labels import HAM10000_CODES, INPUT_SIZE, labels_payload
from ai_engine.utils import engine_dir, skin_keras_path, skin_labels_path, skin_tflite_path


def _require_tensorflow():
    try:
        import tensorflow as tf  # noqa: F401
    except ImportError as exc:
        raise SystemExit(
            "TensorFlow is required to train. Install with:\n"
            "  pip install -r requirements-ai.txt"
        ) from exc
    return __import__("tensorflow")


def _validate_split(split_dir):
    missing = [
        code
        for code in HAM10000_CODES
        if not os.path.isdir(os.path.join(split_dir, code))
    ]
    if missing:
        raise FileNotFoundError(
            f"{split_dir} is missing class folders: {', '.join(missing)}. "
            "Download HAM10000 and arrange train/val folders per class."
        )


def _make_datasets(tf, data_dir, batch_size):
    train_dir = os.path.join(data_dir, "train")
    val_dir = os.path.join(data_dir, "val")
    _validate_split(train_dir)
    _validate_split(val_dir)

    train_ds = tf.keras.utils.image_dataset_from_directory(
        train_dir,
        labels="inferred",
        class_names=list(HAM10000_CODES),
        image_size=(INPUT_SIZE, INPUT_SIZE),
        batch_size=batch_size,
        shuffle=True,
    )
    val_ds = tf.keras.utils.image_dataset_from_directory(
        val_dir,
        labels="inferred",
        class_names=list(HAM10000_CODES),
        image_size=(INPUT_SIZE, INPUT_SIZE),
        batch_size=batch_size,
        shuffle=False,
    )

    def preprocess(image, label):
        image = tf.cast(image, tf.float32)
        image = tf.keras.applications.mobilenet_v2.preprocess_input(image)
        return image, label

    autotune = tf.data.AUTOTUNE
    return (
        train_ds.map(preprocess, num_parallel_calls=autotune).prefetch(autotune),
        val_ds.map(preprocess, num_parallel_calls=autotune).prefetch(autotune),
    )


def build_model(tf):
    base = tf.keras.applications.MobileNetV2(
        input_shape=(INPUT_SIZE, INPUT_SIZE, 3),
        include_top=False,
        weights="imagenet",
    )
    base.trainable = False
    inputs = tf.keras.Input(shape=(INPUT_SIZE, INPUT_SIZE, 3))
    x = base(inputs, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.2)(x)
    outputs = tf.keras.layers.Dense(len(HAM10000_CODES), activation="softmax")(x)
    model = tf.keras.Model(inputs, outputs)
    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    return model, base


def export_tflite(tf, model, tflite_path):
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    os.makedirs(os.path.dirname(tflite_path), exist_ok=True)
    with open(tflite_path, "wb") as handle:
        handle.write(tflite_model)


def copy_to_flutter(tflite_path, labels_path):
    dest_dir = os.path.abspath(
        os.path.join(engine_dir(), "..", "mobile_app", "assets", "models")
    )
    os.makedirs(dest_dir, exist_ok=True)
    shutil.copy2(tflite_path, os.path.join(dest_dir, "skin_cnn.tflite"))
    shutil.copy2(labels_path, os.path.join(dest_dir, "skin_labels.json"))
    return dest_dir


def train(data_dir, epochs=8, batch_size=32, fine_tune_epochs=2):
    tf = _require_tensorflow()
    train_ds, val_ds = _make_datasets(tf, data_dir, batch_size)
    model, base = build_model(tf)

    model.fit(train_ds, validation_data=val_ds, epochs=epochs)

    if fine_tune_epochs > 0:
        base.trainable = True
        model.compile(
            optimizer=tf.keras.optimizers.Adam(1e-5),
            loss="sparse_categorical_crossentropy",
            metrics=["accuracy"],
        )
        model.fit(train_ds, validation_data=val_ds, epochs=fine_tune_epochs)

    keras_path = skin_keras_path()
    tflite_path = skin_tflite_path()
    labels_path = skin_labels_path()
    os.makedirs(os.path.dirname(keras_path), exist_ok=True)
    model.save(keras_path)
    export_tflite(tf, model, tflite_path)
    with open(labels_path, "w", encoding="utf-8") as handle:
        json.dump(labels_payload(), handle, indent=2)
    flutter_dir = copy_to_flutter(tflite_path, labels_path)
    print(f"Saved Keras model: {keras_path}")
    print(f"Saved TFLite model: {tflite_path}")
    print(f"Copied TFLite + labels to {flutter_dir}")
    return tflite_path


def main(argv=None):
    parser = argparse.ArgumentParser(description="Train HAM10000-style skin CNN")
    parser.add_argument(
        "--data-dir",
        default=os.path.join(engine_dir(), "data", "ham10000"),
        help="Folder containing train/ and val/ class subfolders",
    )
    parser.add_argument("--epochs", type=int, default=8)
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--fine-tune-epochs", type=int, default=2)
    args = parser.parse_args(argv)
    if not os.path.isdir(args.data_dir):
        raise SystemExit(
            f"Data directory not found: {args.data_dir}\n"
            "Download HAM10000 and create train/<class> and val/<class> folders."
        )
    train(
        args.data_dir,
        epochs=args.epochs,
        batch_size=args.batch_size,
        fine_tune_epochs=args.fine_tune_epochs,
    )


if __name__ == "__main__":
    main(sys.argv[1:])
