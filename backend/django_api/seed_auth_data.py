import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.users.models import User
from apps.doctors.models import Doctor
from apps.asha_workers.models import ASHAWorker

def seed_data():
    # Users (Patients)
    users_data = [
        {"name": "Ramesh Patil", "village": "Pune", "phone": "9876543210", "email": "ramesh@example.com"},
        {"name": "Sita Sharma", "village": "Nagpur", "phone": "9876543211", "email": "sita@example.com"},
        {"name": "Amit Kumar", "village": "Delhi", "phone": "9876543212", "email": "amit@example.com"},
        {"name": "Priya Deshmukh", "village": "Mumbai", "phone": "9876543213", "email": "priya@example.com"},
    ]

    for data in users_data:
        if not User.objects.filter(phone_number=data["phone"]).exists():
            User.objects.create_user(
                username=data["phone"],
                phone_number=data["phone"],
                name=data["name"],
                village=data["village"],
                email=data["email"],
                password="password123",
                role="user"
            )
            print(f"Created user: {data['name']}")

    # Doctors
    doctors_data = [
        {"name": "Rajesh Sharma", "specialization": "General Physician", "phone": "9999999990", "exp": 10, "hospital": "Apollo Hospital"},
        {"name": "Anjali Verma", "specialization": "Dermatologist", "phone": "9999999991", "exp": 8, "hospital": "Max Healthcare"},
        {"name": "Vivek Patel", "specialization": "Cardiologist", "phone": "9999999992", "exp": 15, "hospital": "Fortis Hospital"},
    ]

    for data in doctors_data:
        if not User.objects.filter(phone_number=data["phone"]).exists():
            user = User.objects.create_user(
                username=data["phone"],
                phone_number=data["phone"],
                name=data["name"],
                password="password123",
                role="doctor",
                email=f"{data['name'].lower().replace(' ', '.')}@example.com"
            )
            Doctor.objects.create(
                user=user,
                specialization=data["specialization"],
                experience_years=data["exp"],
                hospital_name=data["hospital"]
            )
            print(f"Created doctor: {data['name']}")

    # ASHA Workers
    asha_data = [
        {"name": "Sunita Devi", "village": "Rampur Village", "phone": "8888888880", "phc": "Rampur PHC"},
        {"name": "Lata Patil", "village": "Kaman Village", "phone": "8888888881", "phc": "Kaman PHC"},
    ]

    for data in asha_data:
        if not User.objects.filter(phone_number=data["phone"]).exists():
            user = User.objects.create_user(
                username=data["phone"],
                phone_number=data["phone"],
                name=data["name"],
                village=data["village"],
                password="password123",
                role="asha_worker",
                email=f"{data['name'].lower().replace(' ', '.')}@example.com"
            )
            ASHAWorker.objects.create(
                user=user,
                assigned_village=data["village"],
                phc_center=data["phc"]
            )
            print(f"Created ASHA worker: {data['name']}")

if __name__ == "__main__":
    seed_data()
