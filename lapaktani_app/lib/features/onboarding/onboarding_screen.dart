import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_screen.dart';

class OnboardingSlideData {
  final String category;
  final String title;
  final String description;
  final String imageUrl;
  final String primaryBadge;
  final IconData primaryBadgeIcon;
  final Color primaryBadgeColor;
  final String secondaryBadge;
  final IconData secondaryBadgeIcon;
  final Color secondaryBadgeColor;
  final List<String> chips;

  const OnboardingSlideData({
    required this.category,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.primaryBadge,
    required this.primaryBadgeIcon,
    required this.primaryBadgeColor,
    required this.secondaryBadge,
    required this.secondaryBadgeIcon,
    required this.secondaryBadgeColor,
    required this.chips,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      category: 'TRANSPARANSI HARGA',
      title: 'Harga Jujur & Transparan Langsung Petani',
      description:
          'Tanpa perantara tengkulak. Nikmati harga pasar induk paling adil untuk kebutuhan dapur sehat harian keluarga Anda.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBW22Pc5JP-JFraAafFNFP21vFqOL3HnuotJXCXvlpe3hqLJdME_EyrRwCBXecuAntcH0KDUXrFxyQJ2GLuT6ulc1neogfKP39eyD8QbHtEQUDtuBr23sAW7_J4aKVOkx5yLWxOejfVcFPhtngYcf7qLC5tnOnUO2OgG2-w3S7n1VR0CJM5QS8Qc73laB6gQywNh5BSI2gmauN4IQsBmioaCEGcEQYHPFMHzKksUOqCWcvlDugMygq5',
      primaryBadge: 'Harga Petani Jujur',
      primaryBadgeIcon: LucideIcons.tag,
      primaryBadgeColor: AppColors.primary,
      secondaryBadge: 'Hemat s/d 40%',
      secondaryBadgeIcon: LucideIcons.trendingDown,
      secondaryBadgeColor: Color(0xFF16A34A),
      chips: ['100% Panen Lokal', 'Grade A Pilihan', 'Rantai Pasok Singkat'],
    ),
    OnboardingSlideData(
      category: 'PENGIRIMAN DINGIN',
      title: 'Pengiriman Kilat Langsung ke Pintu',
      description:
          'Panen pagi hari langsung diantar cepat dengan armada pendingin khusus demi menjaga kesegaran maksimal sampai di meja Anda.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDWJdQ052JOxGbNEEE0RHW1wg5i9HWybt2k5ROuEHVRa3eK5wyb8niTEW0_op8VS68PgJijfxxbMrJxcvgn3jPPcPlJKiZ0C-czLe3UQND_JLHIgyhPw2Yi0YKTb7Kh0P_mR6JHr_01D9c_lllgw2g5eHDejs1ieo7MIcArHWgAxlPyXCVnNLFdJW7pipmXy7bNAHEKkeaBurb7TPvE3Kb4QBT0PJxgWLinvekxoKIaDMx_NPIViQHr',
      primaryBadge: 'Express 2 Jam',
      primaryBadgeIcon: LucideIcons.zap,
      primaryBadgeColor: Color(0xFFD97706),
      secondaryBadge: 'Gratis Ongkir Rp0',
      secondaryBadgeIcon: LucideIcons.truck,
      secondaryBadgeColor: AppColors.primary,
      chips: ['Armada Pendingin', '100% Segar Terjaga', 'Pantau Langsung'],
    ),
    OnboardingSlideData(
      category: 'STANDAR ORGANIK',
      title: 'Kualitas Terjamin Bebas Bahan Kimia',
      description:
          'Setiap helai sayur dan buah dipetik dari mitra petani terpercaya yang menerapkan standar budidaya bersih dan sehat.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDTZHzHQg90yIFTc9OoqP5N86g3XzPtUAJfC7cSiOdv-boj6tRZxdyjM2nMF_STBHTjFm-7yOq4wKa9yLOBgskjL6ZKRttJ4nNuCdWOftctW625-RrIOErBRCmG-FEtJetkCV_eWjRcWIgRzU9DUfWr156I0HWyX2ExEGLJjp4MzrMROotnW0E8YD2EfX3MyeW23HLI-PtwY_17Ji6C1V-4fIyS31Z3B9IbIP8MOpD9mJF_AfttfHej',
      primaryBadge: 'Organik Bebas Kimia',
      primaryBadgeIcon: LucideIcons.shieldCheck,
      primaryBadgeColor: AppColors.primary,
      secondaryBadge: 'Petani Mitra 4.9 ★',
      secondaryBadgeIcon: LucideIcons.star,
      secondaryBadgeColor: Color(0xFFD97706),
      chips: ['Garansi Ganti Baru', '100% Panen Lokal', 'Petani Terverifikasi'],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateToAuth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSlide = _slides[_currentPage];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.sprout,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'lapak',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                                letterSpacing: -0.4,
                              ),
                            ),
                            TextSpan(
                              text: 'tani',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _navigateToAuth,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      foregroundColor: const Color(0xFF4B5563),
                    ),
                    child: const Text(
                      'Lewati',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildIllustrationArea(_slides[index]);
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activeSlide.category,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 136,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeSlide.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            height: 1.25,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          activeSlide.description,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF4B5563),
                            height: 1.45,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                        .animate(key: ValueKey(_currentPage))
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: const Duration(milliseconds: 400),
                        )
                        .fadeIn(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _slides.length,
                        effect: const ExpandingDotsEffect(
                          activeDotColor: AppColors.primary,
                          dotColor: Color(0xFFE5E7EB),
                          dotHeight: 8,
                          dotWidth: 8,
                          expansionFactor: 3.5,
                          spacing: 6,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage == _slides.length - 1
                                  ? 'Mulai Belanja'
                                  : 'Lanjut',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == _slides.length - 1
                                  ? LucideIcons.shoppingBag
                                  : LucideIcons.arrowRight,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustrationArea(OnboardingSlideData slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                slide.imageUrl,
                height: 220,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildFallbackGraphic(slide);
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackGraphic(slide);
                },
              ),
            ),
          ),
          Positioned(
            top: 24,
            left: 8,
            child: _buildBadgePill(
              icon: slide.primaryBadgeIcon,
              label: slide.primaryBadge,
              accentColor: slide.primaryBadgeColor,
            ),
          ),
          Positioned(
            top: 48,
            right: 8,
            child: _buildBadgePill(
              icon: slide.secondaryBadgeIcon,
              label: slide.secondaryBadge,
              accentColor: slide.secondaryBadgeColor,
            ),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: slide.chips.map((chipText) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      chipText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgePill({
    required IconData icon,
    required String label,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF3F4F6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: accentColor),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackGraphic(OnboardingSlideData slide) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              slide.primaryBadgeIcon,
              size: 54,
              color: slide.primaryBadgeColor,
            ),
            const SizedBox(height: 10),
            Text(
              slide.chips.first,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
