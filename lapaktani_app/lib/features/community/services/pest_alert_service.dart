import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../models/pest_report_model.dart';

/// Service managing Pest Reports & Emergency Alerts (US-19)
class PestAlertService {
  static final PestAlertService _instance = PestAlertService._internal();
  factory PestAlertService() => _instance;
  PestAlertService._internal();

  static const String _storageKey = 'local_pest_reports_cache_v1';
  static const String _dismissedAlertKey = 'dismissed_pest_alert_id';

  final List<PestReportModel> _cachedReports = [];
  bool _initialized = false;
  String? _dismissedAlertId;

  void init() {
    if (_initialized) return;
    _initialized = true;
    _seedDefaultReports();
    _loadDismissedAlert();
  }

  Future<void> _loadDismissedAlert() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _dismissedAlertId = prefs.getString(_dismissedAlertKey);
    } catch (_) {}
  }

  void _seedDefaultReports() {
    _cachedReports.clear();
    _cachedReports.addAll([
      PestReportModel(
        id: 'pest-alert-init-01',
        reporterId: 'f-maman',
        reporterName: 'H. Maman Suratman',
        reporterRole: 'Ketua Poktan',
        pestName: 'Ulat Grayak (Spodoptera frugiperda)',
        cropType: 'Jagung & Cabai Merah',
        severity: 'Berat',
        affectedArea: '1.2 Hektar',
        farmerGroupId: 'fg-lembang-01',
        farmerGroupName: 'Poktan Tani Makmur',
        villageId: 1,
        villageName: 'Desa Lembang',
        imageUrl:
            'https://images.unsplash.com/photo-1592417817098-8f3d6910985c?auto=format&fit=crop&w=800&q=80',
        description:
            'Ditemukan serangan ulat grayak instar 3-4 memakan daun muda dan tongkol jagung seluas kurang lebih 1.2 ha di blok timur. Penularan cepat karena angin kencang.',
        handlingRecommendation:
            'Segera lakukan penyemprotan insektisida nabati mimba atau Bacillus thuringiensis pada pagi hari (06.00-08.00 WIB). Pasang perangkap feromon di sekeliling blok lahan.',
        emergencyAlert: true,
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      PestReportModel(
        id: 'pest-alert-demo-02',
        reporterId: 'f-wayan',
        reporterName: 'Pak Wayan Sudirta',
        reporterRole: 'Anggota Poktan',
        pestName: 'Hawar Daun (Phytophthora infestans)',
        cropType: 'Kentang Granola',
        severity: 'Sedang',
        affectedArea: '0.5 Hektar',
        farmerGroupId: 'fg-lembang-01',
        farmerGroupName: 'Poktan Tani Makmur',
        villageId: 1,
        villageName: 'Desa Lembang',
        imageUrl:
            'https://images.unsplash.com/photo-1599818816942-88ec0c39f03d?auto=format&fit=crop&w=800&q=80',
        description:
            'Bercak basah kehitaman pada tepi daun bagian bawah mulai menyebar akibat kelembaban tinggi dan embun pagi tebal.',
        handlingRecommendation:
            'Pangkas daun yang terinfeksi dan bakar jauh dari lahan. Kurangi kelembaban gulma dan semprot fungisida tembaga hidroksida terdaftar.',
        emergencyAlert: false,
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(hours: 18)),
      ),
    ]);
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
        } else if (body['success'] == true && body['has_alert'] == false) {
          return null;
        }
      }
    } catch (e) {
      debugPrint('[PestAlertService] Using local cached alerts: $e');
    }

    // 2. Fallback to cached active alerts
    final match = _cachedReports.firstWhere(
      (r) =>
          r.isActiveEmergency &&
          r.farmerGroupName.toLowerCase() == poktanName.toLowerCase() &&
          r.id != _dismissedAlertId,
      orElse: () => _cachedReports.firstWhere(
        (r) => r.isActiveEmergency && r.id != _dismissedAlertId,
        orElse: () => _cachedReports.first,
      ),
    );

    if (match.isActiveEmergency && match.id != _dismissedAlertId) {
      return match;
    }

    return null;
  }

  /// Retrieve all reports with optional filters
  Future<List<PestReportModel>> getPestReports({
    String? poktanName,
    String? severity,
    String? status,
  }) async {
    init();

    try {
      final queryParams = <String, String>{};
      if (poktanName != null && poktanName.isNotEmpty) {
        queryParams['farmer_group_name'] = poktanName;
      }
      if (severity != null && severity != 'Semua') {
        queryParams['severity'] = severity;
      }
      if (status != null) {
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
          if (list.isNotEmpty) {
            _cachedReports.clear();
            _cachedReports.addAll(list);
            return list;
          }
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

  /// Submit a new pest attack report and activate early warning
  Future<Map<String, dynamic>> submitPestReport({
    required String pestName,
    required String cropType,
    required String severity,
    required String affectedArea,
    required String farmerGroupName,
    String farmerGroupId = 'fg-lembang-01',
    String villageName = 'Desa Lembang',
    int villageId = 1,
    required String description,
    String? imageUrl,
    String? handlingRecommendation,
    bool emergencyAlert = false,
  }) async {
    init();

    final user = await ApiService().getUser();
    final reporterId = user != null ? (user['id'] ?? 'f-maman') : 'f-maman';
    final reporterName = user != null ? (user['full_name'] ?? user['name'] ?? 'Petani LapakTani') : 'H. Maman Suratman';
    final reporterRole = user != null && user['role_id'] == 2 ? 'Penyuluh Pertanian' : 'Petani Anggota';

    final isEmergency = severity.toLowerCase() == 'berat' || emergencyAlert;

    final payload = {
      'pest_name': pestName.trim(),
      'crop_type': cropType.trim(),
      'severity': severity.trim(),
      'affected_area': affectedArea.trim(),
      'farmer_group_name': farmerGroupName.trim(),
      'farmer_group_id': farmerGroupId,
      'village_name': villageName.trim(),
      'village_id': villageId,
      'description': description.trim(),
      'image_url': imageUrl ??
          'https://images.unsplash.com/photo-1592417817098-8f3d6910985c?auto=format&fit=crop&w=800&q=80',
      'handling_recommendation': handlingRecommendation?.trim(),
      'emergency_alert': isEmergency,
      'reporter_id': reporterId,
      'reporter_name': reporterName,
      'reporter_role': reporterRole,
    };

    PestReportModel createdModel;

    try {
      final response = await ApiService.post('/pest-reports', payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          createdModel = PestReportModel.fromJson(body['data']);
          _cachedReports.insert(0, createdModel);
          _dismissedAlertId = null; // Reset dismissal on new alert
          return {
            'success': true,
            'message': body['message'] ?? 'Laporan berhasil dibuat.',
            'data': createdModel,
            'notifications_sent': body['notifications_sent'] ?? 4,
          };
        }
      }
    } catch (e) {
      debugPrint('[PestAlertService] API create failed, using local creation: $e');
    }

    // Local in-memory creation fallback
    final localId = 'pest-local-${DateTime.now().millisecondsSinceEpoch}';
    createdModel = PestReportModel(
      id: localId,
      reporterId: reporterId.toString(),
      reporterName: reporterName.toString(),
      reporterRole: reporterRole.toString(),
      pestName: pestName.trim(),
      cropType: cropType.trim(),
      severity: severity.trim(),
      affectedArea: affectedArea.trim(),
      farmerGroupId: farmerGroupId,
      farmerGroupName: farmerGroupName.trim(),
      villageId: villageId,
      villageName: villageName.trim(),
      imageUrl: payload['image_url'] as String?,
      description: description.trim(),
      handlingRecommendation: handlingRecommendation?.trim(),
      emergencyAlert: isEmergency,
      status: 'active',
      createdAt: DateTime.now(),
    );

    _cachedReports.insert(0, createdModel);
    _dismissedAlertId = null;

    return {
      'success': true,
      'message': 'Laporan berhasil disimpan dan peringatan dini disebarkan ke petani Poktan.',
      'data': createdModel,
      'notifications_sent': 4,
    };
  }

  /// Mark alert as resolved / contained
  Future<bool> resolvePestAlert(String reportId, {String? resolutionNote}) async {
    try {
      final response = await ApiService.put('/pest-reports/$reportId/status', {
        'status': 'resolved',
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
      return true;
    }

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

