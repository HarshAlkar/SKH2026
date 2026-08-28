from django.core.management.base import BaseCommand

from apps.asha_workers.models import ASHAWorker
from apps.doctors.models import Doctor
from apps.patients.models import Patient
from apps.users.models import User


class Command(BaseCommand):
    help = 'Seed demo patients, doctors, and ASHA workers (idempotent, safe on redeploy).'

    def handle(self, *args, **options):
        users_data = [
            {'name': 'Ramesh Patil', 'village': 'Pune', 'phone': '9876543210', 'email': 'ramesh@example.com'},
            {'name': 'Sita Sharma', 'village': 'Nagpur', 'phone': '9876543211', 'email': 'sita@example.com'},
            {'name': 'Amit Kumar', 'village': 'Delhi', 'phone': '9876543212', 'email': 'amit@example.com'},
            {'name': 'Priya Deshmukh', 'village': 'Mumbai', 'phone': '9876543213', 'email': 'priya@example.com'},
        ]

        for data in users_data:
            user, created = User.objects.get_or_create(
                phone_number=data['phone'],
                defaults={
                    'username': data['phone'],
                    'name': data['name'],
                    'village': data['village'],
                    'email': data['email'],
                    'role': 'user',
                },
            )
            if created:
                user.set_password('password123')
                user.save()
                self.stdout.write(self.style.SUCCESS(f'Created patient: {data["name"]}'))
            Patient.objects.get_or_create(
                user=user,
                defaults={
                    'age': 0,
                    'gender': 'Not Set',
                    'address': data['village'],
                },
            )

        doctors_data = [
            {'name': 'Rajesh Sharma', 'specialization': 'General Physician', 'phone': '9999999990', 'exp': 10, 'hospital': 'Apollo Hospital'},
            {'name': 'Anjali Verma', 'specialization': 'Dermatologist', 'phone': '9999999991', 'exp': 8, 'hospital': 'Max Healthcare'},
            {'name': 'Vivek Patel', 'specialization': 'Cardiologist', 'phone': '9999999992', 'exp': 15, 'hospital': 'Fortis Hospital'},
        ]

        for data in doctors_data:
            user, created = User.objects.get_or_create(
                phone_number=data['phone'],
                defaults={
                    'username': data['phone'],
                    'name': data['name'],
                    'role': 'doctor',
                    'email': f"{data['name'].lower().replace(' ', '.')}@example.com",
                },
            )
            if created:
                user.set_password('password123')
                user.save()
                self.stdout.write(self.style.SUCCESS(f'Created doctor: {data["name"]}'))
            Doctor.objects.get_or_create(
                user=user,
                defaults={
                    'specialization': data['specialization'],
                    'experience_years': data['exp'],
                    'hospital_name': data['hospital'],
                },
            )

        asha_data = [
            {'name': 'Sunita Devi', 'village': 'Rampur Village', 'phone': '8888888880', 'phc': 'Rampur PHC'},
            {'name': 'Lata Patil', 'village': 'Kaman Village', 'phone': '8888888881', 'phc': 'Kaman PHC'},
        ]

        for data in asha_data:
            user, created = User.objects.get_or_create(
                phone_number=data['phone'],
                defaults={
                    'username': data['phone'],
                    'name': data['name'],
                    'village': data['village'],
                    'role': 'asha_worker',
                    'email': f"{data['name'].lower().replace(' ', '.')}@example.com",
                },
            )
            if created:
                user.set_password('password123')
                user.save()
                self.stdout.write(self.style.SUCCESS(f'Created ASHA worker: {data["name"]}'))
            ASHAWorker.objects.get_or_create(
                user=user,
                defaults={
                    'assigned_village': data['village'],
                    'phc_center': data['phc'],
                },
            )

        self.stdout.write(self.style.SUCCESS('Demo users ready (password123 for all).'))
