from django.contrib import admin
from .models import Patient

@admin.register(Patient)
class PatientAdmin(admin.ModelAdmin):
    list_display = ('name', 'age', 'gender', 'village')
    search_fields = ('name', 'phone_number')
    list_filter = ('village', 'gender')
