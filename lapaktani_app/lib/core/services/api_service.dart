import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'https://backslid-salvage-moocher.ngrok-free.dev/api';
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'auth_user';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  final http.Client _client = http.Client();

  Future<String?> getToken() async {
    try {
      final secureToken = await _secureStorage.read(key: tokenKey);
      if (secureToken != null && secureToken.isNotEmpty) {
        return secureToken;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString(tokenKey) ??
          prefs.getString('lapaktani_token') ??
          prefs.getString('token') ??
          prefs.getString('auth_token');

      if (legacyToken != null && legacyToken.isNotEmpty) {
        await _secureStorage.write(key: tokenKey, value: legacyToken);
        await prefs.remove(tokenKey);
        await prefs.remove('lapaktani_token');
        await prefs.remove('token');
        await prefs.remove('auth_token');
        return legacyToken;
      }
    } catch (_) {}

    return null;
  }

  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: tokenKey, value: token);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      await prefs.remove('lapaktani_token');
      await prefs.remove('token');
      await prefs.remove('auth_token');
    } catch (_) {}
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(userKey) ?? prefs.getString('user');
    if (userStr == null) return null;
    try {
      return jsonDecode(userStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAuth() async {
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      await prefs.remove('lapaktani_token');
      await prefs.remove('token');
      await prefs.remove('auth_token');
      await prefs.remove(userKey);
      await prefs.remove('user');
    } catch (_) {}
  }

  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  static Future<http.Response> get(String path) => _instance._fetchGet(path);

  Future<List<dynamic>> getProducts({String? query}) async {
    try {
      final String path = (query != null && query.trim().isNotEmpty)
          ? '/products?search=${Uri.encodeComponent(query.trim())}'
          : '/products';
      final response = await _fetchGet(path);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> list = (body['data'] as List<dynamic>?) ?? [];
        if (query != null && query.trim().isNotEmpty) {
          final q = query.trim().toLowerCase();
          return list.where((item) {
            if (item is! Map) return false;
            final title = (item['title'] ?? '').toString().toLowerCase();
            final category = (item['category'] ?? '').toString().toLowerCase();
            final grade = (item['grade'] ?? '').toString().toLowerCase();
            final poktan = (item['poktan_name'] ?? '').toString().toLowerCase();
            final village = (item['village_name'] ?? '').toString().toLowerCase();
            return title.contains(q) ||
                category.contains(q) ||
                grade.contains(q) ||
                poktan.contains(q) ||
                village.contains(q);
          }).toList();
        }
        return list;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final response = await _fetchGet('/cart');
      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> list = (body['data'] as List<dynamic>?) ??
            (body['items'] as List<dynamic>?) ??
            (body['cart'] as List<dynamic>?) ??
            [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> addToCart({
    required String productId,
    int quantity = 1,
    String? gradeId,
  }) async {
    try {
      final response = await _post('/cart', {
        'product_id': productId,
        'quantity': quantity,
        'grade_id': ?gradeId,
      });
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCartQty({
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      final response = await _put('/cart/$cartItemId', {
        'quantity': quantity,
      });
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeCartItem(String cartItemId) async {
    try {
      final response = await _delete('/cart/$cartItemId');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearCart() async {
    try {
      final response = await _delete('/cart');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> createCheckoutOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required int shippingFee,
    required String courierService,
    String paymentMethod = 'LAPAKPAY_SIMULATOR',
  }) async {
    final response = await _post('/orders/checkout', {
      'items': items,
      'delivery_address': deliveryAddress,
      'shipping_fee': shippingFee,
      'courier_service': courierService,
      'payment_method': paymentMethod,
    });

    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded['success'] == true) {
        return decoded['data'] as Map<String, dynamic>?;
      }
    } else {
      throw Exception(decoded['message'] ?? 'Gagal memproses pesanan (${response.statusCode})');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getMyOrders() async {
    try {
      final response = await _fetchGet('/orders/my-orders');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFarmerOrders() async {
    try {
      final response = await _fetchGet('/orders/farmer/orders');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final response = await _put('/orders/$orderId/status', {
        'status': newStatus,
        'order_status': newStatus,
      });
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final result = Map<String, dynamic>.from(decoded);
          if (decoded['data'] is Map) {
            result.addAll(Map<String, dynamic>.from(decoded['data']));
          }
          result['status'] ??= newStatus;
          return result;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSoilTelemetry(String productId) async {
    try {
      final response = await _fetchGet('/soil/telemetry/$productId');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is Map) {
          return Map<String, dynamic>.from(decoded['data']);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final response = await _fetchGet('/orders/$orderId');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is Map) {
          return Map<String, dynamic>.from(decoded['data']);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> chargeMidtrans({
    required String orderId,
    required double amount,
    required String paymentType,
    String? bank,
  }) async {
    try {
      final payload = {
        'order_id': orderId,
        'gross_amount': amount,
        'payment_type': paymentType,
        'bank': ?bank,
      };
      final response = await _post('/payments/charge', payload);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is Map) {
          return Map<String, dynamic>.from(decoded['data']);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkPaymentStatus(String orderId) async {
    try {
      final response = await _fetchGet('/payments/status/$orderId');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is Map) {
          return Map<String, dynamic>.from(decoded['data']);
        }
      }
      return await getOrderPaymentStatus(orderId);
    } catch (_) {
      return await getOrderPaymentStatus(orderId);
    }
  }

  Future<Map<String, dynamic>?> getOrderPaymentStatus(String orderId) async {
    try {
      final response = await _fetchGet('/orders/$orderId/payment');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is Map) {
          return Map<String, dynamic>.from(decoded['data']);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> simulatePaymentWebhook(String orderId, {String status = 'settlement'}) async {
    try {
      final response = await _post('/orders/$orderId/simulate-payment', {
        'status': status,
      });
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        return decoded['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<http.Response> _fetchGet(String path) async {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final url = Uri.parse('$baseUrl$normalizedPath');
    try {
      final headers = await _buildHeaders();
      final response = await _client.get(url, headers: headers).timeout(
            const Duration(seconds: 15),
          );
      return response;
    } on SocketException {
      throw const SocketException(
        'Tidak dapat terhubung ke server backend lokal (http://10.0.2.2:3000). Pastikan server Express aktif.',
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) =>
      _instance._post(path, body);

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final url = Uri.parse('$baseUrl$normalizedPath');
    try {
      final headers = await _buildHeaders();
      final response = await _client
          .post(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 15),
          );
      return response;
    } on SocketException {
      throw const SocketException(
        'Tidak dapat terhubung ke server backend lokal (http://10.0.2.2:3000). Pastikan server Express aktif.',
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body) =>
      _instance._put(path, body);

  Future<http.Response> _put(String path, Map<String, dynamic> body) async {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final url = Uri.parse('$baseUrl$normalizedPath');
    try {
      final headers = await _buildHeaders();
      final response = await _client
          .put(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 15),
          );
      return response;
    } on SocketException {
      throw const SocketException(
        'Tidak dapat terhubung ke server backend lokal (http://10.0.2.2:3000). Pastikan server Express aktif.',
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> delete(String path) => _instance._delete(path);

  Future<http.Response> _delete(String path) async {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final url = Uri.parse('$baseUrl$normalizedPath');
    try {
      final headers = await _buildHeaders();
      final response = await _client.delete(url, headers: headers).timeout(
            const Duration(seconds: 15),
          );
      return response;
    } on SocketException {
      throw const SocketException(
        'Tidak dapat terhubung ke server backend lokal (http://10.0.2.2:3000). Pastikan server Express aktif.',
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> uploadImage(
    String endpoint,
    File imageFile, {
    String fieldName = 'image',
  }) =>
      _instance._uploadImage(endpoint, imageFile, fieldName: fieldName);

  Future<Map<String, dynamic>> _uploadImage(
    String endpoint,
    File imageFile, {
    String fieldName = 'image',
  }) async {
    final normalizedPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = Uri.parse('$baseUrl$normalizedPath');

    try {
      final request = http.MultipartRequest('POST', url);
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final mimeSplit = mimeType.split('/');
      final mediaType = MediaType(mimeSplit[0], mimeSplit[1]);

      final multipartFile = await http.MultipartFile.fromPath(
        fieldName,
        imageFile.path,
        contentType: mediaType,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 30),
          );
      final response = await http.Response.fromStream(streamedResponse);
      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return {'success': true, 'data': decoded};
      } else {
        final errorMsg = decoded is Map && decoded['message'] != null
            ? decoded['message'].toString()
            : 'Gagal mengunggah gambar (${response.statusCode})';
        throw Exception(errorMsg);
      }
    } on SocketException {
      throw const SocketException(
        'Tidak dapat terhubung ke server backend lokal (http://10.0.2.2:3000). Pastikan server Express aktif.',
      );
    } catch (e) {
      rethrow;
    }
  }
}

