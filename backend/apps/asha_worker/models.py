from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin

class AshaWorkerManager(BaseUserManager):
    def create_user(self, phone_number, password=None, **extra_fields):
        if not phone_number:
            raise ValueError('The phone number must be set')
        user = self.model(phone_number=phone_number, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, phone_number, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(phone_number, password, **extra_fields)

class AshaWorker(AbstractBaseUser, PermissionsMixin):
    name = models.CharField(max_length=255)
    worker_id = models.CharField(max_length=50, unique=True)
    phone_number = models.CharField(max_length=15, unique=True)
    district = models.CharField(max_length=100)
    village = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    objects = AshaWorkerManager()

    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = ['name', 'worker_id']

    def __str__(self):
        return f"{self.name} ({self.worker_id})"
