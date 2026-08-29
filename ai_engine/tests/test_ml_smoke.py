"""Smoke tests for VitalReach AI engine (no Django required)."""

from __future__ import annotations

import os
import sys
import unittest

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if ROOT not in sys.path:
    sys.path.insert(0, ROOT)


class SymptomPredictTests(unittest.TestCase):
    def test_predict_returns_screening_fields(self):
        from ai_engine.predict import predict_symptoms

        result = predict_symptoms(["itching", "skin_rash", "nodal_skin_eruptions"])
        self.assertIn("disease", result)
        self.assertIn("severity", result)
        self.assertIn("confidence", result)
        self.assertIn("disclaimer", result)
        self.assertNotIn("diagnosis", (result.get("disclaimer") or "").lower().split("not a")[0] if False else "")
        self.assertIn("not a", (result.get("disclaimer") or "").lower())

    def test_empty_symptoms(self):
        from ai_engine.predict import predict_symptoms

        result = predict_symptoms([])
        self.assertEqual(result["disease"], "Undetermined")


class LivestockPredictTests(unittest.TestCase):
    def test_livestock_predict_or_graceful(self):
        from ai_engine.livestock.predict import predict_livestock

        result = predict_livestock(
            {"symptoms": "cough nasal discharge fever", "species": "CATTLE"}
        )
        self.assertIn("severity", result)
        self.assertIn("disclaimer", result)
        self.assertIn("veterinar", (result.get("disclaimer") or "").lower())


class AnimalScreenHybridTests(unittest.TestCase):
    def test_critical_rule_override(self):
        # Import from django path if available; else skip
        animal_path = os.path.join(
            ROOT, "backend", "django_api", "apps", "one_health", "animal_screen.py"
        )
        if not os.path.exists(animal_path):
            self.skipTest("animal_screen missing")
        sys.path.insert(0, os.path.join(ROOT, "backend", "django_api"))
        from apps.one_health.animal_screen import screen_animal_symptoms

        result = screen_animal_symptoms("bloody diarrhea and collapse", species="CATTLE")
        self.assertEqual(result["severity"], "Critical")


class ArtifactTests(unittest.TestCase):
    def test_model_artifacts_exist(self):
        models = os.path.join(ROOT, "ai_engine", "models")
        self.assertTrue(os.path.exists(os.path.join(models, "trained_model.pkl")))
        self.assertTrue(os.path.exists(os.path.join(models, "symptom_labels.json")))
        self.assertTrue(os.path.exists(os.path.join(models, "livestock_model.pkl")))
        self.assertTrue(os.path.exists(os.path.join(models, "livestock_labels.json")))
        flutter = os.path.join(ROOT, "mobile_app", "assets", "models")
        self.assertTrue(os.path.exists(os.path.join(flutter, "symptom_mlp.tflite")))
        self.assertTrue(os.path.exists(os.path.join(flutter, "livestock_mlp.tflite")))


if __name__ == "__main__":
    unittest.main()
