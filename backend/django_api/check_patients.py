import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()
from apps.patients.models import Patient
print("=== Patients in DB ===")
for p in Patient.objects.all():
    print(f"ID: {p.id}, Name: {p.user.name or p.user.username}, Village: {p.user.village}, Address: {p.address}")
