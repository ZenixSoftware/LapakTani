import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Model representing a Pest Attack Report and Early Warning (US-19)
/// Aligned with Stitch AI Design Specifications
class PestReportModel {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reporterRole;
  final String pestName;
  final String cropType;
  final String severity; // 'Ringan', 'Sedang', 'Berat'
  final String affectedArea;
  final String farmerGroupId;
  final String farmerGroupName;
  final int villageId;
  final String villageName;
  final String? imageUrl;
  final String description;
  final String? handlingRecommendation;
  final bool emergencyAlert;
  final String status; // 'active', 'contained', 'resolved'
  final DateTime createdAt;
  final String? warningTitle;
  final String? warningMessage;
  final String? recommendedAction;
  final int affectedRadiusKm;

  const PestReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    this.reporterRole = 'Petani',
    required this.pestName,
    required this.cropType,
    required this.severity,
    required this.affectedArea,
    required this.farmerGroupId,
    required this.farmerGroupName,
    this.villageId = 1,
    this.villageName = 'Desa Lembang',
    this.imageUrl,
    required this.description,
    this.handlingRecommendation,
    this.emergencyAlert = false,
    this.status = 'active',
    required this.createdAt,
    this.warningTitle,
    this.warningMessage,
    this.recommendedAction,
    this.affectedRadiusKm = 5,
  });

  // Compatibility getters
  bool get isEmergency => emergencyAlert;
  String get cropCommodity => cropType;
  String get farmerName => reporterName;
  String? get actionTaken => handlingRecommendation ?? recommendedAction;

  factory PestReportModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      final rawDate = json['created_at'] ?? json['createdAt'];
      if (rawDate != null) {
        parsedDate = DateTime.parse(rawDate.toString());
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final rawEmergency = json['emergency_alert'] ?? json['emergencyAlert'];
    final bool isEmergency = rawEmergency == true ||
        rawEmergency == 1 ||
        rawEmergency == '1' ||
        rawEmergency == 'true';

    final sev = (json['severity'] ?? json['severity_label'] ?? 'Sedang').toString();

    return PestReportModel(
      id: (json['id'] ?? '').toString(),
      reporterId: (json['reporter_id'] ?? json['reporter_user_id'] ?? json['reporterId'] ?? '').toString(),
      reporterName: (json['reporter_name'] ?? json['reporterName'] ?? 'Petani LapakTani').toString(),
      reporterRole: (json['reporter_role'] ?? json['reporterRole'] ?? 'Petani').toString(),
      pestName: (json['pest_name'] ?? json['pestName'] ?? '').toString(),
      cropType: (json['crop_type'] ?? json['commodity_name'] ?? json['cropType'] ?? '').toString(),
      severity: sev,
      affectedArea: (json['affected_area'] ?? json['affectedArea'] ?? '').toString(),
      farmerGroupId: (json['farmer_group_id'] ?? json['farmerGroupId'] ?? '').toString(),
      farmerGroupName: (json['farmer_group_name'] ?? json['farmerGroupName'] ?? 'Poktan Tani Makmur').toString(),
      villageId: int.tryParse((json['village_id'] ?? json['villageId'] ?? '1').toString()) ?? 1,
      villageName: (json['village_name'] ?? json['villageName'] ?? 'Desa Lembang').toString(),
      imageUrl: json['photo_url'] ?? json['image_url'] ?? json['imageUrl'],
      description: (json['description'] ?? '').toString(),
      handlingRecommendation: json['handling_recommendation'] ?? json['handlingRecommendation'],
      emergencyAlert: isEmergency,
      status: (json['status'] ?? json['legacy_status'] ?? 'active').toString(),
      createdAt: parsedDate,
      warningTitle: json['warning_title']?.toString(),
      warningMessage: json['warning_message']?.toString(),
      recommendedAction: json['recommended_action']?.toString(),
      affectedRadiusKm: int.tryParse((json['affected_radius_km'] ?? '5').toString()) ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'reporter_name': reporterName,
      'reporter_role': reporterRole,
      'pest_name': pestName,
      'crop_type': cropType,
      'commodity_name': cropType,
      'severity': severity,
      'affected_area': affectedArea,
      'farmer_group_id': farmerGroupId,
      'farmer_group_name': farmerGroupName,
      'village_id': villageId,
      'village_name': villageName,
      'photo_url': imageUrl,
      'image_url': imageUrl,
      'description': description,
      'handling_recommendation': handlingRecommendation,
      'emergency_alert': emergencyAlert,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'warning_title': warningTitle,
      'warning_message': warningMessage,
      'recommended_action': recommendedAction,
      'affected_radius_km': affectedRadiusKm,
    };
  }

  /// Stitch AI Primary brand and severity tint tokens
  Color get severityColor {
    final lower = severity.toLowerCase();
    if (lower.contains('berat') || lower.contains('critical') || lower.contains('high')) {
      return const Color(0xFFC62828); // Soft Red Dark Text
    } else if (lower.contains('sedang') || lower.contains('medium')) {
      return const Color(0xFFEF6C00); // Soft Orange Dark Text
    } else {
      return const Color(0xFF2E7D32); // Stitch Forest/Agri Green
    }
  }

  Color get severityBackgroundColor {
    final lower = severity.toLowerCase();
    if (lower.contains('berat') || lower.contains('critical') || lower.contains('high')) {
      return const Color(0xFFFFEBEE); // Soft Red Tint Background
    } else if (lower.contains('sedang') || lower.contains('medium')) {
      return const Color(0xFFFFF3E0); // Soft Orange Tint Background
    } else {
      return const Color(0xFFE8F5E9); // Soft Green Tint Background
    }
  }

  Color get severityBorderColor {
    final lower = severity.toLowerCase();
    if (lower.contains('berat') || lower.contains('critical') || lower.contains('high')) {
      return const Color(0xFFFFCDD2);
    } else if (lower.contains('sedang') || lower.contains('medium')) {
      return const Color(0xFFFFE0B2);
    } else {
      return const Color(0xFFC8E6C9);
    }
  }

  String get formattedDate {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(createdAt);
    } catch (_) {
      try {
        return DateFormat('dd MMM yyyy, HH:mm').format(createdAt);
      } catch (_) {
        return DateFormat('yyyy-MM-dd HH:mm').format(createdAt);
      }
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes < 1 ? 1 : difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${difference.inDays} hari lalu';
    }
  }

  bool get isActiveEmergency =>
      status == 'active' && (emergencyAlert || severity.toLowerCase() == 'berat');
}
