import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/user_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_soft_card.dart';
import '../../auth/auth_repository.dart';
import '../../navigation/role_based_app_shell.dart';
import '../models/b2b_order_model.dart';
import '../models/poktan_member_model.dart';
import '../services/poktan_service.dart';
import 'allocate_quota_sheet.dart';
import 'create_b2b_order_sheet.dart';
import 'farmer_tasks_screen.dart';

class PoktanDashboardScreen extends StatefulWidget {
  final bool showBackButton;

  const PoktanDashboardScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  State<PoktanDashboardScreen> createState() => _PoktanDashboardScreenState();
}

class _PoktanDashboardScreenState extends State<PoktanDashboardScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final PoktanService _poktanService = PoktanService();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');

  late TabController _tabController;
  bool _isLoading = true;

  String _poktanName = 'Mitra Tani Makmur';
  double _totalLandAreaHa = 11.10;
  List<PoktanMemberModel> _members = [];
  List<B2BOrderModel> _b2bOrders = [];
  List<Map<String, dynamic>> _harvestPools = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final membersData = await _poktanService.fetchMembers();
    final orders = await _poktanService.fetchB2BOrders();
    final pools = await _apiService.getB2BHarvestPools();

    if (!mounted) return;

    setState(() {
      _poktanName = membersData['poktan_name'] ?? 'Mitra Tani Makmur';
      _totalLandAreaHa = (membersData['total_land_area_ha'] as num?)?.toDouble() ?? 11.10;
      _members = (membersData['members'] as List<PoktanMemberModel>?) ?? [];
      _b2bOrders = orders;
      _harvestPools = pools;
      _isLoading = false;
    });
  }

  void _showCreateHarvestPoolSheet() {
    final commodityController = TextEditingController(text: 'Cabai Merah Keriting Grade A');
    final quotaController = TextEditingController(text: '350');
    final priceController = TextEditingController(text: '28000');
    final dateController = TextEditingController(text: '15 Nov 2026');
    final notesController = TextEditingController(text: 'Konsolidasi panen lahan anggota');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Buka Penawaran Partai (B2B)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daftarkan bursa forward pool hasil konsolidasi panen anggota Mitra Tani untuk diserap pembeli borongan.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  Text('Komoditas Pertanian', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: commodityController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Cabai Merah Keriting Grade A',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Kuota (kg)', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: quotaController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                suffixText: 'kg',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Harga Grosir / kg', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: 'Rp ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Target Tanggal Panen', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: dateController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 15 Nov 2026',
                      suffixIcon: const Icon(LucideIcons.calendar, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Catatan / Keterangan', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Panen subuh konsolidasi 11.10 Ha',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () async {
                        final double quota = double.tryParse(quotaController.text) ?? 0.0;
                        final double price = double.tryParse(priceController.text) ?? 0.0;
                        if (commodityController.text.trim().isEmpty || quota <= 0 || price <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mohon lengkapi komoditas, kuota, dan harga dengan benar.'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        final success = await _apiService.createB2BHarvestPool(
                          commodityName: commodityController.text.trim(),
                          totalQuotaKg: quota,
                          pricePerKg: price,
                          targetHarvestDate: dateController.text.trim(),
                          notes: notesController.text.trim(),
                          mitraName: _poktanName,
                        );

                        if (!mounted) return;
                        if (success) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Bursa penawaran partai panen berhasil dibuka!'),
                              backgroundColor: Color(0xFF03AC0E),
                            ),
                          );
                          _loadDashboardData();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF03AC0E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Buka Penawaran Sekarang',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleSpillover(String poolId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Alihkan Sisa Kuota ke Retail?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Mekanisme Zero-Waste: Sisa kuota borongan yang belum terserap akan langsung dialihkan menjadi stok retail di etalase Toko Mitra Tani dan penawaran partai akan ditutup.',
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
              backgroundColor: const Color(0xFF006E04),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Alihkan ke Retail', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await _apiService.spilloverToRetail(poolId: poolId);
      if (!mounted) return;
      if (res != null && res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Sisa kuota berhasil dialihkan ke stok retail Toko Mitra Tani!'),
            backgroundColor: const Color(0xFF03AC0E),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadDashboardData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengalihkan kuota ke retail.'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCreateOrderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateB2BOrderSheet(
        onOrderCreated: _loadDashboardData,
      ),
    );
  }

  void _showAllocateQuotaSheet(B2BOrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AllocateQuotaSheet(
        order: order,
        members: _members,
        onAllocationSuccess: _loadDashboardData,
      ),
    );
  }

  void _showSettleDialog(B2BOrderModel order) {
    final deliveredController = TextEditingController(text: order.totalQuotaKg.toStringAsFixed(0));
    final priceController = TextEditingController(text: '15000');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Timbang Panen & Settlement B2B',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Input tonase aktual panen masuk dari petani untuk ${order.commodityName} (${order.buyerName}). Target kontrak: ${order.totalQuotaKg} kg.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Text('Tonase Panen Masuk (kg)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: deliveredController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Misal: 850',
                  suffixText: 'kg',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              Text('Harga Kesepakatan (Rp/kg)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '15000',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              Text('Catatan Deviasi / Keterangan', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Contoh: Deviasi hasil panen akibat anomali cuaca diverifikasi Poktan.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              final delivered = double.tryParse(deliveredController.text) ?? 0.0;
              final price = double.tryParse(priceController.text) ?? 15000.0;
              if (delivered <= 0) return;

              Navigator.pop(ctx);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final result = await _poktanService.settleB2BOrder(
                orderId: order.id,
                actualDeliveredKg: delivered,
                agreedPricePerKg: price,
                settlementNotes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
              );

              if (result['success'] == true) {
                await _loadDashboardData();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(result['message']?.toString() ?? 'Settlement berhasil diproses.'),
                    backgroundColor: const Color(0xFF03AC0E),
                  ),
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(result['message']?.toString() ?? 'Gagal memproses settlement.'),
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF03AC0E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Proses Settlement', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildAggregatedKpiHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5132), Color(0xFF03AC0E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF03AC0E).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Panel Pengurus Poktan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FarmerTasksScreen(showBackButton: true),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.listTodo, color: AppColors.primaryDark, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'Tugas Petani',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Mitra Tani / Poktan • $_poktanName',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFD1FAE5),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _totalLandAreaHa.toStringAsFixed(2),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Hektare Aktif',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE2E8F0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.users, size: 16, color: Color(0xFFD1FAE5)),
                  const SizedBox(width: 6),
                  Text(
                    '${_members.length} Petani Terdaftar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(LucideIcons.briefcase, size: 16, color: Color(0xFFD1FAE5)),
                  const SizedBox(width: 6),
                  Text(
                    '${_b2bOrders.length} Kontrak B2B',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildB2BOrdersTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        // ---------------- Section 1: Bursa Penawaran Partai Panen (Forward Pool) ----------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bursa Penawaran Partai (Open Pool)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Forward pool konsolidasi panen anggota Mitra Tani.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _showCreateHarvestPoolSheet,
              icon: const Icon(LucideIcons.plus, size: 14, color: AppColors.primary),
              label: Text(
                'Buka Pool',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_harvestPools.isEmpty)
          CustomSoftCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Column(
                children: [
                  const Icon(LucideIcons.layers, size: 36, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada bursa penawaran partai aktif',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Buka penawaran partai untuk menjual borongan ke pembeli B2B.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._harvestPools.map((pool) {
            final double totalKg = (pool['total_quota_kg'] as num?)?.toDouble() ?? 0.0;
            final double remainingKg = (pool['remaining_quota_kg'] as num?)?.toDouble() ?? 0.0;
            final double takenKg = (totalKg - remainingKg).clamp(0.0, totalKg);
            final double progress = totalKg > 0 ? (takenKg / totalKg).clamp(0.0, 1.0) : 0.0;
            final String status = pool['status']?.toString() ?? 'open';
            final bool isSpilled = status == 'spilled_over';
            final bool isSoldOut = remainingKg <= 0.01;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CustomSoftCard(
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.layers, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pool['commodity_name'] ?? 'Komoditas Panen',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF121C2A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pool['poktan_name'] ?? _poktanName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSpilled
                                ? const Color(0xFFFEF3C7)
                                : isSoldOut
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isSpilled
                                ? 'Dialihkan Retail'
                                : isSoldOut
                                    ? 'Terserap Penuh'
                                    : 'Bursa Aktif',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isSpilled
                                  ? const Color(0xFFB45309)
                                  : isSoldOut
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Terserap: ${_currencyFormat.format(takenKg)} / ${_currencyFormat.format(totalKg)} kg',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Sisa: ${_currencyFormat.format(remainingKg)} kg',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isSoldOut ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isSoldOut ? const Color(0xFF16A34A) : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Estimasi Panen: ${pool['est_harvest_date'] ?? '-'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Text(
                          'Rp ${_currencyFormat.format(pool['price_per_kg'] ?? 0)}/kg',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF006E04),
                          ),
                        ),
                      ],
                    ),

                    if (remainingKg > 0 && !isSpilled) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _handleSpillover(pool['id'].toString()),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD97706)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              minimumSize: const Size(40, 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(LucideIcons.arrowRightLeft, size: 14, color: Color(0xFFD97706)),
                            label: Text(
                              'Alihkan Sisa ke Retail',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 16),
        // ---------------- Section 2: Kontrak Pasokan Terjadwal ----------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kontrak Pasokan Terjadwal (B2B)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pesanan kontrak langsung dengan mitra horeka & offtaker.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _showCreateOrderSheet,
              icon: const Icon(LucideIcons.plus, size: 14, color: AppColors.primary),
              label: Text(
                'Kontrak Baru',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_b2bOrders.isEmpty)
          CustomSoftCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Column(
                children: [
                  const Icon(LucideIcons.inbox, size: 36, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada kontrak pesanan B2B terjadwal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._b2bOrders.map((order) {
            final double progress = order.totalQuotaKg > 0
                ? (order.totalAllocatedKg / order.totalQuotaKg).clamp(0.0, 1.0)
                : 0.0;
            final bool isFullyAllocated = order.remainingQuotaKg <= 0.01;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CustomSoftCard(
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.packageCheck, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.commodityName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF121C2A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.buyerName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isFullyAllocated ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isFullyAllocated ? 'Teralokasi Penuh' : 'Perlu Alokasi',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isFullyAllocated ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quota progress indicator
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total: ${_currencyFormat.format(order.totalQuotaKg)} kg',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Sisa: ${_currencyFormat.format(order.remainingQuotaKg)} kg',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isFullyAllocated ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFullyAllocated ? const Color(0xFF16A34A) : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Deadline info and Action buttons
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.calendar, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Tenggat: ${order.deadline}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            if (order.status != 'completed' && order.status != 'PARTIALLY_FULFILLED')
                              OutlinedButton.icon(
                                onPressed: () => _showSettleDialog(order),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF03AC0E)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  minimumSize: const Size(40, 36),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(LucideIcons.scale, size: 14, color: Color(0xFF03AC0E)),
                                label: Text(
                                  'Timbang Masuk',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF03AC0E),
                                  ),
                                ),
                              ),
                            ElevatedButton.icon(
                              onPressed: () => _showAllocateQuotaSheet(order),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFullyAllocated ? const Color(0xFFF1F5F9) : AppColors.primary,
                                foregroundColor: isFullyAllocated ? const Color(0xFF475569) : Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: const Size(44, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: Icon(
                                isFullyAllocated ? LucideIcons.checkCheck : LucideIcons.split,
                                size: 14,
                              ),
                              label: Text(
                                isFullyAllocated ? 'Atur Ulang' : 'Bagi Kuota',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMembersTab() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _members.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final member = _members[index];
        final double sharePercent = _totalLandAreaHa > 0
            ? (member.landAreaHa / _totalLandAreaHa) * 100
            : 0;

        return CustomSoftCard(
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: member.isChairman
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFE2E8F0),
                child: Icon(
                  member.isChairman ? Icons.star : Icons.person,
                  color: member.isChairman
                      ? const Color(0xFFD97706)
                      : const Color(0xFF475569),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.fullName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF121C2A),
                            ),
                          ),
                        ),
                        if (member.isChairman) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Pengurus',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NIK: ${member.nikNumber} | Telp: ${member.phone}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Jenis Tanah: ${member.soilType}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${member.landAreaHa.toStringAsFixed(2)} ha',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${sharePercent.toStringAsFixed(1)}% kapasitas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Keluar dari Akun',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Pengurus Poktan?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
              ),
            ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF121C2A), size: 22),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'Konsolidasi Lahan Mitra Tani / Poktan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF121C2A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Color(0xFF475569), size: 20),
            tooltip: 'Segarkan',
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
            tooltip: 'Keluar',
            onPressed: _handleLogout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateHarvestPoolSheet,
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(LucideIcons.packagePlus, color: Colors.white, size: 20),
        label: Text(
          'Buka Penawaran Partai',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadDashboardData,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: _buildAggregatedKpiHero(),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: const Color(0xFF64748B),
                          indicatorColor: AppColors.primary,
                          indicatorWeight: 3,
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          tabs: const [
                            Tab(text: 'Kontrak & Alokasi B2B'),
                            Tab(text: 'Daftar Lahan Anggota'),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildB2BOrdersTab(),
                    _buildMembersTab(),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 1;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

