# Human Symptom Screening Evaluation

- **dataset**: disease/dataset.csv (deduplicated)
- **n_samples**: 304
- **n_classes**: 41
- **split**: 70/15/15 stratified on deduped rows
- **best_model**: logistic_regression
- **model_size_bytes**: 63253
- **inference_ms_approx**: 0.003079218731727451
- **offline_compatible**: True
- **limitations**: Source CSV is highly duplicated/synthetic; near-perfect sklearn scores on held-out unique rows do NOT prove clinical accuracy. Offline Flutter uses the MLP TFLite model (see test_metrics_mlp_tflite). Never present as diagnosis.

## Test metrics
- **accuracy**: 1.0
- **precision_macro**: 1.0
- **recall_macro**: 1.0
- **f1_macro**: 1.0

## Model comparison (validation)
- logistic_regression: f1_macro=1.0, high_risk_recall=1.0, accuracy=1.0
- random_forest: f1_macro=1.0, high_risk_recall=1.0, accuracy=1.0
- gradient_boosting: f1_macro=0.8569105691056911, high_risk_recall=0.75, accuracy=0.8913043478260869
- xgboost: f1_macro=0.934959349593496, high_risk_recall=1.0, accuracy=0.9565217391304348
