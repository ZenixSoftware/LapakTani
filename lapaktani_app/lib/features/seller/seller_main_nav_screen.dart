import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../product/my_products_screen.dart';
import '../poktan/screens/poktan_dashboard_screen.dart';
import '../poktan/screens/farmer_tasks_screen.dart';
import 'seller_dashboard_screen.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(Icons.storefront, color: Color(0xFF006E04), size: 36),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121C2A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fitur $title sedang dalam pengembangan mitra tani.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SellerMainNavScreen extends StatefulWidget {
  final int initialTabIndex;

  const SellerMainNavScreen({
    super.key,
    this.initialTabIndex = 1,
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

  Widget _buildBodyForCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return const PoktanDashboardScreen();
      case 1:
        return const MyProductsScreen();
      case 2:
        return const SellerDashboardScreen();
      case 3:
        return const FarmerTasksScreen(showBackButton: false);
      case 4:
        return const PlaceholderScreen("Profil Khusus Petani");
      default:
        return const MyProductsScreen();
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
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              badgeText,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
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
                icon: Icons.groups_rounded,
                label: 'Poktan',
              ),
              _buildBottomNavItem(
                index: 1,
                icon: Icons.inventory_2,
                label: 'Produk Saya',
              ),
              _buildBottomNavItem(
                index: 2,
                icon: Icons.receipt_long,
                label: 'Pesanan',
                badgeText: '12',
              ),
              _buildBottomNavItem(
                index: 3,
                icon: Icons.task_alt,
                label: 'Tugas Panen',
              ),
              _buildBottomNavItem(
                index: 4,
                icon: Icons.person,
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
      body: _buildBodyForCurrentTab(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
