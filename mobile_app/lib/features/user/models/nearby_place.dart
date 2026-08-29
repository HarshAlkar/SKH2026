class NearbyPlace {
  final String id;
  final String name;
  final String category;
  final double lat;
  final double lng;
  final double distanceM;
  final String address;
  final bool? openNow;
  final String phone;
  final double? rating;
  final int? userRatingCount;
  final String? stockBadge;
  final bool vitalReach;

  const NearbyPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.distanceM,
    this.address = '',
    this.openNow,
    this.phone = '',
    this.rating,
    this.userRatingCount,
    this.stockBadge,
    this.vitalReach = false,
  });

  String get distanceLabel {
    if (distanceM < 1000) {
      return '${distanceM.round()} m away';
    }
    return '${(distanceM / 1000).toStringAsFixed(1)} km away';
  }

  String get categoryLabel {
    switch (category) {
      case 'hospitals':
        return 'Hospital';
      case 'clinics':
        return 'Clinic';
      case 'labs':
        return 'Lab';
      case 'pharmacies':
        return 'Pharmacy';
      default:
        return category.isEmpty ? 'Healthcare' : category;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'lat': lat,
        'lng': lng,
        'distance_m': distanceM,
        'address': address,
        'open_now': openNow,
        'phone': phone,
        'rating': rating,
        'user_rating_count': userRatingCount,
        'stock_badge': stockBadge,
        'vitalreach': vitalReach,
      };

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    return NearbyPlace(
      id: '${json['place_id'] ?? json['id'] ?? ''}',
      name: '${json['name'] ?? 'Unnamed facility'}',
      category: '${json['category'] ?? 'other'}',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      distanceM: (json['distance_m'] as num?)?.toDouble() ?? 0,
      address: '${json['address'] ?? ''}',
      openNow: json['open_now'] is bool ? json['open_now'] as bool : null,
      phone: '${json['phone'] ?? ''}',
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingCount: (json['user_rating_count'] as num?)?.toInt(),
      stockBadge: json['stock_badge']?.toString(),
      vitalReach: json['vitalreach'] == true,
    );
  }
}

enum NearbyLoadState {
  idle,
  loading,
  ready,
  empty,
  permissionDenied,
  locationDisabled,
  locationUnavailable,
  networkError,
  apiError,
  offlineCached,
}
