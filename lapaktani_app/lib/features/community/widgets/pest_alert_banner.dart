import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/pest_report_model.dart';
import '../screens/pest_alert_detail_screen.dart';
import '../services/pest_alert_service.dart';

/// Pest Alert Banner Component (US-19)
/// Styled according to Stitch AI Design Guidelines:
/// - Brand Primary: #2E7D32, Soft Tint: #E8F5E9 / #FFEBEE
/// - Rounded corners: BorderRadius.circular(16)
/// - Subtle elevation/shadows without harsh borders
class PestAlertBanner extends StatefulWidget {
  final String poktanName;
  final VoidCallback? onDismissed;

  const PestAlertBanner({
    super.key,
    this.poktanName = 'Poktan Tani Makmur',
    this.onDismissed,
  });

  @override
  State<PestAlertBanner> createState() => _PestAlertBannerState();
}

class _PestAlertBannerState extends State<PestAlertBanner> {
  PestReportModel? _activeAlert;
  bool _isLoading = true;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadActiveAlert();
  }

  Future<void> _loadActiveAlert() async {
    try {
      final alert = await PestAlertService().getActiveEmergencyAlert(
        poktanName: widget.poktanName,
      );
      if (mounted) {
        setState(() {
          _activeAlert = alert;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _dismiss() {
    if (_activeAlert != null) {
      PestAlertService().dismissBannerAlert(_activeAlert!.id);
    }
    setState(() => _isDismissed = true);
    widget.onDismissed?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isDismissed || _activeAlert == null) {
      return const SizedBox.shrink();
    }

    final alert = _activeAlert!;
    final isCritical = alert.severity.toLowerCase().contains('berat') ||
        alert.emergencyAlert;

    final bgColor = isCritical ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0);
    final primaryAccent = isCritical ? const Color(0xFFC62828) : const Color(0xFFEF6C00);
    final borderColor = isCritical ? const Color(0xFFFFCDD2) : const Color(0xFFFFE0B2);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PestAlertDetailScreen(report: alert),
              ),
            );
            _loadActiveAlert();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCritical ? LucideIcons.alertTriangle : LucideIcons.bug,
                        size: 18,
                        color: primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primaryAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isCritical ? 'PERINGATAN DINI HAMA' : 'LAPORAN HAMA AKTIF',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                alert.timeAgo,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            alert.pestName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 17, color: Color(0xFF94A3B8)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                      onPressed: _dismiss,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Serangan menyerang komoditas ${alert.cropType} seluas ${alert.affectedArea} di ${alert.farmerGroupName} (${alert.villageName}). Waspadai penyebaran di lahan sekitar.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF334155),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.mapPin, size: 12, color: primaryAccent),
                          const SizedBox(width: 4),
                          Text(
                            alert.villageName,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Lihat Penanganan',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryAccent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(LucideIcons.arrowRight, size: 14, color: primaryAccent),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
