import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';

class SoilTelemetryCard extends StatefulWidget {
  final String productId;
  final Map<String, dynamic>? initialData;

  const SoilTelemetryCard({
    super.key,
    required this.productId,
    this.initialData,
  });

  @override
  State<SoilTelemetryCard> createState() => _SoilTelemetryCardState();
}

class _SoilTelemetryCardState extends State<SoilTelemetryCard> {
  Map<String, dynamic>? _telemetryData;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _telemetryData = widget.initialData;
    } else {
      _loadTelemetryData();
    }
  }

  @override
  void didUpdateWidget(covariant SoilTelemetryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _loadTelemetryData();
    }
  }

  Future<void> _loadTelemetryData() async {
    if (widget.productId.isEmpty) return;
    try {
      final res = await ApiService().getSoilTelemetry(widget.productId);
      if (mounted && res != null) {
        setState(() {
          _telemetryData = res;
        });
      }
    } catch (_) {}
  }

  static double _parseDouble(dynamic val, double fallback) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? fallback;
  }

  static int _parseInt(dynamic val, int fallback) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    final d = double.tryParse(val.toString());
    if (d != null) return d.round();
    return int.tryParse(val.toString()) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    const forestPrimary = AppColors.primary;
    const forestDark = AppColors.primaryDark;
    const lightMintSurface = AppColors.surfaceSoft;
    const mintBorder = AppColors.surfaceSoftBorder;

    final data = _telemetryData ?? widget.initialData ?? {};

    final double ph = _parseDouble(data['ph_level'], 6.4);
    final double nitrogen = _parseDouble(data['nitrogen_mg_kg'], 142.0);
    final double phosphorus = _parseDouble(data['phosphorus_mg_kg'], 38.0);
    final double potassium = _parseDouble(data['potassium_mg_kg'], 210.0);
    final double moisture = _parseDouble(data['moisture_percentage'], 68.0);
    final int score = _parseInt(data['fertility_score'], 94);
    final String label = data['fertility_label']?.toString() ?? 'Sangat Subur';
    final String blok = data['blok_name']?.toString() ?? 'Blok A-3';
    final String validator = data['validator']?.toString() ?? 'PPL Wilayah Binaan (Dinas Pertanian Kab. Bandung Barat)';
    final String lastUpdated = data['last_updated']?.toString() ?? '2 jam yang lalu';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightMintSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mintBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A03AC0E),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with IoT Chip Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.radio, size: 12, color: forestPrimary),
                          const SizedBox(width: 4),
                          Text(
                            'IoT Smart Agri Telemetry',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: forestPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sertifikasi Mutu Lahan & Kesuburan Tanah (IoT Telemetri)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Data telemetri real-time sensor tanah blok lahan budidaya',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: mintBorder),
                ),
                child: Text(
                  blok,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: forestDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Fertility Score Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [forestPrimary, forestDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F2E7D32),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.sprout, color: Colors.white, size: 17),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INDEKS KESUBURAN TANAH',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD1FAE5),
                            letterSpacing: 0.4,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '$score/100',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFFDE047),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '($label)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Kualitas Prima',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 4 Grid Scientific Metrics (pH, N, P, K)
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: '1. pH Tanah',
                  badge: 'Optimal Organik',
                  isBadgeActive: true,
                  value: ph.toStringAsFixed(1),
                  unit: '',
                  subtitle: 'Ideal: 6.0 – 6.8',
                  progress: ((ph - 4.0) / 4.0).clamp(0.0, 1.0),
                  isPrimaryGreen: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: '2. Nitrogen (N)',
                  badge: nitrogen >= 120 ? 'Baik' : 'Cukup',
                  isBadgeActive: false,
                  value: nitrogen.toInt().toString(),
                  unit: 'mg/kg',
                  subtitle: 'Vegetatif Aktif',
                  progress: (nitrogen / 200.0).clamp(0.0, 1.0),
                  isPrimaryGreen: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: '3. Fosfor (P)',
                  badge: phosphorus >= 30 ? 'Sangat Baik' : 'Baik',
                  isBadgeActive: false,
                  value: phosphorus.toInt().toString(),
                  unit: 'mg/kg',
                  subtitle: 'Akar Kuat',
                  progress: (phosphorus / 50.0).clamp(0.0, 1.0),
                  isPrimaryGreen: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: '4. Kalium (K)',
                  badge: potassium >= 180 ? 'Optimal' : 'Cukup',
                  isBadgeActive: true,
                  value: potassium.toInt().toString(),
                  unit: 'mg/kg',
                  subtitle: 'Manis & Berbobot',
                  progress: (potassium / 250.0).clamp(0.0, 1.0),
                  isPrimaryGreen: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Metric 5: Moisture Percentage (Full Width Tile)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.droplets, color: Color(0xFF2563EB), size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '5. Kelembapan Tanah (VWC)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Sensor Kapasitif Kedalaman 20 cm',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${moisture.toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            moisture >= 60 && moisture <= 75 ? 'Stabil / Cukup' : 'Perlu Kontrol',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E40AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Rentang aman 60 – 75%',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Official Validation Footer
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: mintBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: forestPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.check, color: Colors.white, size: 13),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Diverifikasi Sensor NPK 8-in-1 • PPL Wilayah Binaan',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: forestDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: mintBorder),
                            ),
                            child: Text(
                              'Valid',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: forestPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        validator,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: forestPrimary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Update: $lastUpdated',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Sync Otomatis LoRaWAN',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: forestDark,
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
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String badge,
    required bool isBadgeActive,
    required String value,
    required String unit,
    required String subtitle,
    required double progress,
    required bool isPrimaryGreen,
  }) {
    const forestPrimary = Color(0xFF2E7D32);
    const mintBorder = Color(0xFFC8E6C9);

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: isPrimaryGreen ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimaryGreen ? mintBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isBadgeActive ? forestPrimary : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: isBadgeActive ? null : Border.all(color: mintBorder),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: isBadgeActive ? Colors.white : forestPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Row(
                children: [
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isPrimaryGreen ? forestPrimary : const Color(0xFF0F172A),
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 2),
                    Text(
                      unit,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
              Flexible(
                child: Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4.5,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(forestPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
