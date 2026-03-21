from django.contrib import admin
from .models import Doctor

@admin.register(Doctor)
class DoctorAdmin(admin.ModelAdmin):
    list_display = ('name', 'specialization', 'phone_number', 'is_on_call', 'hospital_name')
    list_filter = ('specialization', 'is_on_call')
    search_fields = ('name', 'hospital_name')
