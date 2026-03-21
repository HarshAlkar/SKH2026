from django.contrib import admin
from .models import Consultation

@admin.register(Consultation)
class ConsultationAdmin(admin.ModelAdmin):
    list_display = ('patient', 'urgency_level', 'status', 'created_at')
    list_filter = ('urgency_level', 'status')
