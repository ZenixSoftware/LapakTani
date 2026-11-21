import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:lapaktani_app/core/services/user_session.dart';
import 'package:lapaktani_app/core/theme/app_colors.dart';
import 'package:lapaktani_app/core/widgets/custom_soft_card.dart';
import 'package:lapaktani_app/features/auth/auth_repository.dart';
import 'package:lapaktani_app/features/chat/screens/chat_list_screen.dart';
import 'package:lapaktani_app/features/navigation/role_based_app_shell.dart';
import 'package:lapaktani_app/features/poktan/models/poktan_member_model.dart';
import 'package:lapaktani_app/features/poktan/screens/mitra_store_catalog_screen.dart';
import 'package:lapaktani_app/features/poktan/screens/poktan_dashboard_screen.dart';
import 'package:lapaktani_app/features/poktan/services/poktan_service.dart';
import 'package:lapaktani_app/features/seller/seller_dashboard_screen.dart';

class PoktanMainShell extends StatefulWidget {
  final int initialIndex;

  const PoktanMainShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<PoktanMainShell> createState() => _PoktanMainShellState();
}

class _PoktanMainShellState extends State<PoktanMainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          SellerDashboardScreen(),
          MitraStoreCatalogScreen(),
          PoktanDashboardScreen(showBackButton: false),
          PoktanProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowFaint,
              offset: Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  label: 'Pesanan',
                  activeIcon: Icons.receipt_long,
                  inactiveIcon: Icons.receipt_long_outlined,
                ),
                _buildNavItem(
                  index: 1,
                  label: 'Etalase Toko',
                  activeIcon: Icons.store,
                  inactiveIcon: Icons.store_outlined,
                ),
                _buildNavItem(
                  index: 2,
                  label: 'Lahan & Pool',
                  activeIcon: Icons.landscape,
                  inactiveIcon: Icons.landscape_outlined,
                ),
                _buildNavItem(
                  index: 3,
                  label: 'Profil Akun',
                  activeIcon: Icons.person,
                  inactiveIcon: Icons.person_outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
  }) {
    final bool isSelected = _currentIndex == index;
    final Color color = isSelected ? AppColors.primary : AppColors.neutralMuted;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                size: 22,
                color: color,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// TAB 2: List of member farmers and their registered farm plots
class PoktanMembersTab extends StatefulWidget {
  const PoktanMembersTab({super.key});

  @override
  State<PoktanMembersTab> createState() => _PoktanMembersTabState();
}

class _PoktanMembersTabState extends State<PoktanMembersTab> {
  final PoktanService _poktanService = PoktanService();
  bool _isLoading = true;
  String _poktanName = 'Poktan Tani Makmur';
  double _totalLandAreaHa = 11.10;
  List<PoktanMemberModel> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final data = await _poktanService.fetchMembers();
    if (!mounted) return;
    setState(() {
      _poktanName = (data['poktan_name'] ?? 'Poktan Tani Makmur').toString();
      _totalLandAreaHa = double.tryParse((data['total_land_area_ha'] ?? '11.10').toString()) ?? 11.10;
      _members = (data['members'] as List<PoktanMemberModel>?) ?? [];
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Keluar dari Akun',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Pengurus Poktan?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.neutralMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: AppColors.neutralMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Keluar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await UserSession().clear();
      await AuthRepository().signOut();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleBasedAppShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: Text(
          'Anggota Mitra Tani / Poktan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.neutral,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.messageSquare, color: AppColors.primary, size: 20),
            tooltip: 'Pesan & DM',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: AppColors.neutralMuted, size: 20),
            tooltip: 'Segarkan',
            onPressed: _loadMembers,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            tooltip: 'Keluar',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadMembers,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                children: [
                  // KPI SUMMARY CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: 10,
                          offset: Offset(0, 4),
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
                              _poktanName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_members.length} Anggota',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Total Konsolidasi Lahan Produktif',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.primaryTint,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_totalLandAreaHa.toStringAsFixed(2)} Hektare',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Daftar Petani & Plot Ladang',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._members.map((member) {
                    final double sharePercent = _totalLandAreaHa > 0
                        ? (member.landAreaHa / _totalLandAreaHa) * 100
                        : 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CustomSoftCard(
                        padding: const EdgeInsets.all(14),
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: member.isChairman
                                  ? AppColors.tertiaryTint
                                  : AppColors.border,
                              child: Icon(
                                member.isChairman ? Icons.star : Icons.person,
                                color: member.isChairman
                                    ? AppColors.tertiaryText
                                    : AppColors.neutralMuted,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          member.fullName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.neutral,
                                          ),
                                        ),
                                      ),
                                      if (member.isChairman) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.tertiaryTint,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Ketua',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.tertiaryText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'NIK: ${member.nikNumber} • ${member.phone}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.neutralMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Jenis Tanah: ${member.soilType}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.neutralMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${member.landAreaHa.toStringAsFixed(2)} ha',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '${sharePercent.toStringAsFixed(1)}% kuota',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.neutralSubtle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

/// TAB 3: Profile details, settings, and prominent LOGOUT button
class PoktanProfileTab extends StatelessWidget {
  const PoktanProfileTab({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Keluar dari Akun',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Pengurus Poktan?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.neutralMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: AppColors.neutralMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Keluar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await UserSession().clear();
      await AuthRepository().signOut();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleBasedAppShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthRepository().currentUser;
    final String name = currentUser?.fullName ?? 'Made Irawan';
    final String email = currentUser?.email ?? 'made.irawan@poktan.lapaktani.id';
    final String phone = currentUser?.phone ?? '081234567890';

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: Text(
          'Profil Pengurus Mitra Tani',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.neutral,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            tooltip: 'Keluar',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PROFILE HEADER CARD
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowFaint,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryTint,
                  child: const Icon(
                    Icons.account_balance,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Ketua Mitra Tani • Terverifikasi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mitra Tani Makmur • Desa Lembang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppColors.neutralMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$email | $phone',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.neutralSubtle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // OPERATIONAL SETTINGS
          Text(
            'Pengaturan & Layanan Mitra',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.neutralMuted,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: LucideIcons.wallet,
            title: 'Dompet & Rekening Pencairan',
            subtitle: 'Rekening Bank BCA terdaftar untuk escrow settlement',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rekening operasional terhubung dengan Bank BCA (Escrow Poktan).'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: LucideIcons.truck,
            title: 'Pengaturan Kurir & Penjemputan',
            subtitle: 'Jadwal armada pick-up panen ke gudang poktan',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Armada kurir terintegrasi untuk pick-up komoditas segar.'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: LucideIcons.helpCircle,
            title: 'Pusat Bantuan & Hubungi PPL',
            subtitle: 'Konsultasi hama, cuaca, dan bimbingan pertanian',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hubungi BPP Lembang untuk pendampingan penyuluh.'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // PROMINENT LOGOUT BUTTON
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _handleLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(
                'Keluar dari Akun Mitra Tani',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceCanvas,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.neutralMuted),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.neutral,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.neutralMuted,
          ),
        ),
        trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.neutralSubtle),
        onTap: onTap,
      ),
    );
  }
}

