import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_soft_card.dart';
import 'auth_repository.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nikController = TextEditingController();
  final _landAreaController = TextEditingController();

  final AuthRepository _authRepository = AuthRepository();

  String _selectedRole = 'pembeli';
  String? _selectedFarmerGroupId;
  List<Map<String, dynamic>> _farmerGroups = [];
  bool _isLoadingFarmerGroups = false;
  bool _obscurePassword = true;
  bool _agreedToTerms = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFarmerGroups();
  }

  Future<void> _loadFarmerGroups() async {
    setState(() => _isLoadingFarmerGroups = true);
    final groups = await _authRepository.getFarmerGroups();
    if (mounted) {
      setState(() {
        _farmerGroups = groups;
        if (_farmerGroups.isNotEmpty) {
          _selectedFarmerGroupId = _farmerGroups.first['id'] as String;
        }
        _isLoadingFarmerGroups = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nikController.dispose();
    _landAreaController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui Syarat & Ketentuan.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final double? parsedLandArea = _selectedRole == 'petani'
          ? double.tryParse(_landAreaController.text.trim()) ?? 0.0
          : null;

      final formattedPhone = _phoneController.text.trim().startsWith('+62')
          ? _phoneController.text.trim()
          : '+62${_phoneController.text.trim().replaceAll(RegExp(r'^0+'), '')}';

      final response = await _authRepository.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        roleName: _selectedRole,
        fullName: _nameController.text.trim(),
        phone: formattedPhone,
        nikNumber:
            _selectedRole == 'petani' ? _nikController.text.trim() : null,
        landAreaHa: parsedLandArea,
        farmerGroupId:
            _selectedRole == 'petani' ? _selectedFarmerGroupId : null,
      );

      if (!mounted) return;

      if (response.session != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registrasi berhasil! Silakan periksa email Anda untuk verifikasi.',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendaftar: ${e.toString()}'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFarmer = _selectedRole == 'petani';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          'Panen Segar Harian',
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
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.sprout,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Lapak',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: 'Tani',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Daftar ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    TextSpan(
                      text: 'LapakTani',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isFarmer
                    ? 'Daftar sebagai mitra petani untuk menjangkau pasar langsung tanpa perantara.'
                    : 'Bergabung sekarang untuk belanja sayur dan buah segar langsung dari petani.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              CustomSoftCard(
                padding: const EdgeInsets.all(4),
                borderRadius: BorderRadius.circular(16),
                backgroundColor: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedRole != 'pembeli') {
                            setState(() => _selectedRole = 'pembeli');
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isFarmer
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !isFarmer
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.28),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.shoppingBag,
                                size: 16,
                                color: !isFarmer
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pembeli',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: !isFarmer
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedRole != 'petani') {
                            setState(() => _selectedRole = 'petani');
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isFarmer
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isFarmer
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.28),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.store,
                                size: 16,
                                color: isFarmer
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Petani Mitra',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isFarmer
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isFarmer
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFarmer
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFA7F3D0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isFarmer ? LucideIcons.store : LucideIcons.checkCircle2,
                      size: 16,
                      color: isFarmer
                          ? const Color(0xFFB45309)
                          : const Color(0xFF047857),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isFarmer
                            ? 'Akses pasar luas tanpa tengkulak dengan pembayaran transparan.'
                            : 'Akses produk panen subuh segar dan harga adil dari petani.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isFarmer
                              ? const Color(0xFF92400E)
                              : const Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              CustomSoftCard(
                padding: const EdgeInsets.all(22.0),
                borderRadius: BorderRadius.circular(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFieldLabel(
                        'Nama Lengkap *',
                        isFarmer ? 'Sesuai KTP' : null,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama lengkap wajib diisi';
                          }
                          return null;
                        },
                        decoration: _buildSoftInputDecoration(
                          hintText: 'Contoh: Budi Santoso',
                          prefixIcon: LucideIcons.user,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildFieldLabel('Email Aktif *', null),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Email wajib diisi';
                          }
                          if (!val.contains('@')) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                        decoration: _buildSoftInputDecoration(
                          hintText: 'nama@email.com',
                          prefixIcon: LucideIcons.mail,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildFieldLabel('Nomor WhatsApp / HP *', null),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nomor HP wajib diisi';
                          }
                          if (val.trim().length < 8) {
                            return 'Nomor HP terlalu pendek';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🇮🇩', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 4),
                                Text(
                                  '+62',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          hintText: '812-3456-7890',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w400,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildFieldLabel('Kata Sandi *', 'Minimal 6 karakter'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: isFarmer
                            ? TextInputAction.next
                            : TextInputAction.done,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Kata sandi wajib diisi';
                          }
                          if (val.length < 6) return 'Minimal 6 karakter';
                          return null;
                        },
                        decoration: _buildSoftInputDecoration(
                          hintText: '••••••••',
                          prefixIcon: LucideIcons.lock,
                          suffixWidget: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? LucideIcons.eye
                                  : LucideIcons.eyeOff,
                              size: 19,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                        ),
                      ),
                      if (isFarmer)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFFE2E8F0)),
                            const SizedBox(height: 12),
                            const Text(
                              'Informasi Legalitas & Kebun Petani',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildFieldLabel(
                              'Nomor Induk Kependudukan (NIK) *',
                              '16 Digit',
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nikController,
                              keyboardType: TextInputType.number,
                              maxLength: 16,
                              textInputAction: TextInputAction.next,
                              validator: (val) {
                                if (!isFarmer) return null;
                                if (val == null || val.trim().isEmpty) {
                                  return 'NIK wajib diisi untuk verifikasi petani';
                                }
                                if (val.trim().length != 16) {
                                  return 'NIK harus 16 digit';
                                }
                                return null;
                              },
                              decoration: _buildSoftInputDecoration(
                                hintText: 'Contoh: 3201234567890001',
                                prefixIcon: LucideIcons.fileText,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildFieldLabel(
                              'Luas Lahan Pertanian (Hektar) *',
                              'Contoh: 1.5',
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _landAreaController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (val) {
                                if (!isFarmer) return null;
                                if (val == null || val.trim().isEmpty) {
                                  return 'Luas lahan wajib diisi';
                                }
                                final parsed = double.tryParse(val.trim());
                                if (parsed == null || parsed <= 0) {
                                  return 'Luas lahan harus berupa angka valid';
                                }
                                return null;
                              },
                              decoration: _buildSoftInputDecoration(
                                hintText: '1.5',
                                prefixIcon: LucideIcons.maximize2,
                                suffixWidget: const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    'Ha',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildFieldLabel('Kelompok Tani (Gapoktan) *', null),
                            const SizedBox(height: 6),
                            _isLoadingFarmerGroups
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: _selectedFarmerGroupId,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF1F5F9),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    items: _farmerGroups.map((group) {
                                      return DropdownMenuItem<String>(
                                        value: group['id'] as String,
                                        child: Text(
                                          '${group['group_name']} (${group['domicile_region']})',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E293B),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(
                                        () => _selectedFarmerGroupId = val,
                                      );
                                    },
                                  ),
                          ],
                        ).animate().fadeIn(duration: 300.ms).slideY(
                              begin: 0.08,
                              end: 0,
                              duration: 300.ms,
                            ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _agreedToTerms,
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                setState(() => _agreedToTerms = val ?? false);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Saya menyetujui Syarat & Ketentuan serta Kebijakan Privasi LapakTani.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isFarmer
                                          ? 'Daftar Sebagai Petani Mitra'
                                          : 'Daftar Sekarang',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      LucideIcons.arrowRight,
                                      size: 18,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sudah punya akun?',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Masuk di Sini',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, String? hint) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        if (hint != null)
          Text(
            hint,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
      ],
    );
  }

  InputDecoration _buildSoftInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixWidget,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 14,
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(prefixIcon, size: 19, color: const Color(0xFF94A3B8)),
      suffixIcon: suffixWidget,
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }
}
