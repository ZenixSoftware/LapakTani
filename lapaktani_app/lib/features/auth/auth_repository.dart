import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.lapaktani://login-callback',
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
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName,
        'role': roleName,
        'phone': phone,
      },
    );

    final user = response.user;
    if (user != null) {
      await _syncUserProfile(
        userId: user.id,
        email: email.trim(),
        roleName: roleName,
        fullName: fullName,
        phone: phone,
        nikNumber: nikNumber,
        landAreaHa: landAreaHa,
        farmerGroupId: farmerGroupId,
      );
    }

    return response;
  }

  Future<void> _syncUserProfile({
    required String userId,
    required String email,
    required String roleName,
    String? fullName,
    String? phone,
    String? nikNumber,
    double? landAreaHa,
    String? farmerGroupId,
  }) async {
    try {
      final normalizedRole = roleName.toLowerCase();

      final roleRecord = await _client
          .from('user_roles')
          .select('id')
          .eq('role_name', normalizedRole)
          .maybeSingle();

      final int roleId = roleRecord != null
          ? (roleRecord['id'] as num).toInt()
          : (normalizedRole == 'petani' ? 1 : 4);

      await _client.from('users').upsert({
        'id': userId,
        'email': email,
        'phone': phone,
        'role_id': roleId,
        'updated_at': DateTime.now().toIso8601String(),
      });

      final profileRecord = await _client
          .from('user_profiles')
          .upsert({
            'user_id': userId,
            'full_name': fullName ?? email.split('@').first,
            'nik_number': nikNumber,
            'verification_status':
                normalizedRole == 'petani' ? 'pending' : 'verified',
          })
          .select('id')
          .single();

      final profileId = profileRecord['id'] as String;

      if (normalizedRole == 'petani') {
        await _client.from('farmer_profiles').upsert({
          'user_id': userId,
          if (farmerGroupId != null && farmerGroupId.isNotEmpty)
            'farmer_group_id': farmerGroupId,
          'land_area_ha': landAreaHa ?? 0.0,
        });

        await _client.from('farms').insert({
          'farmer_id': profileId,
          'land_area_ha': landAreaHa ?? 0.0,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFarmerGroups() async {
    try {
      final List<dynamic> rows = await _client
          .from('farmer_groups')
          .select('id, group_name, domicile_region')
          .order('group_name');
      return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [
        {
          'id': '7281a516-ae8d-48cf-8c32-31f6eed77662',
          'group_name': 'Poktan Tani Makmur Sejahtera',
          'domicile_region': 'Lembang, Bandung Barat'
        },
        {
          'id': '929e3700-658c-46e8-af0d-8b6a910dafa2',
          'group_name': 'Gapoktan Harapan Jaya',
          'domicile_region': 'Pangalengan, Bandung'
        },
        {
          'id': '0f05d1d4-6471-4449-8587-b38ab7751f5c',
          'group_name': 'Kelompok Tani Subur Abadi',
          'domicile_region': 'Cipanas, Cianjur'
        },
      ];
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
