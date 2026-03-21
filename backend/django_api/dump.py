import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.users.models import User

for u in User.objects.all():
    print(f"{u.username} | pass123: {u.check_password('password123')} | role: {u.role} | phone: {u.phone_number}")
