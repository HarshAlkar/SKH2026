class MedicineStockModel {
  final int id;
  final int? facilityId;
  final String facilityName;
  final String facilityVillage;
  final int? catalogId;
  final String medicineName;
  final String sku;
  final String category;
  final String unit;
  final String batchNo;
  final int quantity;
  final String expiryDate;
  final int reorderLevel;
  final String status;
  final int? daysToExpiry;

  const MedicineStockModel({
    required this.id,
    this.facilityId,
    this.facilityName = '',
    this.facilityVillage = '',
    this.catalogId,
    required this.medicineName,
    this.sku = '',
    this.category = '',
    this.unit = 'units',
    required this.batchNo,
    required this.quantity,
    required this.expiryDate,
    this.reorderLevel = 20,
    this.status = 'in_stock',
    this.daysToExpiry,
  });

  factory MedicineStockModel.fromJson(Map<String, dynamic> json) {
    return MedicineStockModel(
      id: int.tryParse('${json['id']}') ?? 0,
      facilityId: int.tryParse('${json['facility'] ?? ''}'),
      facilityName: '${json['facility_name'] ?? ''}',
      facilityVillage: '${json['facility_village'] ?? ''}',
      catalogId: int.tryParse('${json['catalog'] ?? ''}'),
      medicineName: '${json['medicine_name'] ?? json['name'] ?? ''}',
      sku: '${json['sku'] ?? ''}',
      category: '${json['category'] ?? ''}',
      unit: '${json['unit'] ?? 'units'}',
      batchNo: '${json['batch_no'] ?? ''}',
      quantity: int.tryParse('${json['quantity'] ?? 0}') ?? 0,
      expiryDate: '${json['expiry_date'] ?? ''}',
      reorderLevel: int.tryParse('${json['reorder_level'] ?? 20}') ?? 20,
      status: '${json['status'] ?? 'in_stock'}',
      daysToExpiry: int.tryParse('${json['days_to_expiry'] ?? ''}'),
    );
  }

  bool get canWrite => true;
}

class StockAvailabilityModel {
  final int facilityId;
  final String facilityName;
  final String facilityType;
  final String village;
  final double? latitude;
  final double? longitude;
  final int catalogId;
  final String medicineName;
  final String sku;
  final String unit;
  final int quantity;
  final String status;
  final double? distanceKm;

  const StockAvailabilityModel({
    required this.facilityId,
    required this.facilityName,
    this.facilityType = '',
    this.village = '',
    this.latitude,
    this.longitude,
    required this.catalogId,
    required this.medicineName,
    this.sku = '',
    this.unit = 'units',
    required this.quantity,
    this.status = 'in_stock',
    this.distanceKm,
  });

  factory StockAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return StockAvailabilityModel(
      facilityId: int.tryParse('${json['facility_id']}') ?? 0,
      facilityName: '${json['facility_name'] ?? ''}',
      facilityType: '${json['facility_type'] ?? ''}',
      village: '${json['village'] ?? ''}',
      latitude: double.tryParse('${json['latitude'] ?? ''}'),
      longitude: double.tryParse('${json['longitude'] ?? ''}'),
      catalogId: int.tryParse('${json['catalog_id']}') ?? 0,
      medicineName: '${json['medicine_name'] ?? ''}',
      sku: '${json['sku'] ?? ''}',
      unit: '${json['unit'] ?? 'units'}',
      quantity: int.tryParse('${json['quantity'] ?? 0}') ?? 0,
      status: '${json['status'] ?? 'in_stock'}',
      distanceKm: double.tryParse('${json['distance_km'] ?? ''}'),
    );
  }
}
