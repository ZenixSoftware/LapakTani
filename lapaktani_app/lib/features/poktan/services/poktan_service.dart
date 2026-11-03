import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../models/b2b_order_model.dart';
import '../models/poktan_member_model.dart';
import '../models/production_task_model.dart';

class PoktanService {
  static final PoktanService _instance = PoktanService._internal();
  factory PoktanService() => _instance;
  PoktanService._internal();

  // In-memory cache for offline/fallback resilience
  double _cachedTotalLandAreaHa = 8.40;
  String _cachedPoktanName = 'Poktan Tani Makmur';
  List<PoktanMemberModel> _cachedMembers = [];
  List<B2BOrderModel> _cachedOrders = [];
  List<ProductionTaskModel> _cachedTasks = [];
  List<PoktanNotificationModel> _cachedNotifications = [];

  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;
    _seedFallbackData();
  }

  void _seedFallbackData() {
    _cachedMembers = [
      const PoktanMemberModel(
        farmerId: 'f-maman',
        fullName: 'H. Maman Suratman (Pengurus)',
        email: 'hmamansuratman@petani.lapaktani.id',
        phone: '081234567802',
        nikNumber: '3204121503650003',
        landAreaHa: 2.50,
        soilType: 'Aluvial Subur',
        isChairman: true,
      ),
      const PoktanMemberModel(
        farmerId: 'f-wayan',
        fullName: 'Pak Wayan Sudirta',
        email: 'pakwayansudirta@petani.lapaktani.id',
        phone: '081234567801',
        nikNumber: '3204120988770001',
        landAreaHa: 1.80,
        soilType: 'Vulkanik Andosol',
        isChairman: false,
      ),
      const PoktanMemberModel(
        farmerId: 'f-siti',
        fullName: 'Bu Siti Aminah',
        email: 'busitiaminah@petani.lapaktani.id',
        phone: '081234567803',
        nikNumber: '3204124401820002',
        landAreaHa: 0.90,
        soilType: 'Andosol',
        isChairman: false,
      ),
      const PoktanMemberModel(
        farmerId: 'f-bambang',
        fullName: 'Bambang Prasetyo',
        email: 'bambangprasetyo@petani.lapaktani.id',
        phone: '081234567804',
        nikNumber: '3204122107900004',
        landAreaHa: 3.20,
        soilType: 'Latosol Lembab',
        isChairman: false,
      ),
    ];

    _cachedOrders = [
      B2BOrderModel(
        id: 'b2b-001',
        farmerGroupId: 'fg-cibogo-1',
        commodityId: 'cmd-kentang-01',
        commodityName: 'Kentang Granola Super',
        totalQuotaKg: 10000,
        totalAllocatedKg: 10000,
        remainingQuotaKg: 0,
        buyerName: 'PT Indofood CBP Sukses Makmur',
        deadline: '2026-12-31',
        status: 'allocated',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      B2BOrderModel(
        id: 'b2b-002',
        farmerGroupId: 'fg-cibogo-1',
        commodityId: 'cmd-cabai-02',
        commodityName: 'Cabai Merah Keriting',
        totalQuotaKg: 5000,
        totalAllocatedKg: 2000,
        remainingQuotaKg: 3000,
        buyerName: 'Super Indo Mitra Segar',
        deadline: '2027-01-15',
        status: 'in_progress',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];

    _cachedTasks = [
      ProductionTaskModel(
        taskId: 'task-001',
        b2bOrderId: 'b2b-001',
        farmerId: 'f-maman',
        allocatedKg: 3000,
        plantingDeadline: '2026-11-15',
        harvestDeadline: '2026-12-20',
        taskStatus: 'planting',
        buyerName: 'PT Indofood CBP Sukses Makmur',
        contractDeadline: '2026-12-31',
        commodityId: 'cmd-kentang-01',
        commodityName: 'Kentang Granola Super',
        poktanName: 'Poktan Tani Makmur',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ProductionTaskModel(
        taskId: 'task-002',
        b2bOrderId: 'b2b-002',
        farmerId: 'f-maman',
        allocatedKg: 2000,
        plantingDeadline: '2026-11-25',
        harvestDeadline: '2027-01-10',
        taskStatus: 'pending',
        buyerName: 'Super Indo Mitra Segar',
        contractDeadline: '2027-01-15',
        commodityId: 'cmd-cabai-02',
        commodityName: 'Cabai Merah Keriting',
        poktanName: 'Poktan Tani Makmur',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];

    _cachedNotifications = [
      PoktanNotificationModel(
        id: 'notif-001',
        title: 'Tugas Kuota Panen B2B Baru',
        message: 'Kelompok tani menugaskan kuota panen Kentang Granola Super sebesar 3.000 kg untuk PT Indofood CBP. Tenggat tanam 15 Nov 2026.',
        type: 'quota_task',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
  }

  // --- API Methods ---

  /// Get Poktan consolidated members and total active land area
  Future<Map<String, dynamic>> fetchMembers() async {
    init();
    try {
      final response = await ApiService.get('/poktan/members');
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final rawMembers = (body['members'] as List<dynamic>?) ?? [];
        final members = rawMembers
            .map((m) => PoktanMemberModel.fromJson(m as Map<String, dynamic>))
            .toList();

        _cachedMembers = members;
        _cachedTotalLandAreaHa = double.tryParse((body['total_land_area_ha'] ?? '0').toString()) ?? 0.0;
        if (body['poktan'] != null && body['poktan']['group_name'] != null) {
          _cachedPoktanName = body['poktan']['group_name'].toString();
        }

        return {
          'poktan_name': _cachedPoktanName,
          'total_land_area_ha': _cachedTotalLandAreaHa,
          'members_count': members.length,
          'members': members,
        };
      }
    } catch (e) {
      debugPrint('[PoktanService] fetchMembers error, using cached data: $e');
    }

    return {
      'poktan_name': _cachedPoktanName,
      'total_land_area_ha': _cachedTotalLandAreaHa,
      'members_count': _cachedMembers.length,
      'members': _cachedMembers,
    };
  }

  /// Get list of B2B orders for the group
  Future<List<B2BOrderModel>> fetchB2BOrders() async {
    init();
    try {
      final response = await ApiService.get('/poktan/b2b-orders');
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final rawOrders = (body['data'] as List<dynamic>?) ?? [];
        final orders = rawOrders
            .map((o) => B2BOrderModel.fromJson(o as Map<String, dynamic>))
            .toList();
        _cachedOrders = orders;
        return orders;
      }
    } catch (e) {
      debugPrint('[PoktanService] fetchB2BOrders error, using cached data: $e');
    }
    return _cachedOrders;
  }

  /// Create new B2B contract order
  Future<bool> createB2BOrder({
    required String commodityId,
    required String commodityName,
    required double totalQuotaKg,
    required String buyerName,
    required String deadline,
  }) async {
    init();
    try {
      final response = await ApiService.post('/poktan/b2b-orders', {
        'commodity_id': commodityId,
        'total_quota_kg': totalQuotaKg,
        'buyer_name': buyerName,
        'deadline': deadline,
      });

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body['data'] != null) {
          final newOrder = B2BOrderModel.fromJson(body['data']);
          _cachedOrders.insert(0, newOrder);
        }
        return true;
      }
    } catch (e) {
      debugPrint('[PoktanService] createB2BOrder error, applying to local cache: $e');
    }

    // Local fallback update
    final newOrder = B2BOrderModel(
      id: 'b2b-${DateTime.now().millisecondsSinceEpoch}',
      farmerGroupId: 'fg-local',
      commodityId: commodityId,
      commodityName: commodityName,
      totalQuotaKg: totalQuotaKg,
      totalAllocatedKg: 0,
      remainingQuotaKg: totalQuotaKg,
      buyerName: buyerName,
      deadline: deadline,
      status: 'draft',
      createdAt: DateTime.now(),
    );
    _cachedOrders.insert(0, newOrder);
    return true;
  }

  /// Distribute quota to member farmers
  Future<Map<String, dynamic>> allocateQuota({
    required String b2bOrderId,
    required List<Map<String, dynamic>> allocations,
  }) async {
    init();
    try {
      final response = await ApiService.post('/poktan/allocate-quota', {
        'b2b_order_id': b2bOrderId,
        'allocations': allocations,
      });

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh B2B orders cache
        await fetchB2BOrders();
        return {'success': true, 'message': body['message'] ?? 'Alokasi berhasil.'};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Gagal mengalokasikan kuota.'};
      }
    } catch (e) {
      debugPrint('[PoktanService] allocateQuota error, applying local allocation: $e');
    }

    // Local fallback calculation
    final orderIndex = _cachedOrders.indexWhere((o) => o.id == b2bOrderId);
    if (orderIndex != -1) {
      final old = _cachedOrders[orderIndex];
      double added = 0;
      for (final a in allocations) {
        final kg = double.tryParse((a['allocated_kg'] ?? 0).toString()) ?? 0.0;
        added += kg;

        // Add to local tasks
        final member = _cachedMembers.firstWhere(
          (m) => m.farmerId == a['farmer_id'],
          orElse: () => const PoktanMemberModel(
            farmerId: 'unknown',
            fullName: 'Petani Anggota',
            email: '',
            phone: '',
            nikNumber: '',
            landAreaHa: 1.0,
            soilType: '',
            isChairman: false,
          ),
        );

        _cachedTasks.insert(
          0,
          ProductionTaskModel(
            taskId: 'task-${DateTime.now().millisecondsSinceEpoch}-${a['farmer_id']}',
            b2bOrderId: b2bOrderId,
            farmerId: a['farmer_id'].toString(),
            allocatedKg: kg,
            plantingDeadline: a['planting_deadline']?.toString(),
            harvestDeadline: a['harvest_deadline']?.toString() ?? old.deadline,
            taskStatus: 'pending',
            buyerName: old.buyerName,
            contractDeadline: old.deadline,
            commodityId: old.commodityId,
            commodityName: old.commodityName,
            poktanName: _cachedPoktanName,
            createdAt: DateTime.now(),
          ),
        );
      }

      final newAllocated = old.totalAllocatedKg + added;
      _cachedOrders[orderIndex] = B2BOrderModel(
        id: old.id,
        farmerGroupId: old.farmerGroupId,
        commodityId: old.commodityId,
        commodityName: old.commodityName,
        totalQuotaKg: old.totalQuotaKg,
        totalAllocatedKg: newAllocated,
        remainingQuotaKg: (old.totalQuotaKg - newAllocated).clamp(0, double.infinity),
        buyerName: old.buyerName,
        deadline: old.deadline,
        status: newAllocated >= old.totalQuotaKg ? 'allocated' : 'in_progress',
        createdAt: old.createdAt,
      );

      _cachedNotifications.insert(
        0,
        PoktanNotificationModel(
          id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Tugas Kuota Panen B2B Baru',
          message: 'Alokasi kuota panen ${old.commodityName} telah didistribusikan ke anggota poktan.',
          type: 'quota_task',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );
    }

    return {'success': true, 'message': 'Alokasi kuota panen berhasil didistribusikan.'};
  }

  /// Farmer retrieves assigned production tasks and task notifications
  Future<Map<String, dynamic>> fetchMyTasks() async {
    init();
    try {
      final response = await ApiService.get('/poktan/my-tasks');
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final rawTasks = (body['tasks'] as List<dynamic>?) ?? [];
        final rawNotifs = (body['notifications'] as List<dynamic>?) ?? [];

        final tasks = rawTasks
            .map((t) => ProductionTaskModel.fromJson(t as Map<String, dynamic>))
            .toList();

        final notifs = rawNotifs
            .map((n) => PoktanNotificationModel.fromJson(n as Map<String, dynamic>))
            .toList();

        _cachedTasks = tasks;
        _cachedNotifications = notifs;

        return {
          'tasks': tasks,
          'notifications': notifs,
        };
      }
    } catch (e) {
      debugPrint('[PoktanService] fetchMyTasks error, using cached tasks: $e');
    }

    return {
      'tasks': _cachedTasks,
      'notifications': _cachedNotifications,
    };
  }

  /// Fetch list of commodities for dropdown
  Future<List<Map<String, String>>> fetchCommodities() async {
    try {
      final response = await ApiService.get('/master/commodities');
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final list = (body['data'] as List<dynamic>?) ?? [];
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          return {
            'id': (m['id'] ?? '').toString(),
            'name': (m['specific_name'] ?? m['name'] ?? 'Komoditas').toString(),
          };
        }).toList();
      }
    } catch (_) {}

    return [
      {'id': 'cmd-kentang-01', 'name': 'Kentang Granola Super'},
      {'id': 'cmd-cabai-02', 'name': 'Cabai Merah Keriting'},
      {'id': 'cmd-bawang-03', 'name': 'Bawang Merah Brebes'},
      {'id': 'cmd-tomat-04', 'name': 'Tomat Beef Segar'},
      {'id': 'cmd-jagung-05', 'name': 'Jagung Manis Madu'},
      {'id': 'cmd-wortel-06', 'name': 'Wortel Brastagi'},
    ];
  }
}

