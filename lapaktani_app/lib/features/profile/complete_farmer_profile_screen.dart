import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_soft_card.dart';
import '../../core/widgets/lapaktani_text_field.dart';
import 'profile_repository.dart';
import 'verification_pending_screen.dart';

class CompleteFarmerProfileScreen extends StatefulWidget {
  final String? initialSubdistrict;
  final String? initialVillage;
  final String? initialRegion;
  final String? initialFarmerGroupId;

  const CompleteFarmerProfileScreen({
    super.key,
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
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedKtpFile;
  List<String> _subdistricts = [];
  String? _selectedSubdistrict;
  List<String> _villages = [];
  String? _selectedVillage;
  List<Map<String, dynamic>> _filteredFarmerGroups = [];
  String? _selectedFarmerGroupId;

  bool _isLoadingSubdistricts = false;
  bool _isLoadingVillages = false;
  bool _isLoadingGroups = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedSubdistrict = widget.initialSubdistrict;
    _selectedVillage = widget.initialVillage;
    _selectedFarmerGroupId = widget.initialFarmerGroupId;

    if (_selectedSubdistrict == null && widget.initialRegion != null) {
      final region = widget.initialRegion!;
      if (region.contains('Kec.')) {
        final parts = region.split('Kec.');
        if (parts.length > 1) {
          _selectedSubdistrict = parts[1].split(',').first.trim();
        }
      }
      if (region.contains('Desa')) {
        final parts = region.split('Desa');
        if (parts.length > 1) {
          _selectedVillage = parts[1].split(',').first.trim();
        }
      }
    }

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
    setState(() => _isLoadingSubdistricts = true);

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
          if (farmerProfile['farmer_groups'] != null) {
            final fg = farmerProfile['farmer_groups'] as Map<String, dynamic>;
            if (fg['subdistrict_name'] != null && _selectedSubdistrict == null) {
              _selectedSubdistrict = fg['subdistrict_name'] as String;
            }
            if (fg['village_name'] != null && _selectedVillage == null) {
              _selectedVillage = fg['village_name'] as String;
            }
          }
        }
      }
    }

    final subdistricts = await _profileRepository.getSubdistricts();
    if (!mounted) return;

    setState(() {
      _subdistricts = subdistricts;
      if (_selectedSubdistrict == null && _subdistricts.isNotEmpty) {
        _selectedSubdistrict = _subdistricts.first;
      }
      _isLoadingSubdistricts = false;
    });

    if (_selectedSubdistrict != null) {
      await _onSubdistrictChanged(_selectedSubdistrict!, preserveSelection: true);
    }
  }

  Future<void> _onSubdistrictChanged(
    String subdistrict, {
    bool preserveSelection = false,
  }) async {
    setState(() {
      _selectedSubdistrict = subdistrict;
      _isLoadingVillages = true;
      if (!preserveSelection) {
        _selectedVillage = null;
        _selectedFarmerGroupId = null;
        _filteredFarmerGroups = [];
      }
    });

    final villages =
        await _profileRepository.getVillagesBySubdistrict(subdistrict);
    if (!mounted) return;

    setState(() {
      _villages = villages;
      if ((_selectedVillage == null || !_villages.contains(_selectedVillage)) &&
          _villages.isNotEmpty) {
        _selectedVillage = _villages.first;
      }
      _isLoadingVillages = false;
    });

    if (_selectedVillage != null) {
      await _onVillageChanged(
        _selectedVillage!,
        preserveGroup: preserveSelection,
      );
    }
  }

  Future<void> _onVillageChanged(
    String village, {
    bool preserveGroup = false,
  }) async {
    setState(() {
      _selectedVillage = village;
      _isLoadingGroups = true;
      if (!preserveGroup) {
        _selectedFarmerGroupId = null;
      }
    });

    final groups = await _profileRepository.getFarmerGroupsByVillage(village);
    if (!mounted) return;

    setState(() {
      _filteredFarmerGroups = groups;
      if (_selectedFarmerGroupId == null ||
          !_filteredFarmerGroups
              .any((g) => g['id'] == _selectedFarmerGroupId)) {
        _selectedFarmerGroupId = _filteredFarmerGroups.isNotEmpty
            ? _filteredFarmerGroups.first['id'] as String
            : null;
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

    if (_selectedSubdistrict == null || _selectedSubdistrict!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih Kecamatan domisili kebun Anda.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_selectedVillage == null || _selectedVillage!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih Desa domisili kebun Anda.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_selectedFarmerGroupId == null || _selectedFarmerGroupId!.isEmpty) {
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
          : 'Desa $_selectedVillage, Kec. $_selectedSubdistrict, Kab. Sumenep';

      await _profileRepository.submitFarmerProfileCompletion(
        userId: user.id,
        ktpImageFile: _selectedKtpFile!,
        nikNumber: _nikController.text.trim(),
        homeAddress: fullAddress,
        farmerGroupId: _selectedFarmerGroupId,
        landAreaHa: landArea,
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

  void _showSubdistrictPicker() {
    if (_subdistricts.isEmpty) return;

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
                const Text(
                  'Pilih Kecamatan (Kab. Sumenep)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Daftar kecamatan resmi di wilayah Kabupaten Sumenep',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _subdistricts.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final subdistrict = _subdistricts[index];
                      final isSelected = subdistrict == _selectedSubdistrict;

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
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : const Color(0xFFF1F5F9),
                          ),
                          child: Icon(
                            LucideIcons.building2,
                            size: 16,
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFF64748B),
                          ),
                        ),
                        title: Text(
                          subdistrict,
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
                          _onSubdistrictChanged(subdistrict);
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

  void _showVillagePicker() {
    if (_selectedSubdistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih Kecamatan terlebih dahulu.')),
      );
      return;
    }

    if (_villages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sedang memuat desa di Kec. $_selectedSubdistrict...',
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
                  'Pilih Desa / Kelurahan di Kec. $_selectedSubdistrict',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Desa sentra pertanian di bawah naungan kelompok tani',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _villages.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final village = _villages[index];
                      final isSelected = village == _selectedVillage;

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
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : const Color(0xFFF1F5F9),
                          ),
                          child: Icon(
                            LucideIcons.mapPin,
                            size: 16,
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFF64748B),
                          ),
                        ),
                        title: Text(
                          village,
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
                          _onVillageChanged(village);
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
            'Belum ada kelompok tani terdaftar di Desa $_selectedVillage.',
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
                  'Kelompok Tani di Desa $_selectedVillage',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kecamatan $_selectedSubdistrict, Kabupaten Sumenep',
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
                              const Text(
                                'Kabupaten Sumenep',
                                style: TextStyle(
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
                      'Unggah e-KTP dan pilih domisili kebun Anda di Kabupaten Sumenep secara bertahap.',
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

                    // Section 2: 2-Tier Domicile Selection (Sumenep: Kecamatan -> Desa -> Poktan)
                    _buildSectionHeader(
                      number: '2',
                      title: 'Wilayah & Kelompok Tani (Sumenep)',
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
                                  LucideIcons.mapPin,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Cakupan Wilayah: Kabupaten Sumenep (Madura)',
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

                          // Tier 1: Kecamatan
                          const Text(
                            '1. Kecamatan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _showSubdistrictPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.building2,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _selectedSubdistrict ??
                                          'Pilih Kecamatan',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedSubdistrict != null
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                  _isLoadingSubdistricts
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          LucideIcons.chevronDown,
                                          size: 16,
                                          color: Color(0xFF64748B),
                                        ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Tier 2: Desa / Kelurahan
                          const Text(
                            '2. Desa / Kelurahan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _showVillagePicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.mapPin,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _selectedVillage ??
                                          (_selectedSubdistrict != null
                                              ? 'Pilih Desa'
                                              : 'Pilih Kecamatan terlebih dahulu'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedVillage != null
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                  _isLoadingVillages
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          LucideIcons.chevronDown,
                                          size: 16,
                                          color: Color(0xFF64748B),
                                        ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Tier 3: Kelompok Tani (Gapoktan) filtered by Desa
                          const Text(
                            '3. Kelompok Tani (Gapoktan)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _showFarmerGroupPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.users,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      selectedGroupName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedFarmerGroupId != null
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFF94A3B8),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _isLoadingGroups
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          LucideIcons.chevronDown,
                                          size: 16,
                                          color: Color(0xFF64748B),
                                        ),
                                ],
                              ),
                            ),
                          ),
                          if (_selectedVillage != null &&
                              _filteredFarmerGroups.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Menampilkan ${_filteredFarmerGroups.length} kelompok tani aktif di Desa $_selectedVillage.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
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
                            hintText: 'Jalan, Dusun, RT/RW di Sumenep',
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
