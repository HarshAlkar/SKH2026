class SyncOperationModel {
  final String id;
  final String operationType;
  final String payload;
  final String status;
  final String timestamp;

  SyncOperationModel({
    required this.id,
    required this.operationType,
    required this.payload,
    required this.status,
    required this.timestamp,
  });

  factory SyncOperationModel.fromJson(Map<String, dynamic> json) {
    return SyncOperationModel(
      id: json['id'] as String,
      operationType: json['operationType'] as String,
      payload: json['payload'] as String,
      status: json['status'] as String,
      timestamp: json['timestamp'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operationType': operationType,
      'payload': payload,
      'status': status,
      'timestamp': timestamp,
    };
  }
}
