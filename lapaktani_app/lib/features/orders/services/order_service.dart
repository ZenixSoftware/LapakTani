import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import 'notification_service.dart';
import '../../product/services/stock_service.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  static const String _storageKey = 'lapaktani_orders_store_v1';

  final ValueNotifier<List<OrderModel>> ordersNotifier = ValueNotifier<List<OrderModel>>([]);
  bool _isInitialized = false;

  List<OrderModel> get orders => ordersNotifier.value;

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        final loaded = list.map((e) => OrderModel.fromMap(e as Map<String, dynamic>)).toList();
        ordersNotifier.value = loaded;
        _isInitialized = true;
        return;
      } catch (_) {}
    }

    // Default Seed Data
    ordersNotifier.value = _buildInitialSeedOrders();
    await _saveToStorage();
    _isInitialized = true;
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final list = ordersNotifier.value.map((e) => e.toMap()).toList();
    await prefs.setString(_storageKey, jsonEncode(list));
  }

  OrderModel? getOrderById(String id) {
    try {
      return ordersNotifier.value.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? checkpointTitle,
    String? checkpointDesc,
    String? location,
  }) async {
    final currentList = List<OrderModel>.from(ordersNotifier.value);
    final index = currentList.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    final target = currentList[index];
    final now = DateTime.now();
    final timeStr = '${now.day} Okt ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';

    final updatedCheckpoints = target.checkpoints.map((c) {
      return TrackingCheckpoint(
        title: c.title,
        description: c.description,
        timestamp: c.timestamp,
        location: c.location,
        isCompleted: true,
        isCurrent: false,
      );
    }).toList();

    if (checkpointTitle != null) {
      updatedCheckpoints.insert(
        0,
        TrackingCheckpoint(
          title: checkpointTitle,
          description: checkpointDesc ?? 'Status diperbarui oleh sistem LapakTani',
          timestamp: timeStr,
          location: location ?? target.sellerLocation,
          isCompleted: true,
          isCurrent: true,
        ),
      );
    }

    currentList[index] = target.copyWith(
      status: newStatus,
      checkpoints: updatedCheckpoints,
    );

    if (newStatus == OrderStatus.cancelled && target.status != OrderStatus.cancelled) {
      for (final item in target.items) {
        final pid = item.productId ?? item.id;
        await StockService().restoreStock(pid, item.qty);
      }
    }

    ordersNotifier.value = currentList;
    await _saveToStorage();
  }

  /// Membatalkan pesanan dan mengembalikan stok otomatis
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    final target = getOrderById(orderId);
    if (target == null) return;
    for (final item in target.items) {
      final pid = item.productId ?? item.id;
      await StockService().restoreStock(pid, item.qty);
    }
    await updateOrderStatus(
      orderId,
      OrderStatus.cancelled,
      checkpointTitle: 'Pesanan Dibatalkan',
      checkpointDesc: reason ?? 'Pesanan telah dibatalkan. Stok komoditas otomatis dikembalikan ke etalase.',
    );
  }

  /// Petani menyelesaikan petik panen & pengemasan di ladang
  Future<void> processHarvest(String orderId, {String? notes}) async {
    final target = getOrderById(orderId);
    if (target == null) return;

    final now = DateTime.now();
    final timeStr = '${now.day} Okt ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';

    final updatedCheckpoints = target.checkpoints.map((c) {
      return TrackingCheckpoint(
        title: c.title,
        description: c.description,
        timestamp: c.timestamp,
        location: c.location,
        isCompleted: true,
        isCurrent: false,
      );
    }).toList();

    updatedCheckpoints.insert(
      0,
      TrackingCheckpoint(
        title: 'Panen Selesai Dipetik & Dikemas',
        description: notes ?? 'Petani telah menyortir kualitas panen segar dan mengemas ke dalam insulated box dingin.',
        timestamp: timeStr,
        location: target.sellerLocation,
        isCompleted: true,
        isCurrent: true,
      ),
    );

    final currentList = List<OrderModel>.from(ordersNotifier.value);
    final index = currentList.indexWhere((o) => o.id == orderId);
    currentList[index] = target.copyWith(
      status: OrderStatus.readyToShip,
      checkpoints: updatedCheckpoints,
    );

    ordersNotifier.value = currentList;
    await _saveToStorage();
  }

  /// Penyerahan paket panen ke kurir logistik
  Future<void> handoverToCourier(String orderId, {String? courierReceipt}) async {
    final target = getOrderById(orderId);
    if (target == null) return;

    final now = DateTime.now();
    final timeStr = '${now.day} Okt ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';

    final updatedCheckpoints = target.checkpoints.map((c) {
      return TrackingCheckpoint(
        title: c.title,
        description: c.description,
        timestamp: c.timestamp,
        location: c.location,
        isCompleted: true,
        isCurrent: false,
      );
    }).toList();

    updatedCheckpoints.insert(
      0,
      TrackingCheckpoint(
        title: 'Diserahkan ke Kurir Logistik LapakTani',
        description: 'Paket dijemput kurir ${target.courier.name} (${target.courier.serviceName}). Suhu cold box termonitor stabil ${target.temperature}.',
        timestamp: timeStr,
        location: target.sellerLocation,
        isCompleted: true,
        isCurrent: true,
      ),
    );

    final currentList = List<OrderModel>.from(ordersNotifier.value);
    final index = currentList.indexWhere((o) => o.id == orderId);
    currentList[index] = target.copyWith(
      status: OrderStatus.inTransit,
      checkpoints: updatedCheckpoints,
    );

    ordersNotifier.value = currentList;
    await _saveToStorage();
  }

  /// Pembeli / Kurir mengonfirmasi pesanan telah sampai
  Future<void> confirmDelivered(String orderId) async {
    final target = getOrderById(orderId);
    if (target == null) return;

    final now = DateTime.now();
    final timeStr = '${now.day} Okt ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';

    final updatedCheckpoints = target.checkpoints.map((c) {
      return TrackingCheckpoint(
        title: c.title,
        description: c.description,
        timestamp: c.timestamp,
        location: c.location,
        isCompleted: true,
        isCurrent: false,
      );
    }).toList();

    updatedCheckpoints.insert(
      0,
      TrackingCheckpoint(
        title: 'Pesanan Telah Tiba di Alamat Pembeli',
        description: 'Paket diterima oleh ${target.buyerName}. Kesegaran panen terverifikasi terjaga baik.',
        timestamp: timeStr,
        location: target.buyerAddress,
        isCompleted: true,
        isCurrent: true,
      ),
    );

    final currentList = List<OrderModel>.from(ordersNotifier.value);
    final index = currentList.indexWhere((o) => o.id == orderId);
    currentList[index] = target.copyWith(
      status: OrderStatus.completed,
      checkpoints: updatedCheckpoints,
    );

    ordersNotifier.value = currentList;
    await _saveToStorage();
  }

  /// Membuat pesanan baru dari checkout pembeli
  Future<OrderModel> createNewOrder({
    required String buyerName,
    required String buyerAddress,
    required String buyerPhone,
    required List<OrderItem> items,
    required int totalPrice,
    required int shippingFee,
    required String paymentMethod,
  }) async {
    final now = DateTime.now();
    final numSuffix = (now.millisecondsSinceEpoch % 90000 + 10000).toString();
    final orderId = '#TANI-$numSuffix';
    final trackingNo = 'LT-LOG-${now.year}${now.month.toString().padLeft(2, '0')}-$numSuffix';

    final newOrder = OrderModel(
      id: orderId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerAddress: buyerAddress,
      sellerName: 'Kebun Manik Sari (Pak Wayan)',
      sellerLocation: 'Ladang Batu, Malang, Jawa Timur',
      createdAt: now,
      status: OrderStatus.needHarvest,
      paymentMethod: paymentMethod,
      paymentStatus: 'Lunas',
      items: items,
      totalPrice: totalPrice,
      shippingFee: shippingFee,
      trackingNumber: trackingNo,
      estimatedDelivery: 'Hari ini, ${now.add(const Duration(hours: 3)).hour}:00 WIB',
      temperature: '4.8°C (Rantai Dingin)',
      courier: const CourierInfo(
        name: 'Budi Santoso',
        phone: '0812-8822-4119',
        vehicle: 'Honda Vario (N 4128 AB) • Insulated Box',
        serviceName: 'Kurir Tani Instan Cold-Chain',
        photoUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCUFEACpiCvSC4b9Ft-t0imRvyUJ8FC-OU2NMCdZZht8TwJAHuXxcAn2CjWVr1GjFWDF5cx5-sfhy_dknyIPXE7TshLCaGO0pcM306Oi2S0pl7LWUoWTrshboISnAf8ZXhLwnM6-XNnDiLdo4xgF7kkjrq4Jk9GUTi3CTmPNltB3qLM3HeDEpIl2Q-foXmnB31ypiSu33ksYofnLvL0A-TZSCa_BjYWe0YZyX095zG31JalH1N6OQ_M',
      ),
      checkpoints: [
        TrackingCheckpoint(
          title: 'Pesanan Terkonfirmasi & Masuk Antrean Petik',
          description: 'Pembayaran berhasil. Petani telah menerima daftar panen segar yang perlu dipetik.',
          timestamp: '${now.day} Okt ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB',
          location: 'Kebun Manik Sari, Batu',
          isCompleted: true,
          isCurrent: true,
        ),
      ],
    );

    final currentList = List<OrderModel>.from(ordersNotifier.value);
    currentList.insert(0, newOrder);
    ordersNotifier.value = currentList;
    await _saveToStorage();

    // Otomatis kurangi stok komoditas dan kirim notifikasi ke petani
    for (final item in items) {
      final pid = item.productId ?? item.id;
      await StockService().deductStock(pid, item.qty);
      await NotificationService().addOrderNotification(
        orderId: orderId,
        buyerName: buyerName,
        productName: item.title,
        qty: item.qty,
        unit: item.unit,
      );
    }

    return newOrder;
  }

  static List<OrderModel> _buildInitialSeedOrders() {
    return [
      OrderModel(
        id: '#TANI-89211',
        buyerName: 'Ibu Ratna Dewi',
        buyerPhone: '0813-2940-1182',
        buyerAddress: 'Jl. Maribaya No. 42, Lembang, Kab. Bandung Barat',
        sellerName: 'Kebun Manik Sari (Pak Wayan)',
        sellerLocation: 'Ladang Lereng Panderman, Batu, Jawa Timur',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        status: OrderStatus.needHarvest,
        paymentMethod: 'LapakPay',
        paymentStatus: 'Lunas',
        items: const [
          OrderItem(
            id: 'item-1',
            title: 'Tomat Merah Segar Organik',
            qty: 2,
            unit: 'kg',
            price: 24000,
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB7MFNm6fGiAm5QTKbvDcHMQ3fNnfFYJO_Kyt9JrlLi9bdKKdnbkUUFDVEY7mCNRqoT57wyH6E0LUIC1jGc0D-kArTwJmp2e_5daQ-YOhbRz6XPP7EYvLTgq5ALb_-pvxAwxa6jFCLpDRll8ED4v4Ji4zgioDov57ptO20jhk2yg-AMXM58Y1QEp-gsPaWJsmltO5szzG6PzNOWC0-PNC7sN4gPpfDUDJMz25zaMnEVC1MiKNDOCJB_',
            grade: 'Grade A Super',
          ),
          OrderItem(
            id: 'item-2',
            title: 'Kangkung Organik Segar',
            qty: 3,
            unit: 'ikat',
            price: 18000,
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBrS3ZtwnKUuZ4K0rT35rQua4KG1cyajZF_8MR1EroaYQyWIjp0_37qFaYqRl4G781JAABaiB_i4NVVSNsggcBvAjzV60ku1UH47FgTptcO92_3CABgJrOuztx_31wSGDZDWounJkqI8_FqYKa1jAvsPrKAQFkk8PIOpgcZM4DaVeZP_9LfJcN8wIx3LY6PBpvsWbpN_uMVUCnCcjr0SXnEcFsxdqgFnj8K6GiGFBP_riuNrkM15QV6',
            grade: 'Petik Pagi',
          ),
        ],
        totalPrice: 42000,
        shippingFee: 8000,
        trackingNumber: 'LT-LOG-202610-89211',
        estimatedDelivery: 'Hari ini, 16:30 WIB',
        temperature: '5.2°C (Optimal Segar)',
        courier: const CourierInfo(
          name: 'Agus Salim',
          phone: '0857-1928-3341',
          vehicle: 'Yamaha Gear (D 3821 TNY) • Cold Box',
          serviceName: 'Kurir Tani Instan (Motor)',
          photoUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCUFEACpiCvSC4b9Ft-t0imRvyUJ8FC-OU2NMCdZZht8TwJAHuXxcAn2CjWVr1GjFWDF5cx5-sfhy_dknyIPXE7TshLCaGO0pcM306Oi2S0pl7LWUoWTrshboISnAf8ZXhLwnM6-XNnDiLdo4xgF7kkjrq4Jk9GUTi3CTmPNltB3qLM3HeDEpIl2Q-foXmnB31ypiSu33ksYofnLvL0A-TZSCa_BjYWe0YZyX095zG31JalH1N6OQ_M',
        ),
        checkpoints: const [
          TrackingCheckpoint(
            title: 'Pesanan Dikonfirmasi Pembayaran',
            description: 'Pembayaran LapakPay berhasil diverifikasi. Notifikasi petik telah dikirimkan ke petani.',
            timestamp: '17 Okt 2026, 14:15 WIB',
            location: 'Sistem Pembayaran LapakTani',
            isCompleted: true,
            isCurrent: true,
          ),
          TrackingCheckpoint(
            title: 'Pesanan Masuk Antrean Panen Ladang',
            description: 'Petani bersiap memetik pesanan langsung di blok sayur daun dan tomat.',
            timestamp: '17 Okt 2026, 14:10 WIB',
            location: 'Kebun Manik Sari, Batu',
            isCompleted: true,
            isCurrent: false,
          ),
        ],
      ),
      OrderModel(
        id: '#TANI-89204',
        buyerName: 'Resto Sambal Cobek',
        buyerPhone: '0821-4455-9011',
        buyerAddress: 'Jl. Riau No. 88, Citarum, Kota Bandung',
        sellerName: 'Kebun Manik Sari (Pak Wayan)',
        sellerLocation: 'Ladang Lereng Panderman, Batu, Jawa Timur',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: OrderStatus.inTransit,
        paymentMethod: 'COD (Tunai saat Sampai)',
        paymentStatus: 'Menunggu Pelunasan',
        items: const [
          OrderItem(
            id: 'item-3',
            title: 'Kentang Dieng Super Granola',
            qty: 5,
            unit: 'kg',
            price: 80000,
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDQfZ8rlRVHk2qkSfC0zsPq1XBOalKVCjz-SK27JBESez2nkF4XHUYWP-swEAKZngWukUvo9Df9G4f9trDz2JqjpoyfGClJ80yD76cURQ-33wsz7GIkmINCKucwTcWZEnF2pKg9NyLwAzB8N_BqidBu0XttzgLQW9bD7fi9kRgYANzWxfO6nmsMw7hQFcHN0cewb8hFiACXv_6zfeZxZ3i9LjW0DRx3RO8-cnPTrZIREWEzmDEUovQr',
            grade: 'Grade A',
          ),
        ],
        totalPrice: 80000,
        shippingFee: 15000,
        trackingNumber: 'LT-LOG-202610-89204',
        estimatedDelivery: 'Hari ini, 17:00 WIB',
        temperature: '6.0°C (Kargo Pendingin)',
        courier: const CourierInfo(
          name: 'Dadang Hendrawan',
          phone: '0812-7711-2093',
          vehicle: 'Isuzu Traga Cold Box (D 8192 LK)',
          serviceName: 'Kargo Pendingin Mitra LapakTani',
          photoUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCUFEACpiCvSC4b9Ft-t0imRvyUJ8FC-OU2NMCdZZht8TwJAHuXxcAn2CjWVr1GjFWDF5cx5-sfhy_dknyIPXE7TshLCaGO0pcM306Oi2S0pl7LWUoWTrshboISnAf8ZXhLwnM6-XNnDiLdo4xgF7kkjrq4Jk9GUTi3CTmPNltB3qLM3HeDEpIl2Q-foXmnB31ypiSu33ksYofnLvL0A-TZSCa_BjYWe0YZyX095zG31JalH1N6OQ_M',
        ),
        checkpoints: const [
          TrackingCheckpoint(
            title: 'Kurir Sedang Menuju Alamat Resto',
            description: 'Kargo berpendingin sedang dalam perjalanan dari Hub Sortir Bandung menuju alamat tujuan.',
            timestamp: '17 Okt 2026, 15:40 WIB',
            location: 'Jl. Laswi, Kota Bandung',
            isCompleted: true,
            isCurrent: true,
          ),
          TrackingCheckpoint(
            title: 'Tiba di Hub Distribusi Regional Bandung',
            description: 'Pengecekan kualitas dan verifikasi suhu peti kemas selesai dengan suhu 5.8°C.',
            timestamp: '17 Okt 2026, 14:30 WIB',
            location: 'Hub Logistik LapakTani Bandung',
            isCompleted: true,
            isCurrent: false,
          ),
          TrackingCheckpoint(
            title: 'Paket Dijemput dari Kebun Petani',
            description: 'Kurir kargo menerima 1 peti kemas kayu berventilasi dengan label kesegaran.',
            timestamp: '17 Okt 2026, 13:10 WIB',
            location: 'Kebun Manik Sari, Batu',
            isCompleted: true,
            isCurrent: false,
          ),
          TrackingCheckpoint(
            title: 'Petani Selesai Memilih & Membersihkan Umbi',
            description: 'Kentang disortir tanpa cacat, tanah dibersihkan, dan dikemas rapi.',
            timestamp: '17 Okt 2026, 12:30 WIB',
            location: 'Ladang Batu, Jawa Timur',
            isCompleted: true,
            isCurrent: false,
          ),
        ],
      ),
      OrderModel(
        id: '#TANI-89198',
        buyerName: 'Bp. Hendra Kusuma',
        buyerPhone: '0811-9201-8422',
        buyerAddress: 'Komplek Permata Cimahi Blok D2 No. 15, Cimahi',
        sellerName: 'Kebun Manik Sari (Pak Wayan)',
        sellerLocation: 'Ladang Lereng Panderman, Batu, Jawa Timur',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        status: OrderStatus.completed,
        paymentMethod: 'LapakPay',
        paymentStatus: 'Lunas',
        items: const [
          OrderItem(
            id: 'item-4',
            title: 'Jagung Manis Madu Organik Segar',
            qty: 2,
            unit: 'pack 1kg',
            price: 29000,
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBNcxC9AeGcJKDIKXvZnkUXpXQZacY4jyGWOKanfYvqS4ASLYkIBwQjNacsUbP2-m6R_Y9vclnMXfhUcZxPTWuAfY8jNDLTyotuWyQ4yQvMPJJIw1-ajA8Ma5dYzNElMD1xuF8PZCuWe3pzX6ndDMhLxrGhW0IPRZv-3PiQi5iIj32W5nns2mpa2U_Npkhkj2u1hAAXDVuhrzE4Mc7gwvqybgAI30IdJCwbwqHEIqVoZEYZ5WnQs2lh',
            grade: 'Grade A',
          ),
        ],
        totalPrice: 29000,
        shippingFee: 10000,
        trackingNumber: 'LT-LOG-202610-89198',
        estimatedDelivery: 'Kemarin, 16:00 WIB',
        temperature: '5.0°C (Selesai)',
        courier: const CourierInfo(
          name: 'Agus Salim',
          phone: '0857-1928-3341',
          vehicle: 'Yamaha Gear (D 3821 TNY) • Cold Box',
          serviceName: 'Kurir Tani Instan (Motor)',
          photoUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCUFEACpiCvSC4b9Ft-t0imRvyUJ8FC-OU2NMCdZZht8TwJAHuXxcAn2CjWVr1GjFWDF5cx5-sfhy_dknyIPXE7TshLCaGO0pcM306Oi2S0pl7LWUoWTrshboISnAf8ZXhLwnM6-XNnDiLdo4xgF7kkjrq4Jk9GUTi3CTmPNltB3qLM3HeDEpIl2Q-foXmnB31ypiSu33ksYofnLvL0A-TZSCa_BjYWe0YZyX095zG31JalH1N6OQ_M',
        ),
        checkpoints: const [
          TrackingCheckpoint(
            title: 'Pesanan Selesai Diterima Pembeli',
            description: 'Paket telah diterima dengan baik oleh Bp. Hendra Kusuma dalam kondisi segar dan manis.',
            timestamp: '16 Okt 2026, 15:50 WIB',
            location: 'Komplek Permata Cimahi',
            isCompleted: true,
            isCurrent: true,
          ),
          TrackingCheckpoint(
            title: 'Kurir Tiba di Lokasi Pengantaran',
            description: 'Kurir menyerahkan paket berlabel jaminan segar.',
            timestamp: '16 Okt 2026, 15:45 WIB',
            location: 'Cimahi, Jawa Barat',
            isCompleted: true,
            isCurrent: false,
          ),
          TrackingCheckpoint(
            title: 'Paket Diambil dari Ladang',
            description: 'Jagung manis dipetik subuh pukul 05:30 WIB dan diserahkan ke kurir.',
            timestamp: '16 Okt 2026, 09:15 WIB',
            location: 'Kebun Manik Sari, Batu',
            isCompleted: true,
            isCurrent: false,
          ),
        ],
      ),
      OrderModel(
        id: '#TANI-89182',
        buyerName: 'Warung Berkah Ibu Siti',
        buyerPhone: '0819-3321-0099',
        buyerAddress: 'Pasar Atas Cimahi No. 12, Cimahi Tengah',
        sellerName: 'Kebun Manik Sari (Pak Wayan)',
        sellerLocation: 'Ladang Lereng Panderman, Batu, Jawa Timur',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        status: OrderStatus.pendingPayment,
        paymentMethod: 'Transfer Bank Mandiri Virtual Account',
        paymentStatus: 'Menunggu Pembayaran',
        items: const [
          OrderItem(
            id: 'item-5',
            title: 'Wortel Manis Berastagi Super',
            qty: 3,
            unit: 'kg',
            price: 33000,
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBrS3ZtwnKUuZ4K0rT35rQua4KG1cyajZF_8MR1EroaYQyWIjp0_37qFaYqRl4G781JAABaiB_i4NVVSNsggcBvAjzV60ku1UH47FgTptcO92_3CABgJrOuztx_31wSGDZDWounJkqI8_FqYKa1jAvsPrKAQFkk8PIOpgcZM4DaVeZP_9LfJcN8wIx3LY6PBpvsWbpN_uMVUCnCcjr0SXnEcFsxdqgFnj8K6GiGFBP_riuNrkM15QV6',
            grade: 'Grade A',
          ),
        ],
        totalPrice: 33000,
        shippingFee: 10000,
        trackingNumber: 'LT-LOG-202610-89182',
        estimatedDelivery: 'Besok, 12:00 WIB',
        temperature: '4-8°C Standar',
        courier: const CourierInfo(
          name: 'Tim Logistik LapakTani',
          phone: '0800-1-LAPAK',
          vehicle: 'Armada Pengiriman Pertanian',
          serviceName: 'Reguler Tani Dingin',
        ),
        checkpoints: const [
          TrackingCheckpoint(
            title: 'Menunggu Pembayaran dari Pembeli',
            description: 'Pesanan telah dibuat. Silakan transfer ke VA Mandiri 8890-1289-89182 sebelum 24 jam.',
            timestamp: '17 Okt 2026, 11:30 WIB',
            location: 'Sistem Pembayaran LapakTani',
            isCompleted: true,
            isCurrent: true,
          ),
        ],
      ),
    ];
  }
}
