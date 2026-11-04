import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/pest_report_model.dart';
import '../services/pest_alert_service.dart';
import 'create_pest_report_screen.dart';

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
          'Serangan hama telah berhasil dikendalikan bersama kelompok tani.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 22),
            const SizedBox(width: 8),
            Text(
              'Tandai Terkendali',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status peringatan darurat akan ditutup dan status laporan diubah menjadi Terkendali.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4B5563)),
            ),
            const SizedBox(height: 12),
            Text(
              'Catatan Penanganan / Evaluasi:',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: noteController,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Tuliskan tindakan yang berhasil menekan serangan...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
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

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Status laporan berhasil diperbarui menjadi Terkendali.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Simpan',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _currentReport;
    final isCritical = report.isActiveEmergency;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Detail Peringatan Hama',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: report.status == 'resolved'
                  ? const Color(0xFFDCFCE7)
                  : report.severityBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: report.status == 'resolved'
                    ? const Color(0xFF86EFAC)
                    : report.severityBorderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  report.status == 'resolved'
                      ? LucideIcons.checkCheck
                      : LucideIcons.alertTriangle,
                  size: 13,
                  color: report.status == 'resolved'
                      ? const Color(0xFF16A34A)
                      : report.severityColor,
                ),
                const SizedBox(width: 4),
                Text(
                  report.status == 'resolved'
                      ? 'Terkendali'
                      : 'Keparahan ${report.severity}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: report.status == 'resolved'
                        ? const Color(0xFF16A34A)
                        : report.severityColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Emergency Banner Bar
            if (isCritical)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFFFEF2F2),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.alertOctagon,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PERINGATAN DARURAT AKTIF',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF991B1B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Pest Alert telah didistribusikan ke seluruh petani Poktan ${report.farmerGroupName}.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Image Preview (if present)
            if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
              Container(
                height: 220,
                width: double.infinity,
                color: const Color(0xFFE2E8F0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      report.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFCBD5E1),
                        child: const Center(
                          child: Icon(
                            LucideIcons.image,
                            size: 48,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.camera, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Foto Bukti Serangan',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title: Pest & Crop
                  Text(
                    report.pestName,
                    style: GoogleFonts.inter(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.sprout, size: 14, color: Color(0xFF059669)),
                      const SizedBox(width: 6),
                      Text(
                        'Tanaman Terdampak: ${report.cropType}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Key Info Cards
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: LucideIcons.mapPin,
                          label: 'Wilayah Poktan',
                          value: '${report.farmerGroupName} (${report.villageName})',
                        ),
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: LucideIcons.maximize2,
                          label: 'Estimasi Area Terdampak',
                          value: report.affectedArea,
                        ),
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: LucideIcons.user,
                          label: 'Pelapor',
                          value: '${report.reporterName} (${report.reporterRole})',
                        ),
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: LucideIcons.clock,
                          label: 'Waktu Pelaporan',
                          value: '${report.formattedDate} (${report.timeAgo})',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description Section
                  Text(
                    'Kondisi & Gejala Serangan',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      report.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF334155),
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Handling Recommendation & SOP Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.shieldAlert,
                              color: Color(0xFF16A34A),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rekomendasi Penanganan Cepat (SOP)',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF166534),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          report.handlingRecommendation != null &&
                                  report.handlingRecommendation!.isNotEmpty
                              ? report.handlingRecommendation!
                              : '1. Isolasi tanaman bergejala dengan pemangkasan daun terdampak.\n2. Lakukan penyemprotan biopestisida / agens hayati pada pagi atau sore hari.\n3. Berkoordinasi dengan petugas PPL setempat untuk verifikasi lapangan.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF14532D),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Menghubungi Posko Penyuluh BPP (${report.villageName})...',
                                ),
                                backgroundColor: const Color(0xFF059669),
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.phoneCall, size: 16),
                          label: Text(
                            'Hubungi PPL',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF059669),
                            side: const BorderSide(color: Color(0xFF059669)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (report.status == 'active')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isResolving ? null : _showResolveDialog,
                            icon: const Icon(LucideIcons.checkCheck, size: 16),
                            label: Text(
                              _isResolving ? 'Menyimpan...' : 'Tandai Selesai',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Button to report similar case in user's farm
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => CreatePestReportScreen(
                              initialPestName: report.pestName,
                              initialCropType: report.cropType,
                              initialPoktanName: report.farmerGroupName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.plusCircle, size: 16, color: Color(0xFF2563EB)),
                      label: Text(
                        'Laporkan Kasus Serupa di Lahanku',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

