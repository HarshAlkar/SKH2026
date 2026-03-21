import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()
from apps.users.models import User
from django.db.models import Count

print("=== Users in DB ===")
users = User.objects.values('phone_number').annotate(count=Count('id')).filter(count__gt=1)
for u in users:
    phone = u['phone_number']
    print(f"Duplicate phone: {phone}")
    dupes = User.objects.filter(phone_number=phone)
    for d in dupes:
        print(f"  ID: {d.id}, Username: {d.username}, Role: {d.role}")

# List all users
for u in User.objects.all():
    print(f"User: {u.id}, Username: {u.username}, Phone: {u.phone_number}, Role: {u.role}")
