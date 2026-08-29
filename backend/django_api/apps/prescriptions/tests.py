"""Handwritten prescription upload — authz, validation, audit tests."""

from io import BytesIO

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from django.utils import timezone
from PIL import Image
from rest_framework.authtoken.models import Token
from rest_framework.test import APIClient

from apps.consultations.models import Appointment
from apps.doctors.models import Doctor
from apps.patients.models import Patient
from apps.prescriptions.models import Prescription
from apps.security_audit.models import SecurityAuditLog

User = get_user_model()


def _png_file(name='rx.png', size=(64, 64)):
    buf = BytesIO()
    Image.new('RGB', size, color=(200, 180, 160)).save(buf, format='PNG')
    return SimpleUploadedFile(name, buf.getvalue(), content_type='image/png')


@override_settings()
class HandwrittenPrescriptionTests(TestCase):
    def setUp(self):
        self.client = APIClient()

        self.patient_user_a = User.objects.create_user(
            username='rx_patient_a', password='SecurePass1!', role='user',
            phone_number='9100000001', name='Rahul',
        )
        self.patient_user_b = User.objects.create_user(
            username='rx_patient_b', password='SecurePass1!', role='user',
            phone_number='9100000002', name='Other Patient',
        )
        self.doctor_user = User.objects.create_user(
            username='rx_doctor', password='SecurePass1!', role='doctor',
            phone_number='9100000099', name='Dr XYZ',
        )

        self.patient_a, _ = Patient.objects.get_or_create(
            user=self.patient_user_a, defaults={'age': 30},
        )
        self.patient_b, _ = Patient.objects.get_or_create(
            user=self.patient_user_b, defaults={'age': 28},
        )
        self.doctor = Doctor.objects.create(
            user=self.doctor_user,
            specialization='General',
            experience_years=5,
            hospital_name='Test Clinic',
            verification_status='VERIFIED',
        )

        Appointment.objects.create(
            patient=self.patient_a,
            doctor=self.doctor,
            appointment_date=timezone.now().date(),
            appointment_time=timezone.now().time().replace(microsecond=0),
            status='ACCEPTED',
            consultation_type='OFFLINE',
        )

        self.token_doctor = Token.objects.create(user=self.doctor_user)
        self.token_a = Token.objects.create(user=self.patient_user_a)
        self.token_b = Token.objects.create(user=self.patient_user_b)

    def test_doctor_uploads_handwritten_prescription(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token_doctor.key}')
        res = self.client.post(
            '/api/prescriptions/',
            {
                'patient': self.patient_a.id,
                'prescription_type': 'handwritten',
                'notes': 'Follow-up prescription',
                'file': _png_file(),
            },
            format='multipart',
        )
        self.assertEqual(res.status_code, 201, res.data)
        self.assertEqual(res.data['prescription_type'], 'handwritten')
        self.assertTrue(res.data['has_file'])
        self.assertTrue(str(res.data['file_url']).endswith(f"/api/prescriptions/{res.data['id']}/file/"))
        self.assertNotIn('media/', str(res.data.get('file_url', '')))
        self.assertTrue(
            SecurityAuditLog.objects.filter(
                action='prescription_handwritten_upload',
                object_id=str(res.data['id']),
                success=True,
            ).exists()
        )

    def test_patient_a_can_view_own_file_patient_b_denied(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token_doctor.key}')
        create = self.client.post(
            '/api/prescriptions/',
            {
                'patient': self.patient_a.id,
                'prescription_type': 'handwritten',
                'file': _png_file(),
            },
            format='multipart',
        )
        self.assertEqual(create.status_code, 201, create.data)
        rx_id = create.data['id']

        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token_a.key}')
        ok = self.client.get(f'/api/prescriptions/{rx_id}/file/')
        self.assertEqual(ok.status_code, 200)
        self.assertTrue(
            SecurityAuditLog.objects.filter(
                action='prescription_file_view',
                object_id=str(rx_id),
                success=True,
            ).exists()
        )

        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token_b.key}')
        denied = self.client.get(f'/api/prescriptions/{rx_id}/file/')
        self.assertIn(denied.status_code, (403, 404))

    def test_unauthenticated_file_denied(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token_doctor.key}')
        create = self.client.post(
            '/api/prescriptions/',
            {
                'patient': self.patient_a.id,
                'prescription_type': 'handwritten',
                'file': _png_file(),
            },
            format='multipart',
        )
        rx_id = create.data['id']
        self.client.credentials()
        res = self.client.get(f'/api/prescriptions/{rx_id}/file/')
        self.assertIn(res.status_code, (401, 403))

    def test_invalid_file_type_rejected(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token_doctor.key}')
        bad = SimpleUploadedFile('malware.exe', b'MZ\x90\x00not-a-real-image', content_type='application/octet-stream')
        res = self.client.post(
            '/api/prescriptions/',
            {
                'patient': self.patient_a.id,
                'prescription_type': 'handwritten',
                'file': bad,
            },
            format='multipart',
        )
        self.assertEqual(res.status_code, 400)
        self.assertTrue(
            SecurityAuditLog.objects.filter(
                action='prescription_handwritten_upload',
                success=False,
            ).exists()
        )

    def test_oversized_file_rejected(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token_doctor.key}')
        big = SimpleUploadedFile(
            'big.png',
            b'\x89PNG\r\n\x1a\n' + b'0' * (6 * 1024 * 1024),
            content_type='image/png',
        )
        res = self.client.post(
            '/api/prescriptions/',
            {
                'patient': self.patient_a.id,
                'prescription_type': 'handwritten',
                'file': big,
            },
            format='multipart',
        )
        self.assertEqual(res.status_code, 400)

    def test_patient_cannot_upload_handwritten(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token_a.key}')
        res = self.client.post(
            '/api/prescriptions/',
            {
                'patient': self.patient_a.id,
                'prescription_type': 'handwritten',
                'file': _png_file(),
            },
            format='multipart',
        )
        self.assertEqual(res.status_code, 403)

    def test_destroy_forbidden_for_doctor(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token_doctor.key}')
        create = self.client.post(
            '/api/prescriptions/',
            {
                'patient': self.patient_a.id,
                'prescription_type': 'handwritten',
                'file': _png_file(),
            },
            format='multipart',
        )
        rx_id = create.data['id']
        res = self.client.delete(f'/api/prescriptions/{rx_id}/')
        self.assertEqual(res.status_code, 403)
        self.assertTrue(Prescription.objects.filter(pk=rx_id).exists())
