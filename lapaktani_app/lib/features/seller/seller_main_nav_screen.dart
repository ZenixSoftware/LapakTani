import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'seller_dashboard_screen.dart';

class SellerMainNavScreen extends StatefulWidget {
  final int initialTabIndex;

  const SellerMainNavScreen({
    super.key,
    this.initialTabIndex = 2, // Default active tab is "Pesanan" as specified
  });

  @override
  State<SellerMainNavScreen> createState() => _SellerMainNavScreenState();
}

class _SellerMainNavScreenState extends State<SellerMainNavScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  Widget _buildPlaceholderTab(String title, String subtitle, IconData icon) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF121C2A), size: 22),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF121C2A),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFB0F1CB),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF006E04), size: 36),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121C2A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentIndex = 2; // Switch to Pesanan
                  });
                },
                icon: const Icon(LucideIcons.receipt, size: 16),
                label: Text(
                  'Buka Pesanan & Produk Saya',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF03AC0E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildPlaceholderTab(
          'Beranda Toko Tani',
          'Pantau performa penjualan ladang, grafik pendapatan panen, dan metrik kepuasan pembeli.',
          LucideIcons.store,
        );
      case 1:
        return _buildPlaceholderTab(
          'Katalog Produk Saya',
          'Kelola daftar etalase komoditas, variasi bibit, dan foto dokumentasi kebun mitra.',
          LucideIcons.package,
        );
      case 2:
        return const SellerDashboardScreen();
      case 3:
        return _buildPlaceholderTab(
          'Profil Mitra Petani',
          'Informasi legalitas ladang, rekening bank pencairan LapakPay, dan pengaturan jam operasional toko.',
          LucideIcons.user,
        );
      default:
        return const SellerDashboardScreen();
    }
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    String? badgeText,
  }) {
    final bool isSelected = _currentIndex == index;
    final Color itemColor = isSelected ? const Color(0xFF03AC0E) : const Color(0xFF64748B);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentIndex = index;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      size: 24,
                      color: itemColor,
                    ),
                    if (badgeText != null)
                      Positioned(
                        top: -4,
                        right: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBA1A1A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeText,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: itemColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14084E33),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _buildBottomNavItem(
                index: 0,
                icon: LucideIcons.store,
                label: 'Beranda',
              ),
              _buildBottomNavItem(
                index: 1,
                icon: LucideIcons.package,
                label: 'Produk Saya',
              ),
              _buildBottomNavItem(
                index: 2,
                icon: LucideIcons.receipt,
                label: 'Pesanan',
                badgeText: '12',
              ),
              _buildBottomNavItem(
                index: 3,
                icon: LucideIcons.user,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
