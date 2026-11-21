import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/pest_report_model.dart';
import '../services/pest_alert_service.dart';
import 'create_pest_report_screen.dart';
import 'package:lapaktani_app/core/theme/app_colors.dart';

/// Pest Alert Detail Screen (US-19)
/// Styled according to Stitch AI Design Guidelines:
/// - Brand Primary: #2E7D32, Soft Tint: #E8F5E9 / #FFEBEE
/// - Rounded corners: BorderRadius.circular(16)
/// - Subtle elevation/shadows (Colors.black.withOpacity(0.04))
class PestAlertDetailScreen extends StatefulWidget {
  final PestReportModel report;

  const PestAlertDetailScreen({
    super.key,
    required this.report,
  });

  @override
  State<PestAlertDetailScreen> createState() => _PestAlertDetailScreenState();
}

class _PestAlertDetailScreenState extends State<PestAlertDetailScreen> {
  late PestReportModel _currentReport;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;
  }

  void _showResolveDialog() {
    final noteController = TextEditingController(
      text: _currentReport.handlingRecommendation ??
          'Serangan hama telah berhasil dikendalikan bersama kelompok tani dan PPL.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Tandai Terkendali',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.neutral,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status peringatan dini darurat akan ditutup dan status laporan diubah menjadi Terkendali.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.neutralMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Catatan Penanganan / Evaluasi:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: noteController,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.neutral),
              decoration: InputDecoration(
                hintText: 'Tuliskan tindakan yang berhasil menekan serangan...',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.neutralSubtle),
                filled: true,
                fillColor: AppColors.surfaceCanvas,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: AppColors.neutralMuted, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isResolving = true);
              final success = await PestAlertService().resolvePestAlert(
                _currentReport.id,
                resolutionNote: noteController.text.trim(),
              );
              setState(() {
                _isResolving = false;
                if (success) {
                  _currentReport = PestReportModel(
                    id: _currentReport.id,
                    reporterId: _currentReport.reporterId,
                    reporterName: _currentReport.reporterName,
                    reporterRole: _currentReport.reporterRole,
                    pestName: _currentReport.pestName,
                    cropType: _currentReport.cropType,
                    severity: _currentReport.severity,
                    affectedArea: _currentReport.affectedArea,
                    farmerGroupId: _currentReport.farmerGroupId,
                    farmerGroupName: _currentReport.farmerGroupName,
                    villageId: _currentReport.villageId,
                    villageName: _currentReport.villageName,
                    imageUrl: _currentReport.imageUrl,
                    description: _currentReport.description,
                    handlingRecommendation: noteController.text.trim(),
                    emergencyAlert: false,
                    status: 'resolved',
                    createdAt: _currentReport.createdAt,
                  );
                }
              });

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Laporan berhasil ditandai sebagai Terkendali di database.'
                        : 'Gagal memperbarui status laporan.',
                  ),
                  backgroundColor: success ? AppColors.primary : AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              'Tandai Terkendali',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _currentReport;
    final isCritical = report.severity.toLowerCase().contains('berat') ||
        report.emergencyAlert;

    final badgeBg = report.severityBackgroundColor;
    final badgeText = report.severityColor;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          'Detail Peringatan Hama',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.neutral,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.neutral, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Header Card with Image & Severity Badge
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      report.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.surfaceCanvas,
                        child: const Center(
                          child: Icon(LucideIcons.image, size: 40, color: AppColors.neutralSubtle),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isCritical ? LucideIcons.alertTriangle : LucideIcons.bug,
                                    size: 14,
                                    color: badgeText,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      'Tingkat: ${report.severity}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: badgeText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: report.status == 'resolved'
                                  ? AppColors.primaryTint
                                  : AppColors.tertiaryTint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              report.status == 'resolved' ? 'Terkendali' : 'Aktif',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: report.status == 'resolved'
                                    ? AppColors.primary
                                    : AppColors.tertiaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        report.pestName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.neutral,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dilaporkan pada ${report.formattedDate} (${report.timeAgo})',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.neutralMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Key Attributes Grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildAttributeRow(
                  icon: LucideIcons.sprout,
                  label: 'Komoditas Terdampak',
                  value: report.cropType,
                ),
                const Divider(height: 20, color: AppColors.surfaceCanvas),
                _buildAttributeRow(
                  icon: LucideIcons.maximize2,
                  label: 'Luas Area Serangan',
                  value: report.affectedArea,
                ),
                const Divider(height: 20, color: AppColors.surfaceCanvas),
                _buildAttributeRow(
                  icon: LucideIcons.users,
                  label: 'Kelompok Tani (Poktan)',
                  value: report.farmerGroupName,
                ),
                const Divider(height: 20, color: AppColors.surfaceCanvas),
                _buildAttributeRow(
                  icon: LucideIcons.mapPin,
                  label: 'Wilayah / Desa',
                  value: report.villageName,
                ),
                const Divider(height: 20, color: AppColors.surfaceCanvas),
                _buildAttributeRow(
                  icon: LucideIcons.userCheck,
                  label: 'Pelapor',
                  value: '${report.reporterName} (${report.reporterRole})',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Description Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deskripsi Gejala & Kondisi Lapangan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  report.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.neutral,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Handling Recommendation Section (Stitch AI Agri Green Accent)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.shieldAlert, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Rekomendasi Penanganan PPL',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  report.handlingRecommendation != null &&
                          report.handlingRecommendation!.isNotEmpty
                      ? report.handlingRecommendation!
                      : 'Belum ada rekomendasi tertulis dari Penyuluh. Lakukan isolasi area tanaman yang bergejala dan hubungi BPP terdekat.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.primary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          if (report.status != 'resolved') ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isResolving ? null : _showResolveDialog,
                icon: const Icon(LucideIcons.checkCircle2, size: 18),
                label: Text(
                  'Tandai Serangan Terkendali',
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePestReportScreen(
                      initialPestName: report.pestName,
                      initialCropType: report.cropType,
                      initialPoktanName: report.farmerGroupName,
                    ),
                  ),
                );
              },
              icon: const Icon(LucideIcons.plusCircle, size: 18, color: AppColors.primary),
              label: Text(
                'Laporkan Serangan Serupa',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAttributeRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: AppColors.neutralMuted),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.neutralMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral,
            ),
          ),
        ),
      ],
    );
  }
}
