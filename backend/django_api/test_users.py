import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.users.models import User

def list_users():
    users = User.objects.all()
    print(f"Total users: {users.count()}")
    for user in users:
        print(f"User: {user.username}, Role: {user.role}, ABHA ID: {user.abha_id}")

if __name__ == "__main__":
    list_users()
