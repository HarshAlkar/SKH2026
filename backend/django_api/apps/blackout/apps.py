from django.apps import AppConfig


class BlackoutConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.blackout'
    label = 'blackout'
    verbose_name = 'Blackout Recovery Demo'
