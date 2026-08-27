import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone


class HealthcareFacility(models.Model):
    TYPE_CHOICES = (
        ('pharmacy', 'Pharmacy'),
        ('phc', 'PHC'),
        ('hospital', 'Hospital'),
    )

    name = models.CharField(max_length=255)
    facility_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='pharmacy')
    village = models.CharField(max_length=100, blank=True, default='')
    district = models.CharField(max_length=100, blank=True, default='')
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']
        verbose_name_plural = 'Healthcare facilities'

    def __str__(self):
        return f'{self.name} ({self.get_facility_type_display()})'


class MedicalStaffProfile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        related_name='medical_staff_profile',
        on_delete=models.CASCADE,
    )
    facility = models.ForeignKey(
        HealthcareFacility,
        related_name='staff',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    designation = models.CharField(max_length=100, blank=True, default='Pharmacist')

    def __str__(self):
        return f'Medical Staff: {self.user.name or self.user.username}'


class MedicineCatalog(models.Model):
    sku = models.CharField(max_length=64, unique=True)
    name = models.CharField(max_length=255)
    form = models.CharField(max_length=80, blank=True, default='')  # tablet, syrup, etc.
    strength = models.CharField(max_length=80, blank=True, default='')
    category = models.CharField(max_length=100, blank=True, default='General')
    unit = models.CharField(max_length=40, blank=True, default='units')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        parts = [self.name]
        if self.strength:
            parts.append(self.strength)
        return ' '.join(parts)

    @property
    def display_name(self):
        return str(self)


class Supplier(models.Model):
    name = models.CharField(max_length=255)
    contact = models.CharField(max_length=120, blank=True, default='')
    notes = models.TextField(blank=True, default='')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name


class StockBatch(models.Model):
    facility = models.ForeignKey(
        HealthcareFacility,
        related_name='batches',
        on_delete=models.CASCADE,
    )
    catalog = models.ForeignKey(
        MedicineCatalog,
        related_name='batches',
        on_delete=models.CASCADE,
    )
    batch_no = models.CharField(max_length=64)
    quantity = models.PositiveIntegerField(default=0)
    expiry_date = models.DateField()
    reorder_level = models.PositiveIntegerField(default=20)
    supplier = models.ForeignKey(
        Supplier,
        related_name='batches',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    updated_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['expiry_date', 'catalog__name']
        unique_together = [('facility', 'catalog', 'batch_no')]
        verbose_name_plural = 'Stock batches'

    def __str__(self):
        return f'{self.catalog} [{self.batch_no}] @ {self.facility.name}'

    @property
    def days_to_expiry(self):
        return (self.expiry_date - timezone.localdate()).days

    @property
    def status(self):
        if self.quantity <= 0:
            return 'out_of_stock'
        if self.days_to_expiry < 0:
            return 'expired'
        if self.days_to_expiry <= 30:
            return 'expiring'
        if self.quantity <= self.reorder_level:
            return 'low_stock'
        return 'in_stock'


class StockMovement(models.Model):
    ACTION_CHOICES = (
        ('add', 'Add Stock'),
        ('remove', 'Remove Stock'),
        ('adjust', 'Adjust'),
        ('disposal', 'Disposal'),
        ('return', 'Return to Supplier'),
    )

    batch = models.ForeignKey(
        StockBatch,
        related_name='movements',
        on_delete=models.CASCADE,
    )
    action = models.CharField(max_length=20, choices=ACTION_CHOICES)
    quantity = models.PositiveIntegerField()
    previous_quantity = models.PositiveIntegerField(default=0)
    new_quantity = models.PositiveIntegerField(default=0)
    reason = models.CharField(max_length=255, blank=True, default='')
    invoice_no = models.CharField(max_length=80, blank=True, default='')
    notes = models.TextField(blank=True, default='')
    supplier_name = models.CharField(max_length=255, blank=True, default='')
    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name='stock_movements',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    client_id = models.UUIDField(default=uuid.uuid4, unique=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.action} {self.quantity} on {self.batch_id}'
