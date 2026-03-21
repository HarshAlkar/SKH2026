import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()
from apps.users.models import User
from apps.patients.models import Patient

users = User.objects.filter(name__icontains='Shreyas')
for u in users:
    print(f"User ID: {u.id}, Name: {u.name}, Username: {u.username}, Phone: {u.phone_number}")
    patient = Patient.objects.filter(user=u).first()
    if patient:
        print(f"  Patient Profile exists: Age {patient.age}, Blood {patient.blood_group}")
