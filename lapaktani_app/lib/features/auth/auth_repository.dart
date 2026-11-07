import 'dart:convert';
import 'dart:io';
import '../../core/services/api_service.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class User {
  final String id;
  final String email;
  final String? fullName;
  final String? role;
  final int? roleId;
  final bool isChairman;
  final bool isVerified;

  const User({
    required this.id,
    required this.email,
    this.fullName,
    this.role,
    this.roleId,
    this.isChairman = false,
    this.isVerified = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    int? parsedRoleId;
    final rId = json['role_id'];
    if (rId is int) {
      parsedRoleId = rId;
    } else if (rId != null) {
      parsedRoleId = int.tryParse(rId.toString());
    }

    final bool chairmanFlag = json['is_chairman'] == true ||
        json['is_chairman'] == 1 ||
        json['isChairman'] == true;

    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString(),
      role: json['role']?.toString(),
      roleId: parsedRoleId,
      isChairman: chairmanFlag,
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role,
        'role_id': roleId,
        'is_chairman': isChairman,
        'is_verified': isVerified,
      };
}

class Session {
  final String accessToken;
  final User? user;

  const Session({
    required this.accessToken,
    this.user,
  });
}

class AuthResponse {
  final Session? session;
  final User? user;

  const AuthResponse({this.session, this.user});
}

class AuthRepository {
  final ApiService _apiService;
  static User? _currentUser;

  AuthRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  static void setCurrentUser(User? user) {
    _currentUser = user;
  }

  User? get currentUser => _currentUser;
  Session? get currentSession => null;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'email': email.trim(),
        'password': password,
      });

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>? ?? {};
        final user = User.fromJson(userData);

        await _apiService.saveToken(token);
        await _apiService.saveUser(userData);

        _currentUser = user;

        return AuthResponse(
          session: Session(accessToken: token, user: user),
          user: user,
        );
      } else {
        throw AuthException(
          data['message']?.toString() ??
              'Email atau password salah. Silakan coba lagi.',
        );
      }
    } on SocketException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Gagal masuk: ${e.toString()}');
    }
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return signInWithPassword(email: email, password: password);
  }

  Future<bool> signInWithGoogle() async {
    throw const AuthException(
      'Login dengan Google dinonaktifkan pada lingkungan server lokal.',
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String roleName,
    String? fullName,
    String? phone,
    String? nikNumber,
    double? landAreaHa,
    String? farmerGroupId,
  }) async {
    try {
      final response = await ApiService.post('/auth/register', {
        'full_name': fullName ?? email.split('@').first,
        'email': email.trim(),
        'password': password,
        'role': roleName.toLowerCase(),
      });

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        final token = data['token'] as String?;
        final userData = data['user'] as Map<String, dynamic>? ?? {};
        final user = User.fromJson(userData);

        if (token != null && token.isNotEmpty) {
          await _apiService.saveToken(token);
          await _apiService.saveUser(userData);
        }

        _currentUser = user;

        return AuthResponse(
          session:
              token != null ? Session(accessToken: token, user: user) : null,
          user: user,
        );
      } else {
        throw AuthException(
          data['message']?.toString() ??
              'Gagal mendaftar. Silakan periksa data Anda.',
        );
      }
    } on SocketException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Gagal mendaftar: ${e.toString()}');
    }
  }

  Future<List<String>> getDomicileRegions() async {
    return const [
      'Desa Kolor, Kec. Kota Sumenep',
      'Desa Kalianget Timur, Kec. Kalianget',
      'Desa Lobuk, Kec. Bluto',
      'Desa Saronggi, Kec. Saronggi',
    ];
  }

  Future<List<Map<String, dynamic>>> getFarmerGroupsByRegion(
    String region,
  ) async {
    return [
      {
        'id': '1',
        'group_name': 'Poktan Tani Makmur Sejahtera',
        'domicile_region': region,
      },
      {
        'id': '2',
        'group_name': 'Gapoktan Harapan Jaya',
        'domicile_region': region,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> getFarmerGroups() async {
    return const [
      {
        'id': '1',
        'group_name': 'Poktan Tani Makmur Sejahtera',
        'domicile_region': 'Desa Kolor, Kec. Kota Sumenep'
      },
      {
        'id': '2',
        'group_name': 'Gapoktan Harapan Jaya',
        'domicile_region': 'Desa Kalianget Timur, Kec. Kalianget'
      },
      {
        'id': '3',
        'group_name': 'Kelompok Tani Subur Abadi',
        'domicile_region': 'Desa Lobuk, Kec. Bluto'
      },
    ];
  }

  Future<String> uploadKtpImage(File imageFile, String userId) async {
    final fileName = 'ktp_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return 'http://10.0.2.2:3000/uploads/$fileName';
  }

  Future<void> signOut() async {
    await _apiService.clearAuth();
    _currentUser = null;
  }
}
