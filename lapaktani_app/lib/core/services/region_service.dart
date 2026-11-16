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
    RegionItem(id: '3529090', name: 'GANDING'),
    RegionItem(id: '3529100', name: 'PRAGAAN'),
    RegionItem(id: '3529110', name: 'AMBUNTEN'),
    RegionItem(id: '3529120', name: 'PASONGSONGAN'),
    RegionItem(id: '3529130', name: 'DASUK'),
    RegionItem(id: '3529140', name: 'RUBARU'),
    RegionItem(id: '3529150', name: 'BATUAN'),
    RegionItem(id: '3529160', name: 'GAPURA'),
    RegionItem(id: '3529170', name: 'DUNGKEK'),
    RegionItem(id: '3529180', name: 'BATANG-BATANG'),
    RegionItem(id: '3529190', name: 'BATUPUTIH'),
    RegionItem(id: '3529200', name: 'NONGGUNONG'),
    RegionItem(id: '3529210', name: 'GAYAM'),
    RegionItem(id: '3529220', name: 'RAAS'),
    RegionItem(id: '3529230', name: 'SAPEKEN'),
    RegionItem(id: '3529240', name: 'ARJASA'),
    RegionItem(id: '3529250', name: 'KANGAYAN'),
    RegionItem(id: '3529260', name: 'MASALEMBU'),
    RegionItem(id: '3529270', name: 'GILIGENTING'),
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
    '3529030': [
      RegionItem(id: '3529030001', name: 'MANDING DAYA'),
      RegionItem(id: '3529030002', name: 'MANDING LAOK'),
      RegionItem(id: '3529030003', name: 'MANDING TIMUR'),
    ],
    '3529040': [
      RegionItem(id: '3529040001', name: 'TALANGO'),
      RegionItem(id: '3529040002', name: 'PADIKE'),
      RegionItem(id: '3529040003', name: 'POTERAN'),
    ],
    '3529050': [
      RegionItem(id: '3529050001', name: 'AENGDAKE'),
      RegionItem(id: '3529050002', name: 'BLUTO'),
      RegionItem(id: '3529050003', name: 'LOBUK'),
      RegionItem(id: '3529050004', name: 'ERRABU'),
      RegionItem(id: '3529050005', name: 'PAKANDANGAN BARAT'),
    ],
    '3529060': [
      RegionItem(id: '3529060001', name: 'SARONGGI'),
      RegionItem(id: '3529060002', name: 'TANJUNG'),
      RegionItem(id: '3529060003', name: 'KEBUNDADAP TIMUR'),
    ],
    '3529070': [
      RegionItem(id: '3529070001', name: 'LENTENG TIMUR'),
      RegionItem(id: '3529070002', name: 'LENTENG BARAT'),
      RegionItem(id: '3529070003', name: 'ELLAK DAYA'),
    ],
    '3529080': [
      RegionItem(id: '3529080001', name: 'GULUK-GULUK'),
      RegionItem(id: '3529080002', name: 'BAKAPUH'),
      RegionItem(id: '3529080003', name: 'BRAGUNG'),
    ],
    '3529090': [
      RegionItem(id: '3529090001', name: 'GANDING'),
      RegionItem(id: '3529090002', name: 'BATAAL BARAT'),
      RegionItem(id: '3529090003', name: 'KETAWANG KARAY'),
    ],
    '3529100': [
      RegionItem(id: '3529100001', name: 'PRAGAAN LAOK'),
      RegionItem(id: '3529100002', name: 'PRAGAAN DAYA'),
      RegionItem(id: '3529100003', name: 'PRENDUAN'),
    ],
    '3529110': [
      RegionItem(id: '3529110001', name: 'AMBUNTEN TIMUR'),
      RegionItem(id: '3529110002', name: 'AMBUNTEN TENGAH'),
      RegionItem(id: '3529110003', name: 'AMBUNTEN BARAT'),
    ],
    '3529120': [
      RegionItem(id: '3529120001', name: 'PASONGSONGAN'),
      RegionItem(id: '3529120002', name: 'PANAONGAN'),
      RegionItem(id: '3529120003', name: 'LEBENG TIMUR'),
    ],
    '3529130': [
      RegionItem(id: '3529130001', name: 'KERTA BARAT'),
      RegionItem(id: '3529130002', name: 'KERTA TIMUR'),
      RegionItem(id: '3529130003', name: 'SLOPENG'),
    ],
    '3529140': [
      RegionItem(id: '3529140001', name: 'PAKONDANG'),
      RegionItem(id: '3529140002', name: 'KARANGNANGKA'),
      RegionItem(id: '3529140003', name: 'TAMBAK SARI'),
    ],
    '3529150': [
      RegionItem(id: '3529150001', name: 'BATUAN'),
      RegionItem(id: '3529150002', name: 'BABBALAN'),
      RegionItem(id: '3529150003', name: 'PATEAN'),
    ],
    '3529160': [
      RegionItem(id: '3529160001', name: 'MANDALA'),
      RegionItem(id: '3529160002', name: 'GAPURA TIMUR'),
      RegionItem(id: '3529160003', name: 'GAPURA BARAT'),
      RegionItem(id: '3529160004', name: 'LONGOS'),
    ],
    '3529170': [
      RegionItem(id: '3529170001', name: 'DUNGKEK'),
      RegionItem(id: '3529170002', name: 'LAPA TAMAN'),
      RegionItem(id: '3529170003', name: 'LAPA DAYA'),
      RegionItem(id: '3529170004', name: 'CANDI'),
    ],
    '3529180': [
      RegionItem(id: '3529180001', name: 'BATANG-BATANG DAYA'),
      RegionItem(id: '3529180002', name: 'BATANG-BATANG LAOK'),
      RegionItem(id: '3529180003', name: 'LOMBANG'),
    ],
    '3529190': [
      RegionItem(id: '3529190001', name: 'BATUPUTIH LAOK'),
      RegionItem(id: '3529190002', name: 'BATUPUTIH DAYA'),
      RegionItem(id: '3529190003', name: 'JURUAN DAYA'),
    ],
    '3529200': [
      RegionItem(id: '3529200001', name: 'NONGGUNONG'),
      RegionItem(id: '3529200002', name: 'SONOK'),
      RegionItem(id: '3529200003', name: 'TALAGA'),
    ],
    '3529210': [
      RegionItem(id: '3529210001', name: 'GAYAM'),
      RegionItem(id: '3529210002', name: 'KARANG TENGAH'),
      RegionItem(id: '3529210003', name: 'NYAMPLONG'),
    ],
    '3529220': [
      RegionItem(id: '3529220001', name: 'ALASMALANG'),
      RegionItem(id: '3529220002', name: 'BRACOL'),
      RegionItem(id: '3529220003', name: 'KETUPAT'),
    ],
    '3529230': [
      RegionItem(id: '3529230001', name: 'SAPEKEN'),
      RegionItem(id: '3529230002', name: 'PAGERUNGAN BESAR'),
      RegionItem(id: '3529230003', name: 'SASIIL'),
    ],
    '3529240': [
      RegionItem(id: '3529240001', name: 'KALINGANYAR'),
      RegionItem(id: '3529240002', name: 'ARJASA'),
      RegionItem(id: '3529240003', name: 'SUMBERNANGKA'),
    ],
    '3529250': [
      RegionItem(id: '3529250001', name: 'KANGAYAN'),
      RegionItem(id: '3529250002', name: 'DAANDUNG'),
      RegionItem(id: '3529250003', name: 'SAOBI'),
    ],
    '3529260': [
      RegionItem(id: '3529260001', name: 'MASAKAMBING'),
      RegionItem(id: '3529260002', name: 'MASALIMA'),
      RegionItem(id: '3529260003', name: 'SUKSA'),
    ],
    '3529270': [
      RegionItem(id: '3529270001', name: 'AENGANYAR'),
      RegionItem(id: '3529270002', name: 'BRINGSANG'),
      RegionItem(id: '3529270003', name: 'LOMBANG'),
    ],
  };
}
