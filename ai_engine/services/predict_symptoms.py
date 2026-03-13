import pandas as pd
import pickle
import os
import json

def predict(symptoms_list):
    model_path = os.path.join(os.path.dirname(__file__), '../models/trained_model.pkl')
    
    if not os.path.exists(model_path):
        return {"error": "Model not found. Please train the model first."}
    
    with open(model_path, 'rb') as f:
        model = pickle.load(f)
    
    # Map symptoms to the binary features used during training
    # fever, cough, headache, fatigue, nausea
    all_symptoms = ['fever', 'cough', 'headache', 'fatigue', 'nausea']
    input_data = []
    for s in all_symptoms:
        input_data.append(1 if s in symptoms_list else 0)
    
    # Reshape for prediction
    input_df = pd.DataFrame([input_data], columns=all_symptoms)
    
    prediction = model.predict(input_df)[0]
    
    # Severity is mocked for this demonstration
    severity_map = {
        'Viral Fever': 'Moderate',
        'Influenza': 'High',
        'Migraine': 'Low',
        'Common Cold': 'Low',
        'Pneumonia': 'Critical',
        'Food Poisoning': 'Moderate',
        'Gastroenteritis': 'Moderate',
        'Stress': 'Low',
        'Bronchitis': 'Moderate',
        'COVID-19': 'High'
    }
    
    return {
        "disease": prediction,
        "severity": severity_map.get(prediction, 'Unknown')
    }

if __name__ == "__main__":
    # Example usage
    test_symptoms = ["fever", "cough"]
    print(json.dumps(predict(test_symptoms)))
