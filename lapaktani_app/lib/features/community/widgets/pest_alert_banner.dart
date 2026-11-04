import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/pest_report_model.dart';
import '../screens/pest_alert_detail_screen.dart';
import '../services/pest_alert_service.dart';

/// Pest Alert Banner Component (US-19)
/// Displays an active emergency pest warning at the top of the dashboard.
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

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFEF2F2), // Light Red-50
            Color(0xFFFFF1F2), // Rose-50
            Color(0xFFFFF7ED), // Orange-50
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFCA5A5), // Red-300
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12EF4444),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Header with Emergency Tag & Close Button
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.alertTriangle,
                        color: Colors.white,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'DARURAT PEST ALERT',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alert.timeAgo,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                ),
                InkWell(
                  onTap: _dismiss,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      LucideIcons.x,
                      size: 15,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Info: Pest Name & Affected Crop
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${alert.pestName} • ${alert.cropType}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      size: 11,
                      color: Color(0xFFB91C1C),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        'Wilayah: ${alert.farmerGroupName} (${alert.villageName}) • Luas: ${alert.affectedArea}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: const Color(0xFF7F1D1D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Action Buttons: "Lihat Detail & Penanganan" & "Tutup"
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 28,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => PestAlertDetailScreen(report: alert),
                          ),
                        ).then((_) => _loadActiveAlert());
                      },
                      icon: const Icon(LucideIcons.shieldAlert, size: 12),
                      label: Text(
                        'Lihat Detail & Penanganan',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  height: 28,
                  child: OutlinedButton(
                    onPressed: _dismiss,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

