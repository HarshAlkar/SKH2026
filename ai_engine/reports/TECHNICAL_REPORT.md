# VitalReach Real Data-Driven AI — Technical Report

**Date:** 2026-08-29  
**Scope:** Offline-first One Health AI screening (human symptoms, skin CNN, livestock)  
**Status:** Implemented with measured metrics (not fabricated)

---

## 1. Datasets used

| Domain | Dataset | Samples | Notes |
|--------|---------|---------|-------|
| Human symptoms | `mobile_app/lib/dataset/disease/dataset.csv` | 4,920 raw → **304 unique** after dedupe | 41 diseases; highly duplicated Kaggle-style table |
| Human advice | `1234/dataset/Disease precaution.csv`, `symptom_Description.csv` | 41 diseases | Joined into `symptom_labels.json` |
| Skin images | `archive (1)/SkinDisease` **22-class** | **13,898 train + 1,546 test** | **Not HAM10000** |
| Livestock | `cleaned_animal_disease_prediction.csv` | 431 → **421** after dedupe | 139 diseases collapsed → **8 families** |
| Not used for ML | `data.csv` (247k×713), medicine catalogs, `archive (2)` | — | Too large / different taxonomy / not screening |

Full inspection: [`ai_engine/reports/dataset_inspection.json`](../ai_engine/reports/dataset_inspection.json)

---

## 2. Models trained

| Domain | Candidates | Selected | Server artifact | Offline artifact |
|--------|------------|----------|-----------------|------------------|
| Human symptoms | LR*, RF, GB, XGB (LGBM N/A) | **Random Forest** | `trained_model.pkl` (~10.2 MB) | `symptom_mlp.tflite` (~33 KB) |
| Livestock | LR*, RF, GB, XGB | **Random Forest** | `livestock_model.pkl` (~7.9 MB) | `livestock_mlp.tflite` (~8 KB) |
| Skin | MobileNetV3-Small transfer | **MobileNetV3Small** | `skin_cnn.tflite` + `.keras` | same TFLite in Flutter assets (~1.1 MB) |

\*Logistic Regression failed on this Windows/Python 3.13 environment (`_posixsubprocess` with parallel BLAS); comparison used RF/GB/XGB.

---

## 3. Model performance (held-out test)

### Human symptoms (deduped 304 rows, 70/15/15)
- **Accuracy / Macro-F1 / Macro-Recall: 1.000** on held-out unique symptom sets  
- High-risk disease recall (Malaria, Dengue, TB, Pneumonia, Heart attack, etc.): **1.0** on this synthetic split  
- **Honest caveat:** near-perfect scores reflect a small, duplicated, synthetic symptom table — **not** clinical generalization. See limitations.

### Livestock (421 rows → 8 families, ~60/20/20)
- **Accuracy: 0.459** | **Macro-F1: 0.326** | **Macro-Recall: 0.324**  
- High-risk family recall mean: **~0.22**  
- Critical keyword rules remain as **safety override** when ML under-calls urgency.

### Skin (22-class MobileNetV3-Small)
- **Test accuracy: 0.449** | **Macro-F1: 0.402** | **Macro-Recall: 0.421**  
- High-risk recalls (test): SkinCancer **0.31**, Actinic_Keratosis **0.33**, Vasculitis **0.46**, Bullous **0.31**, Lupus **0.09**  
- Val accuracy after 5+2 epochs ≈ **0.43** (CPU training; more epochs/fine-tune would help)

Reports: `ai_engine/reports/*_eval.json`

---

## 4. Best model selected (criteria)

Selection score = **macro-F1 + weighted high-risk recall** (not training accuracy).  
Offline path uses compact **TFLite MLPs / CNN** matching the same feature/label schemas for airplane-mode inference.

---

## 5. Model size

| Artifact | Size |
|----------|------|
| `symptom_mlp.tflite` | ~33 KB |
| `livestock_mlp.tflite` | ~8 KB |
| `skin_cnn.tflite` | ~1.1 MB |
| `trained_model.pkl` | ~10.2 MB |
| `livestock_model.pkl` | ~7.9 MB |

---

## 6. Offline inference status

| Module | Offline? | Mechanism |
|--------|----------|-----------|
| Human symptoms | **Yes** | Local-first `SymptomMlService` TFLite → CSV fallback → OfflineApi queue |
| Skin | **Yes** | Local-first `SkinCnnService` TFLite → OfflineApi queue |
| Livestock | **Yes** | Local-first `LivestockMlService` TFLite + Critical rules → OfflineApi queue |
| Sync | **Yes** | Existing `OfflineApi` / `SyncService` → `/one-health/screenings/` |

Online `/symptoms/analyze/` and `/one-health/animal/analyze/` are **optional enrichment / alerts**, not required for a result.

---

## 7. Human symptom checker changes

- Trained RF + TFLite MLP from provided CSV (deduped)  
- [`SymptomProvider`](../mobile_app/lib/providers/symptom_provider.dart) is **local-first**  
- New [`symptom_ml_service.dart`](../mobile_app/lib/features/ai_symptom_checker/services/symptom_ml_service.dart)  
- Screening events persisted via [`screening_persistence.dart`](../mobile_app/lib/features/one_health/screening_persistence.dart)  
- Safe wording: elevated risk / not a diagnosis

---

## 8. Skin screening changes

- Replaced HAM10000-style placeholder pipeline with **22-class SkinDisease** MobileNetV3-Small  
- Overwrote `mobile_app/assets/models/skin_cnn.tflite` + `skin_labels.json`  
- Flutter preprocess matches Keras MobileNetV3 (`x/127.5 - 1`)  
- Skin results now create **HUMAN ScreeningEvent** (`input_type=image`) on device and on Django

---

## 9. Livestock AI changes

- Condition-family classifier (8 classes) + TFLite export  
- Hybrid: ML first, **Critical/High keyword override** in Dart and Django [`animal_screen.py`](../backend/django_api/apps/one_health/animal_screen.py)  
- Local-first livestock screen UI

---

## 10. One Health architecture changes

Shared pieces:
- `ai_engine/common/` (risk, metrics, paths, inspect)  
- Flutter `ScreeningPersistence` → same ScreeningEvent schema  
- Shared severity bands + escalation sheet (unchanged contract)  
- Disclaimers centralized / updated

```
VITALREACH AI ENGINE
        |
   HUMAN ── Symptom TFLite + Skin TFLite
   ANIMAL ── Livestock TFLite + Critical rules
        |
   Risk Engine → OfflineApi → Sync → Doctor / ASHA / Vet
```

---

## 11. Files created (key)

- `ai_engine/common/*`, `ai_engine/symptoms/*`, `ai_engine/livestock/*`  
- `ai_engine/reports/*`  
- `ai_engine/tests/test_ml_smoke.py`  
- `mobile_app/.../symptom_ml_service.dart`, `livestock_ml_service.dart`, `screening_persistence.dart`  
- Assets: `symptom_mlp.tflite`, `symptom_labels.json`, `livestock_mlp.tflite`, `livestock_labels.json`, updated `skin_cnn.tflite`

---

## 12. Files modified (key)

- `ai_engine/skin/train.py`, `labels.py`, `predict.py`, `predict.py` (symptoms), `services/train_model.py`  
- `backend/.../animal_screen.py`, `symptom_analysis/views.py`  
- `mobile_app/.../symptom_provider.dart`, `skin_cnn_service.dart`, `livestock_screening_screen.dart`, `screening_disclaimer.dart`, `symptom_checker_screen.dart`  
- `requirements-ai.txt`

---

## 13. APIs created/modified

- **No new URL routes**  
- `POST /symptoms/analyze/` — still works; disclaimer/message enriched  
- `POST /symptoms/analyze-skin/` — now also writes `ScreeningEvent` (image)  
- `POST /one-health/animal/analyze/` — ML + rule hybrid via `screen_animal_symptoms`  
- `POST /one-health/screenings/` — used by OfflineApi for all domains (unchanged contract)

---

## 14. Database changes

**None.** Reuses `ScreeningEvent` / `LivestockCase` fields; `source` stored inside `result_json`.

---

## 15. Test results

```
python -m unittest ai_engine.tests.test_ml_smoke -v
→ 5 tests OK (predict, livestock, critical rules, artifacts)

flutter analyze (changed paths)
→ 0 errors (1 prior prefer_final_fields info on SymptomProvider)
```

Manual airplane-mode checklist should be run on device: symptom → skin → livestock → reconnect → admin ScreeningEvent counts.

---

## 16. Remaining limitations

1. Human CSV is synthetic/duplicated — **perfect test metrics are not clinical proof**.  
2. Livestock fine-grained disease ML is impossible with 139 labels / 431 rows; family F1 ~0.33 needs more data.  
3. Skin F1 ~0.40 after short CPU training; SkinCancer recall ~0.31 — escalate high-risk UI aggressively.  
4. Field photos / lighting / skin-tone shift may degrade CNN.  
5. Poultry poorly represented in animal CSV (mapped heuristically).  
6. Child growth screener unchanged (rules-only, local).

---

## 17. Exact judge demo flow

1. Enable **Airplane mode**.  
2. Open **One Health → Human screening → Symptoms**; select chips (e.g. itching, skin rash); Analyze → local TFLite result + disclaimer → High/Critical opens escalation.  
3. Switch to **Skin photo**; capture/gallery → on-device CNN → screening wording (not diagnosis).  
4. Open **Livestock screening**; enter “fever cough nasal discharge” → local livestock MLP (+ rules if Critical).  
5. Confirm results saved locally (`queued_offline`).  
6. Disable airplane mode; wait for sync banner.  
7. Open Django admin / admin analytics → **ScreeningEvent** rows for HUMAN + ANIMAL.  
8. Log in as doctor/ASHA/vet → verify escalation/alerts for High/Critical.

**Spoken safety line for judges:**  
“AI-assisted screening only. This is not a medical or veterinary diagnosis.”
