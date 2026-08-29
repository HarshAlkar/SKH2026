# Human Symptom ML Fix — Audit Report

**Date:** 2026-08-29

## Exact root cause of 100% / 100% / 88%

The UI was **not** showing TFLite softmax probabilities.

Verified: for the jaundice-like symptom set, **on-device MLP softmax** is approximately:

- Hepatitis C ≈ **36.5%**
- Chronic cholestasis ≈ **33.4%**
- Hepatitis D ≈ **18.5%**

The **100% / 100% / 88%** pattern matches **CSV coverage fallback** (`SymptomDatasetService`):

`coverage = matched_symptoms / disease_symptom_count`

When the user’s symptom list is a **superset** of a disease’s symptom list, coverage = **1.0** for multiple diseases at once. The UI then did `confidence * 100` → **100%**.

Why CSV ran: `SymptomMlService.tryPredict` **swallowed all TFLite errors** and returned `null`, so `SymptomProvider` fell back to `dataset_local` with no `source` badge.

## Model actually used (after fix)

| Path | Artifact | `source` field |
|------|----------|----------------|
| Primary offline | `assets/models/symptom_mlp.tflite` + `symptom_labels.json` | `symptom_mlp_ondevice` |
| Fallback | CSV coverage (softmax-normalized ranks) | `dataset_local` |
| Server | `trained_model.pkl` (sklearn) | `symptom_ml` / `server_ml` |

Flutter now uses **Float32** TFLite I/O, logs load/run errors, returns **raw probabilities**, applies optional temperature from labels JSON, and shows an **AI source** badge.

## Training / test metrics (held-out deduped CSV)

Dataset: `disease/dataset.csv` — 4920 raw → **304 unique** rows, 41 classes, 131 features. Synthetic/duplicated — **near-perfect scores are not clinical proof**.

- **Best sklearn (server):** Logistic Regression — test Acc/F1 ≈ **1.0** on unique held-out rows  
- **Offline MLP TFLite:** test Acc/F1 ≈ **1.0** on same synthetic split; temperature fitted on val  
- **Honest limitation:** metrics do **not** generalize to real patients; UI now frames **screening**, not diagnosis.

Full JSON: `ai_engine/reports/human_symptoms_eval.json`

## Probability calculation

1. Multi-hot vector in **training feature order** from `symptom_labels.json`  
2. TFLite MLP → softmax outputs (sum ≈ 1)  
3. Optional temperature softening/sharpening  
4. UI shows **one decimal** percentages (e.g. 36.5%)  
5. Ambiguous top-2 → headline **“Elevated-risk screening result”**  
6. CSV fallback **never** claims model confidence; labeled as match ranks

## Free-text NLP

- Offline phrase map + negation (`no/not/without/don't`)  
- Chips ∪ confirmed extracted tokens → **one** multi-hot → same TFLite model  
- Voice fills the same text field (STT may need network)

## Files changed

- `mobile_app/lib/features/ai_symptom_checker/services/symptom_ml_service.dart`
- `mobile_app/lib/features/ai_symptom_checker/services/symptom_dataset_service.dart`
- `mobile_app/lib/features/ai_symptom_checker/services/symptom_text_extractor.dart` **(new)**
- `mobile_app/lib/providers/symptom_provider.dart`
- `mobile_app/lib/features/user/screens/symptom_checker_screen.dart`
- `ai_engine/symptoms/train.py`, `smoke_infer.py`, `nlp_smoke.py`
- `mobile_app/test/symptom_text_extractor_test.dart`
- Retrained `symptom_mlp.tflite` / `symptom_labels.json` / `trained_model.pkl`

## Confirmation

Offline Flutter screening uses the **trained TFLite MLP** when the asset loads; chips + free text are **merged before** inference; CSV is last-resort with explicit labeling.
