from django.test import SimpleTestCase

from apps.trustshield.service import verify_claim


class TrustShieldVerifyTests(SimpleTestCase):
    def test_dengue_antibiotics_misleading_high(self):
        r = verify_claim('WhatsApp says antibiotics cure dengue in two days.')
        self.assertEqual(r['status'], 'MISLEADING')
        self.assertEqual(r['riskLevel'], 'HIGH')
        self.assertTrue(r['sources'])

    def test_handwash_verified(self):
        r = verify_claim('Washing hands with soap helps reduce infection risk.')
        self.assertEqual(r['status'], 'VERIFIED')

    def test_drinking_water_verified(self):
        r = verify_claim('DRINKIN WATER IS GOOD FOR HEALTH')
        self.assertEqual(r['status'], 'VERIFIED')
        self.assertEqual(r['riskLevel'], 'LOW')
        self.assertIn('water', r['claim'].lower())

    def test_obscure_unverified(self):
        r = verify_claim('A rare mineral tea reverses all heart disease overnight without doctors.')
        self.assertEqual(r['status'], 'UNVERIFIED')

    def test_empty_unverified(self):
        r = verify_claim('   ')
        self.assertEqual(r['status'], 'UNVERIFIED')
        self.assertEqual(r['confidence'], 0.0)

    def test_never_verified_without_match(self):
        r = verify_claim('xyzzy unknown claim 12345')
        self.assertNotEqual(r['status'], 'VERIFIED')
