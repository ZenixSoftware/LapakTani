import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Model representing a Pest Attack Report and Early Warning (US-19)
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
  });

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

    return PestReportModel(
      id: (json['id'] ?? '').toString(),
      reporterId: (json['reporter_id'] ?? json['reporterId'] ?? '').toString(),
      reporterName: (json['reporter_name'] ?? json['reporterName'] ?? 'Petani').toString(),
      reporterRole: (json['reporter_role'] ?? json['reporterRole'] ?? 'Petani').toString(),
      pestName: (json['pest_name'] ?? json['pestName'] ?? '').toString(),
      cropType: (json['crop_type'] ?? json['cropType'] ?? '').toString(),
      severity: (json['severity'] ?? 'Sedang').toString(),
      affectedArea: (json['affected_area'] ?? json['affectedArea'] ?? '').toString(),
      farmerGroupId: (json['farmer_group_id'] ?? json['farmerGroupId'] ?? '').toString(),
      farmerGroupName: (json['farmer_group_name'] ?? json['farmerGroupName'] ?? 'Poktan Tani Makmur').toString(),
      villageId: int.tryParse((json['village_id'] ?? json['villageId'] ?? '1').toString()) ?? 1,
      villageName: (json['village_name'] ?? json['villageName'] ?? 'Desa Lembang').toString(),
      imageUrl: json['image_url'] ?? json['imageUrl'],
      description: (json['description'] ?? '').toString(),
      handlingRecommendation: json['handling_recommendation'] ?? json['handlingRecommendation'],
      emergencyAlert: isEmergency,
      status: (json['status'] ?? 'active').toString(),
      createdAt: parsedDate,
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
      'severity': severity,
      'affected_area': affectedArea,
      'farmer_group_id': farmerGroupId,
      'farmer_group_name': farmerGroupName,
      'village_id': villageId,
      'village_name': villageName,
      'image_url': imageUrl,
      'description': description,
      'handling_recommendation': handlingRecommendation,
      'emergency_alert': emergencyAlert,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Visual theme color according to severity level
  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'berat':
        return const Color(0xFFEF4444); // Red
      case 'sedang':
        return const Color(0xFFF59E0B); // Amber/Orange
      case 'ringan':
      default:
        return const Color(0xFF10B981); // Emerald Green
    }
  }

  Color get severityBackgroundColor {
    switch (severity.toLowerCase()) {
      case 'berat':
        return const Color(0xFFFEF2F2); // Red-50
      case 'sedang':
        return const Color(0xFFFFFBEB); // Amber-50
      case 'ringan':
      default:
        return const Color(0xFFECFDF5); // Emerald-50
    }
  }

  Color get severityBorderColor {
    switch (severity.toLowerCase()) {
      case 'berat':
        return const Color(0xFFFCA5A5); // Red-300
      case 'sedang':
        return const Color(0xFFFDE68A); // Amber-300
      case 'ringan':
      default:
        return const Color(0xFFA7F3D0); // Emerald-300
    }
  }

  String get formattedDate {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(createdAt);
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

