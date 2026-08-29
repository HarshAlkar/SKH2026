from django.conf import settings
from django.db import models


class LivestockCase(models.Model):
    SPECIES_CHOICES = (
        ('CATTLE', 'Cattle'),
        ('BUFFALO', 'Buffalo'),
        ('GOAT', 'Goat'),
        ('SHEEP', 'Sheep'),
        ('POULTRY', 'Poultry'),
        ('OTHER', 'Other'),
    )

    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='livestock_cases',
    )
    name = models.CharField(max_length=120, blank=True)
    species = models.CharField(max_length=20, choices=SPECIES_CHOICES, default='CATTLE')
    age_months = models.PositiveIntegerField(null=True, blank=True)
    village = models.CharField(max_length=120, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        label = self.name or self.species
        return f"{label} ({self.owner_id})"


class ScreeningEvent(models.Model):
    DOMAIN_CHOICES = (
        ('HUMAN', 'Human'),
        ('ANIMAL', 'Animal'),
    )

    domain = models.CharField(max_length=10, choices=DOMAIN_CHOICES, default='HUMAN')
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='screening_events',
    )
    livestock_case = models.ForeignKey(
        LivestockCase,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='screenings',
    )
    input_type = models.CharField(max_length=20, default='symptoms')  # symptoms | image | growth
    input_text = models.TextField(blank=True)
    possible_condition = models.CharField(max_length=160, blank=True)
    severity_level = models.CharField(max_length=20, default='Low')
    confidence = models.FloatField(default=0.0)
    advice = models.TextField(blank=True)
    result_json = models.JSONField(default=dict, blank=True)
    client_id = models.CharField(max_length=64, blank=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.domain} {self.possible_condition} ({self.severity_level})"
