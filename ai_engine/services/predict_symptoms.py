import pandas as pd
import os
import json
import re

def predict(symptoms_list):
    # Prepare symptoms for matching
    symptoms_list = [s.lower().strip() for s in symptoms_list if s]
    
    # Path to dataset (from Flutter app as specified)
    dataset_path = os.path.join(os.path.dirname(__file__), '../../../mobile_app/lib/dataset/disease/dataset.csv')
    
    if not os.path.exists(dataset_path):
        # Fallback to local dataset directory if not found in Flutter path
        dataset_path = os.path.join(os.path.dirname(__file__), '../datasets/dataset.csv')

    if not os.path.exists(dataset_path):
        return {"disease": "Unknown (Dataset not found)", "severity": "Low"}
    
    try:
        df = pd.read_csv(dataset_path)
        # The dataset format is: Disease, Symptom_1, Symptom_2, ...
        # We'll use a simple matching logic: which disease has the most symptom overlaps
        
        disease_scores = {}
        for index, row in df.iterrows():
            disease = row['Disease']
            # Get all columns except 'Disease' and filter out NaNs
            disease_symptoms = [str(val).lower().strip() for val in row[1:] if pd.notna(val) and val != '']
            
            # Count matches
            matches = 0
            for input_s in symptoms_list:
                if any(input_s in ds or ds in input_s for ds in disease_symptoms):
                    matches += 1
            
            if matches > 0:
                disease_scores[disease] = matches
        
        if not disease_scores:
            return {"disease": "Undetermined", "severity": "Low"}
        
        # Get disease with highest score
        prediction = max(disease_scores, key=disease_scores.get)
        
        # Severity mapping
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

if __name__ == "__main__":
    # Example usage
    test_symptoms = ["itching", "skin rash"]
    print(json.dumps(predict(test_symptoms)))
