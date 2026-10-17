import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _storageKey = 'lapaktani_farmer_notifications_v1';

  final ValueNotifier<List<NotificationModel>> notificationsNotifier =
      ValueNotifier<List<NotificationModel>>([]);
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  bool _isInitialized = false;

  List<NotificationModel> get notifications => notificationsNotifier.value;
  int get unreadCount => unreadCountNotifier.value;

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        final loaded = list
            .map((e) => NotificationModel.fromMap(e as Map<String, dynamic>))
            .toList();
        notificationsNotifier.value = loaded;
        _recalculateUnread();
        _isInitialized = true;
        return;
      } catch (_) {}
    }

    // Default initial seed notifications
    notificationsNotifier.value = _buildInitialNotifications();
    _recalculateUnread();
    await _saveToStorage();
    _isInitialized = true;
  }

  void _recalculateUnread() {
    unreadCountNotifier.value =
        notificationsNotifier.value.where((n) => !n.isRead).length;
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final list = notificationsNotifier.value.map((e) => e.toMap()).toList();
    await prefs.setString(_storageKey, jsonEncode(list));
    _recalculateUnread();
  }

  /// Tambah notifikasi saat ada pesanan masuk baru
  Future<void> addOrderNotification({
    required String orderId,
    required String buyerName,
    required String productName,
    required int qty,
    required String unit,
  }) async {
    await init();
    final now = DateTime.now();
    final newNotif = NotificationModel(
      id: 'notif-${now.millisecondsSinceEpoch}',
      orderId: orderId,
      title: 'Pesanan Masuk Baru: $orderId',
      message:
          '$buyerName baru saja memesan $qty $unit $productName. Segera petik dari ladang dan siapkan sebelum jadwal penjemputan.',
      createdAt: now,
      isRead: false,
      type: 'order_incoming',
    );

    final current = List<NotificationModel>.from(notificationsNotifier.value);
    current.insert(0, newNotif);
    notificationsNotifier.value = current;
    await _saveToStorage();
  }

  Future<void> markAsRead(String id) async {
    final current = List<NotificationModel>.from(notificationsNotifier.value);
    final idx = current.indexWhere((n) => n.id == id);
    if (idx != -1) {
      current[idx] = current[idx].copyWith(isRead: true);
      notificationsNotifier.value = current;
      await _saveToStorage();
    }
  }

  Future<void> markAllAsRead() async {
    final current = notificationsNotifier.value.map((n) {
      return n.copyWith(isRead: true);
    }).toList();
    notificationsNotifier.value = current;
    await _saveToStorage();
  }

  Future<void> clearAll() async {
    notificationsNotifier.value = [];
    await _saveToStorage();
  }

  static List<NotificationModel> _buildInitialNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: 'notif-seed-1',
        orderId: '#TANI-89211',
        title: 'Pesanan Masuk Baru: #TANI-89211',
        message:
            'Ibu Ratna Dewi memesan 2 kg Tomat Merah Organik dan 3 ikat Kangkung. Batas petik: 10.00 WIB.',
        createdAt: now.subtract(const Duration(minutes: 15)),
        isRead: false,
        type: 'order_incoming',
      ),
      NotificationModel(
        id: 'notif-seed-2',
        orderId: '#TANI-89204',
        title: 'Kurir Menuju Ladang: #TANI-89204',
        message:
            'Kurir Dadang (Kargo Pendingin) sedang dalam perjalanan menjemput 5 kg Kentang Dieng.',
        createdAt: now.subtract(const Duration(hours: 1)),
        isRead: false,
        type: 'courier_pickup',
      ),
      NotificationModel(
        id: 'notif-seed-3',
        orderId: '#TANI-89198',
        title: 'Pesanan Selesai: #TANI-89198',
        message:
            'Bp. Hendra Kusuma telah mengonfirmasi penerimaan 2 pack Jagung Manis Madu. Dana telah diteruskan ke dompet tani Anda.',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
        type: 'order_incoming',
      ),
    ];
  }
}
