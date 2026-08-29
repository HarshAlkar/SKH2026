# Livestock Condition-Family Screening Evaluation

- **dataset**: cleaned_animal_disease_prediction.csv (deduped, collapsed families)
- **n_samples**: 421
- **n_classes**: 8
- **split**: 60/20/20 approx stratified where possible
- **best_model**: random_forest
- **model_size_bytes**: 7870609
- **inference_ms_approx**: 2.489648593655147
- **offline_compatible**: True
- **limitations**: Original 139 disease labels are too sparse; predictions are condition-family screening only. Critical keyword rules remain as safety override. Not a veterinary diagnosis.

## Test metrics
- **accuracy**: 0.4588235294117647
- **precision_macro**: 0.42122758194186766
- **recall_macro**: 0.3237103174603175
- **f1_macro**: 0.3264918248000955

## Model comparison (validation)
- logistic_regression: f1_macro=None, high_risk_recall=None, accuracy=None
- random_forest: f1_macro=0.2504140210446069, high_risk_recall=0.23671497584541062, accuracy=0.40476190476190477
- gradient_boosting: f1_macro=0.236913821472645, high_risk_recall=0.24758454106280192, accuracy=0.42857142857142855
- xgboost: f1_macro=0.22097630718954248, high_risk_recall=0.23719806763285023, accuracy=0.36904761904761907
