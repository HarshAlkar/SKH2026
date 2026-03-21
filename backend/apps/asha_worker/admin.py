from django.contrib import admin
from .models import AshaWorker

@admin.register(AshaWorker)
class AshaWorkerAdmin(admin.ModelAdmin):
    list_display = ('name', 'worker_id', 'phone_number', 'village')
    search_fields = ('name', 'worker_id', 'phone_number')
