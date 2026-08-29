"""
VitalReach Security Tests
Non-destructive checks for auth, IDOR, sync idempotency, uploads, CORS, Gemini proxy.
"""

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from django.contrib.auth import get_user_model
from rest_framework.authtoken.models import Token
from rest_framework.test import APIClient

from apps.alerts.models import EmergencyAlert
from apps.patients.models import Patient
from apps.one_health.models import ScreeningEvent
from apps.security_audit.models import SecurityAuditLog

User = get_user_model()


class SecurityHardeningTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user_a = User.objects.create_user(
            username='sec_user_a', password='SecurePass1!', role='user',
            phone_number='9000000001', name='User A',
        )
        self.user_b = User.objects.create_user(
            username='sec_user_b', password='SecurePass1!', role='user',
            phone_number='9000000002', name='User B',
        )
        Patient.objects.get_or_create(user=self.user_a, defaults={'age': 30})
        Patient.objects.get_or_create(user=self.user_b, defaults={'age': 28})
        self.token_a = Token.objects.create(user=self.user_a)
        self.token_b = Token.objects.create(user=self.user_b)

    def test_unauthenticated_blocked(self):
        res = self.client.get('/api/patients/')
        self.assertIn(res.status_code, (401, 403))

    def test_invalid_token_rejected(self):
        self.client.credentials(HTTP_AUTHORIZATION='Token deadbeef')
        res = self.client.get('/api/users/me/')
        self.assertIn(res.status_code, (401, 403))

    def test_register_does_not_reissue_token(self):
        res = self.client.post('/api/auth/register/', {
            'phone_number': '9000000001',
            'password': 'SecurePass1!',
            'role': 'user',
            'name': 'Dup',
        }, format='json')
        self.assertEqual(res.status_code, 400)
        self.assertTrue(res.data.get('already_exists'))
        self.assertNotIn('token', res.data)

    def test_emergency_alert_idor(self):
        alert = EmergencyAlert.objects.create(user=self.user_a, alert_type='Test')
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token_b.key}')
        res = self.client.get('/api/alerts/emergencies/')
        self.assertEqual(res.status_code, 200)
        ids = [row['id'] for row in res.data] if isinstance(res.data, list) else [
            row['id'] for row in res.data.get('results', [])
        ]
        self.assertNotIn(alert.id, ids)

    def test_screening_idempotent_client_id(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token_a.key}')
        payload = {
            'domain': 'HUMAN',
            'input_type': 'symptoms',
            'input_text': 'fever',
            'possible_condition': 'Flu',
            'severity_level': 'Low',
            'confidence': 0.5,
            'client_id': 'test-client-id-001',
        }
        r1 = self.client.post('/api/one-health/screenings/', payload, format='json')
        r2 = self.client.post('/api/one-health/screenings/', payload, format='json')
        self.assertIn(r1.status_code, (200, 201))
        self.assertIn(r2.status_code, (200, 201))
        self.assertEqual(
            ScreeningEvent.objects.filter(user=self.user_a, client_id='test-client-id-001').count(),
            1,
        )

    def test_screening_rejects_client_user_id(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token_a.key}')
        payload = {
            'domain': 'HUMAN',
            'input_type': 'symptoms',
            'input_text': 'cough',
            'user': self.user_b.id,
            'client_id': 'test-client-id-002',
        }
        res = self.client.post('/api/one-health/screenings/', payload, format='json')
        self.assertIn(res.status_code, (200, 201))
        event = ScreeningEvent.objects.get(client_id='test-client-id-002')
        self.assertEqual(event.user_id, self.user_a.id)

    def test_oversized_skin_upload_rejected(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token_a.key}')
        big = SimpleUploadedFile('x.jpg', b'not-an-image' + b'0' * (4 * 1024 * 1024), content_type='image/jpeg')
        res = self.client.post('/api/symptoms/analyze-skin/', {'image': big}, format='multipart')
        self.assertEqual(res.status_code, 400)

    def test_login_audited(self):
        self.client.post('/api/auth/login/', {
            'phone_number': '9000000001',
            'password': 'SecurePass1!',
            'role': 'user',
        }, format='json')
        self.assertTrue(SecurityAuditLog.objects.filter(action='login', success=True).exists())

    @override_settings(DEBUG=False, CORS_ALLOW_ALL_ORIGINS=False)
    def test_cors_not_wildcard_in_production_settings(self):
        from django.conf import settings
        self.assertFalse(getattr(settings, 'CORS_ALLOW_ALL_ORIGINS', True))

    def test_gemini_proxy_requires_auth(self):
        res = self.client.post('/api/ai/gemini-chat/', {'message': 'hello'}, format='json')
        self.assertIn(res.status_code, (401, 403))

    def test_gemini_status_requires_auth(self):
        res = self.client.get('/api/ai/status/')
        self.assertIn(res.status_code, (401, 403))

    def test_gemini_status_reports_configured_false(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token_a.key}')
        res = self.client.get('/api/ai/status/')
        self.assertEqual(res.status_code, 200)
        self.assertIn('gemini_configured', res.data)
        self.assertIsInstance(res.data['gemini_configured'], bool)

    @override_settings(GEMINI_API_KEY='')
    def test_gemini_chat_503_when_key_empty(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token_a.key}')
        res = self.client.post('/api/ai/gemini-chat/', {'message': 'hello'}, format='json')
        self.assertEqual(res.status_code, 503)
        self.assertIn('not configured', res.data.get('error', '').lower())
        self.assertEqual(res.data.get('result_state'), 'AI_CHAT_UNAVAILABLE')
        self.assertFalse(res.data.get('gemini_configured'))

    @override_settings(GEMINI_API_KEY='')
    def test_gemini_status_false_when_key_empty(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token_a.key}')
        res = self.client.get('/api/ai/status/')
        self.assertEqual(res.status_code, 200)
        self.assertFalse(res.data['gemini_configured'])
