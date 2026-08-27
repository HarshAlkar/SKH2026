from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone


class User(AbstractUser):
    ROLE_CHOICES = (
        ('user', 'User'),
        ('doctor', 'Doctor'),
        ('asha_worker', 'ASHA Worker'),
        ('medical_staff', 'Medical Staff'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='user')
    phone_number = models.CharField(max_length=15, blank=True, null=True, unique=True)
    village = models.CharField(max_length=100, blank=True, null=True)
    name = models.CharField(max_length=255, blank=True, null=True)
    photo = models.ImageField(upload_to='profiles/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

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
