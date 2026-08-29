from django.db import models
from django.conf import settings


def asha_village(asha):
    if asha is None:
        return ''
    return (asha.assigned_village or getattr(getattr(asha, 'user', None), 'village', None) or '').strip()


def sync_patient_village_to_asha(patient, asha=None):
    """Keep the patient village aligned with the assigned ASHA worker."""
    asha = asha if asha is not None else getattr(patient, 'assigned_asha', None)
    village = asha_village(asha)
    if not village:
        return
    user = patient.user
    if user.village != village:
        user.village = village
        user.save(update_fields=['village'])


def assign_patient_to_asha(patient, asha):
    patient.assigned_asha = asha
    patient.save(update_fields=['assigned_asha'])
    if asha:
        sync_patient_village_to_asha(patient, asha)
    return patient


def sync_assigned_patients_village(asha):
    """When an ASHA village changes, move their assigned patients with them."""
    from apps.users.models import User

    village = asha_village(asha)
    if not village:
        return 0
    return User.objects.filter(
        patient_profile__assigned_asha=asha,
    ).exclude(village=village).update(village=village)


class Patient(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, related_name='patient_profile', on_delete=models.CASCADE)
    age = models.IntegerField()
    gender = models.CharField(max_length=10)
    blood_group = models.CharField(max_length=5, blank=True)
    address = models.TextField()
    medical_history = models.TextField(blank=True)
    assigned_asha = models.ForeignKey(
        'asha_workers.ASHAWorker',
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='assigned_patients',
    )

    def __str__(self):
        return f"Patient: {self.user.username}"
