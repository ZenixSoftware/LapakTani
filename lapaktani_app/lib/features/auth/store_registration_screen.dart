import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_dashboard_screen.dart';

class StoreRegistrationScreen extends StatefulWidget {
  const StoreRegistrationScreen({super.key});

  @override
  State<StoreRegistrationScreen> createState() =>
      _StoreRegistrationScreenState();
}

class _StoreRegistrationScreenState extends State<StoreRegistrationScreen> {
  final ApiService _apiService = ApiService();
  int _step = 0; // 0: Personal & Wilayah, 1: Syarat Toko
  bool _isLoading = true;
  bool _isSubmitting = false;

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
  int _selectedVillageId = 109;
  List<Map<String, dynamic>> _villages = [];
  String? _existingStatus;

  static const List<Map<String, dynamic>> _fallbackVillages = [
    {
      'id': 101,
      'district_id': 352901,
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
      'district_id': 352902,
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
    _loadInitialData();
  }

  @override
  void dispose() {
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

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getMyStoreApplication();
      final data = res['data'];
      if (data is Map) {
        final rawVillages = data['villages'];
        if (rawVillages is List && rawVillages.isNotEmpty) {
          _villages = rawVillages
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
          if (app['village_id'] != null) {
            _selectedVillageId =
                int.tryParse(app['village_id'].toString()) ?? 109;
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
    } catch (_) {
      // Fall back to default village options if offline
    }

    if (_villages.isEmpty) {
      _villages = _fallbackVillages;
    }
    if (!_villages.any((v) => int.tryParse('${v['id']}') == _selectedVillageId)) {
      _selectedVillageId = int.tryParse('${_villages.first['id']}') ?? 109;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> get _currentVillage {
    return _villages.firstWhere(
      (v) => int.tryParse('${v['id']}') == _selectedVillageId,
      orElse: () => _villages.first,
    );
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

    setState(() => _isSubmitting = true);
    try {
      final v = _currentVillage;
      final res = await _apiService.submitStoreApplication({
        'nama_toko': _storeNameCtrl.text.trim(),
        'tipe_pengelola': _selectedType,
        'nik': _nikCtrl.text.trim(),
        'no_hp': _phoneCtrl.text.trim(),
        'province_id': 35,
        'regency_id': 3529,
        'district_id': int.tryParse('${v['district_id']}') ?? 352917,
        'village_id': _selectedVillageId,
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

      if (freezeAsBuyer) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
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
                // 2-step indicator
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
    final v = _currentVillage;
    final bool isQuotaFull = v['is_quota_full'] == true;
    final bool quotaEnabled =
        v['is_store_quota_enabled'] == true || v['is_store_quota_enabled'] == 1;
    final approvedCnt = v['approved_stores_count'] ?? 0;
    final maxQuota = v['max_stores_quota'] ?? 5;

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
            'Tahap 1: Data Pengelola & Wilayah Desa',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
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
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: _selectedVillageId,
            decoration: const InputDecoration(
              labelText: 'Pilih Desa (Prov. Jawa Timur • Kab. Sumenep)',
              border: OutlineInputBorder(),
            ),
            items: _villages.map((item) {
              final id = int.tryParse('${item['id']}') ?? 109;
              final name = (item['name'] ?? 'Dungkek').toString();
              final dist = (item['district_name'] ?? 'Sumenep').toString();
              final qOn = item['is_store_quota_enabled'] == true ||
                  item['is_store_quota_enabled'] == 1;
              final full = item['is_quota_full'] == true;
              final cnt = item['approved_stores_count'] ?? 0;
              final maxQ = item['max_stores_quota'] ?? 5;
              final badge = qOn
                  ? (full ? ' [KUOTA PENUH $cnt/$maxQ]' : ' [Kuota $cnt/$maxQ]')
                  : ' [Terbuka]';
              return DropdownMenuItem<int>(
                value: id,
                child: Text('Desa $name ($dist)$badge'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedVillageId = val;
                  final found = _villages.firstWhere(
                    (x) => int.tryParse('${x['id']}') == val,
                    orElse: () => _villages.first,
                  );
                  if (found['postal_code'] != null) {
                    _postalCtrl.text = found['postal_code'].toString();
                  }
                });
              }
            },
          ),
          const SizedBox(height: 8),
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
                    quotaEnabled
                        ? (isQuotaFull
                            ? 'Kuota toko Desa ${v['name']} penuh ($approvedCnt/$maxQuota). Pilih desa lain atau tangguhkan.'
                            : 'Kuota toko Desa ${v['name']}: $approvedCnt/$maxQuota terpakai (Tersedia).')
                        : 'Desa ${v['name']} membuka pendaftaran toko tanpa batas kuota.',
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
