import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'https://backslid-salvage-moocher.ngrok-free.dev/api';
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'auth_user';

  final http.Client _client = http.Client();

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(userKey);
    if (userStr == null) return null;
    try {
      return jsonDecode(userStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
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
}
