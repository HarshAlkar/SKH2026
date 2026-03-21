import os
import django
import sys
from datetime import date, time

# Set up Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.asha_workers.models import VillageVisit, ASHAWorker
from apps.patients.models import Patient

def seed_visits():
    try:
        asha = ASHAWorker.objects.first()
        patients = Patient.objects.all()[:5]

        if not asha:
            print("No ASHA Worker found. Run seed_auth_data.py first.")
            return

        if not patients:
            print("No Patients found. Run seed_data.py first.")
            return

        print(f"Seeding visits for ASHA: {asha.user.username}...")

        visits_data = [
            {'patient': patients[0], 'visit_date': date.today(), 'visit_time': time(10, 30), 'status': 'PENDING', 'notes': 'Routine checkup'},
            {'patient': patients[1], 'visit_date': date.today(), 'visit_time': time(11, 45), 'status': 'COMPLETED', 'notes': 'Followup'},
            {'patient': patients[2], 'visit_date': date.today(), 'visit_time': time(13, 15), 'status': 'PENDING', 'notes': 'Fever monitor'},
            {'patient': patients[3], 'visit_date': date.today(), 'visit_time': time(14, 30), 'status': 'MISSED', 'notes': 'Patient not home'},
            {'patient': patients[4], 'visit_date': date.today(), 'visit_time': time(16, 0), 'status': 'PENDING', 'notes': 'Blood pressure check'},
        ]

        VillageVisit.objects.all().delete()
        
        for data in visits_data:
            VillageVisit.objects.create(
                asha_worker=asha,
                patient=data['patient'],
                visit_date=data['visit_date'],
                visit_time=data['visit_time'],
                status=data['status'],
                notes=data['notes']
            )

        print("Successfully seeded Village Visits!")
    except Exception as e:
        print(f"Error seeding visits: {e}")

if __name__ == '__main__':
    seed_visits()
