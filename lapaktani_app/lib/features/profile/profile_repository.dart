import 'dart:convert';
import 'dart:io';
import '../../core/services/api_service.dart';
import '../auth/auth_repository.dart';

class ProfileRepository {
  // ignore: unused_field
  final ApiService _apiService;

  ProfileRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  User? get currentUser => AuthRepository().currentUser;

  Future<String> uploadKtpImage(File imageFile, String userId) async {
    final fileExt = imageFile.path.split('.').last.toLowerCase();
    final fileName =
        '$userId/ktp_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    return 'http://10.0.2.2:3000/uploads/$fileName';
  }

  Future<void> submitFarmerProfileCompletion({
    required String userId,
    required File ktpImageFile,
    File? selfieImageFile,
    String? ktpImageUrl,
    String? selfieImageUrl,
    String? nikNumber,
    String? homeAddress,
    String? farmerGroupId,
    double? landAreaHa,
    String? province,
    String? regency,
    String? district,
    String? village,
    String? birthDate,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'nik_number': nikNumber,
      'nik': nikNumber,
      if (birthDate != null && birthDate.isNotEmpty)
        'birth_date': birthDate,
      'home_address': homeAddress,
      'farmer_group_id': farmerGroupId,
      'farmer_group': farmerGroupId,
      'land_area_ha': landAreaHa,
      'land_area': landAreaHa,
      'province': province,
      'regency': regency,
      'district': district,
      'village': village,
      'village_id': village,
      if (ktpImageUrl != null && ktpImageUrl.isNotEmpty)
        'ktp_image_url': ktpImageUrl,
      if (selfieImageUrl != null && selfieImageUrl.isNotEmpty)
        'selfie_image_url': selfieImageUrl,
      'verification_status': 'pending',
    };

    final response = await ApiService.post('/profiles/farmer', payload);
    if (response.statusCode >= 400) {
      String message = 'Gagal menyimpan profil petani.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return {
      'user_id': userId,
      'verification_status': 'pending',
    };
  }

  Future<Map<String, dynamic>?> getFarmerProfile(String userId) async {
    return {
      'user_id': userId,
      'land_area_ha': 1.0,
    };
  }

  Future<List<String>> getSubdistricts() async {
    return const [
      'Kota Sumenep',
      'Kalianget',
      'Bluto',
      'Saronggi',
      'Guluk-Guluk',
      'Pragaan',
      'Lenteng',
      'Manding',
    ];
  }

  Future<List<String>> getVillagesBySubdistrict(String subdistrict) async {
    const staticVillages = {
      'Kota Sumenep': [
        'Kolor',
        'Pabian',
        'Pangarangan',
        'Bangselok',
        'Karangduak',
        'Pamolokan',
      ],
      'Kalianget': [
        'Kalianget Timur',
        'Kalianget Barat',
        'Kalimook',
        'Marengan Laok',
        'Kertasada',
      ],
      'Bluto': [
        'Aengdake',
        'Bluto',
        'Lobuk',
        'Errabu',
        'Pakandangan Barat',
        'Pakandangan Tengah',
      ],
      'Saronggi': ['Saronggi', 'Nambakor', 'Tanamerah', 'Juluk'],
      'Guluk-Guluk': ['Guluk-Guluk', 'Payudan Dundang', 'Pordapor'],
      'Pragaan': ['Pragaan Laok', 'Karduluk'],
      'Lenteng': ['Lenteng Timur', 'Lenteng Barat'],
      'Manding': ['Manding Laok', 'Gadur'],
    };

    return staticVillages[subdistrict] ?? ['Desa 1', 'Desa 2'];
  }

  Future<List<Map<String, dynamic>>> getFarmerGroupsByVillage(
    String village,
  ) async {
    final trimmed = village.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    const allGroups = [
      {
        'id': '1',
        'group_name': 'Poktan Tani Makmur Sejahtera',
        'subdistrict_name': 'Kota Sumenep',
        'village_name': 'Kolor',
        'domicile_region': 'Desa Kolor, Kec. Kota Sumenep',
        'secretariat_address': 'Jl. Trunojoyo No. 45, Kolor',
      },
      {
        'id': '2',
        'group_name': 'Gapoktan Harapan Jaya',
        'subdistrict_name': 'Kalianget',
        'village_name': 'Kalianget Timur',
        'domicile_region': 'Desa Kalianget Timur, Kec. Kalianget',
        'secretariat_address': 'Dusun Pelabuhan, Kalianget Timur',
      },
      {
        'id': '3',
        'group_name': 'Kelompok Tani Subur Abadi',
        'subdistrict_name': 'Bluto',
        'village_name': 'Lobuk',
        'domicile_region': 'Desa Lobuk, Kec. Bluto',
        'secretariat_address': 'Dusun Pesisir, Lobuk',
      },
      {
        'id': '4',
        'group_name': 'Poktan Barokah Tani Kolor',
        'subdistrict_name': 'Kota Sumenep',
        'village_name': 'Kolor',
        'domicile_region': 'Desa Kolor, Kec. Kota Sumenep',
        'secretariat_address': 'Jl. KH. Agus Salim, Kolor',
      },
      {
        'id': '5',
        'group_name': 'Poktan Tani Mandiri Bluto',
        'subdistrict_name': 'Bluto',
        'village_name': 'Aengdake',
        'domicile_region': 'Desa Aengdake, Kec. Bluto',
        'secretariat_address': 'Jl. Raya Bluto - Saronggi, Aengdake',
      },
    ];

    final matched = allGroups
        .where(
          (g) =>
              g['village_name']!.toLowerCase() == trimmed ||
              g['village_name']!.toLowerCase().contains(trimmed) ||
              g['domicile_region']!.toLowerCase().contains(trimmed),
        )
        .toList();

    if (matched.isNotEmpty) return matched;

    return [
      {
        'id': '99',
        'group_name': 'Poktan Tani Bina Warga $village',
        'subdistrict_name': 'Sumenep',
        'village_name': village,
        'domicile_region': 'Desa $village, Sumenep',
        'secretariat_address': 'Kantor Balai Desa $village',
      }
    ];
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
}
