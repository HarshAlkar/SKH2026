import os
import django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from apps.users.models import User
from apps.asha_workers.models import ASHAWorker
from apps.patients.models import Patient

with open("debug_output.txt", "w") as f:
    f.write("--- Users ---\n")
    for u in User.objects.all():
        f.write(f"User: {u.username}, Role: {u.role}, Village: '{u.village}'\n")
    f.write("\n--- ASHA Workers ---\n")
    for a in ASHAWorker.objects.all():
        f.write(f"ASHA: {a.user.username}, Assigned: '{a.assigned_village}'\n")
    f.write("\n--- Patients ---\n")
    for p in Patient.objects.all():
        f.write(f"Patient ID: {p.id}, User: {p.user.username}, User.Village: '{p.user.village}'\n")
