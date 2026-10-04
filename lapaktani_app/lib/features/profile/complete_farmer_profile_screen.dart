import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/region_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_soft_card.dart';
import '../../core/widgets/lapaktani_text_field.dart';
import 'profile_repository.dart';
import 'verification_pending_screen.dart';

class CompleteFarmerProfileScreen extends StatefulWidget {
  final String? initialProvince;
  final String? initialRegency;
  final String? initialSubdistrict;
  final String? initialVillage;
  final String? initialRegion;
  final String? initialFarmerGroupId;

  const CompleteFarmerProfileScreen({
    super.key,
    this.initialProvince,
    this.initialRegency,
    this.initialSubdistrict,
    this.initialVillage,
    this.initialRegion,
    this.initialFarmerGroupId,
  });

  @override
  State<CompleteFarmerProfileScreen> createState() =>
      _CompleteFarmerProfileScreenState();
}

class _CompleteFarmerProfileScreenState
    extends State<CompleteFarmerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nikController = TextEditingController();
  final _landAreaController = TextEditingController();
  final _addressController = TextEditingController();

  final ProfileRepository _profileRepository = ProfileRepository();
  final RegionService _regionService = RegionService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedKtpFile;

  List<RegionItem> _provinces = [];
  RegionItem? _selectedProvince;

  List<RegionItem> _regencies = [];
  RegionItem? _selectedRegency;

  List<RegionItem> _districts = [];
  RegionItem? _selectedDistrict;

  List<RegionItem> _villages = [];
  RegionItem? _selectedVillage;

  List<Map<String, dynamic>> _filteredFarmerGroups = [];
  String? _selectedFarmerGroupId;

  bool _isLoadingProvinces = false;
  bool _isLoadingRegencies = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingVillages = false;
  bool _isLoadingGroups = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedFarmerGroupId = widget.initialFarmerGroupId;
    _loadInitialData();
  }

  @override
  void dispose() {
    _nikController.dispose();
    _landAreaController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingProvinces = true);

    final user = _profileRepository.currentUser;
    if (user != null) {
      final userProfile = await _profileRepository.getUserProfile(user.id);
      if (userProfile != null && mounted) {
        if (userProfile['nik_number'] != null) {
          _nikController.text = userProfile['nik_number'] as String;
        }
        if (userProfile['home_address'] != null) {
          _addressController.text = userProfile['home_address'] as String;
        }
      }

      final farmerProfile = await _profileRepository.getFarmerProfile(user.id);
      if (farmerProfile != null && mounted) {
        if (farmerProfile['land_area_ha'] != null) {
          _landAreaController.text =
              (farmerProfile['land_area_ha'] as num).toString();
        }
        if (farmerProfile['farmer_group_id'] != null) {
          _selectedFarmerGroupId = farmerProfile['farmer_group_id'] as String;
        }
      }
    }

    final provinces = await _regionService.getProvinces();
    if (!mounted) return;

    RegionItem? defaultProvince;
    if (widget.initialProvince != null) {
      final match = provinces.where(
        (p) =>
            p.name.toUpperCase() == widget.initialProvince!.toUpperCase() ||
            p.displayName.toUpperCase() ==
                widget.initialProvince!.toUpperCase(),
      );
      if (match.isNotEmpty) defaultProvince = match.first;
    }

    defaultProvince ??= provinces.firstWhere(
      (p) => p.name.toUpperCase().contains('JAWA TIMUR') || p.id == '35',
      orElse: () => provinces.isNotEmpty
          ? provinces.first
          : const RegionItem(id: '35', name: 'JAWA TIMUR'),
    );

    setState(() {
      _provinces = provinces;
      _selectedProvince = defaultProvince;
      _isLoadingProvinces = false;
      _isLoadingRegencies = true;
    });

    final regencies = await _regionService.getRegencies(defaultProvince.id);
    if (!mounted) return;

    RegionItem? defaultRegency;
    if (widget.initialRegency != null) {
      final match = regencies.where(
        (r) =>
            r.name.toUpperCase() == widget.initialRegency!.toUpperCase() ||
            r.displayName.toUpperCase() == widget.initialRegency!.toUpperCase(),
      );
      if (match.isNotEmpty) defaultRegency = match.first;
    }

    defaultRegency ??= regencies.firstWhere(
      (r) => r.name.toUpperCase().contains('SUMENEP') || r.id == '3529',
      orElse: () => regencies.isNotEmpty
          ? regencies.first
          : const RegionItem(id: '3529', name: 'KABUPATEN SUMENEP'),
    );

    setState(() {
      _regencies = regencies;
      _selectedRegency = defaultRegency;
      _isLoadingRegencies = false;
      _isLoadingDistricts = true;
    });

    final districts = await _regionService.getDistricts(defaultRegency.id);
    if (!mounted) return;

    setState(() {
      _districts = districts;
      _selectedDistrict = null;
      _selectedVillage = null;
      _isLoadingDistricts = false;
    });
  }

  Future<void> _onProvinceSelected(RegionItem province) async {
    if (_selectedProvince?.id == province.id) return;

    setState(() {
      _selectedProvince = province;
      _selectedRegency = null;
      _regencies = [];
      _selectedDistrict = null;
      _districts = [];
      _selectedVillage = null;
      _villages = [];
      _selectedFarmerGroupId = null;
      _filteredFarmerGroups = [];
      _isLoadingRegencies = true;
    });

    final regencies = await _regionService.getRegencies(province.id);
    if (!mounted) return;

    setState(() {
      _regencies = regencies;
      _isLoadingRegencies = false;
    });
  }

  Future<void> _onRegencySelected(RegionItem regency) async {
    if (_selectedRegency?.id == regency.id) return;

    setState(() {
      _selectedRegency = regency;
      _selectedDistrict = null;
      _districts = [];
      _selectedVillage = null;
      _villages = [];
      _selectedFarmerGroupId = null;
      _filteredFarmerGroups = [];
      _isLoadingDistricts = true;
    });

    final districts = await _regionService.getDistricts(regency.id);
    if (!mounted) return;

    setState(() {
      _districts = districts;
      _isLoadingDistricts = false;
    });
  }

  Future<void> _onDistrictSelected(RegionItem district) async {
    if (_selectedDistrict?.id == district.id) return;

    setState(() {
      _selectedDistrict = district;
      _selectedVillage = null;
      _villages = [];
      _selectedFarmerGroupId = null;
      _filteredFarmerGroups = [];
      _isLoadingVillages = true;
    });

    final villages = await _regionService.getVillages(district.id);
    if (!mounted) return;

    setState(() {
      _villages = villages;
      _isLoadingVillages = false;
    });
  }

  Future<void> _onVillageSelected(RegionItem village) async {
    setState(() {
      _selectedVillage = village;
      _selectedFarmerGroupId = null;
      _filteredFarmerGroups = [];
      _isLoadingGroups = true;
    });

    var groups = await _profileRepository.getFarmerGroupsByVillage(village.name);
    if (groups.isEmpty) {
      groups = await _profileRepository.getFarmerGroupsByVillage(
        village.displayName,
      );
    }

    if (!mounted) return;

    setState(() {
      _filteredFarmerGroups = groups;
      if (groups.isNotEmpty) {
        _selectedFarmerGroupId = groups.first['id'] as String;
      }
      _isLoadingGroups = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1200,
        imageQuality: 88,
      );

      if (pickedFile == null) return;

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Atur Foto KTP',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Atur Foto KTP',
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        setState(() {
          _selectedKtpFile = File(croppedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: ${e.toString()}'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _submitVerification() async {
    if (_selectedKtpFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wajib mengunggah foto e-KTP untuk verifikasi petani.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_selectedProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih Provinsi domisili kebun Anda.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_selectedRegency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih Kabupaten / Kota domisili kebun Anda.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih Kecamatan domisili kebun Anda.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih Desa / Kelurahan domisili kebun Anda.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_filteredFarmerGroups.isNotEmpty &&
        (_selectedFarmerGroupId == null || _selectedFarmerGroupId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kelompok tani (Poktan) binaan Anda.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final user = _profileRepository.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi pengguna tidak valid. Silakan login kembali.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final landArea = double.tryParse(
            _landAreaController.text.trim().replaceAll(',', '.'),
          ) ??
          0.0;

      final fullAddress = _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : 'Desa ${_selectedVillage!.displayName}, Kec. ${_selectedDistrict!.displayName}, ${_selectedRegency!.displayName}, ${_selectedProvince!.displayName}';

      await _profileRepository.submitFarmerProfileCompletion(
        userId: user.id,
        ktpImageFile: _selectedKtpFile!,
        nikNumber: _nikController.text.trim(),
        homeAddress: fullAddress,
        farmerGroupId: _selectedFarmerGroupId,
        landAreaHa: landArea,
        province: _selectedProvince?.displayName ?? _selectedProvince?.name,
        regency: _selectedRegency?.displayName ?? _selectedRegency?.name,
        district: _selectedDistrict?.displayName ?? _selectedDistrict?.name,
        village: _selectedVillage?.displayName ?? _selectedVillage?.name,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const VerificationPendingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim verifikasi: ${e.toString()}'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showRegionPicker({
    required String title,
    required String subtitle,
    required List<RegionItem> items,
    required RegionItem? selectedItem,
    required IconData icon,
    required ValueChanged<RegionItem> onSelected,
  }) {
    if (items.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredItems = searchQuery.trim().isEmpty
                ? items
                : items.where((item) {
                    final query = searchQuery.trim().toLowerCase();
                    return item.name.toLowerCase().contains(query) ||
                        item.displayName.toLowerCase().contains(query);
                  }).toList();

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(LucideIcons.x, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF64748B),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setSheetState(() => searchQuery = val);
                        },
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari wilayah...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(
                            LucideIcons.search,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    LucideIcons.xCircle,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    setSheetState(() => searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.mapPinOff,
                                    size: 36,
                                    color: const Color(0xFF94A3B8)
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tidak ditemukan hasil yang cocok',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredItems.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                height: 1,
                                color: Color(0xFFF1F5F9),
                              ),
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final isSelected = item.id == selectedItem?.id;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  leading: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.primary
                                              .withValues(alpha: 0.12)
                                          : const Color(0xFFF1F5F9),
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 16,
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                  title: Text(
                                    item.displayName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          LucideIcons.checkCircle2,
                                          color: AppColors.primary,
                                          size: 20,
                                        )
                                      : null,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    onSelected(item);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFarmerGroupPicker() {
    if (_selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih Desa terlebih dahulu.')),
      );
      return;
    }

    if (_filteredFarmerGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Belum ada kelompok tani terdaftar di Desa ${_selectedVillage!.displayName}.',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kelompok Tani di Desa ${_selectedVillage!.displayName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kecamatan ${_selectedDistrict?.displayName ?? ''}, ${_selectedRegency?.displayName ?? ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filteredFarmerGroups.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final group = _filteredFarmerGroups[index];
                      final isSelected = group['id'] == _selectedFarmerGroupId;
                      final address = group['secretariat_address'] ??
                          group['domicile_region'] ??
                          '';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : const Color(0xFFF1F5F9),
                          ),
                          child: Icon(
                            LucideIcons.users,
                            size: 18,
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFF64748B),
                          ),
                        ),
                        title: Text(
                          group['group_name'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: address.toString().isNotEmpty
                            ? Text(
                                address.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: isSelected
                            ? const Icon(
                                LucideIcons.checkCircle2,
                                color: AppColors.primary,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedFarmerGroupId = group['id'] as String;
                          });
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectorTile({
    required String label,
    required String? value,
    required String placeholder,
    required IconData icon,
    required bool isEnabled,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return GestureDetector(
      onTap: isEnabled && !isLoading ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue
                ? AppColors.primary.withValues(alpha: 0.3)
                : (isEnabled
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFFCBD5E1)),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasValue
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : const Color(0xFFE2E8F0),
              ),
              child: Icon(
                icon,
                size: 16,
                color: hasValue ? AppColors.primary : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? value : placeholder,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                      color: hasValue
                          ? const Color(0xFF0F172A)
                          : (isEnabled
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFFCBD5E1)),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            else
              Icon(
                LucideIcons.chevronDown,
                size: 16,
                color:
                    isEnabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedGroupName = _filteredFarmerGroups.firstWhere(
      (g) => g['id'] == _selectedFarmerGroupId,
      orElse: () => {
        'group_name': _filteredFarmerGroups.isEmpty
            ? (_selectedVillage != null
                ? 'Belum ada kelompok tani di desa ini'
                : 'Pilih Desa terlebih dahulu')
            : 'Pilih Kelompok Tani',
      },
    )['group_name'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          Positioned(
            top: -96,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD1FAE5).withValues(alpha: 0.6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD1FAE5).withValues(alpha: 0.6),
                    blurRadius: 90,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 48,
            right: -96,
            child: Container(
              width: 288,
              height: 288,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFECFCCB).withValues(alpha: 0.4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFECFCCB).withValues(alpha: 0.4),
                    blurRadius: 80,
                    spreadRadius: 35,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.arrowLeft, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E293B),
                            padding: const EdgeInsets.all(10),
                            elevation: 0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFA7F3D0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedRegency?.displayName ??
                                    'Wilayah Indonesia',
                                style: const TextStyle(
                                  color: Color(0xFF065F46),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Lengkapi Berkas Petani',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Unggah e-KTP dan tentukan domisili kebun Anda melalui hierarki wilayah terpadu.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 1: KTP Upload Card
                    _buildSectionHeader(
                      number: '1',
                      title: 'Foto e-KTP Asli',
                      isRequired: true,
                    ),
                    const SizedBox(height: 8),
                    CustomSoftCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_selectedKtpFile == null)
                            GestureDetector(
                              onTap: () => _pickImage(ImageSource.camera),
                              child: Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: CustomPaint(
                                  painter: _DashedBorderPainter(
                                    color: const Color(0xFFCBD5E1),
                                    strokeWidth: 1.6,
                                    dashLength: 8,
                                    dashGap: 5,
                                    borderRadius: 16,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            LucideIcons.camera,
                                            color: AppColors.primary,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Unggah Foto e-KTP Anda',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Format JPG/PNG, maks. 10MB',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Stack(
                                    children: [
                                      Image.file(
                                        _selectedKtpFile!,
                                        height: 190,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.65),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                LucideIcons.checkCircle2,
                                                color: Color(0xFF34D399),
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'KTP Terpilih',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _pickImage(ImageSource.camera),
                                  icon:
                                      const Icon(LucideIcons.camera, size: 16),
                                  label: const Text('Kamera'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1E293B),
                                    backgroundColor: const Color(0xFFF8FAFC),
                                    side: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _pickImage(ImageSource.gallery),
                                  icon: const Icon(LucideIcons.image, size: 16),
                                  label: const Text('Galeri'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1E293B),
                                    backgroundColor: const Color(0xFFF8FAFC),
                                    side: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 2: 4-Tier Cascading Domicile Selection
                    _buildSectionHeader(
                      number: '2',
                      title: 'Domisili Kebun (Hierarki 4 Tingkat)',
                      isRequired: true,
                    ),
                    const SizedBox(height: 8),
                    CustomSoftCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFBBF7D0),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  LucideIcons.globe,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Pilih wilayah bertingkat dari Provinsi hingga Desa.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tier 1: Provinsi
                          _buildSelectorTile(
                            label: '1. Provinsi',
                            value: _selectedProvince?.displayName,
                            placeholder: 'Pilih Provinsi',
                            icon: LucideIcons.globe,
                            isEnabled: true,
                            isLoading: _isLoadingProvinces,
                            onTap: () {
                              _showRegionPicker(
                                title: 'Pilih Provinsi',
                                subtitle:
                                    'Daftar 34 provinsi resmi di Indonesia',
                                items: _provinces,
                                selectedItem: _selectedProvince,
                                icon: LucideIcons.globe,
                                onSelected: _onProvinceSelected,
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Tier 2: Kabupaten / Kota
                          _buildSelectorTile(
                            label: '2. Kabupaten / Kota',
                            value: _selectedRegency?.displayName,
                            placeholder: _selectedProvince != null
                                ? 'Pilih Kabupaten / Kota'
                                : 'Pilih Provinsi terlebih dahulu',
                            icon: LucideIcons.landmark,
                            isEnabled: _selectedProvince != null,
                            isLoading: _isLoadingRegencies,
                            onTap: () {
                              _showRegionPicker(
                                title:
                                    'Pilih Kab / Kota di ${_selectedProvince?.displayName ?? ''}',
                                subtitle: 'Daftar kabupaten / kota resmi',
                                items: _regencies,
                                selectedItem: _selectedRegency,
                                icon: LucideIcons.landmark,
                                onSelected: _onRegencySelected,
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Tier 3: Kecamatan
                          _buildSelectorTile(
                            label: '3. Kecamatan',
                            value: _selectedDistrict?.displayName,
                            placeholder: _selectedRegency != null
                                ? 'Pilih Kecamatan'
                                : 'Pilih Kab / Kota terlebih dahulu',
                            icon: LucideIcons.building2,
                            isEnabled: _selectedRegency != null,
                            isLoading: _isLoadingDistricts,
                            onTap: () {
                              _showRegionPicker(
                                title:
                                    'Pilih Kecamatan di ${_selectedRegency?.displayName ?? ''}',
                                subtitle: 'Daftar kecamatan resmi',
                                items: _districts,
                                selectedItem: _selectedDistrict,
                                icon: LucideIcons.building2,
                                onSelected: _onDistrictSelected,
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Tier 4: Desa / Kelurahan
                          _buildSelectorTile(
                            label: '4. Desa / Kelurahan',
                            value: _selectedVillage?.displayName,
                            placeholder: _selectedDistrict != null
                                ? 'Pilih Desa / Kelurahan'
                                : 'Pilih Kecamatan terlebih dahulu',
                            icon: LucideIcons.mapPin,
                            isEnabled: _selectedDistrict != null,
                            isLoading: _isLoadingVillages,
                            onTap: () {
                              _showRegionPicker(
                                title:
                                    'Pilih Desa / Kelurahan di Kec. ${_selectedDistrict?.displayName ?? ''}',
                                subtitle: 'Desa sentra pertanian',
                                items: _villages,
                                selectedItem: _selectedVillage,
                                icon: LucideIcons.mapPin,
                                onSelected: _onVillageSelected,
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Tier 5: Kelompok Tani (Gapoktan) filtered by Village
                          _buildSelectorTile(
                            label: '5. Kelompok Tani (Gapoktan)',
                            value: selectedGroupName,
                            placeholder: _selectedVillage != null
                                ? (_filteredFarmerGroups.isEmpty
                                    ? 'Belum ada Poktan di desa ini'
                                    : 'Pilih Kelompok Tani')
                                : 'Pilih Desa terlebih dahulu',
                            icon: LucideIcons.users,
                            isEnabled: _selectedVillage != null &&
                                _filteredFarmerGroups.isNotEmpty,
                            isLoading: _isLoadingGroups,
                            onTap: _showFarmerGroupPicker,
                          ),
                          if (_selectedVillage != null) ...[
                            const SizedBox(height: 10),
                            if (_filteredFarmerGroups.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.checkCircle2,
                                      size: 14,
                                      color: Color(0xFF16A34A),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Ditemukan ${_filteredFarmerGroups.length} kelompok tani aktif di ${_selectedVillage!.displayName}.',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF166534),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (!_isLoadingGroups)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFDE68A),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      LucideIcons.info,
                                      size: 14,
                                      color: Color(0xFFD97706),
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Belum ada Poktan terdaftar di desa ini. Dinas pertanian akan mengarahkan penempatan saat verifikasi berkas.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF92400E),
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Data Detail
                    _buildSectionHeader(
                      number: '3',
                      title: 'Detail Identitas & Lahan',
                      isRequired: false,
                    ),
                    const SizedBox(height: 8),
                    CustomSoftCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          LapaktaniTextField(
                            label: 'Nomor Induk Kependudukan (NIK)',
                            hintText: '16 digit NIK sesuai KTP',
                            controller: _nikController,
                            keyboardType: TextInputType.number,
                            prefixIcon: LucideIcons.creditCard,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(16),
                            ],
                            validator: (val) {
                              if (val != null &&
                                  val.isNotEmpty &&
                                  val.length != 16) {
                                return 'NIK harus terdiri dari 16 digit';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          LapaktaniTextField(
                            label: 'Luas Lahan Garapan (Hektar)',
                            hintText: 'Contoh: 1.5',
                            controller: _landAreaController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            prefixIcon: LucideIcons.layers,
                          ),
                          const SizedBox(height: 14),
                          LapaktaniTextField(
                            label: 'Alamat Domisili Lengkap',
                            hintText: 'Jalan, Dusun, RT/RW',
                            controller: _addressController,
                            keyboardType: TextInputType.streetAddress,
                            prefixIcon: LucideIcons.home,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Submit Action Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.send, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Kirim Permohonan',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String number,
    required String title,
    required bool isRequired,
  }) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Wajib',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashLength = 6.0,
    this.dashGap = 4.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            strokeWidth / 2,
            strokeWidth / 2,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(borderRadius),
        ),
      );

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + dashLength < metric.length)
            ? dashLength
            : metric.length - distance;
        final extractPath = metric.extractPath(distance, distance + len);
        canvas.drawPath(extractPath, paint);
        distance += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashLength != oldDelegate.dashLength ||
      dashGap != oldDelegate.dashGap ||
      borderRadius != oldDelegate.borderRadius;
}
