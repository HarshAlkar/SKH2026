import os
import pickle

import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

from ai_engine.utils import dataset_path, model_path, normalize_symptom


def load_symptom_rows(csv_path):
    df = pd.read_csv(csv_path)
    rows = []
    all_symptoms = set()
    for _, row in df.iterrows():
        disease = str(row.iloc[0]).strip()
        symptoms = []
        for val in row.iloc[1:]:
            if pd.notna(val) and str(val).strip():
                symptom = normalize_symptom(val)
                if symptom:
                    symptoms.append(symptom)
                    all_symptoms.add(symptom)
        if symptoms:
            rows.append((disease, symptoms))
    return rows, sorted(all_symptoms)


def train_model():
    csv_path = dataset_path()
    if not os.path.exists(csv_path):
        raise FileNotFoundError(f"Dataset not found at {csv_path}")

    rows, features = load_symptom_rows(csv_path)
    X = []
    y = []
    for disease, symptoms in rows:
        present = set(symptoms)
        X.append([1 if feature in present else 0 for feature in features])
        y.append(disease)

    encoder = LabelEncoder()
    y_encoded = encoder.fit_transform(y)

    stratify = y_encoded if len(set(y_encoded)) > 1 else None
    try:
        X_train, X_test, y_train, y_test = train_test_split(
            X, y_encoded, test_size=0.2, random_state=42, stratify=stratify
        )
    except ValueError:
        X_train, y_train, X_test, y_test = X, y_encoded, X, y_encoded

    model = RandomForestClassifier(n_estimators=120, random_state=42, n_jobs=-1)
    model.fit(X_train, y_train)
    accuracy = float(model.score(X_test, y_test))

    os.makedirs(os.path.dirname(model_path()), exist_ok=True)
    with open(model_path(), "wb") as handle:
        pickle.dump(
            {
                "model": model,
                "features": features,
                "encoder": encoder,
                "accuracy": accuracy,
            },
            handle,
        )

    print(f"Model trained (accuracy={accuracy:.3f}) and saved to {model_path()}")
    return model_path()


if __name__ == "__main__":
    train_model()
