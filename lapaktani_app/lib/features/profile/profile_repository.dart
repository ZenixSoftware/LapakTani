import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  User? get currentUser => _client.auth.currentUser;

  Future<String> uploadKtpImage(File imageFile, String userId) async {
    final fileExt = imageFile.path.split('.').last.toLowerCase();
    final fileName =
        '$userId/ktp_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final bytes = await imageFile.readAsBytes();

    await _client.storage.from('ktp-documents').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$fileExt',
            upsert: true,
          ),
        );

    return _client.storage.from('ktp-documents').getPublicUrl(fileName);
  }

  Future<void> submitFarmerProfileCompletion({
    required String userId,
    required File ktpImageFile,
    String? nikNumber,
    String? homeAddress,
    String? farmerGroupId,
    double? landAreaHa,
  }) async {
    final ktpUrl = await uploadKtpImage(ktpImageFile, userId);

    final userUpdates = <String, dynamic>{
      'verification_status': 'pending',
    };
    if (nikNumber != null && nikNumber.trim().isNotEmpty) {
      userUpdates['nik_number'] = nikNumber.trim();
    }
    if (homeAddress != null && homeAddress.trim().isNotEmpty) {
      userUpdates['home_address'] = homeAddress.trim();
    }

    await _client
        .from('user_profiles')
        .update(userUpdates)
        .eq('user_id', userId);

    final farmerUpdates = <String, dynamic>{
      'ktp_image_url': ktpUrl,
    };
    if (farmerGroupId != null && farmerGroupId.isNotEmpty) {
      farmerUpdates['farmer_group_id'] = farmerGroupId;
    }
    if (landAreaHa != null) {
      farmerUpdates['land_area_ha'] = landAreaHa;
    }

    final existingFarmer = await _client
        .from('farmer_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (existingFarmer != null) {
      await _client
          .from('farmer_profiles')
          .update(farmerUpdates)
          .eq('user_id', userId);
    } else {
      farmerUpdates['user_id'] = userId;
      await _client.from('farmer_profiles').insert(farmerUpdates);
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      return await _client
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getFarmerProfile(String userId) async {
    try {
      return await _client
          .from('farmer_profiles')
          .select('*, farmer_groups(group_name, domicile_region)')
          .eq('user_id', userId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> getDomicileRegions() async {
    try {
      final List<dynamic> rows = await _client
          .from('farmer_groups')
          .select('domicile_region')
          .order('domicile_region');
      final regions = rows
          .map((e) => (e['domicile_region'] as String).trim())
          .toSet()
          .toList();
      return regions.isNotEmpty
          ? regions
          : [
              'Cipanas, Cianjur',
              'Lembang, Bandung Barat',
              'Pangalengan, Bandung',
            ];
    } catch (_) {
      return [
        'Cipanas, Cianjur',
        'Lembang, Bandung Barat',
        'Pangalengan, Bandung',
      ];
    }
  }

  Future<List<Map<String, dynamic>>> getFarmerGroupsByRegion(
    String region,
  ) async {
    try {
      final List<dynamic> rows = await _client
          .from('farmer_groups')
          .select('id, group_name, domicile_region')
          .eq('domicile_region', region)
          .order('group_name');
      return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [
        {
          'id': '7281a516-ae8d-48cf-8c32-31f6eed77662',
          'group_name': 'Poktan Tani Makmur Sejahtera',
          'domicile_region': region,
        },
      ];
    }
  }
}
