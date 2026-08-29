# VitalReach Dataset Inspection

## human_symptoms
- name: disease/dataset.csv (Kaggle-style 41-disease symptom table)
- path: C:\Users\HARSH\OneDrive\Desktop\HARSH\SKH\SKH2026\mobile_app\lib\dataset\disease\dataset.csv
- n_records: 4920
- n_unique_disease_symptom_sets: 304
- n_duplicate_rows: 4616
- n_diseases: 41
- missing_cells: 46992
- features: Disease + Symptom_1..Symptom_17 (sparse string lists)
- target: Disease
- suitable_for_symptom_screening: True
- notes: High duplicate rate; train on deduplicated rows. Synthetic/balanced 120 rows per disease before dedupe.
- precaution_csv_exists: True
- description_csv_exists: True

## livestock
- name: cleaned_animal_disease_prediction.csv
- path: C:\Users\HARSH\OneDrive\Desktop\HARSH\SKH\SKH2026\mobile_app\lib\dataset\1234\dataset\cleaned_animal_disease_prediction.csv
- n_records: 431
- n_duplicate_rows: 10
- missing_cells: 0
- animal_types: {'Dog': 75, 'Cat': 72, 'Cow': 68, 'Horse': 66, 'Sheep': 39, 'Goat': 39, 'Pig': 38, 'Rabbit': 34}
- n_diseases: 139
- diseases_with_lt3_samples: 87
- diseases_with_1_sample: 57
- columns: ['Animal_Type', 'Breed', 'Age', 'Gender', 'Weight', 'Symptom_1', 'Symptom_2', 'Symptom_3', 'Symptom_4', 'Duration', 'Appetite_Loss', 'Vomiting', 'Diarrhea', 'Coughing', 'Labored_Breathing', 'Lameness', 'Skin_Lesions', 'Nasal_Discharge', 'Eye_Discharge', 'Body_Temperature', 'Heart_Rate', 'Disease_Prediction']
- suitable_for_fine_grained_disease_ml: False
- suitable_for_condition_family_screening: True
- notes: 139 diseases on 431 rows is too sparse for reliable disease ID; collapse to condition families + severity.

## skin
- name: archive (1) SkinDisease 22-class clinical set
- path: C:\Users\HARSH\OneDrive\Desktop\HARSH\SKH\SKH2026\mobile_app\lib\dataset\archive (1)\SkinDisease\SkinDisease
- is_ham10000: False
- n_classes: 22
- classes: ['Acne', 'Actinic_Keratosis', 'Benign_tumors', 'Bullous', 'Candidiasis', 'DrugEruption', 'Eczema', 'Infestations_Bites', 'Lichen', 'Lupus', 'Moles', 'Psoriasis', 'Rosacea', 'Seborrh_Keratoses', 'SkinCancer', 'Sun_Sunlight_Damage', 'Tinea', 'Unknown_Normal', 'Vascular_Tumors', 'Vasculitis', 'Vitiligo', 'Warts']
- n_train: 13898
- n_test: 1546
- corrupt_samples_checked: 0
- suitable_for_image_screening: True
