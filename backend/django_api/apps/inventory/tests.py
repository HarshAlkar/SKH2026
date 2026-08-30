from datetime import timedelta

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from apps.asha_workers.models import ASHAWorker
from apps.inventory.models import HealthcareFacility, MedicineCatalog, StockBatch
from apps.inventory.views import _place_needles, user_facility_ids
from apps.users.models import User


class AshaStockScopeTests(TestCase):
    def setUp(self):
        self.phc = HealthcareFacility.objects.create(
            name='Rampur Primary Health Centre',
            facility_type='phc',
            village='Rampur',
            district='Nashik',
            is_active=True,
        )
        self.catalog = MedicineCatalog.objects.create(
            sku='PARA-500',
            name='Paracetamol',
            strength='500mg',
        )
        StockBatch.objects.create(
            facility=self.phc,
            catalog=self.catalog,
            batch_no='PHC-PARA-01',
            quantity=40,
            expiry_date=timezone.localdate() + timedelta(days=200),
        )
        self.user = User.objects.create_user(
            username='8888888880',
            password='password123',
            role='asha_worker',
            village='Rampur Village',
            phone_number='8888888880',
        )
        ASHAWorker.objects.create(
            user=self.user,
            assigned_village='Rampur Village',
            phc_center='Rampur PHC',
            verification_status='VERIFIED',
        )

    def test_place_needles_strips_village_suffix(self):
        needles = [n.lower() for n in _place_needles('Rampur Village', 'Rampur PHC')]
        self.assertIn('rampur', needles)

    def test_asha_sees_phc_stock_despite_village_suffix(self):
        ids = user_facility_ids(self.user)
        self.assertIn(self.phc.id, ids)

    def test_asha_can_list_and_adjust_batches(self):
        client = APIClient()
        client.force_authenticate(user=self.user)
        listed = client.get('/api/stock/batches/')
        self.assertEqual(listed.status_code, 200)
        rows = listed.json()
        if isinstance(rows, dict):
            rows = rows.get('results', [])
        self.assertTrue(rows)

        batch_id = rows[0]['id']
        adjust = client.post(
            '/api/stock/adjust/',
            {
                'batch_id': batch_id,
                'action': 'add',
                'quantity': 10,
                'client_id': 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
                'reason': 'New Delivery Received',
            },
            format='json',
        )
        self.assertIn(adjust.status_code, (200, 201), adjust.content)
        self.assertEqual(adjust.json()['batch']['quantity'], 50)

    def test_pharmacist_can_create_new_batch(self):
        from apps.inventory.models import MedicalStaffProfile

        pharma = User.objects.create_user(
            username='pharmacist',
            password='pharma123',
            role='medical_staff',
            name='Dr. Sarah Jenkins',
        )
        MedicalStaffProfile.objects.create(user=pharma, facility=self.phc, designation='Pharmacist')
        client = APIClient()
        client.force_authenticate(user=pharma)
        listed = client.get('/api/stock/catalog/?active=1')
        self.assertEqual(listed.status_code, 200)
        rows = listed.json()
        if isinstance(rows, dict):
            rows = rows.get('results', [])
        self.assertTrue(rows)

        created = client.post(
            '/api/stock/adjust/',
            {
                'facility_id': self.phc.id,
                'catalog_id': self.catalog.id,
                'batch_no': 'BAT-NEW-01',
                'expiry_date': (timezone.localdate() + timedelta(days=365)).isoformat(),
                'action': 'add',
                'quantity': 50,
                'client_id': 'bbbbbbbb-bbbb-4ccc-8ddd-eeeeeeeeeeee',
                'reason': 'New Delivery Received',
            },
            format='json',
        )
        self.assertIn(created.status_code, (200, 201), created.content)
        self.assertEqual(created.json()['batch']['quantity'], 50)
