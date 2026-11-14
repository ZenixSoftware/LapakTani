import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:lapaktani_app/core/services/api_service.dart';
import 'package:lapaktani_app/core/services/user_session.dart';
import 'package:lapaktani_app/core/theme/app_colors.dart';
import 'package:lapaktani_app/features/auth/auth_repository.dart';
import 'package:lapaktani_app/features/chat/screens/chat_list_screen.dart';
import 'package:lapaktani_app/features/community/screens/create_pest_report_screen.dart';
import 'package:lapaktani_app/features/community/screens/education_feed_screen.dart';
import 'package:lapaktani_app/features/navigation/role_based_app_shell.dart';
import 'package:lapaktani_app/features/penyuluh/models/precision_soil_models.dart';
import 'package:lapaktani_app/features/petani/screens/petani_land_monitoring_screen.dart';
import 'package:lapaktani_app/features/poktan/screens/farmer_tasks_screen.dart';
import 'package:lapaktani_app/features/poktan/services/poktan_service.dart';

class PetaniSimpleScreen extends StatefulWidget {
  const PetaniSimpleScreen({super.key});

  @override
  State<PetaniSimpleScreen> createState() => _PetaniSimpleScreenState();
}

class _PetaniSimpleScreenState extends State<PetaniSimpleScreen> {
  final PoktanService _poktanService = PoktanService();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _poktanName = 'Poktan Tani Makmur';
  int _activeTaskCount = 0;
  double _totalAssignedKg = 0.0;
  final double _landAreaHa = 1.2;
  final String _commodity = 'Cabai Rawit';

  // IoT Telemetry State (US-26)
  double _phLevel = 6.50;
  double _nitrogen = 155.00;
  double _phosphorus = 42.00;
  double _potassium = 220.00;
  double _moisture = 72.00;
  String _fertilityIndex = 'OPTIMAL';

  // Village Advisory & Farmer Daily Logs State
  List<Map<String, dynamic>> _advisories = [];
  List<Map<String, dynamic>> _dailyLogs = [];
  String? _ackingReportId;

  @override
  void initState() {
    super.initState();
    _loadFarmerData();
  }

  Future<void> _loadFarmerData() async {
    setState(() => _isLoading = true);
    try {
      final poktanData = await _poktanService.fetchMembers();
      if (poktanData['poktan_name'] != null) {
        _poktanName = poktanData['poktan_name'] as String;
      }

      final taskData = await _poktanService.fetchMyTasks();
      final tasks = taskData['tasks'] as List<dynamic>? ?? [];
      _activeTaskCount = tasks.length;
      _totalAssignedKg = tasks.fold<double>(0.0, (sum, t) {
        final kg = (t.allocatedKg as num?)?.toDouble() ?? 0.0;
        return sum + kg;
      });

      final currentUser = AuthRepository().currentUser;
      final extraResults = await Future.wait([
        _apiService
            .getDecisionReports(role: 'petani')
            .catchError((_) => <Map<String, dynamic>>[]),
        _apiService
            .getFarmerDailyLogs(userId: currentUser?.id)
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);
      _advisories = extraResults[0];
      _dailyLogs = extraResults[1];

      // Fetch soil telemetry if product available
      try {
        final res = await ApiService.get('/soil/telemetry/prod-tomat-lembang-001');
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['success'] == true && data['data'] != null) {
            final t = data['data'];
            _phLevel = (t['ph_level'] as num?)?.toDouble() ?? _phLevel;
            _nitrogen = (t['nitrogen_mg_kg'] as num?)?.toDouble() ?? _nitrogen;
            _phosphorus = (t['phosphorus_mg_kg'] as num?)?.toDouble() ?? _phosphorus;
            _potassium = (t['potassium_mg_kg'] as num?)?.toDouble() ?? _potassium;
            _moisture = (t['moisture_percentage'] as num?)?.toDouble() ?? _moisture;
            _fertilityIndex = t['fertility_index']?.toString() ?? _fertilityIndex;
          }
        }
      } catch (_) {}
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showReportHarvestPredictionModal() {
    final qtyController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 14));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lapor Prediksi Panen ke Poktan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121C2A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Laporkan estimasi hasil panen ladang Anda agar Ketua Poktan dapat menyerap kuota untuk kontrak B2B.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Estimasi Tonase (kg)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Contoh: 350',
                  suffixText: 'kg',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Perkiraan Tanggal Petik',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      ),
                      const Icon(LucideIcons.calendar, size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Catatan Kondisi Lahan (Opsional)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Contoh: Buah mulai memerah, pupuk organik tahap 2 selesai.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    final qty = double.tryParse(qtyController.text) ?? 0.0;
                    if (qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Masukkan estimasi tonase panen yang valid.'),
                          backgroundColor: Color(0xFFDC2626),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Laporan prediksi panen ($qty kg) berhasil dikirim ke Pengurus $_poktanName.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Kirim Laporan ke Poktan',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Keluar dari Aplikasi',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Petani Anda?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Keluar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await UserSession().clear();
      await AuthRepository().signOut();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleBasedAppShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthRepository().currentUser;
    final farmerName = currentUser?.fullName ?? 'Petani LapakTani';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              farmerName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Petani Anggota • $_poktanName',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.messageSquare, color: Colors.white),
            tooltip: 'Pesan & DM',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.bookOpen, color: Colors.white),
            tooltip: 'Panduan Edukasi PPL',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EducationFeedScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Keluar',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadFarmerData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CARD 0: Arahan & Keputusan Penyuluh Desa
                    _buildCardPenyuluhAdvisories(),
                    const SizedBox(height: 14),

                    // CARD 1: Status Lahan & Prediksi Panen
                    _buildCardLandStatus(),
                    const SizedBox(height: 14),

                    // CARD 2: Tugas Penyerapan Kontrak Poktan
                    _buildCardContractQuota(),
                    const SizedBox(height: 14),

                    // CARD 3: Telemetri Kualitas Tanah IoT (US-26)
                    _buildCardSoilTelemetry(),
                    const SizedBox(height: 14),

                    // CARD 3B: Laporan Harian Kondisi Lahan ke Penyuluh
                    _buildCardDailyLogs(),
                    const SizedBox(height: 14),

                    // CARD 4: Tombol Cepat Lapor Serangan Hama (US-19)
                    _buildCardPestAlertAction(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCardLandStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.mapPin, size: 18, color: Color(0xFF006E04)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Status Lahan & Prediksi Panen',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121C2A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Aktif',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Luas Lahan Terdaftar',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_landAreaHa Ha',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Komoditas Utama',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _commodity,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF006E04),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: _showReportHarvestPredictionModal,
              icon: const Icon(LucideIcons.send, size: 16),
              label: Text(
                'Lapor Perkiraan Panen ke Poktan',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContractQuota() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.clipboardCheck, size: 18, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tugas Penyerapan Kontrak Poktan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF121C2A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_activeTaskCount Tugas',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Target kuota panen yang ditugaskan oleh pengurus kelompok tani untuk memenuhi kontrak pasokan B2B.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Alokasi Kuota Aktif',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                    Text(
                      '${_totalAssignedKg.toStringAsFixed(0)} kg',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FarmerTasksScreen()),
                    );
                  },
                  icon: const Icon(LucideIcons.arrowRight, size: 14, color: Color(0xFF2563EB)),
                  label: Text(
                    'Lihat Tugas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF93C5FD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSoilTelemetry() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.activity, size: 18, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Telemetri Kualitas Tanah IoT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF121C2A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _fertilityIndex,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildTelemetryPill('pH Tanah', '$_phLevel', 'Optimal: 6.0-7.0')),
              const SizedBox(width: 8),
              Expanded(child: _buildTelemetryPill('Kelembaban', '$_moisture%', 'Kadar Lengas')),
              const SizedBox(width: 8),
              Expanded(child: _buildTelemetryPill('Nitrogen (N)', '${_nitrogen.toStringAsFixed(0)} mg/kg', 'NPK Sensor')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTelemetryPill('Fosfor (P)', '${_phosphorus.toStringAsFixed(0)} mg/kg', 'NPK Sensor')),
              const SizedBox(width: 8),
              Expanded(child: _buildTelemetryPill('Kalium (K)', '${_potassium.toStringAsFixed(0)} mg/kg', 'NPK Sensor')),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PetaniLandMonitoringScreen(),
                  ),
                );
              },
              icon: const Icon(LucideIcons.activity, size: 16),
              label: Text(
                'Input Kondisi Lahan & Sensor 8-in-1',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.surfaceSoftBorder),
                backgroundColor: AppColors.surfaceSoft,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryPill(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
          Text(
            sub,
            style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPestAlertAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.alertTriangle, size: 22, color: Color(0xFFDC2626)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lapor Serangan Hama (US-19)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                Text(
                  'Temukan bercak daun, ulat grayak, atau wereng? Laporkan segera ke PPL.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePestReportScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Lapor',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acknowledgeReport(String reportId) async {
    setState(() => _ackingReportId = reportId);
    try {
      await _apiService.acknowledgeDecisionReport(
        reportId,
        status: 'ACKNOWLEDGED',
        notes: 'Sudah diterima & dijadwalkan tindak lanjut lapangan oleh petani.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arahan Penyuluh ditandai sudah ditindaklanjuti!'),
          backgroundColor: AppColors.primary,
        ),
      );
      await _loadFarmerData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui status arahan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _ackingReportId = null);
    }
  }

  void _showDailyLogModal() {
    SumenepVillagePreset selectedVillage = SumenepVillagePreset.presets.last;
    String selectedActivity = 'Pemupukan & Pengapuran';
    String selectedKomoditas = 'Bawang Merah';
    final notesCtrl = TextEditingController();
    final moistureCtrl = TextEditingController(text: _moisture.toStringAsFixed(0));
    final phCtrl = TextEditingController(text: _phLevel.toStringAsFixed(1));
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kirim Laporan Harian ke Penyuluh',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Catat kondisi aktual tanaman, aplikasi Dolomit/NPK, atau kendala air desa.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<SumenepVillagePreset>(
                  initialValue: selectedVillage,
                  decoration: const InputDecoration(
                    labelText: 'Desa / Kecamatan',
                    border: OutlineInputBorder(),
                  ),
                  items: SumenepVillagePreset.presets
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text('Desa ${p.desa} (Kec. ${p.kecamatan})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => selectedVillage = v);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedKomoditas,
                        decoration: const InputDecoration(
                          labelText: 'Komoditas',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Bawang Merah', child: Text('Bawang Merah')),
                          DropdownMenuItem(value: 'Cabai Rawit', child: Text('Cabai Rawit')),
                          DropdownMenuItem(value: 'Padi', child: Text('Padi')),
                          DropdownMenuItem(value: 'Jagung', child: Text('Jagung')),
                          DropdownMenuItem(value: 'Tembakau', child: Text('Tembakau')),
                        ],
                        onChanged: (v) {
                          if (v != null) setModalState(() => selectedKomoditas = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedActivity,
                        decoration: const InputDecoration(
                          labelText: 'Aktivitas',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Pemupukan & Pengapuran',
                            child: Text('Pemupukan/Kapur'),
                          ),
                          DropdownMenuItem(
                            value: 'Irigasi & Pengairan',
                            child: Text('Irigasi/Air'),
                          ),
                          DropdownMenuItem(
                            value: 'Pengamatan OPT/Hama',
                            child: Text('Pantau OPT'),
                          ),
                          DropdownMenuItem(
                            value: 'Persiapan Panen',
                            child: Text('Siap Panen'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setModalState(() => selectedActivity = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'pH Lapangan (Opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: moistureCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Lembab % (Opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Kondisi Lahan',
                    hintText: 'Contoh: Sudah tebar Dolomit 100 kg di petak utara, butuh bantuan pompa.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (notesCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Catatan kondisi lahan wajib diisi.'),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            try {
                              await _apiService.submitFarmerDailyLog({
                                'desa': selectedVillage.desa,
                                'kecamatan': selectedVillage.kecamatan,
                                'komoditas': selectedKomoditas,
                                'activity_type': selectedActivity,
                                'notes': notesCtrl.text.trim(),
                                if (double.tryParse(phCtrl.text.trim()) != null)
                                  'ph': double.parse(phCtrl.text.trim()),
                                if (double.tryParse(moistureCtrl.text.trim()) != null)
                                  'moisture': double.parse(moistureCtrl.text.trim()),
                              });
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Laporan harian terkirim ke Penyuluh Desa!'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                              await _loadFarmerData();
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal mengirim laporan: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.send, size: 16),
                    label: Text(
                      isSubmitting ? 'Mengirim...' : 'Kirim ke Penyuluh BPP',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardPenyuluhAdvisories() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceSoftBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.sprout, size: 17, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Arahan & Keputusan Penyuluh Desa',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceSoftBorder),
                ),
                child: Text(
                  '${_advisories.length} Arahan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_advisories.isEmpty)
            Text(
              'Belum ada arahan resmi terbaru dari Penyuluh BPP untuk desa Anda.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            Column(
              children: _advisories.take(3).map((adv) {
                final id = (adv['id'] ?? '').toString();
                final desa = (adv['desa'] ?? 'Sumenep').toString();
                final komoditas = (adv['komoditas'] ?? 'Tanaman').toString();
                final summary = (adv['decision_summary'] ?? '').toString();
                final actionPlan = (adv['action_plan'] ?? '').toString();
                final status = (adv['status'] ?? 'SENT').toString().toUpperCase();
                final isAcked = status == 'ACKNOWLEDGED';
                final isBusy = _ackingReportId == id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceSoftBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Desa $desa • $komoditas',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isAcked
                                  ? AppColors.surfaceMint
                                  : AppColors.warningSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isAcked ? 'DIKERJAKAN' : 'ARAHAN BARU',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isAcked ? AppColors.primary : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        summary,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (actionPlan.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          actionPlan,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (!isAcked) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: isBusy ? null : () => _acknowledgeReport(id),
                            icon: const Icon(LucideIcons.checkCircle2, size: 14),
                            label: Text(
                              isBusy ? 'Menyimpan...' : 'Tandai Sudah Diterapkan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.surfaceSoftBorder),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCardDailyLogs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.clipboardList,
                  size: 18,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Laporan Harian ke Penyuluh',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _showDailyLogModal,
                icon: const Icon(LucideIcons.plus, size: 15),
                label: Text(
                  'Tulis',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_dailyLogs.isEmpty)
            Text(
              'Belum ada log harian dikirim. Catat progres pengapuran, pengairan, atau pertumbuhan lahan Anda.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            )
          else
            Column(
              children: _dailyLogs.take(2).map((log) {
                final desa = (log['desa'] ?? 'Sumenep').toString();
                final activity = (log['activity_type'] ?? 'Catatan').toString();
                final notes = (log['notes'] ?? '').toString();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Desa $desa • $activity',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notes,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

