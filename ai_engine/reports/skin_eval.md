# Skin Screening CNN Evaluation

- **dataset**: archive (1) SkinDisease 22-class (NOT HAM10000)
- **n_samples**: 15444
- **n_classes**: 22
- **split**: train 90% + val 10% from train/; held-out test/ folder
- **best_model**: MobileNetV3Small
- **model_size_bytes**: 1142144
- **offline_compatible**: True
- **limitations**: Clinical photo dataset may not match field lighting/skin tones. Not a diagnosis. High-risk classes (SkinCancer etc.) require clinician review.

## Test metrics
- **accuracy**: 0.4489003880983182
- **precision_macro**: 0.42835692999366604
- **recall_macro**: 0.42119242061299905
- **f1_macro**: 0.40248946038384975
