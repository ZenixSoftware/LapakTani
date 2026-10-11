import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../auth/auth_repository.dart';
import '../seller/seller_main_nav_screen.dart';
import 'complete_farmer_profile_screen.dart';
import 'profile_repository.dart';
import 'verification_pending_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = _profileRepository.currentUser;
      final localUser = await _apiService.getUser();
      final profile = await _profileRepository.getMyProfile();

      if (mounted) {
        setState(() {
          _userProfile = profile ?? localUser;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get _userRole {
    final role = _userProfile?['role'] ??
        _currentUser?.role ??
        (_userProfile?['role_id'] == 1 ? 'petani' : 'pembeli');
    return role?.toString().toLowerCase() ?? 'pembeli';
  }

  String get _verificationStatus {
    final status = _userProfile?['verification_status'];
    if (status != null && status.toString().isNotEmpty) {
      return status.toString().toLowerCase();
    }
    final isVerified = _userProfile?['is_verified'] == true ||
        _userProfile?['is_verified'] == 1 ||
        _currentUser?.isVerified == true;
    return isVerified ? 'verified' : 'pending';
  }

  String get _displayName {
    final name = _userProfile?['full_name'] ??
        _currentUser?.fullName ??
        _userProfile?['name'] ??
        _userProfile?['email']?.toString().split('@').first;
    return name?.toString() ?? 'Budi Santoso';
  }

  String get _displayEmailOrPhone {
    final phone = _userProfile?['phone'] ?? _userProfile?['nik_number'];
    if (phone != null && phone.toString().isNotEmpty) {
      final str = phone.toString();
      if (str.length >= 8) {
        return '${str.substring(0, 4)} •••• ${str.substring(str.length - 4)}';
      }
      return str;
    }
    final email = _userProfile?['email'] ?? _currentUser?.email;
    return email?.toString() ?? '0812 •••• 7890';
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Keluar dari Akun',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF121C2A),
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari aplikasi LapakTani?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _apiService.clearAuth();
      AuthRepository.setCurrentUser(null);
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        elevation: 0.5,
        title: Text(
          'Akun Pengguna',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF121C2A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.messageCircle, color: Color(0xFF475569), size: 20),
            onPressed: () {},
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.shoppingCart, color: Color(0xFF475569), size: 20),
                onPressed: () {},
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBA1A1A),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings, color: Color(0xFF475569), size: 20),
            onPressed: () {},
          ),
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 14, left: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF03AC0E),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.user, color: Colors.white, size: 17),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF03AC0E),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF03AC0E),
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    _buildProfileHeaderCard(),
                    const SizedBox(height: 14),
                    _buildDynamicSellerHubSection(),
                    const SizedBox(height: 14),
                    _buildWalletStatsCard(),
                    const SizedBox(height: 14),
                    _buildOrdersActivityCard(),
                    const SizedBox(height: 14),
                    _buildWarrantyBanner(),
                    const SizedBox(height: 14),
                    _buildSettingsListCard(),
                    const SizedBox(height: 18),
                    _buildLogoutSection(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
    );
  }

  /// Profile Header Card matching Stitch HTML:
  /// bg-surface-container-lowest rounded-xl p-space-lg shadow-sm flex items-center justify-between
  Widget _buildProfileHeaderCard() {
    final avatarUrl = _userProfile?['avatar_url']?.toString();
    final isVerified = _verificationStatus == 'verified';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8F8EC),
                  border: Border.all(color: const Color(0xFFD1F2D6), width: 1.5),
                  image: avatarUrl != null && avatarUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Center(
                        child: Text(
                          _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'B',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF03AC0E),
                          ),
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isVerified ? const Color(0xFF03AC0E) : const Color(0xFFD97706),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Icon(
                    isVerified ? LucideIcons.check : LucideIcons.clock,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF121C2A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _userRole == 'petani'
                        ? (isVerified ? const Color(0xFFB0F1CB) : const Color(0xFFFEF3C7))
                        : const Color(0xFFB0F1CB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _userRole == 'petani'
                            ? (isVerified ? LucideIcons.checkCircle : LucideIcons.clock)
                            : LucideIcons.sprout,
                        size: 11,
                        color: _userRole == 'petani'
                            ? (isVerified ? const Color(0xFF065F46) : const Color(0xFFB45309))
                            : const Color(0xFF065F46),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _userRole == 'petani'
                            ? (isVerified ? 'Mitra Tani Terdaftar' : 'Mitra Tani (Pending)')
                            : 'Prioritas Panen',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _userRole == 'petani'
                              ? (isVerified ? const Color(0xFF065F46) : const Color(0xFFB45309))
                              : const Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _displayEmailOrPhone,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.edit2, size: 16, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  /// Dynamic Seller Hub section matching the 3 state flows:
  /// CASE 1: Role pembeli -> "Daftar Mitra Tani"
  /// CASE 2: Role petani, status pending -> "Status Pendaftaran: Menunggu Verifikasi"
  /// CASE 3: Role petani, status verified -> "Dasbor Toko Tani" / "Produk Saya"
  Widget _buildDynamicSellerHubSection() {
    final role = _userRole;
    final status = _verificationStatus;

    if (role == 'pembeli') {
      return _buildBuyerEntryCard();
    } else if (role == 'petani' && status != 'verified') {
      return _buildPendingVerificationBanner();
    } else {
      return _buildVerifiedSellerDashboardBanner();
    }
  }

  /// CASE 1: Role pembeli -> "Daftar Mitra Tani"
  Widget _buildBuyerEntryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1F2D6), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0803AC0E),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => const CompleteFarmerProfileScreen(),
              ),
            ).then((_) => _loadProfile());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.store,
                    color: Color(0xFF03AC0E),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Daftar Mitra Tani',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF121C2A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB800),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Gratis',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF121C2A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Jual langsung hasil panen ke konsumen tanpa perantara.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  color: Color(0xFF03AC0E),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// CASE 2: Role petani, status pending -> "Status Pendaftaran: Menunggu Verifikasi"
  Widget _buildPendingVerificationBanner() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08D97706),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => const VerificationPendingScreen(),
              ),
            ).then((_) => _loadProfile());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.clock,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Pendaftaran: Menunggu Verifikasi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF92400E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Berkas NIK & KTP sedang ditinjau penyuluh pertanian wilayah Anda.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFFB45309),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  LucideIcons.chevronRight,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// CASE 3: Role petani, status verified -> "Dasbor Toko Tani" / "Produk Saya"
  Widget _buildVerifiedSellerDashboardBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF084E33), Color(0xFF03AC0E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26084E33),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => const SellerMainNavScreen(),
              ),
            ).then((_) => _loadProfile());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.store,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Mitra Tani Terdaftar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF76FF64),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Ladang Organik Lembang (Aktif)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFFB0F1CB),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (_) => const SellerMainNavScreen(),
                          ),
                        ).then((_) => _loadProfile());
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Kelola Ladang',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF006E04),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              LucideIcons.arrowRight,
                              size: 13,
                              color: Color(0xFF006E04),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Wallet / Stats Card matching Stitch HTML:
  /// 3-column grid/row (LapakPay, Koin Panen, Kupon Saya) with vertical dividers
  Widget _buildWalletStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Column 1: LapakPay
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.wallet, size: 15, color: Color(0xFF03AC0E)),
                    const SizedBox(width: 5),
                    Text(
                      'LapakPay',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121C2A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Rp 250.000',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF121C2A),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '+ Isi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF03AC0E),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('•', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    const SizedBox(width: 4),
                    Text(
                      'Riwayat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: const Color(0xFFE2E8F0),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          // Column 2: Koin Panen
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.coins, size: 15, color: Color(0xFFFFB800)),
                    const SizedBox(width: 5),
                    Text(
                      'Koin Panen',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121C2A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    text: '1.250 ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121C2A),
                    ),
                    children: [
                      TextSpan(
                        text: 'Koin',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tukar Koin',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: const Color(0xFFE2E8F0),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          // Column 3: Kupon Saya
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.ticket, size: 15, color: Color(0xFF03AC0E)),
                    const SizedBox(width: 5),
                    Text(
                      'Kupon Saya',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121C2A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '8',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121C2A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDAD6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Panen Hemat',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFBA1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Pakai Promo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF03AC0E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Orders Activity Card matching Stitch HTML:
  /// Aktivitas Pesanan Panen + 4 order status icon buttons + Wishlist / Ulasan sub-box
  Widget _buildOrdersActivityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aktivitas Pesanan Panen',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121C2A),
                ),
              ),
              InkWell(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'Semua Transaksi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF03AC0E),
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 15, color: Color(0xFF03AC0E)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOrderStatusItem(LucideIcons.clock, 'Menunggu Bayar', '1'),
              _buildOrderStatusItem(LucideIcons.truck, 'Sedang Kirim', '2'),
              _buildOrderStatusItem(LucideIcons.checkCircle2, 'Selesai', null),
              _buildOrderStatusItem(LucideIcons.xCircle, 'Dibatalkan', null),
            ],
          ),
          const SizedBox(height: 14),
          // Sub-box: Wishlist Panen & Ulasan Saya (from Stitch HTML)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.heart, size: 16, color: Color(0xFF03AC0E)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wishlist Panen',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF121C2A),
                              ),
                            ),
                            Text(
                              '14 Komoditas',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.star, size: 16, color: Color(0xFFFFB800)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ulasan Saya',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF121C2A),
                              ),
                            ),
                            Text(
                              '2 Perlu Ditinjau',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF03AC0E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusItem(IconData icon, String label, String? badge) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF475569)),
            ),
            if (badge != null)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBA1A1A),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badge,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121C2A),
          ),
        ),
      ],
    );
  }

  /// Warranty Banner matching Stitch HTML:
  /// bg-secondary-container text-on-secondary-container rounded-xl p-space-md flex items-center gap-space-md
  Widget _buildWarrantyBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFB0F1CB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(LucideIcons.shieldCheck, color: Color(0xFF006E04), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Garansi Segar 100% Ganti Baru',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF002113),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Sayur & buah layu sampai di rumah? Ajukan klaim instan tanpa ribet.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: const Color(0xFF327052),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFF327052)),
        ],
      ),
    );
  }

  /// Settings List matching Stitch HTML (Custom Containers, NO ListTile):
  /// bg-surface-container-lowest rounded-xl shadow-sm overflow-hidden
  Widget _buildSettingsListCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              'Pengaturan & Bantuan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF121C2A),
              ),
            ),
          ),
          _buildCustomMenuItem(
            icon: LucideIcons.mapPin,
            title: 'Alamat Pengiriman',
            subtitle: 'Rumah (Jl. Cikutra No. 42, Bandung) • Utama',
          ),
          const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildCustomMenuItem(
            icon: LucideIcons.creditCard,
            title: 'Rekening Bank & Pembayaran Instan',
            subtitle: 'BCA, Mandiri, QRIS Terhubung',
          ),
          const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildCustomMenuItem(
            icon: LucideIcons.shield,
            title: 'Keamanan Akun & PIN LapakPay',
            subtitle: 'Biometrik & PIN 6 Digit Aktif',
          ),
          const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildCustomMenuItem(
            icon: LucideIcons.headphones,
            title: 'LapakTani Care 24/7',
            subtitle: 'Bantuan pesanan & respon cepat',
            trailingTag: 'CS Siap Bantu',
          ),
          const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildCustomMenuItem(
            icon: LucideIcons.info,
            title: 'Tentang LapakTani',
            subtitle: 'Versi 4.12.0 (Dari Ladang ke Meja)',
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  /// Custom Menu Item without ListTile
  Widget _buildCustomMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailingTag,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF475569)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF121C2A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trailingTag != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8EC),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              trailingTag,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF03AC0E),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _handleLogout,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFFDAD6)),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFBA1A1A)),
            label: Text(
              'Keluar dari Akun',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFBA1A1A),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'LapakTani Indonesia • Menghubungkan Petani Nusantara',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
