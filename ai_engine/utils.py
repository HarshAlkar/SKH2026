import os
import re


def engine_dir():
    return os.path.dirname(os.path.abspath(__file__))


def dataset_path():
    return os.path.abspath(
        os.path.join(engine_dir(), "..", "mobile_app", "lib", "dataset", "disease", "dataset.csv")
    )


def model_path():
    return os.path.join(engine_dir(), "models", "trained_model.pkl")


def skin_tflite_path():
    return os.path.join(engine_dir(), "models", "skin_cnn.tflite")


def skin_keras_path():
    return os.path.join(engine_dir(), "models", "skin_cnn.keras")


def skin_labels_path():
    return os.path.join(engine_dir(), "models", "skin_labels.json")


def normalize_symptom(value):
    text = str(value).lower().strip()
    text = text.replace(" ", "_")
    text = re.sub(r"_+", "_", text)
    return text.strip("_")
