import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:lapaktani_app/core/services/api_service.dart';
import 'package:lapaktani_app/core/services/user_session.dart';
import 'package:lapaktani_app/core/theme/app_colors.dart';
import 'package:lapaktani_app/features/auth/auth_repository.dart';
import 'package:lapaktani_app/features/auth/login_screen.dart';
import 'package:lapaktani_app/features/chat/screens/chat_list_screen.dart';
import 'package:lapaktani_app/features/chat/screens/chat_room_screen.dart';
import 'package:lapaktani_app/features/chat/services/chat_service.dart';
import 'package:lapaktani_app/features/community/models/pest_report_model.dart';
import 'package:lapaktani_app/features/community/screens/create_education_post_screen.dart';
import 'package:lapaktani_app/features/community/screens/education_feed_screen.dart';
import 'package:lapaktani_app/features/community/screens/pest_alert_detail_screen.dart';
import 'package:lapaktani_app/features/community/services/pest_alert_service.dart';
import 'package:lapaktani_app/features/community/widgets/penyuluh_official_badge.dart';
import 'package:lapaktani_app/features/penyuluh/screens/ppl_soil_checkup_screen.dart';

class PenyuluhHubScreen extends StatefulWidget {
  const PenyuluhHubScreen({super.key});

  @override
  State<PenyuluhHubScreen> createState() => _PenyuluhHubScreenState();
}

class _PenyuluhHubScreenState extends State<PenyuluhHubScreen> {
  final PestAlertService _pestAlertService = PestAlertService();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<PestReportModel> _pestReports = [];
  List<Map<String, dynamic>> _pendingFarmers = [];
  List<Map<String, dynamic>> _storeApps = [];
  List<Map<String, dynamic>> _villageQuotas = [];
  List<Map<String, dynamic>> _villageForumPosts = [];
  List<Map<String, dynamic>> _interPplPosts = [];
  final int _selectedForumVillageId = 109;
  String? _verifyingFarmerId;
  String? _busyStoreId;
  int _pendingVerificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPenyuluhData();
  }

  Future<void> _loadPenyuluhData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _pestAlertService.getPestReports(),
        _apiService.getPendingFarmers().catchError((_) => <Map<String, dynamic>>[]),
        _apiService
            .getStoreApplicationsForPpl()
            .catchError((_) => <String, dynamic>{}),
        _apiService
            .getVillageForumPosts(villageId: _selectedForumVillageId)
            .catchError((_) => <Map<String, dynamic>>[]),
        _apiService
            .getInterPplForumPosts()
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);
      final reports = results[0] as List<PestReportModel>;
      final pending = results[1] as List<Map<String, dynamic>>;
      final storeRes = results[2] as Map<String, dynamic>;
      final vPosts = results[3] as List<Map<String, dynamic>>;
      final pplPosts = results[4] as List<Map<String, dynamic>>;

      final rawApps = storeRes['data'] is List
          ? (storeRes['data'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      final rawQuotas = storeRes['villages'] is List
          ? (storeRes['villages'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _pestReports = reports;
        _pendingFarmers = pending;
        _storeApps = rawApps;
        _villageQuotas = rawQuotas;
        _villageForumPosts = vPosts;
        _interPplPosts = pplPosts;
        _pendingVerificationCount = reports
            .where((r) => r.isEmergency && r.actionTaken == null)
            .length;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyFarmer(String farmerId, String fullName, String status) async {
    setState(() => _verifyingFarmerId = farmerId);
    try {
      await _apiService.verifyFarmerAccount(
        farmerId,
        status: status,
        notes: status == 'verified'
            ? 'Diverifikasi melalui Aplikasi LapakTani Penyuluh BPP'
            : 'Perlu kelengkapan ulang data NIK/Poktan',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'verified'
                ? 'Akun petani $fullName berhasil disetujui!'
                : 'Permohonan $fullName ditolak.',
          ),
          backgroundColor:
              status == 'verified' ? AppColors.primary : AppColors.warning,
        ),
      );
      await _loadPenyuluhData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses verifikasi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _verifyingFarmerId = null);
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
          content: Text('Gagal membuka ruang DM: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Keluar dari Aplikasi',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Apakah Anda ingin keluar dari akun Penyuluh Pertanian Lapangan (PPL)?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await UserSession().clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthRepository().currentUser;
    final penyuluhName = currentUser?.fullName ?? 'Ir. Ahmad Hidayat';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              penyuluhName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Penyuluh Pertanian Lapangan (PPL) BPP Sumenep',
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
            tooltip: 'Pesan & Konsultasi DM',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: Colors.white),
            tooltip: 'Keluar',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadPenyuluhData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // CARD 1: Profil PPL & Official Verification Badge (US-18)
                    _buildPplOfficialCard(),
                    const SizedBox(height: 16),

                    // PORTAL WEB GIS: Eksklusif di Browser (ppl-lapaktani.velosixraptor.my.id)
                    _buildWebGisPortalCard(),
                    const SizedBox(height: 12),

                    // CARD PROBE 8-IN-1: Uji Sampel Tanah Presisi Sumenep
                    _buildPrecisionSoilCheckupCard(),
                    const SizedBox(height: 14),

                    // CARD AI RAG: Penyelesaian Masalah Desa -> Dinas & Petani
                    _buildAiRagQuickDispatchCard(),
                    const SizedBox(height: 16),

                    // CARD US-06: Validasi Calon Petani Mitra Tani
                    _buildFarmerVerificationSection(),
                    const SizedBox(height: 16),

                    // CARD: ACC Pembukaan Toko & Toggle Kuota Toko Desa
                    _buildStoreApprovalAndQuotaSection(),
                    const SizedBox(height: 16),

                    // CARD: Forum Privat Desa & Pengumuman Pupuk Subsidi
                    _buildVillageForumSection(),
                    const SizedBox(height: 16),

                    // CARD: Forum Khusus Antar-Penyuluh Lintas Desa
                    _buildInterPplForumSection(),
                    const SizedBox(height: 16),

                    // CARD 2: Quick Action Hub (Publish Edukasi & Buka Feed)
                    _buildEducationPublishSection(),
                    const SizedBox(height: 16),

                    // CARD 3: Early Warning & Validasi Laporan Hama (US-19)
                    _buildPestValidationSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPplOfficialCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.infoSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.shieldCheck,
                  color: AppColors.info,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PenyuluhOfficialBadge(),
                    const SizedBox(height: 4),
                    Text(
                      'NIP: 19820315 200801 1 003 • BPP Lembang',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Text(
            'Sebagai PPL resmi berlisensi dinas pertanian, panduan budidaya yang Anda publikasikan otomatis membawa lencana terverifikasi untuk menjamin akurasi teknis bagi petani.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebGisPortalCard() {
    const portalUrl = 'https://ppl-lapaktani.velosixraptor.my.id';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceSoftBorder),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.globe,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Peta GIS & AI RAG Eksklusif di Web',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warningSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'WEB ONLY',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Analisis spasial GIS, AI Decision Support (RAG) & eskalasi Dinas Pertanian Kab. Sumenep tersedia di Portal Web PPL.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceSoftBorder),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.link2, size: 15, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    portalUrl,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: portalUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tautan Portal Web GIS berhasil disalin.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.copy, size: 14),
                  label: Text(
                    'Salin URL',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openDirectChat(
                targetRole: 'dinas',
                title: 'Koordinasi Dinas Pertanian Sumenep',
              ),
              icon: const Icon(LucideIcons.messageSquare, size: 15),
              label: Text(
                'DM Langsung ke Dinas Pertanian',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                side: const BorderSide(color: AppColors.surfaceSoftBorder),
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiRagQuickDispatchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: AppColors.tertiaryText,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI RAG Penyelesaian Masalah Desa',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Sintesis solusi agronomis dari sensor 8-in-1, OPT, & log petani.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _showAiRagDispatchModal,
              icon: const Icon(LucideIcons.send, size: 16),
              label: Text(
                'Buat & Kirim ke Dinas + Petani Desa',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAiRagDispatchModal() {
    String selectedDesa = 'Dungkek';
    int selectedVillageId = 109;
    final komCtrl = TextEditingController(text: 'Bawang Merah');
    final promptCtrl = TextEditingController(
      text: 'Atasi pH asam, salinitas pesisir, dan kebutuhan pupuk subsidi desa.',
    );
    final summaryCtrl = TextEditingController();
    final actionCtrl = TextEditingController();
    bool synthesizing = false;
    bool dispatching = false;

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
                  'AI RAG Keputusan Agronomi (Dual-Target)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedVillageId,
                        decoration: const InputDecoration(
                          labelText: 'Desa Terdampak',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 109, child: Text('Desa Dungkek')),
                          DropdownMenuItem(value: 101, child: Text('Desa Mandala')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() {
                              selectedVillageId = v;
                              selectedDesa = v == 101 ? 'Mandala' : 'Dungkek';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: komCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Komoditas',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: promptCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Fokus Masalah Lapangan',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: synthesizing
                        ? null
                        : () async {
                            setModalState(() => synthesizing = true);
                            try {
                              final res = await _apiService.generatePenyuluhRagDecision({
                                'desa': selectedDesa,
                                'komoditas': komCtrl.text.trim(),
                                'query_prompt': promptCtrl.text.trim(),
                              });
                              final data = res['data'] is Map
                                  ? Map<String, dynamic>.from(res['data'] as Map)
                                  : res;
                              setModalState(() {
                                summaryCtrl.text =
                                    (data['decision_summary'] ?? '').toString();
                                actionCtrl.text =
                                    (data['action_plan'] ?? '').toString();
                                synthesizing = false;
                              });
                            } catch (e) {
                              setModalState(() => synthesizing = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal sintesis RAG: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    icon: const Icon(LucideIcons.sparkles, size: 15),
                    label: Text(
                      synthesizing
                          ? 'Menyintesis RAG...'
                          : 'Sintesis Solusi RAG Otomatis',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: summaryCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Ringkasan Keputusan',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: actionCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Rencana Aksi Petani & Eskalasi Dinas',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: dispatching
                        ? null
                        : () async {
                            if (summaryCtrl.text.trim().isEmpty ||
                                actionCtrl.text.trim().isEmpty) {
                              return;
                            }
                            setModalState(() => dispatching = true);
                            try {
                              await _apiService.dispatchPenyuluhRagDecision({
                                'village_id': selectedVillageId,
                                'desa': selectedDesa,
                                'kecamatan':
                                    selectedVillageId == 101 ? 'Gapura' : 'Dungkek',
                                'komoditas': komCtrl.text.trim(),
                                'decision_summary': summaryCtrl.text.trim(),
                                'action_plan': actionCtrl.text.trim(),
                                'target_scope': 'BOTH',
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Keputusan RAG Desa $selectedDesa terkirim ke Dinas & Forum/DM Petani!',
                                  ),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                              await _loadPenyuluhData();
                            } catch (e) {
                              setModalState(() => dispatching = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal mengirim RAG: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    icon: const Icon(LucideIcons.send, size: 15),
                    label: Text(
                      dispatching
                          ? 'Mengirim...'
                          : 'Kirim ke Dinas & Petani Desa Terdampak',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
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

  Widget _buildFarmerVerificationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.userCheck,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Validasi Calon Petani Mitra Tani',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _pendingFarmers.isEmpty
                      ? AppColors.surfaceSoft
                      : AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_pendingFarmers.length} Antrian',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _pendingFarmers.isEmpty
                        ? AppColors.primary
                        : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tinjau pengajuan petani baru dan setujui status keanggotaan Poktan (US-06).',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          if (_pendingFarmers.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Seluruh permohonan pendaftaran petani telah diproses.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            Column(
              children: _pendingFarmers.take(4).map((farmer) {
                final farmerId =
                    (farmer['user_id'] ?? farmer['id'] ?? '').toString();
                final name = (farmer['full_name'] ?? farmer['name'] ?? 'Calon Petani')
                    .toString();
                final poktan = (farmer['poktan'] ?? 'Poktan Binaan').toString();
                final village = (farmer['village'] ?? 'Sumenep').toString();
                final isBusy = _verifyingFarmerId == farmerId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$poktan • $village',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _verifyFarmer(
                                        farmerId,
                                        name,
                                        'rejected',
                                      ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.errorBorder),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: Text(
                                'Tolak',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _verifyFarmer(
                                        farmerId,
                                        name,
                                        'verified',
                                      ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: Text(
                                isBusy ? 'Memproses...' : 'Setujui',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildPrecisionSoilCheckupCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PplSoilCheckupScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceSoftBorder),
                  ),
                  child: const Icon(
                    LucideIcons.flaskConical,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Uji Sampel Tanah Presisi 8-in-1',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMint,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Sumenep',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Alur 3 tahap PPL: baseline komoditas, probe NPK/EC/pH + 3 foto, dan rekomendasi remediasi.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEducationPublishSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.graduationCap,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Pusat Edukasi Pertanian (US-18)',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EducationFeedScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'Feed Edukasi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Publikasikan panduan teknis pengendalian OPT, pemupukan berimbang, dan penanganan pasca-panen.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateEducationPostScreen(),
                  ),
                );
              },
              icon: const Icon(LucideIcons.plusCircle, size: 16),
              label: Text(
                'Tulis Panduan Edukasi Baru (Badge PPL)',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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

  Widget _buildPestValidationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.errorSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.alertOctagon,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Validasi Serangan Hama (US-19)',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _pendingVerificationCount > 0
                      ? AppColors.errorSoft
                      : AppColors.surfaceMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_pendingVerificationCount Perlu Tindakan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _pendingVerificationCount > 0
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Laporan masuk dari petani desa. Lakukan verifikasi lapangan dan tetapkan status peringatan dini desa.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          if (_pestReports.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Tidak ada laporan serangan hama aktif saat ini.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pestReports.take(5).length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final report = _pestReports[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PestAlertDetailScreen(report: report),
                      ),
                    ).then((_) => _loadPenyuluhData());
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          report.isEmergency
                              ? LucideIcons.alertTriangle
                              : LucideIcons.bug,
                          size: 18,
                          color: report.isEmergency
                              ? AppColors.error
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${report.pestName} • ${report.cropCommodity}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${report.villageName} • Dilaporkan oleh ${report.farmerName}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _verifyStoreApp(String id, String storeName, String status) async {
    setState(() => _busyStoreId = id);
    try {
      await _apiService.verifyStoreApplicationByPpl(
        id,
        status,
        reason: status == 'REJECTED' ? 'Lengkapi syarat toko desa.' : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'APPROVED'
                ? 'Toko $storeName disetujui menjadi Admin Toko!'
                : 'Pengajuan toko $storeName ditolak.',
          ),
          backgroundColor:
              status == 'APPROVED' ? AppColors.primary : AppColors.warning,
        ),
      );
      await _loadPenyuluhData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memverifikasi toko: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyStoreId = null);
    }
  }

  void _showVillageQuotaDialog() {
    int selectedId = _selectedForumVillageId;
    final found = _villageQuotas.firstWhere(
      (v) => int.tryParse('${v['id']}') == selectedId,
      orElse: () => <String, dynamic>{
        'id': selectedId,
        'is_store_quota_enabled': true,
        'max_stores_quota': 3,
      },
    );
    bool quotaOn = found['is_store_quota_enabled'] == true ||
        found['is_store_quota_enabled'] == 1;
    final maxCtrl = TextEditingController(
      text: '${found['max_stores_quota'] ?? 3}',
    );
    bool saving = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Pengaturan Kuota Toko Desa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_villageQuotas.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: selectedId,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Desa Binaan',
                    border: OutlineInputBorder(),
                  ),
                  items: _villageQuotas.map((v) {
                    final id = int.tryParse('${v['id']}') ?? 109;
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text('Desa ${v['name']}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDlgState(() {
                        selectedId = val;
                        final match = _villageQuotas.firstWhere(
                          (x) => int.tryParse('${x['id']}') == val,
                          orElse: () => found,
                        );
                        quotaOn = match['is_store_quota_enabled'] == true ||
                            match['is_store_quota_enabled'] == 1;
                        maxCtrl.text = '${match['max_stores_quota'] ?? 3}';
                      });
                    }
                  },
                ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: quotaOn,
                activeThumbColor: AppColors.primary,
                title: const Text('Aktifkan Batas Kuota Toko'),
                onChanged: (v) => setDlgState(() => quotaOn = v),
              ),
              TextField(
                controller: maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maksimal Toko Aktif per Desa',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDlgState(() => saving = true);
                      try {
                        await _apiService.updateVillageStoreQuota({
                          'village_id': selectedId,
                          'is_store_quota_enabled': quotaOn,
                          'max_stores_quota': int.tryParse(maxCtrl.text) ?? 3,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _loadPenyuluhData();
                      } catch (_) {
                        setDlgState(() => saving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(saving ? 'Menyimpan...' : 'Simpan Kuota'),
            ),
          ],
        ),
      ),
    );
  }

  void _showVillageForumPostModal() {
    String kategori = 'INFO_PUPUK';
    final judulCtrl = TextEditingController();
    final isiCtrl = TextEditingController();
    final pickupCtrl = TextEditingController(
      text: 'Balai Poktan Harapan Dungkek (Depan Embung Desa)',
    );
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
                  'Kirim Info Pupuk / Arahan Forum Desa',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: kategori,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'INFO_PUPUK', child: Text('Info Titik Ambil Pupuk')),
                    DropdownMenuItem(value: 'ARAHAN_TANAM', child: Text('Arahan Tanam Desa')),
                    DropdownMenuItem(value: 'PERINGATAN_HAMA', child: Text('Peringatan Hama')),
                    DropdownMenuItem(value: 'TANYA_JAWAB', child: Text('Respon Tanya Jawab')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => kategori = v);
                  },
                ),
                if (kategori == 'INFO_PUPUK') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: pickupCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Titik Ambil Pupuk Desa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: judulCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Judul Pengumuman',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: isiCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Isi Pesan ke Petani Desa',
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
                            if (judulCtrl.text.trim().isEmpty ||
                                isiCtrl.text.trim().isEmpty) {
                              return;
                            }
                            setModalState(() => sending = true);
                            try {
                              await _apiService.createVillageForumPost({
                                'village_id': _selectedForumVillageId,
                                'kategori': kategori,
                                'judul': judulCtrl.text.trim(),
                                'isi_pesan': isiCtrl.text.trim(),
                                if (kategori == 'INFO_PUPUK')
                                  'titik_ambil_pupuk': pickupCtrl.text.trim(),
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _loadPenyuluhData();
                            } catch (_) {
                              setModalState(() => sending = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      sending ? 'Mengirim...' : 'Terbitkan ke Forum Desa',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
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

  void _showInterPplPostModal() {
    final topicCtrl = TextEditingController();
    final komCtrl = TextEditingController(text: 'Bawang Merah');
    final discCtrl = TextEditingController();
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
                'Diskusi Khusus Antar-Penyuluh',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: topicCtrl,
                decoration: const InputDecoration(
                  labelText: 'Topik Agronomi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: komCtrl,
                decoration: const InputDecoration(
                  labelText: 'Komoditas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: discCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Studi Kasus & Solusi',
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
                          if (topicCtrl.text.trim().isEmpty ||
                              discCtrl.text.trim().isEmpty) {
                            return;
                          }
                          setModalState(() => sending = true);
                          try {
                            await _apiService.createInterPplForumPost({
                              'topik': topicCtrl.text.trim(),
                              'komoditas': komCtrl.text.trim(),
                              'isi_diskusi': discCtrl.text.trim(),
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            await _loadPenyuluhData();
                          } catch (_) {
                            setModalState(() => sending = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    sending ? 'Mengirim...' : 'Bagikan ke Sesama Penyuluh',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreApprovalAndQuotaSection() {
    final pendingStores = _storeApps
        .where((s) => (s['status'] ?? '').toString().toUpperCase() == 'PENDING_PPL')
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.store, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ACC Toko & Kuota Toko Desa',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showVillageQuotaDialog,
                icon: const Icon(LucideIcons.slidersHorizontal, size: 13),
                label: Text(
                  'Atur Kuota',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (pendingStores.isEmpty)
            Text(
              'Tidak ada pengajuan pembukaan toko baru yang menunggu ACC.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            )
          else
            ...pendingStores.take(3).map((app) {
              final id = app['id'].toString();
              final name = (app['nama_toko'] ?? 'Toko Baru').toString();
              final village =
                  (app['resolved_village_name'] ?? app['village_name'] ?? 'Sumenep')
                      .toString();
              final isBusy = _busyStoreId == id;

              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name (${app['tipe_pengelola']})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Desa $village • Pemohon: ${app['applicant_name'] ?? app['user_id']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isBusy
                                ? null
                                : () => _verifyStoreApp(id, name, 'REJECTED'),
                            child: const Text('Tolak'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isBusy
                                ? null
                                : () => _verifyStoreApp(id, name, 'APPROVED'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(isBusy ? 'Memproses...' : 'ACC Buka Toko'),
                          ),
                        ),
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

  Widget _buildVillageForumSection() {
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
              const Icon(LucideIcons.megaphone, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Forum Privat Desa & Info Pupuk',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _showVillageForumPostModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                child: Text(
                  '+ Pengumuman',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (_villageForumPosts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Belum ada diskusi di forum desa terpilih.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            ..._villageForumPosts.take(2).map((p) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceSoftBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p['kategori']} • ${p['judul']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p['isi_pesan']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _openDirectChat(
                          targetUserId: (p['author_role'] == 'petani')
                              ? p['author_id']?.toString()
                              : null,
                          targetRole: 'petani',
                          title: 'DM — ${p['author_name'] ?? 'Petani Desa'}',
                        ),
                        icon: const Icon(LucideIcons.messageSquare, size: 12),
                        label: Text(
                          'Kirim DM',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildInterPplForumSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.users, color: AppColors.info, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Forum Khusus Antar-Penyuluh',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: _showInterPplPostModal,
                child: Text(
                  '+ Diskusi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          ..._interPplPosts.take(2).map((p) {
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
                    '${p['komoditas']} • ${p['topik']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p['penyuluh_name']}: ${p['isi_diskusi']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _openDirectChat(
                        targetUserId: p['penyuluh_id']?.toString(),
                        targetRole: 'penyuluh',
                        title: 'DM — ${p['penyuluh_name'] ?? 'Rekan Penyuluh'}',
                      ),
                      icon: const Icon(LucideIcons.messageSquare, size: 12),
                      label: Text(
                        'Kirim DM',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
