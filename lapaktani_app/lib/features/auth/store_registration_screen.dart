import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_service.dart';
import '../../core/services/region_service.dart';
import '../../core/services/user_session.dart';
import '../../core/theme/app_colors.dart';
import '../navigation/role_based_app_shell.dart';
import 'auth_repository.dart';

class StoreRegistrationScreen extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;
  final String? initialPhone;
  final String? initialPassword;

  const StoreRegistrationScreen({
    super.key,
    this.initialName,
    this.initialEmail,
    this.initialPhone,
    this.initialPassword,
  });

  @override
  State<StoreRegistrationScreen> createState() =>
      _StoreRegistrationScreenState();
}

class _StoreRegistrationScreenState extends State<StoreRegistrationScreen> {
  final ApiService _apiService = ApiService();
  final RegionService _regionService = RegionService();

  int _step = 0; // 0: Personal & Wilayah, 1: Syarat Toko
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasExistingToken = false;

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nikCtrl = TextEditingController(text: '3529172207880003');
  final _phoneCtrl = TextEditingController(text: '081357902468');
  final _addressCtrl = TextEditingController(
    text: 'Dusun Embung Timur, Kec. Dungkek, Kab. Sumenep',
  );
  final _postalCtrl = TextEditingController(text: '69474');
  final _storeNameCtrl = TextEditingController(
    text: 'Toko Tani Berkah Sumenep',
  );
  final _minWholesaleCtrl = TextEditingController(text: '30');
  final _bannerCtrl = TextEditingController(
    text: 'Promo Panen Segar Hemat s/d 15% & Harga Partai B2B',
  );
  final _docCtrl = TextEditingController(
    text: 'uploads/docs/sk_pengelola_toko_desa.pdf',
  );

  String _selectedType = 'POKTAN';
  String? _existingStatus;

  // Backend quota-enabled villages list from GET /store/my-application or /store/villages
  List<Map<String, dynamic>> _backendQuotaVillages = [];

  // 4-Level Cascading Region State
  List<RegionItem> _provinces = [];
  RegionItem? _selectedProvince;
  bool _isLoadingProvinces = false;

  List<RegionItem> _regencies = [];
  RegionItem? _selectedRegency;
  bool _isLoadingRegencies = false;

  List<RegionItem> _districts = [];
  RegionItem? _selectedDistrict;
  bool _isLoadingDistricts = false;

  List<RegionItem> _villages = [];
  RegionItem? _selectedVillage;
  bool _isLoadingVillages = false;

  static const List<Map<String, dynamic>> _fallbackBackendVillages = [
    {
      'id': 101,
      'district_id': 352916,
      'name': 'Mandala',
      'district_name': 'Gapura',
      'postal_code': '69472',
      'is_store_quota_enabled': true,
      'max_stores_quota': 3,
      'approved_stores_count': 1,
      'is_quota_full': false,
    },
    {
      'id': 109,
      'district_id': 352917,
      'name': 'Dungkek',
      'district_name': 'Dungkek',
      'postal_code': '69474',
      'is_store_quota_enabled': true,
      'max_stores_quota': 3,
      'approved_stores_count': 0,
      'is_quota_full': false,
    },
    {
      'id': 102,
      'district_id': 352914,
      'name': 'Pakondang',
      'district_name': 'Rubaru',
      'postal_code': '69456',
      'is_store_quota_enabled': false,
      'max_stores_quota': 5,
      'approved_stores_count': 0,
      'is_quota_full': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null && widget.initialName!.trim().isNotEmpty) {
      _fullNameCtrl.text = widget.initialName!.trim();
    }
    if (widget.initialEmail != null && widget.initialEmail!.trim().isNotEmpty) {
      _emailCtrl.text = widget.initialEmail!.trim();
    }
    if (widget.initialPassword != null && widget.initialPassword!.isNotEmpty) {
      _passwordCtrl.text = widget.initialPassword!;
    }
    if (widget.initialPhone != null && widget.initialPhone!.trim().isNotEmpty) {
      _phoneCtrl.text = widget.initialPhone!.trim();
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nikCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _postalCtrl.dispose();
    _storeNameCtrl.dispose();
    _minWholesaleCtrl.dispose();
    _bannerCtrl.dispose();
    _docCtrl.dispose();
    super.dispose();
  }

  String _normalizeName(String raw) {
    return raw.split('(').first.trim().toLowerCase();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _isLoadingProvinces = true;
    });

    String? savedVillageName;

    final existingToken = await _apiService.getToken();
    _hasExistingToken = existingToken != null && existingToken.trim().isNotEmpty;

    // 1. Load existing store application (only if authenticated) & village store quota list
    if (_hasExistingToken) {
      try {
        final res = await _apiService.getMyStoreApplication();
        final data = res['data'];
        if (data is Map) {
          final rawVillages = data['villages'];
          if (rawVillages is List && rawVillages.isNotEmpty) {
            _backendQuotaVillages = rawVillages
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
          final app = data['application'];
          if (app is Map) {
            _existingStatus = app['status']?.toString();
            if (app['nama_toko'] != null) {
              _storeNameCtrl.text = app['nama_toko'].toString();
            }
            if (app['nik'] != null) _nikCtrl.text = app['nik'].toString();
            if (app['no_hp'] != null) _phoneCtrl.text = app['no_hp'].toString();
            if (app['alamat_lengkap'] != null) {
              _addressCtrl.text = app['alamat_lengkap'].toString();
            }
            if (app['postal_code'] != null) {
              _postalCtrl.text = app['postal_code'].toString();
            }
            if (app['village_name'] != null) {
              savedVillageName = app['village_name'].toString();
            }
            if (app['tipe_pengelola'] != null) {
              _selectedType = app['tipe_pengelola'].toString();
            }
            if (app['default_min_wholesale_kg'] != null) {
              _minWholesaleCtrl.text =
                  app['default_min_wholesale_kg'].toString();
            }
            if (app['store_discount_banner'] != null) {
              _bannerCtrl.text = app['store_discount_banner'].toString();
            }
          }
        }
      } catch (_) {}
    }

    if (_backendQuotaVillages.isEmpty) {
      try {
        final vRes = await _apiService.getStoreVillages();
        if (vRes['villages'] is List) {
          _backendQuotaVillages = (vRes['villages'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } catch (_) {}
    }

    if (_backendQuotaVillages.isEmpty) {
      _backendQuotaVillages = _fallbackBackendVillages;
    }

    // 2. Load 4-level Cascading Regions pre-selected to Jawa Timur -> Kabupaten Sumenep -> Dungkek
    final provinces = await _regionService.getProvinces();
    final defaultProv = provinces.firstWhere(
      (p) => p.id == '35' || p.name.toUpperCase().contains('JAWA TIMUR'),
      orElse: () => provinces.isNotEmpty
          ? provinces.first
          : const RegionItem(id: '35', name: 'JAWA TIMUR'),
    );

    final regencies = await _regionService.getRegencies(defaultProv.id);
    final defaultReg = regencies.firstWhere(
      (r) => r.id == '3529' || r.name.toUpperCase().contains('SUMENEP'),
      orElse: () => regencies.isNotEmpty
          ? regencies.first
          : const RegionItem(id: '3529', name: 'KABUPATEN SUMENEP'),
    );

    final districts = await _regionService.getDistricts(defaultReg.id);
    RegionItem? defaultDist;
    if (districts.isNotEmpty) {
      final preferredDistKeyword =
          savedVillageName != null && savedVillageName.toLowerCase().contains('mandala')
              ? 'GAPURA'
              : 'DUNGKEK';
      defaultDist = districts.firstWhere(
        (d) => d.name.toUpperCase().contains(preferredDistKeyword),
        orElse: () => districts.first,
      );
    }

    final villages = defaultDist != null
        ? await _regionService.getVillages(defaultDist.id)
        : <RegionItem>[];
    RegionItem? defaultVill;
    if (villages.isNotEmpty) {
      final targetNorm = savedVillageName != null
          ? _normalizeName(savedVillageName)
          : 'dungkek';
      defaultVill = villages.firstWhere(
        (v) => _normalizeName(v.name).contains(targetNorm),
        orElse: () => villages.first,
      );
    }

    if (!mounted) return;
    setState(() {
      _provinces = provinces;
      _selectedProvince = defaultProv;
      _isLoadingProvinces = false;

      _regencies = regencies;
      _selectedRegency = defaultReg;
      _isLoadingRegencies = false;

      _districts = districts;
      _selectedDistrict = defaultDist;
      _isLoadingDistricts = false;

      _villages = villages;
      _selectedVillage = defaultVill;
      _isLoadingVillages = false;

      _syncPostalFromSelectedVillage();
      _isLoading = false;
    });
  }

  Future<void> _onProvinceChanged(RegionItem? prov) async {
    if (prov == null || prov.id == _selectedProvince?.id) return;
    setState(() {
      _selectedProvince = prov;
      _selectedRegency = null;
      _regencies = [];
      _selectedDistrict = null;
      _districts = [];
      _selectedVillage = null;
      _villages = [];
      _isLoadingRegencies = true;
    });

    final regencies = await _regionService.getRegencies(prov.id);
    if (!mounted) return;

    RegionItem? nextReg;
    if (regencies.isNotEmpty) {
      nextReg = regencies.firstWhere(
        (r) => r.id == '3529' || r.name.toUpperCase().contains('SUMENEP'),
        orElse: () => regencies.first,
      );
    }

    setState(() {
      _regencies = regencies;
      _selectedRegency = nextReg;
      _isLoadingRegencies = false;
    });

    if (nextReg != null) {
      await _loadDistrictsForRegency(nextReg);
    }
  }

  Future<void> _onRegencyChanged(RegionItem? reg) async {
    if (reg == null || reg.id == _selectedRegency?.id) return;
    setState(() {
      _selectedRegency = reg;
      _selectedDistrict = null;
      _districts = [];
      _selectedVillage = null;
      _villages = [];
    });
    await _loadDistrictsForRegency(reg);
  }

  Future<void> _loadDistrictsForRegency(RegionItem reg) async {
    setState(() => _isLoadingDistricts = true);
    final districts = await _regionService.getDistricts(reg.id);
    if (!mounted) return;

    final nextDist = districts.isNotEmpty ? districts.first : null;
    setState(() {
      _districts = districts;
      _selectedDistrict = nextDist;
      _isLoadingDistricts = false;
    });

    if (nextDist != null) {
      await _loadVillagesForDistrict(nextDist);
    }
  }

  Future<void> _onDistrictChanged(RegionItem? dist) async {
    if (dist == null || dist.id == _selectedDistrict?.id) return;
    setState(() {
      _selectedDistrict = dist;
      _selectedVillage = null;
      _villages = [];
    });
    await _loadVillagesForDistrict(dist);
  }

  Future<void> _loadVillagesForDistrict(RegionItem dist) async {
    setState(() => _isLoadingVillages = true);
    final villages = await _regionService.getVillages(dist.id);
    if (!mounted) return;

    final nextVill = villages.isNotEmpty ? villages.first : null;
    setState(() {
      _villages = villages;
      _selectedVillage = nextVill;
      _isLoadingVillages = false;
      _syncPostalFromSelectedVillage();
    });
  }

  void _onVillageChanged(RegionItem? village) {
    if (village == null) return;
    setState(() {
      _selectedVillage = village;
      _syncPostalFromSelectedVillage();
    });
  }

  Map<String, dynamic>? get _matchedBackendVillage {
    if (_selectedVillage == null) return null;
    final target = _normalizeName(_selectedVillage!.name);
    for (final v in _backendQuotaVillages) {
      final candidate = _normalizeName((v['name'] ?? '').toString());
      if (candidate == target || candidate.contains(target) || target.contains(candidate)) {
        return v;
      }
    }
    return null;
  }

  void _syncPostalFromSelectedVillage() {
    final matched = _matchedBackendVillage;
    if (matched != null && matched['postal_code'] != null) {
      final p = matched['postal_code'].toString().trim();
      if (p.isNotEmpty) {
        _postalCtrl.text = p;
      }
    }
  }

  Future<void> _submitApplication({required bool freezeAsBuyer}) async {
    if (_storeNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama toko wajib diisi sebelum melanjutkan.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_selectedVillage == null || _selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih Kecamatan dan Desa terlebih dahulu.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    bool registeredJustNow = false;
    try {
      // Auto-register / login unauthenticated applicants before submitting /store/apply
      var token = await _apiService.getToken();
      if (token == null || token.trim().isEmpty) {
        final fullName = _fullNameCtrl.text.trim();
        final email = _emailCtrl.text.trim();
        final password = _passwordCtrl.text;

        if (fullName.isEmpty || email.isEmpty || password.length < 6) {
          setState(() {
            _isSubmitting = false;
            _step = 0;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Lengkapi Nama Lengkap, Email, dan Kata Sandi (min. 6 karakter) di Tahap 1 untuk membuat akun.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
          return;
        }

        var authResp = await ApiService.post('/auth/register', {
          'full_name': fullName,
          'email': email,
          'password': password,
          'role': 'pembeli',
        });
        Map<String, dynamic> authBody = authResp.body.isNotEmpty
            ? Map<String, dynamic>.from(jsonDecode(authResp.body) as Map)
            : <String, dynamic>{};

        if (authResp.statusCode == 400 || authResp.statusCode == 409) {
          authResp = await ApiService.post('/auth/login', {
            'email': email,
            'password': password,
          });
          authBody = authResp.body.isNotEmpty
              ? Map<String, dynamic>.from(jsonDecode(authResp.body) as Map)
              : <String, dynamic>{};
        }

        final newToken = authBody['token']?.toString();
        if (authResp.statusCode < 200 ||
            authResp.statusCode >= 300 ||
            newToken == null ||
            newToken.isEmpty) {
          final authMsg = authBody['message']?.toString() ??
              'Gagal membuat atau masuk akun sebelum mengajukan toko.';
          throw Exception(authMsg);
        }

        await _apiService.saveToken(newToken);
        if (authBody['user'] is Map) {
          final userMap = Map<String, dynamic>.from(authBody['user'] as Map);
          await _apiService.saveUser(userMap);
          UserSession().setUser(User.fromJson(userMap));
        }
        registeredJustNow = true;
        _hasExistingToken = true;
      }

      final matched = _matchedBackendVillage;
      final provId = int.tryParse(_selectedProvince?.id ?? '35') ?? 35;
      final regId = int.tryParse(_selectedRegency?.id ?? '3529') ?? 3529;
      final rawDistId = int.tryParse(_selectedDistrict?.id ?? '352917');
      final resolvedDistId = (matched != null ? int.tryParse('${matched['district_id']}') : null) ??
          (rawDistId != null && rawDistId <= 2147483647 ? rawDistId : 352917);
      final resolvedVillageId = matched != null
          ? int.tryParse('${matched['id']}')
          : null;

      final res = await _apiService.submitStoreApplication({
        'nama_toko': _storeNameCtrl.text.trim(),
        'tipe_pengelola': _selectedType,
        'nik': _nikCtrl.text.trim(),
        'no_hp': _phoneCtrl.text.trim(),
        'province_id': provId,
        'province_name': _selectedProvince?.displayName ?? 'Jawa Timur',
        'regency_id': regId,
        'regency_name': _selectedRegency?.displayName ?? 'Kabupaten Sumenep',
        'district_id': resolvedDistId,
        'district_name': _selectedDistrict?.displayName ?? 'Dungkek',
        'village_id': ?resolvedVillageId,
        'village_name': _selectedVillage!.displayName,
        'postal_code': _postalCtrl.text.trim(),
        'alamat_lengkap': _addressCtrl.text.trim(),
        'dokumen_syarat_url': _docCtrl.text.trim(),
        'default_min_wholesale_kg':
            int.tryParse(_minWholesaleCtrl.text.trim()) ?? 30,
        'store_discount_banner': _bannerCtrl.text.trim(),
        'mode': freezeAsBuyer ? 'FREEZE_AS_BUYER' : 'SUBMIT_TO_PPL',
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('frozen_store_draft', freezeAsBuyer);
      await prefs.setString('frozen_store_name', _storeNameCtrl.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ??
                (freezeAsBuyer
                    ? 'Pengajuan dibekukan. Anda dapat belanja sebagai Pembeli!'
                    : 'Pengajuan dikirim ke Penyuluh Desa untuk verifikasi!'),
          ),
          backgroundColor:
              freezeAsBuyer ? AppColors.warning : AppColors.primary,
        ),
      );

      if (freezeAsBuyer || registeredJustNow) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RoleBasedAppShell()),
          (route) => false,
        );
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      final errMsg = e.toString().replaceFirst('Exception: ', '');
      if (errMsg.toLowerCase().contains('kuota toko')) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'Kuota Toko Desa Penuh',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            content: Text(
              errMsg,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Pilih Desa Lain'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pendaftaran Toko Desa (2 Tahap)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              _existingStatus == 'DRAFT_FROZEN'
                  ? 'Melanjutkan Pengajuan Dibekukan (Draft)'
                  : 'Pengajuan Admin Toko / Koperasi / Pengepul',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    _stepPill(0, '1. Diri & Desa'),
                    const SizedBox(width: 8),
                    _stepPill(1, '2. Syarat Toko'),
                  ],
                ),
                const SizedBox(height: 16),
                if (_step == 0) _buildStepOne() else _buildStepTwo(),
              ],
            ),
    );
  }

  Widget _stepPill(int index, String label) {
    final active = _step == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _step = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.outline,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepOne() {
    final matchedQuota = _matchedBackendVillage;
    final bool isQuotaFull = matchedQuota?['is_quota_full'] == true;
    final bool quotaEnabled =
        matchedQuota?['is_store_quota_enabled'] == true ||
            matchedQuota?['is_store_quota_enabled'] == 1;
    final approvedCnt = matchedQuota?['approved_stores_count'] ?? 0;
    final maxQuota = matchedQuota?['max_stores_quota'] ?? 5;
    final villageDisplay =
        _selectedVillage?.displayName ?? 'Desa Terpilih';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tahap 1: Data Pengelola & Wilayah (Sumenep)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (!_hasExistingToken) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceSoftBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Akun Pendaftar Baru',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Akun Pembeli akan dibuat otomatis agar Anda dapat mengajukan pembukaan toko atau menangguhkannya.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _fullNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap Pemilik',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Aktif',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata Sandi (Min. 6 Karakter)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _nikCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'NIK Pemilik / Pengurus',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor HP / WhatsApp Aktif',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // 1. Provinsi (Cascading Selector)
          DropdownButtonFormField<RegionItem>(
            key: ValueKey('prov-${_provinces.length}-${_selectedProvince?.id}'),
            isExpanded: true,
            initialValue: _provinces.contains(_selectedProvince)
                ? _selectedProvince
                : null,
            decoration: InputDecoration(
              labelText: _isLoadingProvinces
                  ? '1. Provinsi (Memuat...)'
                  : '1. Provinsi',
              border: const OutlineInputBorder(),
            ),
            items: _provinces
                .map(
                  (p) => DropdownMenuItem<RegionItem>(
                    value: p,
                    child: Text(
                      p.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _isLoadingProvinces ? null : _onProvinceChanged,
          ),
          const SizedBox(height: 10),

          // 2. Kabupaten / Kota (Cascading Selector)
          DropdownButtonFormField<RegionItem>(
            key: ValueKey(
              'reg-${_selectedProvince?.id}-${_regencies.length}-${_selectedRegency?.id}',
            ),
            isExpanded: true,
            initialValue: _regencies.contains(_selectedRegency)
                ? _selectedRegency
                : null,
            decoration: InputDecoration(
              labelText: _isLoadingRegencies
                  ? '2. Kabupaten / Kota (Memuat...)'
                  : '2. Kabupaten / Kota',
              border: const OutlineInputBorder(),
            ),
            items: _regencies
                .map(
                  (r) => DropdownMenuItem<RegionItem>(
                    value: r,
                    child: Text(
                      r.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _isLoadingRegencies ? null : _onRegencyChanged,
          ),
          const SizedBox(height: 10),

          // 3. Kecamatan (27 Kecamatan Sumenep Cascading Selector)
          DropdownButtonFormField<RegionItem>(
            key: ValueKey(
              'dist-${_selectedRegency?.id}-${_districts.length}-${_selectedDistrict?.id}',
            ),
            isExpanded: true,
            initialValue: _districts.contains(_selectedDistrict)
                ? _selectedDistrict
                : null,
            decoration: InputDecoration(
              labelText: _isLoadingDistricts
                  ? '3. Kecamatan (Memuat...)'
                  : '3. Kecamatan',
              border: const OutlineInputBorder(),
            ),
            items: _districts
                .map(
                  (d) => DropdownMenuItem<RegionItem>(
                    value: d,
                    child: Text(
                      'Kec. ${d.displayName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _isLoadingDistricts ? null : _onDistrictChanged,
          ),
          const SizedBox(height: 10),

          // 4. Desa / Kelurahan (Cascading Selector)
          DropdownButtonFormField<RegionItem>(
            key: ValueKey(
              'vill-${_selectedDistrict?.id}-${_villages.length}-${_selectedVillage?.id}',
            ),
            isExpanded: true,
            initialValue:
                _villages.contains(_selectedVillage) ? _selectedVillage : null,
            decoration: InputDecoration(
              labelText: _isLoadingVillages
                  ? '4. Desa / Kelurahan (Memuat...)'
                  : '4. Desa / Kelurahan',
              border: const OutlineInputBorder(),
            ),
            items: _villages
                .map(
                  (v) => DropdownMenuItem<RegionItem>(
                    value: v,
                    child: Text(
                      'Desa ${v.displayName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _isLoadingVillages ? null : _onVillageChanged,
          ),
          const SizedBox(height: 10),

          // Live Store Quota Badge rendered outside dropdown to avoid overflow
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isQuotaFull ? AppColors.errorSoft : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isQuotaFull
                    ? AppColors.errorBorder
                    : AppColors.surfaceSoftBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isQuotaFull
                      ? LucideIcons.alertTriangle
                      : LucideIcons.checkCircle2,
                  size: 16,
                  color: isQuotaFull ? AppColors.error : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    matchedQuota == null
                        ? 'Desa $villageDisplay (Kec. ${_selectedDistrict?.displayName ?? '-'}) terbuka untuk pengajuan toko desa.'
                        : quotaEnabled
                            ? (isQuotaFull
                                ? 'Kuota toko Desa $villageDisplay penuh ($approvedCnt/$maxQuota). Pilih desa lain atau tangguhkan.'
                                : 'Kuota toko Desa $villageDisplay: $approvedCnt/$maxQuota terpakai (Tersedia).')
                            : 'Desa $villageDisplay membuka pendaftaran toko tanpa batas kuota.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isQuotaFull
                          ? AppColors.error
                          : AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _postalCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kode Pos',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Lengkap Gudang/Toko',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _step = 1),
              icon: const Icon(LucideIcons.arrowRight, size: 17),
              label: Text(
                'Lanjut ke Tahap 2 (Syarat Toko)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTwo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tahap 2: Profil & Syarat Toko Mitra',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _storeNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama Toko / Koperasi / Unit Poktan',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Tipe Pengelola Toko',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'POKTAN', child: Text('Unit Usaha Poktan')),
              DropdownMenuItem(value: 'KOPERASI', child: Text('Koperasi Tani')),
              DropdownMenuItem(
                value: 'PENGEPUL_DESA',
                child: Text('Pengepul / Offtaker Desa'),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _selectedType = v);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _minWholesaleCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Default Minimal Pembelian Partai (kg)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bannerCtrl,
            decoration: const InputDecoration(
              labelText: 'Banner Promo Toko',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _docCtrl,
            decoration: const InputDecoration(
              labelText: 'Berkas Syarat (SK Poktan / Surat Izin Usaha)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => _submitApplication(freezeAsBuyer: false),
              icon: const Icon(LucideIcons.checkCircle, size: 18),
              label: Text(
                'Ajukan Pembukaan Toko ke Penyuluh',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => _submitApplication(freezeAsBuyer: true),
              icon: const Icon(LucideIcons.pauseCircle, size: 17),
              label: Text(
                'Tangguhkan & Lanjut sebagai Pembeli (Status Pengajuan Dibekukan)',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.accent),
                backgroundColor: AppColors.warningSoft,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
