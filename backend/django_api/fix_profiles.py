import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.users.models import User
from apps.doctors.models import Doctor
from apps.patients.models import Patient
from apps.asha_workers.models import ASHAWorker

def fix_profiles():
    users = User.objects.all()
    for user in users:
        if user.role == 'doctor':
            if not hasattr(user, 'doctor_profile'):
                print(f"Adding doctor profile for {user.username}")
                Doctor.objects.create(
                    user=user,
                    specialization="General",
                    experience_years=0,
                    hospital_name="General Hospital"
                )
        elif user.role == 'user':
            if not hasattr(user, 'patient_profile'):
                print(f"Adding patient profile for {user.username}")
                Patient.objects.create(
                    user=user,
                    age=0,
                    gender="Not Set",
                    address=user.village or "Not Set"
                )
        elif user.role == 'asha_worker':
            if not hasattr(user, 'asha_profile'):
                print(f"Adding ASHA profile for {user.username}")
                ASHAWorker.objects.create(
                    user=user,
                    assigned_village=user.village or "Local Village",
                    phc_center="Local PHC"
                )

if __name__ == "__main__":
    fix_profiles()
    print("Done!")
