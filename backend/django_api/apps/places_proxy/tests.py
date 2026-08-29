from django.test import SimpleTestCase

from apps.places_proxy.views import _classify, _haversine_m, _normalize_place


class PlacesProxyHelpersTests(SimpleTestCase):
    def test_haversine_same_point(self):
        self.assertAlmostEqual(_haversine_m(19.0, 73.0, 19.0, 73.0), 0.0, places=1)

    def test_classify_hospital(self):
        self.assertEqual(_classify(['hospital', 'health'], 'hospital'), 'hospitals')

    def test_classify_pharmacy(self):
        self.assertEqual(_classify(['pharmacy'], None), 'pharmacies')

    def test_normalize_place(self):
        raw = {
            'id': 'places/abc123',
            'displayName': {'text': 'City Hospital'},
            'types': ['hospital'],
            'primaryType': 'hospital',
            'formattedAddress': '1 Main St',
            'location': {'latitude': 19.1, 'longitude': 73.1},
            'rating': 4.5,
            'nationalPhoneNumber': '1234567890',
            'currentOpeningHours': {'openNow': True},
        }
        out = _normalize_place(raw, 19.0, 73.0)
        self.assertIsNotNone(out)
        assert out is not None
        self.assertEqual(out['name'], 'City Hospital')
        self.assertEqual(out['category'], 'hospitals')
        self.assertEqual(out['place_id'], 'abc123')
        self.assertTrue(out['open_now'])
        self.assertGreater(out['distance_m'], 0)
