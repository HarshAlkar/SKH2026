import pandas as pd
import os
import json
import re

def predict_symptoms(symptoms_list):
    # If a string is passed, convert to list
    if isinstance(symptoms_list, str):
        symptoms_list = re.findall(r'\w+', symptoms_list.lower())
        
    symptoms_list = [s.lower().strip() for s in symptoms_list if s]
    
    # Path to dataset (from Flutter app as specified)
    # Since we are in hs053/ai_engine/predict.py
    dataset_path = os.path.join(os.path.dirname(__file__), '../mobile_app/lib/dataset/disease/dataset.csv')
    
    if not os.path.exists(dataset_path):
        # Fallback to absolute search or relative to CWD if needed
        # For now try sibling directory
        dataset_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'mobile_app', 'lib', 'dataset', 'disease', 'dataset.csv'))

    if not os.path.exists(dataset_path):
        return {"disease": "Unknown (Dataset not found)", "severity": "Low"}
    
    try:
        df = pd.read_csv(dataset_path)
        
        disease_scores = {}
        for index, row in df.iterrows():
            disease = row['Disease']
            disease_symptoms = [str(val).lower().strip() for val in row[1:] if pd.notna(val) and val != '']
            
            matches = 0
            for input_s in symptoms_list:
                if any(input_s in ds or ds in input_s for ds in disease_symptoms):
                    matches += 1
            
            if matches > 0:
                disease_scores[disease] = matches
        
        if not disease_scores:
            return {"disease": "Undetermined", "severity": "Low"}
        
        prediction = max(disease_scores, key=disease_scores.get)
        
        severity_map = {
            'High': ['Pneumonia', 'Heart attack', 'Jaundice', 'Malaria', 'Dengue', 'Typhoid', 'COVID-19'],
            'Moderate': ['Fungal infection', 'Hepatitis A', 'Hepatitis B', 'Hypertension', 'Diabetes'],
        }
        
        severity = 'Low'
        for level, diseases in severity_map.items():
            if any(d.lower() in prediction.lower() for d in diseases):
                severity = level
                break
                
        return {
            "disease": prediction,
            "severity": severity
        }
    except Exception as e:
        return {"disease": f"Error: {str(e)}", "severity": "Low"}
