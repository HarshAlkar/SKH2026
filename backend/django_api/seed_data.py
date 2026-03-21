import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.contrib.auth import get_user_model
from apps.doctors.models import Doctor
from apps.medicine_tracker.models import MedicineSchedule
from apps.patients.models import Patient

User = get_user_model()

def seed_data():
    # 1. Create a test doctor user
    doc_user, _ = User.objects.get_or_create(
        username='dr_sharma',
        defaults={
            'first_name': 'Aryan',
            'last_name': 'Sharma',
            'role': 'doctor',
            'email': 'sharma@example.com'
        }
    )
    doc_user.set_password('password123')
    doc_user.save()

    Doctor.objects.get_or_create(
        user=doc_user,
        defaults={
            'specialization': 'Senior Cardiologist',
            'qualification': 'MBBS, MD',
            'experience_years': 12,
            'bio': 'Expert in heart surgeries and preventive care.'
        }
    )

    doc_user2, _ = User.objects.get_or_create(
        username='dr_priya',
        defaults={
            'first_name': 'Priya',
            'last_name': 'Verma',
            'role': 'doctor',
            'email': 'priya@example.com'
        }
    )
    doc_user2.set_password('password123')
    doc_user2.save()

    Doctor.objects.get_or_create(
        user=doc_user2,
        defaults={
            'specialization': 'Physician',
            'qualification': 'MBBS',
            'experience_years': 8,
            'bio': 'General physician with focus on rural health.'
        }
    )

    # 2. Create a test patient for the "admin" or current user
    test_user = User.objects.filter(is_superuser=True).first()
    if test_user:
        patient, _ = Patient.objects.get_or_create(
            user=test_user,
            defaults={'age': 30, 'gender': 'Male', 'address': 'Main St, Village'}
        )

        # 3. Add medicines
        medicines = [
            {'name': 'Paracetamol', 'dosage': '1 Tablet', 'instructions': 'Take after food'},
            {'name': 'Insulin Dose', 'dosage': '5 Units', 'instructions': 'Inject before breakfast'},
            {'name': 'Vitamin C', 'dosage': '1 Tablet', 'instructions': 'Once daily'},
        ]

        for med in medicines:
            MedicineSchedule.objects.get_or_create(
                patient=patient,
                medicine_name=med['name'],
                defaults={
                    'dosage': med['dosage'],
                    'instructions': med['instructions'],
                    'frequency': 'Daily'
                }
            )

    print("Data seeding completed!")

if __name__ == '__main__':
    seed_data()
