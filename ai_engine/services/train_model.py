import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
import pickle
import os

def train_model():
    # Load dataset
    dataset_path = os.path.join(os.path.dirname(__file__), '../datasets/symptom_disease_dataset.csv')
    if not os.path.exists(dataset_path):
        print("Dataset not found. Creating a sample dataset...")
        create_sample_dataset(dataset_path)
    
    df = pd.read_csv(dataset_path)
    
    # Simple encoding for demonstration
    # In a real scenario, we'd use OneHotEncoder or MultiLabelBinarizer
    X = df.drop('disease', axis=1)
    y = df['disease']
    
    # Convert symptom names to numeric positions for simplicity in this mockup
    # Real implementation would use more robust vectorization
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    model = RandomForestClassifier(n_estimators=100)
    model.fit(X_train, y_train)
    
    # Save model
    model_path = os.path.join(os.path.dirname(__file__), '../models/trained_model.pkl')
    os.makedirs(os.path.dirname(model_path), exist_ok=True)
    with open(model_path, 'wb') as f:
        pickle.dump(model, f)
    
    print(f"Model trained and saved to {model_path}")

def create_sample_dataset(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    # Example symptoms: fever, cough, headache, fatigue, nausea
    data = {
        'fever': [1, 1, 0, 0, 1, 0, 1, 0, 0, 1],
        'cough': [1, 0, 0, 1, 1, 0, 0, 0, 1, 1],
        'headache': [0, 1, 1, 0, 1, 1, 0, 1, 0, 0],
        'fatigue': [1, 1, 0, 1, 0, 1, 0, 1, 1, 1],
        'nausea': [0, 0, 1, 0, 0, 1, 1, 0, 0, 0],
        'disease': [
            'Viral Fever', 'Influenza', 'Migraine', 'Common Cold', 
            'Pneumonia', 'Food Poisoning', 'Gastroenteritis', 
            'Stress', 'Bronchitis', 'COVID-19'
        ]
    }
    df = pd.DataFrame(data)
    df.to_csv(path, index=False)

if __name__ == "__main__":
    train_model()
