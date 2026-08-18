from django.db import models
from django.conf import settings

class ASHAWorker(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, related_name='asha_profile', on_delete=models.CASCADE)
    assigned_village = models.CharField(max_length=100)
    phc_center = models.CharField(max_length=200)
    worker_id = models.CharField(max_length=50, blank=True, default='')
    district = models.CharField(max_length=100, blank=True, default='')

    def __str__(self):
        return f"ASHA Worker: {self.user.name or self.user.username} - {self.assigned_village}"
