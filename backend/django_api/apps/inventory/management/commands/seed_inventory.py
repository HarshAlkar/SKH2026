from datetime import timedelta
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone

from apps.inventory.models import (
    HealthcareFacility,
    MedicalStaffProfile,
    MedicineCatalog,
    Supplier,
    StockBatch,
)
from apps.asha_workers.models import ASHAWorker

User = get_user_model()


class Command(BaseCommand):
    help = 'Seed demo healthcare facilities, catalog, batches, and pharmacist user'

    def handle(self, *args, **options):
        phc, _ = HealthcareFacility.objects.get_or_create(
            name='Rampur Primary Health Centre',
            defaults={
                'facility_type': 'phc',
                'village': 'Rampur',
                'district': 'Nashik',
                'latitude': 19.9975,
                'longitude': 73.7898,
                'is_active': True,
            },
        )
        pharmacy, _ = HealthcareFacility.objects.get_or_create(
            name='City General Pharmacy',
            defaults={
                'facility_type': 'pharmacy',
                'village': 'Rampur',
                'district': 'Nashik',
                'latitude': 20.0050,
                'longitude': 73.7800,
                'is_active': True,
            },
        )

        supplier, _ = Supplier.objects.get_or_create(
            name='McKesson Corp',
            defaults={'contact': '+91-9876500001', 'notes': 'Primary wholesale supplier'},
        )

        catalog_items = [
            ('PARA-500', 'Paracetamol', 'Tablet', '500mg', 'Analgesic'),
            ('AMOX-250', 'Amoxicillin', 'Capsule', '250mg', 'Antibiotic'),
            ('AMOX-500', 'Amoxicillin', 'Capsule', '500mg', 'Antibiotic'),
            ('METF-500', 'Metformin', 'Tablet', '500mg', 'Diabetes'),
            ('AZITH-250', 'Azithromycin', 'Tablet', '250mg', 'Antibiotic'),
            ('IBU-400', 'Ibuprofen', 'Tablet', '400mg', 'Analgesic'),
            ('IBU-SYR', 'Ibuprofen Syrup', 'Syrup', '100mg/5ml', 'Analgesic'),
            ('CET-10', 'Cetirizine', 'Tablet', '10mg', 'Antihistamine'),
        ]
        catalogs = []
        for sku, name, form, strength, category in catalog_items:
            c, _ = MedicineCatalog.objects.get_or_create(
                sku=sku,
                defaults={
                    'name': name,
                    'form': form,
                    'strength': strength,
                    'category': category,
                    'unit': 'units',
                },
            )
            catalogs.append(c)

        today = timezone.localdate()
        seed_batches = [
            (pharmacy, catalogs[0], 'BAT-2024-001', 150, today + timedelta(days=400), 30),
            (pharmacy, catalogs[1], 'BAT-2023-8941', 12, today + timedelta(days=12), 40),
            (pharmacy, catalogs[3], 'BAT-2024-MET', 12, today + timedelta(days=200), 50),
            (pharmacy, catalogs[4], 'BAT-AZ-01', 18, today + timedelta(days=180), 25),
            (pharmacy, catalogs[5], 'BAT-IBU-01', 80, today + timedelta(days=25), 20),
            (pharmacy, catalogs[6], 'BAT-IBU-SYR', 5, today - timedelta(days=5), 10),
            (pharmacy, catalogs[7], 'BAT-CET-01', 0, today + timedelta(days=300), 15),
            (phc, catalogs[0], 'PHC-PARA-01', 200, today + timedelta(days=365), 40),
            (phc, catalogs[2], 'PHC-AMOX-01', 40, today + timedelta(days=90), 30),
            (phc, catalogs[3], 'PHC-MET-01', 60, today + timedelta(days=200), 25),
        ]
        for facility, catalog, batch_no, qty, expiry, reorder in seed_batches:
            StockBatch.objects.update_or_create(
                facility=facility,
                catalog=catalog,
                batch_no=batch_no,
                defaults={
                    'quantity': qty,
                    'expiry_date': expiry,
                    'reorder_level': reorder,
                    'supplier': supplier,
                },
            )

        pharma_user, created = User.objects.get_or_create(
            username='pharmacist',
            defaults={
                'role': 'medical_staff',
                'name': 'Dr. Sarah Jenkins',
                'email': 'pharmacist@vitalreach.local',
                'village': 'Rampur',
                'phone_number': '9000000099',
            },
        )
        if not created and not pharma_user.phone_number:
            pharma_user.phone_number = '9000000099'
        pharma_user.set_password('pharma123')
        pharma_user.role = 'medical_staff'
        pharma_user.name = pharma_user.name or 'Dr. Sarah Jenkins'
        pharma_user.save()
        MedicalStaffProfile.objects.update_or_create(
            user=pharma_user,
            defaults={'facility': pharmacy, 'designation': 'Chief Pharmacist'},
        )

        kaman, _ = HealthcareFacility.objects.get_or_create(
            name='Kaman Primary Health Centre',
            defaults={
                'facility_type': 'phc',
                'village': 'Kaman',
                'district': 'Nashik',
                'latitude': 19.3900,
                'longitude': 72.9100,
                'is_active': True,
            },
        )
        StockBatch.objects.update_or_create(
            facility=kaman,
            catalog=catalogs[0],
            batch_no='KAM-PARA-01',
            defaults={
                'quantity': 80,
                'expiry_date': today + timedelta(days=300),
                'reorder_level': 20,
                'supplier': supplier,
            },
        )

        # Link existing ASHA workers to a nearby PHC
        for asha in ASHAWorker.objects.select_related('user').all():
            village = (asha.assigned_village or '').lower()
            if not asha.assigned_village:
                asha.assigned_village = 'Rampur'
                asha.phc_center = phc.name
                asha.district = 'Nashik'
                asha.save()
            elif 'kaman' in village:
                asha.phc_center = asha.phc_center or kaman.name
                asha.district = asha.district or 'Nashik'
                asha.save()
            else:
                asha.phc_center = asha.phc_center or phc.name
                asha.district = asha.district or 'Nashik'
                asha.save()

        self.stdout.write(self.style.SUCCESS(
            f'Seeded inventory: PHC={phc.id}, Pharmacy={pharmacy.id}, '
            f'catalog={len(catalogs)}, pharmacist={"created" if created else "updated"}'
        ))
