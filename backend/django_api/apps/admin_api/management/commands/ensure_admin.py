from django.core.management.base import BaseCommand
from rest_framework.authtoken.models import Token

from apps.users.models import User


class Command(BaseCommand):
    help = 'Create a default staff admin if none exists (admin / admin123).'

    def handle(self, *args, **options):
        existing = User.objects.filter(is_staff=True).first()
        if existing:
            Token.objects.get_or_create(user=existing)
            self.stdout.write(self.style.SUCCESS(
                f'Staff user already exists: {existing.username}'
            ))
            return

        user = User.objects.create_superuser(
            username='admin',
            email='admin@vitalreach.local',
            password='admin123',
            name='VitalReach Admin',
            phone_number='9999999999',
            role='user',
        )
        user.is_staff = True
        user.is_superuser = True
        user.save()
        Token.objects.get_or_create(user=user)
        self.stdout.write(self.style.SUCCESS(
            'Created staff admin  username=admin  password=admin123'
        ))
