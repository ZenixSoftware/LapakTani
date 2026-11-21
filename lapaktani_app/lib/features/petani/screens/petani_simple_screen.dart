import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:lapaktani_app/core/services/api_service.dart';
import 'package:lapaktani_app/core/services/user_session.dart';
import 'package:lapaktani_app/core/theme/app_colors.dart';
import 'package:lapaktani_app/features/auth/auth_repository.dart';
import 'package:lapaktani_app/features/chat/screens/chat_list_screen.dart';
import 'package:lapaktani_app/features/chat/screens/chat_room_screen.dart';
import 'package:lapaktani_app/features/chat/services/chat_service.dart';
import 'package:lapaktani_app/features/community/screens/create_pest_report_screen.dart';
import 'package:lapaktani_app/features/community/screens/education_feed_screen.dart';
import 'package:lapaktani_app/features/navigation/role_based_app_shell.dart';
import 'package:lapaktani_app/features/penyuluh/models/precision_soil_models.dart';
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

  // Village Advisory & Farmer Daily Logs State
  List<Map<String, dynamic>> _advisories = [];
  List<Map<String, dynamic>> _dailyLogs = [];
  List<Map<String, dynamic>> _harvestReports = [];
  List<Map<String, dynamic>> _purchaseOffers = [];
  List<Map<String, dynamic>> _villageForumPosts = [];
  String? _ackingReportId;
  String? _respondingOfferId;

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
        _apiService
            .getFarmerHarvestReports()
            .catchError((_) => <Map<String, dynamic>>[]),
        _apiService
            .getFarmerPurchaseOffers()
            .catchError((_) => <Map<String, dynamic>>[]),
        _apiService
            .getVillageForumPosts()
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);
      _advisories = extraResults[0];
      _dailyLogs = extraResults[1];
      _harvestReports = extraResults[2];
      _purchaseOffers = extraResults[3];
      _villageForumPosts = extraResults[4];
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openDirectChat({
    String? targetUserId,
    String? targetRole,
    required String title,
  }) async {
    try {
      final conv = await ChatService().openDirectConversation(
        targetUserId: targetUserId,
        targetRole: targetRole,
        title: title,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatRoomScreen(conversation: conv)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka DM: $e'),
          backgroundColor: AppColors.error,
        ),
      );
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
                      color: AppColors.neutral,
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
                  color: AppColors.neutralMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Estimasi Tonase (kg)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral,
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
                  color: AppColors.neutral,
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
                    border: Border.all(color: AppColors.neutralBorder),
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
                  color: AppColors.neutral,
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
                          backgroundColor: AppColors.error,
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
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.neutralMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: AppColors.neutralMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
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
      backgroundColor: AppColors.surfaceCanvas,
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

                    // CARD 0B: Tawaran Beli & Kontrak Panen Offtaker (Transparan)
                    _buildCardPurchaseOffers(),
                    const SizedBox(height: 14),

                    // CARD 0C: Forum Privat Desa & Info Titik Ambil Pupuk
                    _buildCardVillageForumAndFertilizer(),
                    const SizedBox(height: 14),

                    // CARD 0D: Siaran Status Tanam & Estimasi Panen ke Toko Sekitar
                    _buildCardHarvestBroadcast(),
                    const SizedBox(height: 14),

                    // CARD 1: Status Lahan & Prediksi Panen
                    _buildCardLandStatus(),
                    const SizedBox(height: 14),

                    // CARD 2: Tugas Penyerapan Kontrak Poktan
                    _buildCardContractQuota(),
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
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowFaint,
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
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.mapPin, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Status Lahan & Prediksi Panen',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCanvas,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Aktif',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral,
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.neutralMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_landAreaHa Ha',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.neutral,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Komoditas Utama',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.neutralMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _commodity,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
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
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowFaint,
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
                  color: AppColors.secondaryTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.clipboardCheck, size: 18, color: AppColors.secondary),
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
                    color: AppColors.neutral,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_activeTaskCount Tugas',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Target kuota panen yang ditugaskan oleh pengurus kelompok tani untuk memenuhi kontrak pasokan B2B.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.neutralMuted),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceCanvas),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Alokasi Kuota Aktif',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.neutralMuted),
                    ),
                    Text(
                      '${_totalAssignedKg.toStringAsFixed(0)} kg',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.neutral,
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
                  icon: const Icon(LucideIcons.arrowRight, size: 14, color: AppColors.secondary),
                  label: Text(
                    'Lihat Tugas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.secondaryBorder),
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

  Widget _buildCardPestAlertAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.errorTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.alertTriangle, size: 22, color: AppColors.error),
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
                    color: AppColors.error,
                  ),
                ),
                Text(
                  'Temukan bercak daun, ulat grayak, atau wereng? Laporkan segera ke PPL.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.error,
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
              backgroundColor: AppColors.error,
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
    final moistureCtrl = TextEditingController();
    final phCtrl = TextEditingController();
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

  Future<void> _respondOffer(String offerId, String status) async {
    setState(() => _respondingOfferId = offerId);
    try {
      await _apiService.respondToPurchaseOffer(offerId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'ACCEPTED_CONTRACT'
                ? 'Kontrak panen disetujui! Menunggu timbang ulang di lokasi.'
                : 'Tawaran pembelian ditolak.',
          ),
          backgroundColor:
              status == 'ACCEPTED_CONTRACT' ? AppColors.primary : AppColors.warning,
        ),
      );
      await _loadFarmerData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses tawaran: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _respondingOfferId = null);
    }
  }

  void _showHarvestBroadcastModal() {
    String statusTanam = 'HAMPIR_PANEN';
    final komCtrl = TextEditingController(text: 'Bawang Merah Sumenep');
    final beratCtrl = TextEditingController(text: '350');
    final luasCtrl = TextEditingController(text: '0.8');
    final catatanCtrl = TextEditingController();
    bool sending = false;

    showModalBottomSheet<void>(
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
                  'Siaran Tanam & Estimasi Panen',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mulai Tanam, Hampir Panen, dan Siap Panen otomatis disiarkan ke Penyuluh & Admin Toko sekitar.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: statusTanam,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Laporan',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MULAI_TANAM', child: Text('Mulai Tanam')),
                    DropdownMenuItem(value: 'HAMPIR_PANEN', child: Text('Hampir Panen')),
                    DropdownMenuItem(value: 'SIAP_PANEN', child: Text('Siap Panen')),
                    DropdownMenuItem(value: 'LAPOR_HAMA', child: Text('Lapor Hama')),
                    DropdownMenuItem(value: 'MINTA_SARAN', child: Text('Minta Saran PPL')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => statusTanam = v);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: komCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Komoditas',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: beratCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Est. kg',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: luasCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Luas (Ha)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: catatanCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Lapangan',
                    hintText: 'Contoh: Siap dipetik 2 hari lagi, mutu umbi super.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: sending
                        ? null
                        : () async {
                            setModalState(() => sending = true);
                            try {
                              await _apiService.submitFarmerHarvestReport({
                                'komoditas': komCtrl.text.trim(),
                                'status_tanam': statusTanam,
                                'estimasi_berat_kg':
                                    double.tryParse(beratCtrl.text) ?? 100,
                                'luas_lahan_ha':
                                    double.tryParse(luasCtrl.text.trim()) ?? 0.5,
                                'catatan': catatanCtrl.text.trim(),
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Siaran tanam/panen berhasil dikirim!'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                              await _loadFarmerData();
                            } catch (e) {
                              setModalState(() => sending = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      sending ? 'Menyiarkan...' : 'Kirim & Siarkan Sekarang',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
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

  void _showVillageQuestionModal() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    bool sending = false;

    showModalBottomSheet<void>(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kirim Pertanyaan ke Forum Privat Desa',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul / Keluhan Tanaman',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Isi Pertanyaan untuk PPL Desa',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: sending
                      ? null
                      : () async {
                          if (titleCtrl.text.trim().isEmpty ||
                              bodyCtrl.text.trim().isEmpty) {
                            return;
                          }
                          setModalState(() => sending = true);
                          try {
                            await _apiService.createVillageForumPost({
                              'kategori': 'TANYA_JAWAB',
                              'judul': titleCtrl.text.trim(),
                              'isi_pesan': bodyCtrl.text.trim(),
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            await _loadFarmerData();
                          } catch (_) {
                            setModalState(() => sending = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    sending ? 'Mengirim...' : 'Kirim ke Forum Desa',
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

  Widget _buildCardHarvestBroadcast() {
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
              const Icon(LucideIcons.radio, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Siaran Tanam & Estimasi Panen',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _showHarvestBroadcastModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                child: Text(
                  '+ Siarkan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Keanggotaan Resmi: Maks. 1 Poktan ($_poktanName) • Bebas Jual ke Banyak Toko Mitra.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          if (_harvestReports.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._harvestReports.take(3).map((hr) {
              final hrStatus = (hr['status_tanam'] ?? '').toString();
              final bool isSudahPanen = hrStatus == 'SUDAH_PANEN';
              final bool isDeficit =
                  hr['is_deficit'] == true || hr['is_deficit'] == 1;
              final luasHa = hr['luas_lahan_ha'] ?? 0.5;
              final realisasiKg = hr['realisasi_panen_kg'];

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDeficit
                        ? AppColors.accent
                        : isSudahPanen
                            ? AppColors.primary
                            : AppColors.outline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$hrStatus • ${hr['komoditas']} (Est. ${hr['estimasi_berat_kg']} kg • $luasHa Ha)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if ((hr['catatan'] ?? '').toString().trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          hr['catatan'].toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    if (isSudahPanen && realisasiKg != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          isDeficit
                              ? 'Realisasi Panen: $realisasiKg kg (Defisit — Alokasi Pro-Rata Otomatis Aktif)'
                              : 'Realisasi Panen: $realisasiKg kg (Memenuhi seluruh kontrak)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDeficit
                                ? AppColors.warning
                                : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    if (!isSudahPanen && hr['id'] != null) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _showDeclareHarvestedModal(hr),
                          icon: const Icon(LucideIcons.scale, size: 13),
                          label: Text(
                            'Umumkan Sudah Panen (Input Realisasi kg)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  void _showDeclareHarvestedModal(Map<String, dynamic> report) {
    final estKg = report['estimasi_berat_kg']?.toString() ?? '300';
    final realCtrl = TextEditingController(text: estKg);
    final noteCtrl = TextEditingController();
    bool submitting = false;

    showModalBottomSheet<void>(
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
                  'Umumkan Sudah Panen (${report['komoditas']})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jika realisasi panen (kg) lebih kecil dari total kontrak toko, sistem otomatis membagikan kuota secara adil (Pro-Rata).',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: realCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Realisasi Hasil Panen (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Panen (Opsional)',
                    hintText: 'Contoh: Cuaca kemarau menyebabkan susut timbangan 20%',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            final kg = double.tryParse(realCtrl.text.trim()) ?? 0;
                            if (kg <= 0) return;
                            setModalState(() => submitting = true);
                            try {
                              final res = await _apiService.declareFarmerHarvested(
                                report['id'].toString(),
                                realisasiPanenKg: kg,
                                catatan: noteCtrl.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _loadFarmerData();
                              if (!mounted) return;
                              final data = res['data'] is Map
                                  ? Map<String, dynamic>.from(res['data'] as Map)
                                  : <String, dynamic>{};
                              final allocations = data['allocations'] is List
                                  ? List<Map<String, dynamic>>.from(
                                      (data['allocations'] as List).map(
                                        (e) => Map<String, dynamic>.from(e as Map),
                                      ),
                                    )
                                  : <Map<String, dynamic>>[];
                              final bool deficit = data['is_deficit'] == true;
                              await showDialog<void>(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  title: Text(
                                    deficit
                                        ? 'Panen Tercatat · Mode Pro-Rata Aktif'
                                        : 'Panen Tercatat Lengkap',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          res['message']?.toString() ??
                                              'Realisasi panen berhasil diumumkan.',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
                                        ),
                                        if (allocations.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            'Rincian Pembagian Kontrak Offtaker:',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          ...allocations.map((a) {
                                            final pct = ((double.tryParse(
                                                            '${a['share_ratio'] ?? 0}') ??
                                                        0) *
                                                    100)
                                                .toStringAsFixed(1);
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: Text(
                                                '• ${a['store_name'] ?? 'Toko'}: ${a['allocated_pro_rata_kg']} kg (dari ${a['requested_kg']} kg · $pct%)',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primaryDark,
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dCtx),
                                      child: const Text('Tutup'),
                                    ),
                                  ],
                                ),
                              );
                            } catch (e) {
                              setModalState(() => submitting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      submitting ? 'Menghitung...' : 'Simpan Realisasi & Hitung Pro-Rata',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
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

  Widget _buildCardPurchaseOffers() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.badgeDollarSign, size: 18, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tawaran Beli & Kontrak Panen Offtaker',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${_purchaseOffers.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_purchaseOffers.isEmpty)
            Text(
              'Belum ada tawaran pembelian masuk dari Admin Toko sekitar.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            )
          else
            ..._purchaseOffers.take(3).map((offer) {
              final id = offer['id'].toString();
              final status = (offer['status'] ?? 'OFFER_SENT').toString();
              final market = offer['harga_acuan_pasar_per_kg'] ?? 0;
              final trans = offer['biaya_transport_per_kg'] ?? 0;
              final ops = offer['biaya_operasional_lain_per_kg'] ?? 0;
              final net = offer['harga_tawar_bersih_per_kg'] ?? 0;
              final isBusy = _respondingOfferId == id;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${offer['store_name'] ?? 'Toko Mitra'} • ${offer['komoditas']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          status,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Acuan Pasar: Rp $market/kg - Transport: Rp $trans - Ops: Rp $ops => Harga Bersih: Rp $net/kg',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    if (offer['allocated_pro_rata_kg'] != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.surfaceSoftBorder),
                        ),
                        child: Text(
                          'Alokasi Pro-Rata: ${offer['allocated_pro_rata_kg']} kg'
                          '${offer['share_ratio'] != null ? ' (${((double.tryParse('${offer['share_ratio']}') ?? 0) * 100).toStringAsFixed(1)}%)' : ''}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openDirectChat(
                            targetUserId: offer['store_admin_id']?.toString(),
                            targetRole: 'admin',
                            title: 'DM — ${offer['store_name'] ?? 'Admin Toko'}',
                          ),
                          icon: const Icon(LucideIcons.messageSquare, size: 13),
                          label: Text(
                            'DM Toko',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (status == 'OFFER_SENT') ...[
                          TextButton(
                            onPressed: isBusy
                                ? null
                                : () => _respondOffer(id, 'REJECTED'),
                            child: const Text('Tolak'),
                          ),
                          ElevatedButton(
                            onPressed: isBusy
                                ? null
                                : () => _respondOffer(id, 'ACCEPTED_CONTRACT'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            child: Text(
                              isBusy ? 'Menyimpan...' : 'Setuju Kontrak Panen',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCardVillageForumAndFertilizer() {
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
              const Icon(LucideIcons.mapPin, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Forum Privat Desa & Info Pupuk Subsidi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: _showVillageQuestionModal,
                child: Text(
                  '+ Tanya PPL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _openDirectChat(
                  targetRole: 'penyuluh',
                  title: 'Konsultasi Penyuluh BPP Desa',
                ),
                icon: const Icon(LucideIcons.messageSquare, size: 17, color: AppColors.primary),
                tooltip: 'Kirim DM Penyuluh',
              ),
            ],
          ),
          if (_villageForumPosts.isEmpty)
            Text(
              'Belum ada pengumuman titik ambil pupuk atau diskusi desa terbaru.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            )
          else
            ..._villageForumPosts.take(3).map((post) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceSoftBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${post['kategori']} • ${post['judul']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      post['isi_pesan']?.toString() ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (post['titik_ambil_pupuk'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Titik Ambil Pupuk: ${post['titik_ambil_pupuk']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

