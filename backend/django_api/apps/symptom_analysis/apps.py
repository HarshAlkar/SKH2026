from django.apps import AppConfig


class SymptomAnalysisConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.symptom_analysis'

    def ready(self):
        from django.conf import settings
        import sys

        project_root = str(settings.BASE_DIR.parent.parent)
        if project_root not in sys.path:
            sys.path.append(project_root)
        try:
            from ai_engine.predict import _load_bundle
            _load_bundle()
        except Exception:
            pass
        try:
            from ai_engine.skin.predict import _load_interpreter
            _load_interpreter()
        except Exception:
            pass
