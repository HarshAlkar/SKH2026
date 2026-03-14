from django.apps import AppConfig


class MedicineTrackerConfig(AppConfig):
    name = 'apps.medicine_tracker'

    def ready(self):
        import apps.medicine_tracker.signals
