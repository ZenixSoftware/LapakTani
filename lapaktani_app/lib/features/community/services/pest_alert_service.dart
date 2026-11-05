import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../models/pest_report_model.dart';

/// Service managing Pest Reports & Emergency Alerts (US-19)
/// Connects directly to persistent MySQL backend on /api/pest-reports
class PestAlertService {
  static final PestAlertService _instance = PestAlertService._internal();
  factory PestAlertService() => _instance;
  PestAlertService._internal();

  static const String _dismissedAlertKey = 'dismissed_pest_alert_id';

  final List<PestReportModel> _cachedReports = [];
  bool _initialized = false;
  String? _dismissedAlertId;

  void init() {
    if (_initialized) return;
    _initialized = true;
    _loadDismissedAlert();
  }

  Future<void> _loadDismissedAlert() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _dismissedAlertId = prefs.getString(_dismissedAlertKey);
    } catch (_) {}
  }

  /// Get active emergency pest alert for Poktan banner
  Future<PestReportModel?> getActiveEmergencyAlert({
    String poktanName = 'Poktan Tani Makmur',
  }) async {
    init();

    // 1. Try remote API first
    try {
      final query = Uri.encodeComponent(poktanName);
      final response = await ApiService.get('/pest-reports/active-alert?farmer_group_name=$query');
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['has_alert'] == true && body['data'] != null) {
          final remoteAlert = PestReportModel.fromJson(body['data']);
          if (remoteAlert.id != _dismissedAlertId) {
            return remoteAlert;
          }
        }
      }
    } catch (e) {
      debugPrint('[PestAlertService] Error fetching remote active alert: $e');
    }

    // 2. Fallback to cached alert
    try {
      final found = _cachedReports.firstWhere(
        (r) =>
            r.status == 'active' &&
            (r.emergencyAlert || r.severity.toLowerCase().contains('berat')) &&
            r.id != _dismissedAlertId,
      );
      return found;
    } catch (_) {
      return null;
    }
  }

  /// Get list of pest reports with optional filters
  Future<List<PestReportModel>> getPestReports({
    String? poktanName,
    String? severity,
    String? status,
  }) async {
    init();

    try {
      final queryParams = <String, String>{};
      if (poktanName != null && poktanName.isNotEmpty && poktanName != 'Semua') {
        queryParams['farmer_group_name'] = poktanName;
      }
      if (severity != null && severity.isNotEmpty && severity != 'Semua') {
        queryParams['severity'] = severity;
      }
      if (status != null && status.isNotEmpty && status != 'Semua') {
        queryParams['status'] = status;
      }

      final qs = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final path = '/pest-reports${qs.isNotEmpty ? '?$qs' : ''}';

      final response = await ApiService.get(path);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] is List) {
          final list = (body['data'] as List)
              .map((item) => PestReportModel.fromJson(item as Map<String, dynamic>))
              .toList();
          _cachedReports.clear();
          _cachedReports.addAll(list);
          return list;
        }
      }
    } catch (_) {}

    // Fallback to local cache
    var results = List<PestReportModel>.from(_cachedReports);
    if (poktanName != null && poktanName.isNotEmpty && poktanName != 'Semua') {
      results = results
          .where((r) => r.farmerGroupName.toLowerCase().contains(poktanName.toLowerCase()))
          .toList();
    }
    if (severity != null && severity.isNotEmpty && severity != 'Semua') {
      results = results
          .where((r) => r.severity.toLowerCase() == severity.toLowerCase())
          .toList();
    }
    if (status != null && status.isNotEmpty) {
      results = results.where((r) => r.status == status).toList();
    }

    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  /// Create a new pest attack report with optional multipart image upload
  Future<Map<String, dynamic>> createPestReport({
    required String pestName,
    required String cropType,
    required String severity,
    required String affectedArea,
    required String farmerGroupId,
    required String farmerGroupName,
    int villageId = 1,
    String villageName = 'Desa Lembang',
    required String description,
    String? handlingRecommendation,
    bool emergencyAlert = false,
    File? imageFile,
    String? sampleImageUrl,
  }) async {
    init();

    final user = await ApiService().getUser();
    final reporterId = user != null ? (user['id'] ?? '') : '';
    final reporterName = user != null ? (user['full_name'] ?? user['name'] ?? 'Petani LapakTani') : 'Petani LapakTani';
    final reporterRole = user != null && user['role_id'] == 2 ? 'Penyuluh Pertanian' : 'Petani';

    final isEmergency = severity.toLowerCase().contains('berat') || emergencyAlert;

    // If an image file is selected, upload it first via ApiService
    String? uploadedImageUrl = sampleImageUrl;
    if (imageFile != null) {
      try {
        final uploadRes = await ApiService.uploadImage('/upload/product-image', imageFile);
        if (uploadRes['data'] != null && uploadRes['data']['url'] != null) {
          uploadedImageUrl = uploadRes['data']['url'].toString();
        }
      } catch (e) {
        debugPrint('[PestAlertService] Image upload failed: $e');
      }
    }

    final payload = {
      'pest_name': pestName.trim(),
      'crop_type': cropType.trim(),
      'commodity_name': cropType.trim(),
      'severity': severity.trim(),
      'affected_area': affectedArea.trim(),
      'farmer_group_name': farmerGroupName.trim(),
      'farmer_group_id': farmerGroupId,
      'village_name': villageName.trim(),
      'village_id': villageId,
      'description': description.trim(),
      'photo_url': uploadedImageUrl ??
          'https://images.unsplash.com/photo-1592417817098-8f3d6910985c?auto=format&fit=crop&w=800&q=80',
      'image_url': uploadedImageUrl ??
          'https://images.unsplash.com/photo-1592417817098-8f3d6910985c?auto=format&fit=crop&w=800&q=80',
      'handling_recommendation': handlingRecommendation?.trim(),
      'emergency_alert': isEmergency,
      'reporter_id': reporterId,
      'reporter_name': reporterName,
      'reporter_role': reporterRole,
    };

    try {
      final response = await ApiService.post('/pest-reports', payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final createdModel = PestReportModel.fromJson(body['data']);
          _cachedReports.insert(0, createdModel);
          _dismissedAlertId = null; // Reset dismissal on new alert
          return {
            'success': true,
            'message': body['message'] ?? 'Laporan berhasil dibuat.',
            'data': createdModel,
            'notifications_sent': body['notifications_sent'] ?? 0,
          };
        }
      } else {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal menyimpan laporan ke server.',
        };
      }
    } catch (e) {
      debugPrint('[PestAlertService] API create error: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server LapakTani: $e',
      };
    }

    return {
      'success': false,
      'message': 'Terjadi kesalahan sistem.',
    };
  }

  /// Mark alert as resolved / contained in MySQL
  Future<bool> resolvePestAlert(String reportId, {String? resolutionNote}) async {
    try {
      final response = await ApiService.put('/pest-reports/$reportId/status', {
        'status': 'RESOLVED',
        'legacy_status': 'resolved',
        'handling_recommendation': resolutionNote,
      });
      if (response.statusCode == 200) {
        final index = _cachedReports.indexWhere((r) => r.id == reportId);
        if (index != -1) {
          final old = _cachedReports[index];
          _cachedReports[index] = PestReportModel(
            id: old.id,
            reporterId: old.reporterId,
            reporterName: old.reporterName,
            reporterRole: old.reporterRole,
            pestName: old.pestName,
            cropType: old.cropType,
            severity: old.severity,
            affectedArea: old.affectedArea,
            farmerGroupId: old.farmerGroupId,
            farmerGroupName: old.farmerGroupName,
            villageId: old.villageId,
            villageName: old.villageName,
            imageUrl: old.imageUrl,
            description: old.description,
            handlingRecommendation: resolutionNote ?? old.handlingRecommendation,
            emergencyAlert: false,
            status: 'resolved',
            createdAt: old.createdAt,
          );
        }
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Dismiss the active banner alert for the current session
  Future<void> dismissBannerAlert(String alertId) async {
    _dismissedAlertId = alertId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedAlertKey, alertId);
    } catch (_) {}
  }
}
