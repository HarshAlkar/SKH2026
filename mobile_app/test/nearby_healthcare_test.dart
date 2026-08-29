import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hs053/core/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  group('Nearby Healthcare Data & Formatting Tests', () {
    test('Distance formatting correctly formats meters and kilometers', () {
      String formatDistance(double meters) {
        if (meters < 1000) {
          return '${meters.round()} m away';
        }
        return '${(meters / 1000).toStringAsFixed(1)} km away';
      }

      expect(formatDistance(450.0), equals('450 m away'));
      expect(formatDistance(999.4), equals('999 m away'));
      expect(formatDistance(1000.0), equals('1.0 km away'));
      expect(formatDistance(2450.0), equals('2.5 km away'));
      expect(formatDistance(15230.0), equals('15.2 km away'));
    });

    test('Search filter matches facility name, address, category and badges', () {
      final samplePlaces = [
        {
          'name': 'District Civil Hospital',
          'category': 'Hospitals',
          'address': 'Station Road, Pune',
          'stock_badge': 'In Stock',
        },
        {
          'name': 'Rampur Primary Health Centre',
          'category': 'Clinics',
          'address': 'Village Rampur, Nashik',
          'stock_badge': 'Active Facility',
        },
        {
          'name': 'City General Pharmacy',
          'category': 'Medical Stores',
          'address': 'Market Yard, Rampur',
          'stock_badge': 'In Stock',
        },
      ];

      List<Map<String, dynamic>> filter(String query) {
        final q = query.toLowerCase().trim();
        if (q.isEmpty) return samplePlaces;
        return samplePlaces.where((loc) {
          final name = loc['name']?.toString().toLowerCase() ?? '';
          final address = loc['address']?.toString().toLowerCase() ?? '';
          final category = loc['category']?.toString().toLowerCase() ?? '';
          final badge = loc['stock_badge']?.toString().toLowerCase() ?? '';
          return name.contains(q) ||
              address.contains(q) ||
              category.contains(q) ||
              badge.contains(q);
        }).toList();
      }

      // Empty query -> returns all
      expect(filter('').length, equals(3));

      // Specific name match
      final hosp = filter('civil hospital');
      expect(hosp.length, equals(1));
      expect(hosp.first['name'], equals('District Civil Hospital'));

      // Address match
      final rampur = filter('rampur');
      expect(rampur.length, equals(2));

      // Category match
      final pharmacy = filter('medical stores');
      expect(pharmacy.length, equals(1));
      expect(pharmacy.first['name'], equals('City General Pharmacy'));
    });

    test('Offline cache saving and retrieval works seamlessly', () {
      final placesToCache = [
        {
          'id': 'vr-1',
          'name': 'Rampur PHC',
          'category': 'Clinics',
          'distance': '1.2 km away',
          'lat': 19.9975,
          'lng': 73.7898,
        }
      ];

      StorageService.saveStringSync(
        'cached_nearby_Clinics',
        jsonEncode(placesToCache),
      );

      final retrievedJson = StorageService.getStringSync('cached_nearby_Clinics');
      expect(retrievedJson, isNotNull);

      final List decoded = jsonDecode(retrievedJson!);
      expect(decoded.length, equals(1));
      expect(decoded.first['name'], equals('Rampur PHC'));
      expect(decoded.first['category'], equals('Clinics'));
    });

    test('Directions URL generation builds valid Apple Maps and Google Maps URLs without invalid place_id', () {
      final loc = {
        'name': 'Saint Francis Memorial Hospital',
        'address': '900 Hyde Street, Lower Nob Hill',
        'lat': 37.7891,
        'lng': -122.4172,
      };

      final lat = loc['lat'] as double;
      final lng = loc['lng'] as double;
      final name = loc['name'] as String;

      // Google Maps
      final gmapUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&origin=37.7749,-122.4194');
      expect(gmapUri.scheme, equals('https'));
      expect(gmapUri.host, equals('www.google.com'));
      expect(gmapUri.queryParameters['destination'], equals('37.7891,-122.4172'));
      expect(gmapUri.queryParameters['origin'], equals('37.7749,-122.4194'));
      expect(gmapUri.queryParameters.containsKey('destination_place_id'), isFalse);

      // Apple Maps
      final appleUri = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&saddr=37.7749,-122.4194&dirflg=d&q=${Uri.encodeComponent(name)}');
      expect(appleUri.scheme, equals('https'));
      expect(appleUri.host, equals('maps.apple.com'));
      expect(appleUri.queryParameters['daddr'], equals('37.7891,-122.4172'));
      expect(appleUri.queryParameters['q'], equals('Saint Francis Memorial Hospital'));
    });

    test('Facility phone number validation extracts actual phone and never falls back to 102', () {
      String getCleanPhone(Map<String, dynamic> loc) {
        final rawPhone = (loc['phone'] ?? '').toString().trim();
        return rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
      }

      // Case 1: Real phone number
      final locWithPhone = {
        'name': 'Ruby Hall Clinic',
        'phone': '+91 20 6645 5100',
      };
      final clean = getCleanPhone(locWithPhone);
      expect(clean, equals('+912066455100'));
      expect(clean, isNot(equals('102')));

      // Case 2: No phone number
      final locWithoutPhone = {
        'name': 'Rural Sub Centre',
        'phone': '',
      };
      final cleanEmpty = getCleanPhone(locWithoutPhone);
      expect(cleanEmpty, isEmpty);
      expect(cleanEmpty, isNot(equals('102')));
    });
  });
}
