class ReportModel {
  final int id;
  final String title;
  final String description;
  final String fileUrl;
  final String createdAt;
  final String reportType;
  final int patient;
  final String patientName;

  ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.createdAt,
    required this.reportType,
    required this.patient,
    required this.patientName,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      title: json['title'] ?? 'Report',
      description: json['description'] ?? '',
      fileUrl: json['file_url'] ?? '',
      createdAt: json['created_at'] ?? '',
      reportType: json['report_type'] ?? 'Lab Report',
      patient: json['patient'],
      patientName: json['patient_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'file_url': fileUrl,
    'created_at': createdAt,
    'report_type': reportType,
    'patient': patient,
    'patient_name': patientName,
  };
}
