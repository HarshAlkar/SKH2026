from django.contrib.auth import get_user_model
from rest_framework.authtoken.models import Token
from rest_framework.test import APIClient, APITestCase

from apps.asha_workers.models import ASHAWorker
from apps.doctors.models import Doctor
from apps.inventory.models import HealthcareFacility, MedicalStaffProfile
from apps.patients.models import Patient

User = get_user_model()


class AdminSetPasswordTests(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin = User.objects.create_user(
            username='admin_pw',
            password='AdminPass1!',
            role='user',
            phone_number='9000000099',
            name='Staff Admin',
            is_staff=True,
            is_superuser=True,
        )
        self.admin_token = Token.objects.create(user=self.admin)
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.admin_token.key}')

        self.patient_user = User.objects.create_user(
            username='9000000001',
            password='OldPass12',
            role='user',
            phone_number='9000000001',
            name='Patient One',
            village='Rampur',
        )
        self.patient = Patient.objects.create(user=self.patient_user, age=30)

        self.doctor_user = User.objects.create_user(
            username='9000000002',
            password='OldPass12',
            role='doctor',
            phone_number='9000000002',
            name='Doctor One',
        )
        self.doctor = Doctor.objects.create(
            user=self.doctor_user,
            specialization='General',
            experience_years=1,
            hospital_name='General Hospital',
        )

        self.asha_user = User.objects.create_user(
            username='9000000003',
            password='OldPass12',
            role='asha_worker',
            phone_number='9000000003',
            name='ASHA One',
        )
        self.asha = ASHAWorker.objects.create(
            user=self.asha_user,
            assigned_village='Rampur',
            phc_center='Local PHC',
        )

        self.staff_user = User.objects.create_user(
            username='9000000004',
            password='OldPass12',
            role='medical_staff',
            phone_number='9000000004',
            name='Pharmacist One',
        )
        facility = HealthcareFacility.objects.create(name='Rampur PHC', facility_type='phc', village='Rampur')
        MedicalStaffProfile.objects.create(user=self.staff_user, facility=facility, designation='Pharmacist')
        self.old_patient_token = Token.objects.create(user=self.patient_user)

    def test_staff_can_reset_patient_password(self):
        res = self.client.post(
            f'/api/admin/patients/{self.patient.id}/set-password/',
            {'new_password': 'NewPass99'},
            format='json',
        )
        self.assertEqual(res.status_code, 200)
        self.patient_user.refresh_from_db()
        self.assertTrue(self.patient_user.check_password('NewPass99'))
        self.assertFalse(Token.objects.filter(key=self.old_patient_token.key).exists())

    def test_staff_can_reset_doctor_password(self):
        res = self.client.post(
            f'/api/admin/doctors/{self.doctor.id}/set-password/',
            {'new_password': 'NewPass99'},
            format='json',
        )
        self.assertEqual(res.status_code, 200)
        self.doctor_user.refresh_from_db()
        self.assertTrue(self.doctor_user.check_password('NewPass99'))

    def test_staff_can_reset_asha_password(self):
        res = self.client.post(
            f'/api/admin/asha-workers/{self.asha.id}/set-password/',
            {'new_password': 'NewPass99'},
            format='json',
        )
        self.assertEqual(res.status_code, 200)
        self.asha_user.refresh_from_db()
        self.assertTrue(self.asha_user.check_password('NewPass99'))

    def test_staff_can_reset_medical_staff_password(self):
        res = self.client.post(
            f'/api/admin/users/{self.staff_user.id}/set-password/',
            {'password': 'NewPass99'},
            format='json',
        )
        self.assertEqual(res.status_code, 200)
        self.staff_user.refresh_from_db()
        self.assertTrue(self.staff_user.check_password('NewPass99'))

    def test_short_password_rejected(self):
        res = self.client.post(
            f'/api/admin/users/{self.patient_user.id}/set-password/',
            {'new_password': 'short'},
            format='json',
        )
        self.assertEqual(res.status_code, 400)

    def test_non_staff_blocked(self):
        other = APIClient()
        other.credentials(HTTP_AUTHORIZATION=f'Token {self.old_patient_token.key}')
        res = other.post(
            f'/api/admin/users/{self.doctor_user.id}/set-password/',
            {'new_password': 'NewPass99'},
            format='json',
        )
        self.assertIn(res.status_code, (401, 403))
        self.doctor_user.refresh_from_db()
        self.assertTrue(self.doctor_user.check_password('OldPass12'))

    def test_non_superuser_cannot_change_superuser_password(self):
        limited = User.objects.create_user(
            username='limited_admin',
            password='AdminPass1!',
            role='user',
            phone_number='9000000098',
            name='Limited Staff',
            is_staff=True,
            is_superuser=False,
        )
        token = Token.objects.create(user=limited)
        client = APIClient()
        client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')
        res = client.post(
            f'/api/admin/users/{self.admin.id}/set-password/',
            {'new_password': 'HackedPass1'},
            format='json',
        )
        self.assertEqual(res.status_code, 403)
        self.admin.refresh_from_db()
        self.assertTrue(self.admin.check_password('AdminPass1!'))


class AdminAshaPatientAssignmentTests(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin = User.objects.create_user(
            username='admin_assign',
            password='AdminPass1!',
            role='user',
            phone_number='9000000088',
            name='Staff Admin',
            is_staff=True,
            is_superuser=True,
        )
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {Token.objects.create(user=self.admin).key}')

        self.asha_user = User.objects.create_user(
            username='9000000081',
            password='OldPass12',
            role='asha_worker',
            phone_number='9000000081',
            name='ASHA One',
            village='Rampur',
        )
        self.asha = ASHAWorker.objects.create(
            user=self.asha_user,
            assigned_village='Rampur',
            phc_center='Local PHC',
        )
        self.patient_user = User.objects.create_user(
            username='9000000082',
            password='OldPass12',
            role='user',
            phone_number='9000000082',
            name='Patient Two',
            village='Other Village',
        )
        self.patient = Patient.objects.create(user=self.patient_user, age=28)

    def test_admin_can_assign_patient_under_asha(self):
        res = self.client.patch(
            f'/api/admin/patients/{self.patient.id}/',
            {'assigned_asha': self.asha.id},
            format='json',
        )
        self.assertEqual(res.status_code, 200)
        self.patient.refresh_from_db()
        self.patient_user.refresh_from_db()
        self.assertEqual(self.patient.assigned_asha_id, self.asha.id)
        self.assertEqual(self.patient_user.village, 'Rampur')
        self.assertEqual(res.data.get('assigned_asha_name'), 'ASHA One')

    def test_asha_roster_endpoint_and_sync_on_village_change(self):
        assign = self.client.post(
            f'/api/admin/asha-workers/{self.asha.id}/assign-patients/',
            {'patient_ids': [self.patient.id]},
            format='json',
        )
        self.assertEqual(assign.status_code, 200)
        roster = self.client.get(f'/api/admin/asha-workers/{self.asha.id}/patients/')
        self.assertEqual(roster.status_code, 200)
        self.assertEqual(len(roster.data), 1)
        self.assertEqual(roster.data[0]['id'], self.patient.id)

        res = self.client.patch(
            f'/api/admin/asha-workers/{self.asha.id}/',
            {'assigned_village': 'Sundarpur'},
            format='json',
        )
        self.assertEqual(res.status_code, 200)
        self.patient_user.refresh_from_db()
        self.assertEqual(self.patient_user.village, 'Sundarpur')

