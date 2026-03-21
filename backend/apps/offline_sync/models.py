from django.db import models
from django.conf import settings

class SyncLog(models.Model):
    asha_worker = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='sync_logs')
    payload = models.JSONField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Sync Log from worker {self.asha_worker.worker_id} at {self.created_at}"
