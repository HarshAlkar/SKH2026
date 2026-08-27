import os
import django
from django.utils import timezone
from datetime import time, timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.users.models import User
from apps.doctors.models import Doctor
from apps.asha_workers.models import ASHAWorker
from apps.patients.models import Patient
from apps.consultations.models import Appointment
from apps.prescriptions.models import Prescription
from apps.health_records.models import HealthRecord

def seed_data():
    # Users (Patients)
    users_data = [
        {"name": "Ramesh Patil", "village": "Kaman Village", "phone": "9876543210", "email": "ramesh@example.com", "age": 45, "gender": "Male", "blood_group": "A+", "history": "Type 2 Diabetes (Managed)"},
        {"name": "Sunita Deshmukh", "village": "Pelhar", "phone": "9876543211", "email": "sunita@example.com", "age": 32, "gender": "Female", "blood_group": "AB+", "history": "Back pain physiotherapy follow-up"},
        {"name": "Amitabh Bachchan", "village": "Mumbai South", "phone": "9876543212", "email": "amitabh@example.com", "age": 78, "gender": "Male", "blood_group": "B+", "history": "Hypertension, Blood pressure monitoring"},
        {"name": "Priyanka Chopra", "village": "Green Valley", "phone": "9876543213", "email": "priyanka@example.com", "age": 28, "gender": "Female", "blood_group": "O+", "history": "Upper respiratory infection"},
    ]

    patient_objs = []
    for data in users_data:
        user, created = User.objects.get_or_create(
            phone_number=data["phone"],
            defaults={
                "username": data["phone"],
                "name": data["name"],
                "village": data["village"],
                "email": data["email"],
                "role": "user",
            },
        )
        if not created and (user.name != data["name"] or user.village != data["village"]):
            user.name = data["name"]
            user.village = data["village"]
            user.save()
        if created:
            user.set_password("password123")
            user.save()
            print(f"Created user: {data['name']}")
        p_obj, _ = Patient.objects.get_or_create(
            user=user,
            defaults={
                "age": data["age"],
                "gender": data["gender"],
                "blood_group": data["blood_group"],
                "address": data["village"],
                "medical_history": data["history"],
            },
        )
        p_obj.age = data["age"]
        p_obj.gender = data["gender"]
        p_obj.blood_group = data["blood_group"]
        p_obj.address = data["village"]
        p_obj.medical_history = data["history"]
        p_obj.save()
        patient_objs.append(p_obj)

    # Doctors
    doctors_data = [
        {"name": "Rajesh Sharma", "specialization": "General Physician", "phone": "9999999990", "exp": 10, "hospital": "Apollo Hospital"},
        {"name": "Anjali Verma", "specialization": "Dermatologist", "phone": "9999999991", "exp": 8, "hospital": "Max Healthcare"},
        {"name": "Vivek Patel", "specialization": "Cardiologist", "phone": "9999999992", "exp": 15, "hospital": "Fortis Hospital"},
    ]

    doctor_objs = []
    for data in doctors_data:
        user = User.objects.filter(phone_number=data["phone"]).first()
        if not user:
            user = User.objects.create_user(
                username=data["phone"],
                phone_number=data["phone"],
                name=data["name"],
                password="password123",
                role="doctor",
                email=f"{data['name'].lower().replace(' ', '.')}@example.com"
            )
            doc = Doctor.objects.create(
                user=user,
                specialization=data["specialization"],
                experience_years=data["exp"],
                hospital_name=data["hospital"]
            )
            print(f"Created doctor: {data['name']}")
        else:
            doc = getattr(user, 'doctor_profile', None) or Doctor.objects.filter(user=user).first()
        if doc:
            doctor_objs.append(doc)

    # Also handle doctor with username dr_sharma if exists
    dr_sharma = Doctor.objects.filter(user__username='dr_sharma').first()
    if dr_sharma and dr_sharma not in doctor_objs:
        doctor_objs.append(dr_sharma)

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

    # Seed Sample Prescriptions & Health Records for Registered Patients
    if patient_objs and doctor_objs:
        primary_doc = doctor_objs[0]
        # Prescriptions
        Prescription.objects.get_or_create(
            patient=patient_objs[0], # Ramesh Patil
            doctor=primary_doc,
            medications="Metformin 500mg - 1 Tab Daily after food",
            defaults={"notes": "Regular blood sugar monitoring"}
        )
        Prescription.objects.get_or_create(
            patient=patient_objs[3], # Priyanka Chopra
            doctor=primary_doc,
            medications="Amoxicillin 500mg - 1 Tab Thrice Daily for 5 days",
            defaults={"notes": "Rest and plenty of fluids"}
        )

        # Health Records
        HealthRecord.objects.get_or_create(
            patient=patient_objs[0],
            defaults={
                "temperature": "98.6 F",
                "blood_pressure": "130/85 mmHg",
                "blood_sugar": "140 mg/dL",
                "weight": "72 kg",
                "symptoms": "Chronic cough, managed blood sugar",
                "risk_level": "normal"
            }
        )
        HealthRecord.objects.get_or_create(
            patient=patient_objs[1],
            defaults={
                "temperature": "98.4 F",
                "blood_pressure": "120/80 mmHg",
                "blood_sugar": "95 mg/dL",
                "weight": "58 kg",
                "symptoms": "Lower back strain",
                "risk_level": "normal"
            }
        )

        # Seed Appointments for each doctor for TODAY and UPCOMING
        today = timezone.localdate()
        for doc in doctor_objs:
            # 1. Today Video Call with Ramesh Patil
            Appointment.objects.get_or_create(
                patient=patient_objs[0],
                doctor=doc,
                appointment_date=today,
                appointment_time=time(10, 30),
                defaults={
                    "consultation_type": "VIDEO",
                    "status": "SCHEDULED",
                    "notes": "Follow-up consultation for sugar levels"
                }
            )
            # 2. Today Audio Call with Sunita Deshmukh
            Appointment.objects.get_or_create(
                patient=patient_objs[1],
                doctor=doc,
                appointment_date=today,
                appointment_time=time(11, 15),
                defaults={
                    "consultation_type": "AUDIO",
                    "status": "SCHEDULED",
                    "notes": "Physiotherapy progress check"
                }
            )
            # 3. Today Offline Visit with Amitabh Bachchan
            Appointment.objects.get_or_create(
                patient=patient_objs[2],
                doctor=doc,
                appointment_date=today,
                appointment_time=time(14, 0),
                defaults={
                    "consultation_type": "OFFLINE",
                    "status": "SCHEDULED",
                    "notes": "Routine in-person BP check"
                }
            )
            # 4. Tomorrow Video Call with Priyanka Chopra
            Appointment.objects.get_or_create(
                patient=patient_objs[3],
                doctor=doc,
                appointment_date=today + timedelta(days=1),
                appointment_time=time(10, 0),
                defaults={
                    "consultation_type": "VIDEO",
                    "status": "SCHEDULED",
                    "notes": "Chest auscultation follow-up"
                }
            )
        print("Appointments and health records seeded successfully!")

if __name__ == "__main__":
    seed_data()

