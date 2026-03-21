import os
import django
import random
import string

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'django_api.settings')
django.setup()

from apps.users.models import User

def generate_abha_id():
    return ''.join(random.choices(string.digits, k=14))

def populate():
    users = User.objects.filter(abha_id__isnull=True) | User.objects.filter(abha_id='')
    print(f"Found {users.count()} users without ABHA ID.")
    
    count = 0
    for user in users:
        while True:
            new_id = generate_abha_id()
            if not User.objects.filter(abha_id=new_id).exists():
                user.abha_id = new_id
                user.save()
                count += 1
                break
    
    print(f"Successfully assigned ABHA IDs to {count} users.")

if __name__ == '__main__':
    populate()
