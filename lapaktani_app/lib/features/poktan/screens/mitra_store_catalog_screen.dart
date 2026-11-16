/*
 * ============================================================================
 * LAPAKTANI MOBILE APP - [US-09] MITRA STORE COMMODITY CATALOG & INVENTORY
 * ============================================================================
 * Module       : Features / Mitra Store & Poktan Catalog
 * User Story   : [US-09] CRUD Stok/Harga Toko (Retail, Diskon, Partai/Grosir)
 * Author       : Moch. Ilham Abdul Aziz (MochIlham05 - 3125522014)
 * Architecture : Flutter Multi-Tab View, Wholesale Tier Calculation, Dynamic Quota
 * ============================================================================
 */

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_soft_card.dart';
import '../../buyer/screens/wholesale_detail_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../chat/screens/chat_room_screen.dart';
import '../../chat/services/chat_service.dart';
import '../../product/add_product_screen.dart';
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
  String _storeName = 'Koperasi Tani Sumber Lestari';
  int _defaultMinWholesaleKg = 30;
  String _storeBanner = 'Promo Panen Raya Hemat s/d 15% & Harga Partai B2B';

  List<dynamic> _retailProducts = [];
  List<Map<String, dynamic>> _harvestPools = [];
  List<Map<String, dynamic>> _nearbyHarvests = [];
  List<Map<String, dynamic>> _purchaseOffers = [];

  double _toDouble(dynamic v, [double fallback = 0.0]) => v == null
      ? fallback
      : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? fallback);

  int _toInt(dynamic v, [int fallback = 0]) => v == null
      ? fallback
      : (v is int
          ? v
          : (v is num
              ? v.toInt()
              : double.tryParse(v.toString())?.round() ?? fallback));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final results = await Future.wait([
        _apiService.getProducts(),
        _apiService.getB2BHarvestPools(),
        _apiService
            .getNearbyHarvests()
            .catchError((_) => <Map<String, dynamic>>[]),
        _apiService
            .getStorePurchaseOffers()
            .catchError((_) => <Map<String, dynamic>>[]),
        _apiService
            .getMyStoreApplication()
            .catchError((_) => <String, dynamic>{}),
      ]);

      final products = results[0] as List<dynamic>;
      final pools = results[1] as List<Map<String, dynamic>>;
      final nearby = results[2] as List<Map<String, dynamic>>;
      final offers = results[3] as List<Map<String, dynamic>>;
      final storeRes = results[4] as Map<String, dynamic>;

      final storeApp = storeRes['data'] is Map ? storeRes['data']['application'] : null;
      if (storeApp is Map) {
        if (storeApp['nama_toko'] != null) {
          _storeName = storeApp['nama_toko'].toString();
        }
        if (storeApp['default_min_wholesale_kg'] != null) {
          _defaultMinWholesaleKg =
              _toInt(storeApp['default_min_wholesale_kg'], 30);
        }
        if (storeApp['store_discount_banner'] != null) {
          _storeBanner = storeApp['store_discount_banner'].toString();
        }
        if (storeApp['is_store_open'] != null) {
          _isStoreOpen =
              storeApp['is_store_open'] == 1 ||
              storeApp['is_store_open'] == true;
        }
      }

      if (!mounted) return;
      setState(() {
        _retailProducts = products.isNotEmpty
            ? products
            : [
                {
                  'id': 'prod-01',
                  'title': 'Tomat Merah Segar Lembang 1 Kg',
                  'price_per_kg': 12000,
                  'discount_percent': 10,
                  'discount_price': 10800,
                  'is_wholesale_enabled': true,
                  'min_wholesale_qty': 30,
                  'wholesale_price': 10200,
                  'stock_kg': 150,
                  'image_url': 'uploads/products/tomat.jpg',
                  'isActive': true,
                },
                {
                  'id': 'prod-02',
                  'title': 'Cabai Rawit Merah Super 1 Kg',
                  'price_per_kg': 35000,
                  'discount_percent': 10,
                  'discount_price': 31500,
                  'is_wholesale_enabled': true,
                  'min_wholesale_qty': 25,
                  'wholesale_price': 29750,
                  'stock_kg': 85,
                  'image_url': 'uploads/products/cabai.jpg',
                  'isActive': true,
                },
              ];
        _harvestPools = pools;
        _nearbyHarvests = nearby;
        _purchaseOffers = offers;
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
              backgroundColor: AppColors.primary,
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
            backgroundColor: AppColors.primary,
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                ).then((_) => _loadCatalog());
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.shoppingBag, color: AppColors.primary),
              ),
              title: Text(
                'Tambah Produk (Retail, Diskon & Partai B2B)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                'Atur harga normal, promo diskon %, batas minimal Partai (kg) & harga grosir.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
              ),
              trailing: const Icon(LucideIcons.chevronRight, size: 18),
            ),
            const Divider(height: 16),
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                _showWalkInPurchaseModal();
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.scale, color: AppColors.info),
              ),
              title: Text(
                'Input Beli Petani Tradisional (Walk-in)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                'Catat pembelian hasil panen petani langsung di toko tanpa aplikasi.',
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

  void _showStoreSettingsDialog() {
    final nameCtrl = TextEditingController(text: _storeName);
    final minCtrl =
        TextEditingController(text: _defaultMinWholesaleKg.toString());
    final bannerCtrl = TextEditingController(text: _storeBanner);
    bool isOpen = _isStoreOpen;
    bool saving = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text(
            'Pengaturan Toko & Partai Default',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Toko / Koperasi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimal Pembelian Partai Default (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bannerCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Banner Promo Toko',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isOpen,
                  activeThumbColor: AppColors.primary,
                  title: const Text('Status Toko Buka'),
                  onChanged: (v) => setDlgState(() => isOpen = v),
                ),
              ],
            ),
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
                        await _apiService.updateStoreSettings({
                          'nama_toko': nameCtrl.text.trim(),
                          'default_min_wholesale_kg':
                              int.tryParse(minCtrl.text.trim()) ?? 30,
                          'store_discount_banner': bannerCtrl.text.trim(),
                          'is_store_open': isOpen,
                        });
                        if (mounted) {
                          setState(() {
                            _storeName = nameCtrl.text.trim();
                            _defaultMinWholesaleKg =
                                int.tryParse(minCtrl.text.trim()) ?? 30;
                            _storeBanner = bannerCtrl.text.trim();
                            _isStoreOpen = isOpen;
                          });
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pengaturan toko berhasil disimpan!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Gagal menyimpan: $e'),
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
              child: Text(saving ? 'Menyimpan...' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStockModal(Map<String, dynamic> item) {
    final stockController = TextEditingController(
      text: _toDouble(item['stock_kg'] ?? item['stock']).toStringAsFixed(0),
    );
    final priceController = TextEditingController(
      text: _toDouble(item['price_per_kg'] ?? item['price']).toStringAsFixed(0),
    );
    final discountPctCtrl = TextEditingController(
      text: _toDouble(item['discount_percent']).toStringAsFixed(0),
    );
    final minWholesaleCtrl = TextEditingController(
      text: '${_toInt(item['min_wholesale_qty'], _defaultMinWholesaleKg)}',
    );
    final wholesalePriceCtrl = TextEditingController(
      text: item['wholesale_price'] != null
          ? '${_toInt(item['wholesale_price'])}'
          : '',
    );
    bool wholesaleEnabled = item['is_wholesale_enabled'] != false &&
        item['is_wholesale_enabled'] != 0;
    bool saving = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text(
            'Atur Harga Retail, Diskon & Partai',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title']?.toString() ?? 'Produk',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga Retail Normal (Rp/kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: discountPctCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Diskon Promo (%)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stok (kg)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: wholesaleEnabled,
                  activeThumbColor: AppColors.primary,
                  title: Text(
                    'Aktifkan Pembelian Partai (B2B)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onChanged: (v) => setDlgState(() => wholesaleEnabled = v),
                ),
                if (wholesaleEnabled) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minWholesaleCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Min. Partai (kg)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: wholesalePriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Harga Partai (Rp/kg)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final newPrice = double.tryParse(priceController.text) ??
                          _toDouble(item['price_per_kg']);
                      final newStock = double.tryParse(stockController.text) ??
                          _toDouble(item['stock_kg']);
                      final newDiscPct =
                          double.tryParse(discountPctCtrl.text.trim()) ?? 0;
                      final newMinWholesale =
                          int.tryParse(minWholesaleCtrl.text.trim()) ?? 30;
                      final newWholesalePrice =
                          double.tryParse(wholesalePriceCtrl.text.trim()) ??
                              (newPrice * 0.85).roundToDouble();

                      setDlgState(() => saving = true);
                      try {
                        final id = item['id']?.toString() ?? '';
                        if (id.isNotEmpty && !id.startsWith('prod-0')) {
                          await _apiService.updateProductPricing(id, {
                            'price_per_kg': newPrice,
                            'stock_kg': newStock,
                            'discount_percent': newDiscPct,
                            'is_wholesale_enabled': wholesaleEnabled,
                            'min_wholesale_qty': newMinWholesale,
                            'wholesale_price': newWholesalePrice,
                          });
                        }
                        if (mounted) {
                          setState(() {
                            item['price_per_kg'] = newPrice;
                            item['price'] = newPrice;
                            item['stock_kg'] = newStock;
                            item['discount_percent'] = newDiscPct;
                            item['discount_price'] = newDiscPct > 0
                                ? (newPrice * (1 - newDiscPct / 100)).round()
                                : null;
                            item['is_wholesale_enabled'] = wholesaleEnabled;
                            item['min_wholesale_qty'] = newMinWholesale;
                            item['wholesale_price'] = newWholesalePrice;
                          });
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Harga retail, diskon & partai berhasil disimpan!',
                              ),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Gagal update harga: $e'),
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
                saving ? 'Menyimpan...' : 'Simpan Harga',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
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
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChatListScreen(initialTab: 'ORDER'),
                ),
              );
            },
            icon: const Icon(LucideIcons.messageSquare, size: 19, color: AppColors.primary),
            tooltip: 'Chat Pembeli',
          ),
          IconButton(
            onPressed: _showStoreSettingsDialog,
            icon: const Icon(LucideIcons.settings, size: 19, color: AppColors.primary),
            tooltip: 'Pengaturan Toko & Min. Partai',
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreProfileScreen(storeName: _storeName),
                ),
              );
            },
            icon: const Icon(LucideIcons.externalLink, size: 14, color: AppColors.primary),
            label: Text(
              'Lihat Toko',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_mitra_store_catalog',
        onPressed: _showAddProductOptionSheet,
        backgroundColor: AppColors.primary,
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
                    child: Icon(LucideIcons.store, color: AppColors.primary, size: 26),
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
                          const Icon(LucideIcons.badgeCheck, size: 16, color: AppColors.primary),
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
                      activeThumbColor: AppColors.primary,
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
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Katalog & Harga'),
                Tab(text: 'Bursa Partai'),
                Tab(text: 'Serapan & Walk-in'),
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
                      _buildHarvestAbsorptionView(),
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
        final double price = _toDouble(item['price_per_kg'] ?? item['price']);
        final double stock = _toDouble(item['stock_kg'] ?? item['stock']);
        final double discPct = _toDouble(item['discount_percent']);
        final double rawDiscPrice = _toDouble(item['discount_price']);
        final double effectiveRetailPrice =
            (rawDiscPrice > 0 && rawDiscPrice < price) ? rawDiscPrice : price;
        final double wholesalePrice =
            _toDouble(item['wholesale_price'], (price * 0.85).roundToDouble());
        final int minWholesaleQty =
            _toInt(item['min_wholesale_qty'], _defaultMinWholesaleKg);
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Rp ${_currencyFormat.format(effectiveRetailPrice)} / kg',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (discPct > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.errorSoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${discPct.toStringAsFixed(0)}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stok: ${stock.toStringAsFixed(0)} kg'
                      '${(item['is_wholesale_enabled'] != false && item['is_wholesale_enabled'] != 0) ? " • Partai Min. ${minWholesaleQty}kg @ Rp ${_currencyFormat.format(wholesalePrice)}" : " • Partai Nonaktif"}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
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
                    activeThumbColor: AppColors.primary,
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
                          const Icon(LucideIcons.edit2, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
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
        final String commodity = pool['commodity_name']?.toString() ?? 'Komoditas Partai';
        final double totalKg = _toDouble(pool['total_quota_kg'], 100.0);
        final double remainingKg = _toDouble(pool['remaining_quota_kg'], 50.0);
        final double takenKg = (totalKg - remainingKg).clamp(0.0, totalKg);
        final double progress = totalKg > 0 ? (takenKg / totalKg).clamp(0.0, 1.0) : 0.0;
        final double priceKg = _toDouble(pool['price_per_kg']);
        final String harvestDate = (pool['target_harvest_date'] ?? pool['est_harvest_date'] ?? '15 Nov 2026').toString();
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
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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

  Widget _buildHarvestAbsorptionView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: [
        CustomSoftCard(
          backgroundColor: AppColors.surfaceSoft,
          border: Border.all(color: AppColors.surfaceSoftBorder),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(LucideIcons.scale, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Serap Panen & Petani Tradisional',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'Kirim tawaran transparan ke petani sekitar atau input pembelian walk-in.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _showWalkInPurchaseModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                child: Text(
                  '+ Walk-in',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Siaran Panen Petani Sekitar (${_nearbyHarvests.length})',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (_nearbyHarvests.isEmpty)
          CustomSoftCard(
            child: Text(
              'Belum ada siaran Hampir Panen / Siap Panen dari petani sekitar.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          )
        else
          ..._nearbyHarvests.map((h) {
            final kom = (h['komoditas'] ?? 'Komoditas').toString();
            final farmer = (h['farmer_name'] ?? 'Petani Mitra').toString();
            final village = (h['village_name'] ?? 'Sumenep').toString();
            final status = (h['status_tanam'] ?? 'SIAP_PANEN').toString();
            final weight = _toDouble(h['estimasi_berat_kg']).toStringAsFixed(0);
            return CustomSoftCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$kom • $weight kg',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$farmer • Desa $village',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (h['catatan'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      h['catatan'].toString(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final conv = await ChatService().openDirectConversation(
                                targetUserId: h['farmer_id']?.toString(),
                                targetRole: 'petani',
                                title: 'DM — $farmer',
                              );
                              if (!mounted) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatRoomScreen(conversation: conv),
                                ),
                              );
                            } catch (_) {}
                          },
                          icon: const Icon(LucideIcons.messageSquare, size: 13),
                          label: Text(
                            'DM Petani',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: () => _showSendOfferModal(h),
                          icon: const Icon(LucideIcons.badgeDollarSign, size: 14),
                          label: Text(
                            'Tawarkan Harga',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 12),
        Text(
          'Kontrak & Riwayat Penyerapan (${_purchaseOffers.length})',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ..._purchaseOffers.map((offer) {
          final status = (offer['status'] ?? 'OFFER_SENT').toString();
          final netPrice = _toDouble(offer['harga_tawar_bersih_per_kg']);
          final weight = _toDouble(
            offer['berat_timbang_riil_kg'] ?? offer['estimasi_berat_kg'],
          );
          final totalNilai = _toDouble(offer['total_nilai_kontrak']);
          return CustomSoftCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${offer['komoditas'] ?? 'Komoditas'} • ${weight.toStringAsFixed(0)} kg',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warningSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Harga Bersih: Rp ${_currencyFormat.format(netPrice)}/kg • Total: Rp ${_currencyFormat.format(totalNilai)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                if (offer['rincian_biaya_catatan'] != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    offer['rincian_biaya_catatan'].toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                if (status == 'ACCEPTED_CONTRACT') ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _showWeighAndPayModal(offer),
                      icon: const Icon(LucideIcons.scale, size: 14),
                      label: Text(
                        'Timbang Ulang & Bayar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
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
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showSendOfferModal(Map<String, dynamic> harvest) {
    final weightCtrl = TextEditingController(
      text: ((num.tryParse('${harvest['estimasi_berat_kg'] ?? 100}') ?? 100))
          .toStringAsFixed(0),
    );
    final marketCtrl = TextEditingController(text: '28000');
    final transportCtrl = TextEditingController(text: '1200');
    final opsCtrl = TextEditingController(text: '800');
    final noteCtrl = TextEditingController(
      text: 'Acuan harga pasar harian Sumenep dikurangi ongkos angkut & karung.',
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
        builder: (ctx, setModalState) {
          final m = double.tryParse(marketCtrl.text) ?? 0;
          final t = double.tryParse(transportCtrl.text) ?? 0;
          final o = double.tryParse(opsCtrl.text) ?? 0;
          final net = (m - t - o).clamp(0, double.infinity);

          return Padding(
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
                    'Tawaran Harga Transparan (${harvest['komoditas']})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: weightCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Estimasi Berat (kg)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: marketCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setModalState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Harga Pasar (Rp/kg)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: transportCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setModalState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Potong Transport/kg',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: opsCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setModalState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Potong Ops Lain/kg',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Harga Bersih Diterima Petani: Rp ${_currencyFormat.format(net)} / kg',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Rincian Catatan Biaya',
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
                                await _apiService.createHarvestPurchaseOffer({
                                  'harvest_report_id': harvest['id'],
                                  'farmer_id': harvest['farmer_id'],
                                  'komoditas': harvest['komoditas'],
                                  'estimasi_berat_kg':
                                      double.tryParse(weightCtrl.text) ?? 100,
                                  'harga_acuan_pasar_per_kg': m,
                                  'biaya_transport_per_kg': t,
                                  'biaya_operasional_lain_per_kg': o,
                                  'rincian_biaya_catatan': noteCtrl.text.trim(),
                                  'mode': 'OFFER_SENT',
                                });
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadCatalog();
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
                        sending ? 'Mengirim...' : 'Kirim Tawaran ke Petani',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
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

  void _showWalkInPurchaseModal() {
    final nameCtrl = TextEditingController();
    final komCtrl = TextEditingController(text: 'Bawang Merah');
    final weightCtrl = TextEditingController(text: '120');
    final priceCtrl = TextEditingController(text: '25000');
    bool saving = false;

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
                'Pembelian Petani Tradisional (Walk-in)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Petani Walk-in',
                  hintText: 'Contoh: Pak Matrawi (Desa Dungkek)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
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
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Berat Riil (kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Beli Sepakat (Rp/kg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          setModalState(() => saving = true);
                          try {
                            await _apiService.createHarvestPurchaseOffer({
                              'nama_petani_walkin': nameCtrl.text.trim(),
                              'komoditas': komCtrl.text.trim(),
                              'estimasi_berat_kg':
                                  double.tryParse(weightCtrl.text) ?? 50,
                              'harga_acuan_pasar_per_kg':
                                  double.tryParse(priceCtrl.text) ?? 20000,
                              'mode': 'TRADITIONAL_WALKIN',
                              'add_to_catalog_stock': true,
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadCatalog();
                          } catch (_) {
                            setModalState(() => saving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    saving ? 'Menyimpan...' : 'Catat & Tambah ke Stok Toko',
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

  void _showWeighAndPayModal(Map<String, dynamic> offer) {
    final weightCtrl = TextEditingController(
      text: ((num.tryParse('${offer['estimasi_berat_kg'] ?? 100}') ?? 100))
          .toStringAsFixed(0),
    );
    bool saving = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Konfirmasi Timbang Ulang & Bayar'),
          content: TextField(
            controller: weightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Berat Timbangan Riil di Lokasi (kg)',
              border: OutlineInputBorder(),
            ),
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
                      final w = double.tryParse(weightCtrl.text) ?? 0;
                      if (w <= 0) return;
                      setDlgState(() => saving = true);
                      try {
                        await _apiService.weighAndPayHarvestOffer(
                          offer['id'].toString(),
                          w,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadCatalog();
                      } catch (_) {
                        setDlgState(() => saving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(saving ? 'Memproses...' : 'Selesaikan Bayar'),
            ),
          ],
        ),
      ),
    );
  }
}
