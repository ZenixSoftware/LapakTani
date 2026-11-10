import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_soft_card.dart';
import '../../buyer/screens/wholesale_detail_screen.dart';
import '../../store/screens/store_profile_screen.dart';
import '../widgets/create_wholesale_pool_sheet.dart';

class MitraStoreCatalogScreen extends StatefulWidget {
  const MitraStoreCatalogScreen({super.key});

  @override
  State<MitraStoreCatalogScreen> createState() =>
      _MitraStoreCatalogScreenState();
}

class _MitraStoreCatalogScreenState extends State<MitraStoreCatalogScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');

  late TabController _tabController;
  bool _isLoading = true;
  bool _isStoreOpen = true;
  final String _storeName = 'Mitra Tani Makmur';

  List<dynamic> _retailProducts = [];
  List<Map<String, dynamic>> _harvestPools = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCatalog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() => _isLoading = true);
    try {
      final products = await _apiService.getProducts();
      final pools = await _apiService.getB2BHarvestPools();

      if (!mounted) return;
      setState(() {
        _retailProducts = products.isNotEmpty
            ? products
            : [
                {
                  'id': 'prod-01',
                  'title': 'Tomat Merah Segar Lembang 1 Kg',
                  'price_per_kg': 12000,
                  'stock_kg': 150,
                  'image_url': 'uploads/products/tomat.jpg',
                  'isActive': true,
                },
                {
                  'id': 'prod-02',
                  'title': 'Cabai Rawit Merah Super 1 Kg',
                  'price_per_kg': 35000,
                  'stock_kg': 85,
                  'image_url': 'uploads/products/cabai.jpg',
                  'isActive': true,
                },
                {
                  'id': 'prod-03',
                  'title': 'Kentang Dieng Super Grade A',
                  'price_per_kg': 16000,
                  'stock_kg': 200,
                  'image_url': 'uploads/products/kentang.jpg',
                  'isActive': true,
                },
              ];
        _harvestPools = pools;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http')) return rawUrl;
    final clean = rawUrl.startsWith('/') ? rawUrl.substring(1) : rawUrl;
    return '${ApiService.baseUrl.replaceAll('/api', '')}/$clean';
  }

  Future<void> _handleSpillover(String poolId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Alihkan Sisa Kuota ke Retail?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Mekanisme Zero-Waste: Sisa kuota borongan yang belum terserap akan langsung dialihkan menjadi stok retail di etalase Toko Mitra Tani dan penawaran partai akan ditutup.',
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
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006E04),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Alihkan ke Retail',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
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
            content: Text(res['message'] ?? 'Sisa kuota berhasil dialihkan ke stok retail!'),
            backgroundColor: const Color(0xFF006E04),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadCatalog();
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

  void _showAddProductOptionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tambah Katalog Toko',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pilih jenis penjualan produk pertanian untuk etalase Anda:',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                _showCreateRetailProductSheet();
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.shoppingBag, color: Color(0xFF006E04)),
              ),
              title: Text(
                'Tambah Produk Retail (Eceran)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                'Jual sayur/buah segar per kg langsung ke konsumen rumah tangga.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
              ),
              trailing: const Icon(LucideIcons.chevronRight, size: 18),
            ),
            const Divider(height: 16),
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                CreateWholesalePoolSheet.show(
                  context,
                  mitraName: _storeName,
                  onCreated: _loadCatalog,
                );
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.layers, color: Color(0xFFB45309)),
              ),
              title: Text(
                'Buka Penawaran Partai (B2B)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                'Buka bursa forward pool hasil konsolidasi panen borongan skala besar.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
              ),
              trailing: const Icon(LucideIcons.chevronRight, size: 18),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showCreateRetailProductSheet() {
    final titleController = TextEditingController(text: 'Wortel Manis Brastagi Super');
    final priceController = TextEditingController(text: '14000');
    final stockController = TextEditingController(text: '100');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tambah Produk Retail',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Nama Produk & Kemasan', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Harga Eceran (Rp/kg)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: 'Rp ',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stok Awal (kg)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          suffixText: 'kg',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final newProd = {
                    'id': 'prod-${DateTime.now().millisecondsSinceEpoch}',
                    'title': titleController.text.trim(),
                    'price_per_kg': double.tryParse(priceController.text) ?? 14000,
                    'stock_kg': double.tryParse(stockController.text) ?? 100,
                    'image_url': 'uploads/products/tomat.jpg',
                    'isActive': true,
                  };
                  setState(() {
                    _retailProducts.insert(0, newProd);
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produk retail berhasil ditambahkan ke etalase toko!'),
                      backgroundColor: Color(0xFF006E04),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006E04),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Simpan ke Etalase', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStockModal(Map<String, dynamic> item) {
    final stockController = TextEditingController(
      text: ((item['stock_kg'] ?? item['stock'] ?? 0) as num).toStringAsFixed(0),
    );
    final priceController = TextEditingController(
      text: ((item['price_per_kg'] ?? item['price'] ?? 0) as num).toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Ubah Stok & Harga',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['title'] ?? 'Produk', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Text('Harga per kg (Rp)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            Text('Stok Tersedia (kg)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                item['price_per_kg'] = double.tryParse(priceController.text) ?? item['price_per_kg'];
                item['stock_kg'] = double.tryParse(stockController.text) ?? item['stock_kg'];
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Katalog berhasil diperbarui!'),
                  backgroundColor: Color(0xFF006E04),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006E04),
              foregroundColor: Colors.white,
            ),
            child: Text('Simpan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: Text(
          'Etalase Toko Mitra Tani',
          style: GoogleFonts.plusJakartaSans(fontSize: 16.5, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreProfileScreen(storeName: _storeName),
                ),
              );
            },
            icon: const Icon(LucideIcons.externalLink, size: 14, color: Color(0xFF006E04)),
            label: Text(
              'Lihat Toko',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF006E04),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductOptionSheet,
        backgroundColor: const Color(0xFF006E04),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: Text(
          'Tambah Produk',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      body: Column(
        children: [
          // 1. Store Header summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.store, color: Color(0xFF006E04), size: 26),
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
                              _storeName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.badgeCheck, size: 16, color: Color(0xFF006E04)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Performa Toko: 98% • 11.10 Ha Lahan Terdaftar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
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
                      _isStoreOpen ? 'Toko Buka' : 'Toko Libur',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _isStoreOpen ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                      ),
                    ),
                    Switch(
                      value: _isStoreOpen,
                      activeThumbColor: const Color(0xFF006E04),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val) {
                        setState(() => _isStoreOpen = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val ? 'Etalase toko sekarang dibuka!' : 'Toko ditutup sementara.'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF006E04),
              indicatorWeight: 3,
              labelColor: const Color(0xFF006E04),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Produk Retail'),
                Tab(text: 'Penawaran Partai (B2B)'),
              ],
            ),
          ),

          // Content Views
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRetailCatalogView(),
                      _buildWholesalePoolsView(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetailCatalogView() {
    if (_retailProducts.isEmpty) {
      return Center(
        child: Text(
          'Belum ada produk retail di etalase.',
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      itemCount: _retailProducts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _retailProducts[index];
        final String title = item['title']?.toString() ?? 'Komoditas Segar';
        final num price = (item['price_per_kg'] as num?) ?? (item['price'] as num?) ?? 0;
        final num stock = (item['stock_kg'] as num?) ?? (item['stock'] as num?) ?? 0;
        final String rawImg = item['image_url']?.toString() ?? '';
        final String imageUrl = _resolveImageUrl(rawImg);
        final bool isActive = item['isActive'] ?? true;

        return CustomSoftCard(
          padding: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFFE2E8F0),
                            child: const Icon(LucideIcons.image, color: Color(0xFF94A3B8)),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(LucideIcons.image, color: Color(0xFF94A3B8)),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_currencyFormat.format(price)} / kg',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF006E04),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stok: ${stock.toStringAsFixed(0)} kg',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Switch(
                    value: isActive,
                    activeThumbColor: const Color(0xFF006E04),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      setState(() => item['isActive'] = val);
                    },
                  ),
                  InkWell(
                    onTap: () => _showEditStockModal(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.edit2, size: 12, color: Color(0xFF006E04)),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF006E04),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildWholesalePoolsView() {
    if (_harvestPools.isEmpty) {
      return Center(
        child: Text(
          'Belum ada bursa penawaran partai panen aktif.',
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      itemCount: _harvestPools.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final pool = _harvestPools[index];
        final String commodity = pool['commodity_name'] ?? 'Komoditas Partai';
        final double totalKg = (pool['total_quota_kg'] as num?)?.toDouble() ?? 100.0;
        final double remainingKg = (pool['remaining_quota_kg'] as num?)?.toDouble() ?? 50.0;
        final double takenKg = (totalKg - remainingKg).clamp(0.0, totalKg);
        final double progress = totalKg > 0 ? (takenKg / totalKg).clamp(0.0, 1.0) : 0.0;
        final double priceKg = (pool['price_per_kg'] as num?)?.toDouble() ?? 0.0;
        final String harvestDate = pool['target_harvest_date'] ?? pool['est_harvest_date'] ?? '15 Nov 2026';
        final String status = pool['status']?.toString() ?? 'open';
        final bool isSpilled = status == 'spilled_over';

        return CustomSoftCard(
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      commodity,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSpilled
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isSpilled ? 'Surplus Dialihkan ke Retail' : 'Bursa Aktif',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isSpilled ? const Color(0xFFB45309) : const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Harga Borongan: Rp ${_currencyFormat.format(priceKg)} / kg • Target: $harvestDate',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
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
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF006E04)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WholesaleDetailScreen(pool: pool),
                        ),
                      );
                    },
                    child: Text(
                      'Pratinjau Pembeli',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (remainingKg > 0 && !isSpilled)
                    ElevatedButton.icon(
                      onPressed: () => _handleSpillover(pool['id'].toString()),
                      icon: const Icon(LucideIcons.arrowRightLeft, size: 14),
                      label: Text(
                        'Alihkan Sisa ke Retail',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
}
