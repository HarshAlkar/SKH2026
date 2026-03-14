import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gramin_health_backend.settings')
django.setup()

from asha_worker.models import AshaWorker
if not AshaWorker.objects.filter(phone_number='1234567890').exists():
    AshaWorker.objects.create_superuser(phone_number='1234567890', password='password123', name='Test ASHA', worker_id='ASHA001')
    print('User created successfully')
else:
    print('User already exists')
