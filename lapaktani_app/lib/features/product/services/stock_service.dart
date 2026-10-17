import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';

class StockService {
  static final StockService _instance = StockService._internal();
  factory StockService() => _instance;
  StockService._internal();

  static const String _storageKey = 'lapaktani_product_stocks_v1';

  final ValueNotifier<Map<String, int>> stockNotifier = ValueNotifier<Map<String, int>>({});
  bool _isInitialized = false;

  static final Map<String, int> _defaultStocks = {
    'demo-1': 25, // Kangkung Organik
    'demo-2': 150, // Tomat Merah Segar
    'demo-3': 80, // Kentang Dieng Super
    'prod-1': 40, // Jagung Manis Madu
    'prod-2': 65, // Wortel Manis Berastagi
    'prod-3': 120, // Tomat Merah Petik Subuh
    'prod-4': 95, // Kentang Granola
  };

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
        final Map<String, int> loaded = {};
        decoded.forEach((key, value) {
          loaded[key] = (value as num).toInt();
        });
        stockNotifier.value = loaded;
        _isInitialized = true;
        return;
      } catch (_) {}
    }

    stockNotifier.value = Map<String, int>.from(_defaultStocks);
    await _saveToStorage();
    _isInitialized = true;
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(stockNotifier.value));
  }

  int getStock(String productId, {int fallback = 50}) {
    if (stockNotifier.value.containsKey(productId)) {
      return stockNotifier.value[productId]!;
    }
    return fallback;
  }

  bool isAvailable(String productId, int requestedQty, {int fallback = 50}) {
    final currentStock = getStock(productId, fallback: fallback);
    return currentStock >= requestedQty;
  }

  /// Pengurangan stok otomatis saat pesanan dibuat
  Future<bool> deductStock(String productId, int qty, {int fallback = 50}) async {
    await init();
    final currentStocks = Map<String, int>.from(stockNotifier.value);
    final current = currentStocks[productId] ?? fallback;

    if (current < qty) {
      return false; // Stok tidak mencukupi
    }

    final newStock = current - qty;
    currentStocks[productId] = newStock;
    stockNotifier.value = currentStocks;
    await _saveToStorage();

    // Sync to backend if possible
    _syncDeductStockToBackend(productId, qty);
    return true;
  }

  /// Pengembalian stok otomatis saat pesanan dibatalkan
  Future<void> restoreStock(String productId, int qty, {int fallback = 50}) async {
    await init();
    final currentStocks = Map<String, int>.from(stockNotifier.value);
    final current = currentStocks[productId] ?? fallback;

    final newStock = current + qty;
    currentStocks[productId] = newStock;
    stockNotifier.value = currentStocks;
    await _saveToStorage();

    _syncRestoreStockToBackend(productId, qty);
  }

  /// Update manual oleh petani
  Future<void> updateStock(String productId, int newStock) async {
    await init();
    final currentStocks = Map<String, int>.from(stockNotifier.value);
    currentStocks[productId] = newStock < 0 ? 0 : newStock;
    stockNotifier.value = currentStocks;
    await _saveToStorage();

    _syncStockToBackend(productId, currentStocks[productId]!);
  }

  void _syncDeductStockToBackend(String productId, int qty) async {
    try {
      await ApiService.post('/products/$productId/deduct-stock', {
        'qty': qty,
      });
    } catch (_) {
      // Offline fallback: stock remains persistent in SharedPreferences
    }
  }

  void _syncRestoreStockToBackend(String productId, int qty) async {
    try {
      await ApiService.post('/products/$productId/restore-stock', {
        'qty': qty,
      });
    } catch (_) {
      // Offline fallback: stock remains persistent in SharedPreferences
    }
  }

  void _syncStockToBackend(String productId, int newStock) async {
    try {
      await ApiService.put('/products/$productId', {
        'stock_kg': newStock,
      });
    } catch (_) {
      // Offline fallback: stock remains persistent in SharedPreferences
    }
  }
}
