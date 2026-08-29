"""Dataset and artifact paths for VitalReach AI."""

from __future__ import annotations

import os

from ai_engine.utils import engine_dir


def repo_root():
    return os.path.abspath(os.path.join(engine_dir(), ".."))


def dataset_root():
    return os.path.join(repo_root(), "mobile_app", "lib", "dataset")


def human_symptom_csv():
    return os.path.join(dataset_root(), "disease", "dataset.csv")


def human_precaution_csv():
    return os.path.join(
        dataset_root(), "1234", "dataset", "Disease precaution.csv"
    )


def human_description_csv():
    return os.path.join(
        dataset_root(), "1234", "dataset", "symptom_Description.csv"
    )


def animal_csv():
    return os.path.join(
        dataset_root(),
        "1234",
        "dataset",
        "cleaned_animal_disease_prediction.csv",
    )


def skin_archive1_dir():
    return os.path.join(
        dataset_root(),
        "archive (1)",
        "SkinDisease",
        "SkinDisease",
    )


def flutter_models_dir():
    return os.path.join(repo_root(), "mobile_app", "assets", "models")


def reports_dir():
    return os.path.join(engine_dir(), "reports")


def models_dir():
    return os.path.join(engine_dir(), "models")
