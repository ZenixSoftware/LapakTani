import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_soft_card.dart';
import '../../core/widgets/lapaktani_logo.dart';
import '../home/home_screen.dart';

class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                    blurRadius: 80,
                    spreadRadius: 35,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const LapaktaniLogo(
                      width: 56,
                      height: 56,
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(curve: Curves.easeOutBack),
                    const SizedBox(height: 20),
                    CustomSoftCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFEF3C7),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.clock,
                              size: 36,
                              color: Color(0xFFD97706),
                            ),
                          )
                              .animate()
                              .scale(duration: 500.ms, curve: Curves.easeOutBack)
                              .fadeIn(),
                          const SizedBox(height: 20),
                          const Text(
                            'Menunggu Verifikasi',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Dokumen e-KTP dan data kelompok tani Anda telah berhasil dikirim. Tim kurasi LapakTani sedang meninjau berkas untuk menjaga integritas pasar tani terpercaya.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildTimelineStep(
                                  stepNumber: '1',
                                  title: 'Dokumen Dikirim',
                                  subtitle: 'Foto e-KTP dan data kebun tersimpan',
                                  isDone: true,
                                  isLast: false,
                                ),
                                _buildTimelineStep(
                                  stepNumber: '2',
                                  title: 'Pemeriksaan Berkas',
                                  subtitle: 'Proses peninjauan estimasi 1x24 jam kerja',
                                  isCurrent: true,
                                  isLast: false,
                                ),
                                _buildTimelineStep(
                                  stepNumber: '3',
                                  title: 'Akun Petani Aktif',
                                  subtitle: 'Dapat mulai membuka lapak dan menjual hasil panen',
                                  isDone: false,
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  LucideIcons.info,
                                  size: 16,
                                  color: Color(0xFF059669),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Anda tetap dapat menjelajahi etalase dan informasi pasar selama verifikasi diproses.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF065F46),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (context, animation, secondaryAnimation) =>
                                            const HomeScreen(),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration:
                                        const Duration(milliseconds: 350),
                                  ),
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Jelajahi Beranda',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 100.ms)
                        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String stepNumber,
    required String title,
    required String subtitle,
    bool isDone = false,
    bool isCurrent = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppColors.primary
                    : isCurrent
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFE2E8F0),
                border: isCurrent
                    ? Border.all(color: const Color(0xFFF59E0B), width: 1.5)
                    : null,
              ),
              child: Center(
                child: isDone
                    ? const Icon(
                        LucideIcons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : Text(
                        stepNumber,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isCurrent
                              ? const Color(0xFFB45309)
                              : const Color(0xFF64748B),
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: isDone
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isCurrent || isDone ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent || isDone
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
