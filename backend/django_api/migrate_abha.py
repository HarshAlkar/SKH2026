import os
import django
import random

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.users.models import User

def generate_abha_id():
    # Generate 14-digit random number
    digits = "".join([str(random.randint(0, 9)) for _ in range(14)])
    # Format: XXXX-XXXX-XXXX-XX
    formatted = f"{digits[0:4]}-{digits[4:8]}-{digits[8:12]}-{digits[12:14]}"
    return formatted

def migrate_users():
    users = User.objects.filter(abha_id__isnull=True)
    count = 0
    for user in users:
        user.abha_id = generate_abha_id()
        user.save()
        count += 1
        print(f"Assigned ABHA ID to user: {user.username}")
    print(f"Successfully migrated {count} users.")

if __name__ == "__main__":
    migrate_users()
