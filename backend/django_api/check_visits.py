import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()
from apps.asha_workers.models import VillageVisit
print("=== Visits in DB ===")
for v in VillageVisit.objects.all():
    print(f"ID: {v.id}, PatientID: {v.patient_id}, Name: {v.patient.user.name or v.patient.user.username}")
