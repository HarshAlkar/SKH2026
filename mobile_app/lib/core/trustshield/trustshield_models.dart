enum ClaimStatus { verified, unverified, misleading, highRisk }

enum RiskLevel { low, moderate, high, critical }

class ClaimSource {
  final String name;
  final String type;
  final String reference;
  final DateTime? verifiedAt;

  const ClaimSource({
    required this.name,
    required this.type,
    required this.reference,
    this.verifiedAt,
  });

  factory ClaimSource.fromJson(Map<String, dynamic> json) {
    return ClaimSource(
      name: '${json['name'] ?? ''}',
      type: '${json['type'] ?? 'CURATED_MEDICAL_KNOWLEDGE'}',
      reference: '${json['reference'] ?? ''}',
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse('${json['verifiedAt']}')
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'reference': reference,
        if (verifiedAt != null) 'verifiedAt': verifiedAt!.toIso8601String(),
      };
}

class HealthClaimResult {
  final String claim;
  final ClaimStatus status;
  final RiskLevel riskLevel;
  final double confidence;
  final String explanation;
  final String recommendedAction;
  final List<ClaimSource> sources;
  final DateTime? verifiedAt;
  final String disclaimer;
  final bool offline;
  final String correctedGuidance;
  final String kbLabel;

  const HealthClaimResult({
    required this.claim,
    required this.status,
    required this.riskLevel,
    required this.confidence,
    required this.explanation,
    required this.recommendedAction,
    required this.sources,
    required this.disclaimer,
    this.verifiedAt,
    this.offline = false,
    this.correctedGuidance = '',
    this.kbLabel = '',
  });

  bool get isDangerous =>
      status == ClaimStatus.misleading ||
      status == ClaimStatus.highRisk ||
      riskLevel == RiskLevel.high ||
      riskLevel == RiskLevel.critical;

  String get statusLabel {
    switch (status) {
      case ClaimStatus.verified:
        return 'VERIFIED';
      case ClaimStatus.unverified:
        return 'UNVERIFIED';
      case ClaimStatus.misleading:
        return 'MISLEADING';
      case ClaimStatus.highRisk:
        return 'HIGH_RISK';
    }
  }

  factory HealthClaimResult.fromJson(Map<String, dynamic> json) {
    return HealthClaimResult(
      claim: '${json['claim'] ?? ''}',
      status: _parseStatus('${json['status'] ?? 'UNVERIFIED'}'),
      riskLevel: _parseRisk('${json['riskLevel'] ?? 'LOW'}'),
      confidence: (json['confidence'] is num)
          ? (json['confidence'] as num).toDouble()
          : double.tryParse('${json['confidence']}') ?? 0,
      explanation: '${json['explanation'] ?? ''}',
      recommendedAction: '${json['recommendedAction'] ?? ''}',
      sources: (json['sources'] is List)
          ? (json['sources'] as List)
              .whereType<Map>()
              .map((e) => ClaimSource.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse('${json['verifiedAt']}')
          : null,
      disclaimer: '${json['disclaimer'] ?? ''}',
      offline: json['offline'] == true,
      correctedGuidance: '${json['correctedGuidance'] ?? ''}',
      kbLabel: '${json['kbLabel'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
        'claim': claim,
        'status': status.name.toUpperCase().replaceAll('HIGHRISK', 'HIGH_RISK'),
        'riskLevel': riskLevel.name.toUpperCase(),
        'confidence': confidence,
        'explanation': explanation,
        'recommendedAction': recommendedAction,
        'sources': sources.map((s) => s.toJson()).toList(),
        'verifiedAt': verifiedAt?.toIso8601String(),
        'disclaimer': disclaimer,
        'offline': offline,
        'correctedGuidance': correctedGuidance,
        'kbLabel': kbLabel,
      };

  static ClaimStatus _parseStatus(String raw) {
    switch (raw.toUpperCase().replaceAll(' ', '_')) {
      case 'VERIFIED':
        return ClaimStatus.verified;
      case 'MISLEADING':
        return ClaimStatus.misleading;
      case 'HIGH_RISK':
      case 'HIGHRISK':
        return ClaimStatus.highRisk;
      default:
        return ClaimStatus.unverified;
    }
  }

  static RiskLevel _parseRisk(String raw) {
    switch (raw.toUpperCase()) {
      case 'HIGH':
        return RiskLevel.high;
      case 'CRITICAL':
        return RiskLevel.critical;
      case 'MODERATE':
        return RiskLevel.moderate;
      default:
        return RiskLevel.low;
    }
  }
}
