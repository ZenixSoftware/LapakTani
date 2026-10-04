import 'dart:convert';
import 'package:http/http.dart' as http;

class RegionItem {
  final String id;
  final String name;

  const RegionItem({
    required this.id,
    required this.name,
  });

  factory RegionItem.fromJson(Map<String, dynamic> json) {
    return RegionItem(
      id: json['id']?.toString() ?? '',
      name: (json['name']?.toString() ?? '').trim(),
    );
  }

  String get displayName {
    if (name.isEmpty) return '';
    return name
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegionItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class RegionService {
  static const String _baseUrl =
      'https://emsifa.github.io/api-wilayah-indonesia/api';

  final http.Client _client;
  final Map<String, List<RegionItem>> _cache = {};

  RegionService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<RegionItem>> getProvinces() async {
    const cacheKey = 'provinces';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final uri = Uri.parse('$_baseUrl/provinces.json');
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list = data
            .map((e) => RegionItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _cache[cacheKey] = list;
        return list;
      }
    } catch (_) {}

    return _fallbackProvinces;
  }

  Future<List<RegionItem>> getRegencies(String provinceId) async {
    final cacheKey = 'regencies_$provinceId';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final uri = Uri.parse('$_baseUrl/regencies/$provinceId.json');
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list = data
            .map((e) => RegionItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _cache[cacheKey] = list;
        return list;
      }
    } catch (_) {}

    if (provinceId == '35') {
      return _fallbackEastJavaRegencies;
    }
    return [];
  }

  Future<List<RegionItem>> getDistricts(String regencyId) async {
    final cacheKey = 'districts_$regencyId';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final uri = Uri.parse('$_baseUrl/districts/$regencyId.json');
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list = data
            .map((e) => RegionItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _cache[cacheKey] = list;
        return list;
      }
    } catch (_) {}

    if (regencyId == '3529') {
      return _fallbackSumenepDistricts;
    }
    return [];
  }

  Future<List<RegionItem>> getVillages(String districtId) async {
    final cacheKey = 'villages_$districtId';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final uri = Uri.parse('$_baseUrl/villages/$districtId.json');
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final list = data
            .map((e) => RegionItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _cache[cacheKey] = list;
        return list;
      }
    } catch (_) {}

    return _fallbackSumenepVillages[districtId] ?? [];
  }

  static const List<RegionItem> _fallbackProvinces = [
    RegionItem(id: '31', name: 'DKI JAKARTA'),
    RegionItem(id: '32', name: 'JAWA BARAT'),
    RegionItem(id: '33', name: 'JAWA TENGAH'),
    RegionItem(id: '34', name: 'DI YOGYAKARTA'),
    RegionItem(id: '35', name: 'JAWA TIMUR'),
    RegionItem(id: '36', name: 'BANTEN'),
    RegionItem(id: '51', name: 'BALI'),
  ];

  static const List<RegionItem> _fallbackEastJavaRegencies = [
    RegionItem(id: '3529', name: 'KABUPATEN SUMENEP'),
    RegionItem(id: '3528', name: 'KABUPATEN PAMEKASAN'),
    RegionItem(id: '3527', name: 'KABUPATEN SAMPANG'),
    RegionItem(id: '3526', name: 'KABUPATEN BANGKALAN'),
    RegionItem(id: '3578', name: 'KOTA SURABAYA'),
  ];

  static const List<RegionItem> _fallbackSumenepDistricts = [
    RegionItem(id: '3529010', name: 'KOTA SUMENEP'),
    RegionItem(id: '3529020', name: 'KALIANGET'),
    RegionItem(id: '3529030', name: 'MANDING'),
    RegionItem(id: '3529040', name: 'TALANGO'),
    RegionItem(id: '3529050', name: 'BLUTO'),
    RegionItem(id: '3529060', name: 'SARONGGI'),
    RegionItem(id: '3529070', name: 'LENTENG'),
    RegionItem(id: '3529080', name: 'GULUK-GULUK'),
    RegionItem(id: '3529090', name: 'PRAGAAN'),
  ];

  static const Map<String, List<RegionItem>> _fallbackSumenepVillages = {
    '3529010': [
      RegionItem(id: '3529010001', name: 'KOLOR'),
      RegionItem(id: '3529010002', name: 'PABIAN'),
      RegionItem(id: '3529010003', name: 'PANGARANGAN'),
      RegionItem(id: '3529010004', name: 'BANGSELOK'),
      RegionItem(id: '3529010005', name: 'KARANGDUAK'),
      RegionItem(id: '3529010006', name: 'PAMOLOKAN'),
    ],
    '3529020': [
      RegionItem(id: '3529020001', name: 'KALIANGET TIMUR'),
      RegionItem(id: '3529020002', name: 'KALIANGET BARAT'),
      RegionItem(id: '3529020003', name: 'KALIMOOK'),
      RegionItem(id: '3529020004', name: 'MARENGAN LAOK'),
      RegionItem(id: '3529020005', name: 'KERTASADA'),
    ],
    '3529050': [
      RegionItem(id: '3529050001', name: 'AENGDAKE'),
      RegionItem(id: '3529050002', name: 'BLUTO'),
      RegionItem(id: '3529050003', name: 'LOBUK'),
      RegionItem(id: '3529050004', name: 'ERRABU'),
      RegionItem(id: '3529050005', name: 'PAKANDANGAN BARAT'),
    ],
  };
}
