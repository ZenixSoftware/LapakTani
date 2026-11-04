import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum PenyuluhBadgeSize {
  small,
  medium,
  large,
}

class PenyuluhOfficialBadge extends StatelessWidget {
  final PenyuluhBadgeSize size;
  final bool showTooltip;
  final String? bppAffiliation;
  final VoidCallback? onTap;

  const PenyuluhOfficialBadge({
    super.key,
    this.size = PenyuluhBadgeSize.medium,
    this.showTooltip = true,
    this.bppAffiliation,
    this.onTap,
  });

  void _showVerificationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFA5D6A7),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.badgeCheck,
                        color: Color(0xFF15803D),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Identitas Terverifikasi',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Penyuluh Pertanian Resmi',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: LucideIcons.building,
                        label: 'Instansi:',
                        value: bppAffiliation ?? 'Balai Penyuluhan Pertanian (BPP)',
                      ),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildInfoRow(
                        icon: LucideIcons.shieldCheck,
                        label: 'Validasi:',
                        value: 'Kementerian Pertanian RI',
                      ),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildInfoRow(
                        icon: LucideIcons.bookOpen,
                        label: 'Wewenang:',
                        value: 'Materi edukasi & rekomendasi budidaya',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Badge ini menandakan materi edukasi disusun oleh penyuluh pertanian bersertifikasi resmi yang bertugas mendampingi petani.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF475569),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03AC0E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double iconSize;
    final double fontSize;
    final EdgeInsets padding;
    final double borderRadius;

    switch (size) {
      case PenyuluhBadgeSize.small:
        iconSize = 11;
        fontSize = 9.5;
        padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 2);
        borderRadius = 6;
        break;
      case PenyuluhBadgeSize.large:
        iconSize = 16;
        fontSize = 12.5;
        padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
        borderRadius = 10;
        break;
      case PenyuluhBadgeSize.medium:
        iconSize = 13;
        fontSize = 11;
        padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 3);
        borderRadius = 8;
        break;
    }

    final badgeContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: const Color(0xFFA5D6A7),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.badgeCheck,
            color: const Color(0xFF15803D),
            size: iconSize,
          ),
          const SizedBox(width: 4),
          Text(
            bppAffiliation != null
                ? 'Penyuluh Resmi • $bppAffiliation'
                : 'Penyuluh Resmi',
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF14532D),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (showTooltip) {
          _showVerificationDialog(context);
        }
      },
      borderRadius: BorderRadius.circular(borderRadius),
      child: badgeContent,
    );
  }
}

