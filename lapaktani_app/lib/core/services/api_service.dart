import 'dart:convert';
import 'dart:io';
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

