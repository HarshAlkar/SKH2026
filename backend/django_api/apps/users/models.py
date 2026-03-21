from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone

import random
import string

def generate_abha_id():
    """Generates a unique 14-digit ABHA ID in the format: 1234-5678-9012-34."""
    digits = ''.join(random.choices(string.digits, k=14))
    return f"{digits[:4]}-{digits[4:8]}-{digits[8:12]}-{digits[12:]}"

class User(AbstractUser):
    ROLE_CHOICES = (
        ('user', 'User'),
        ('doctor', 'Doctor'),
        ('asha_worker', 'ASHA Worker'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='user')
    phone_number = models.CharField(max_length=15, blank=True, null=True)
    village = models.CharField(max_length=100, blank=True, null=True)
    name = models.CharField(max_length=255, blank=True, null=True)
    abha_id = models.CharField(max_length=20, unique=True, null=True, blank=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.abha_id:
            while True:
                new_id = generate_abha_id()
                if not User.objects.filter(abha_id=new_id).exists():
                    self.abha_id = new_id
                    break
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.name or self.username} ({self.role})"

class OTPVerification(models.Model):
    phone_number = models.CharField(max_length=15)
    otp_code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    expiry_time = models.DateTimeField()
    is_verified = models.BooleanField(default=False)

    def is_expired(self):
        return timezone.now() > self.expiry_time

    def __str__(self):
        return f"OTP for {self.phone_number}: {self.otp_code} (Verified: {self.is_verified})"
