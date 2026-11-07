import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_soft_card.dart';
import '../../buyer/screens/wholesale_detail_screen.dart';
import '../../cart/cart_screen.dart';
import '../../product/product_detail_screen.dart';

class StoreProfileScreen extends StatefulWidget {
  final String storeName;
  final String? location;
  final String? avatarUrl;
  final String? bannerUrl;

  const StoreProfileScreen({
    super.key,
    this.storeName = 'Mitra Tani Makmur',
    this.location = 'Desa Lembang, Kab. Bandung Barat',
    this.avatarUrl,
    this.bannerUrl,
  });

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');

  late TabController _tabController;
  bool _isFollowing = false;
  bool _isLoading = true;

  List<dynamic> _retailProducts = [];
  List<Map<String, dynamic>> _wholesalePools = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStoreData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
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
                  'id': 'prod-tomat-01',
                  'title': 'Tomat Merah Segar Lembang 1 Kg',
                  'price_per_kg': 12000,
                  'stock_kg': 150,
                  'image_url': 'uploads/products/tomat.jpg',
                  'category': 'Sayur Buah',
                  'grade': 'Grade A',
                  'village_name': 'Lembang',
                  'poktan_name': widget.storeName,
                },
                {
                  'id': 'prod-cabai-01',
                  'title': 'Cabai Rawit Merah Super 1 Kg',
                  'price_per_kg': 35000,
                  'stock_kg': 85,
                  'image_url': 'uploads/products/cabai.jpg',
                  'category': 'Rempah & Bumbu',
                  'grade': 'Grade A',
                  'village_name': 'Lembang',
                  'poktan_name': widget.storeName,
                },
                {
                  'id': 'prod-kentang-01',
                  'title': 'Kentang Dieng Super Grade A',
                  'price_per_kg': 16000,
                  'stock_kg': 200,
                  'image_url': 'uploads/products/kentang.jpg',
                  'category': 'Umbi-umbian',
                  'grade': 'Grade A',
                  'village_name': 'Lembang',
                  'poktan_name': widget.storeName,
                },
                {
                  'id': 'prod-kangkung-01',
                  'title': 'Kangkung Organik Hidroponik 1 Kg',
                  'price_per_kg': 6000,
                  'stock_kg': 120,
                  'image_url': 'uploads/products/kangkung.jpg',
                  'category': 'Sayur Daun',
                  'grade': 'Grade A',
                  'village_name': 'Lembang',
                  'poktan_name': widget.storeName,
                },
              ];

        _wholesalePools = pools.isNotEmpty
            ? pools
            : [
                {
                  'id': 'pool-01',
                  'mitra_name': widget.storeName,
                  'commodity_name': 'Cabai Merah Keriting Super',
                  'variety': 'Kencana Tropis',
                  'grade': 'Grade A Super',
                  'image_url': 'uploads/products/cabai.jpg',
                  'min_order_kg': 50.0,
                  'target_harvest_date': '15 Nov 2026',
                  'total_quota_kg': 350.0,
                  'remaining_quota_kg': 50.0,
                  'price_per_kg': 28000.0,
                  'status': 'open',
                },
                {
                  'id': 'pool-02',
                  'mitra_name': widget.storeName,
                  'commodity_name': 'Tomat Beef Dataran Tinggi',
                  'variety': 'Beef Lembang Super',
                  'grade': 'Grade A Super',
                  'image_url': 'uploads/products/tomat.jpg',
                  'min_order_kg': 40.0,
                  'target_harvest_date': '20 Nov 2026',
                  'total_quota_kg': 500.0,
                  'remaining_quota_kg': 300.0,
                  'price_per_kg': 12500.0,
                  'status': 'open',
                },
              ];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              backgroundColor: const Color(0xFF006E04),
              foregroundColor: Colors.white,
              title: innerBoxIsScrolled
                  ? Text(
                      widget.storeName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    )
                  : null,
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.shoppingBag, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(LucideIcons.share2, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tautan toko Mitra Tani disalin ke clipboard!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background gradient cover
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF004D02), Color(0xFF006E04), Color(0xFF028708)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Pattern overlay
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.08,
                        child: Image.network(
                          'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=1200&q=80',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                        ),
                      ),
                    ),
                    // Store Details Overlay
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x2A000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    LucideIcons.store,
                                    size: 28,
                                    color: Color(0xFF006E04),
                                  ),
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
                                            widget.storeName,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          LucideIcons.badgeCheck,
                                          size: 18,
                                          color: Color(0xFF68D391),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(
                                          LucideIcons.mapPin,
                                          size: 13,
                                          color: Color(0xFFD1FAE5),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            widget.location ?? 'Lembang, Jawa Barat',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: const Color(0xFFD1FAE5),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => _isFollowing = !_isFollowing);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _isFollowing
                                            ? 'Anda kini mengikuti ${widget.storeName}'
                                            : 'Berhenti mengikuti toko',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFollowing
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.white,
                                  foregroundColor: _isFollowing
                                      ? Colors.white
                                      : const Color(0xFF006E04),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: _isFollowing
                                        ? const BorderSide(color: Colors.white)
                                        : BorderSide.none,
                                  ),
                                ),
                                child: Text(
                                  _isFollowing ? 'Mengikuti' : '+ Ikuti',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Stats banner row
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem('Rating', '4.9 ★', LucideIcons.star),
                                _buildStatDivider(),
                                _buildStatItem('Lahan Binaan', '11.10 Ha', LucideIcons.sprout),
                                _buildStatDivider(),
                                _buildStatItem('Anggota', '42 Petani', LucideIcons.users),
                                _buildStatDivider(),
                                _buildStatItem('Performa', '99%', LucideIcons.checkCircle2),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF006E04),
                    indicatorWeight: 3,
                    labelColor: const Color(0xFF006E04),
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'Produk Retail'),
                      Tab(text: 'Penawaran Partai (B2B)'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildRetailGrid(),
                  _buildWholesaleList(),
                ],
              ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: const Color(0xFFD1FAE5),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 22,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget _buildRetailGrid() {
    if (_retailProducts.isEmpty) {
      return Center(
        child: Text(
          'Belum ada produk retail yang ditawarkan.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _retailProducts.length,
      itemBuilder: (context, index) {
        final product = _retailProducts[index];
        final String title = product['title']?.toString() ?? 'Komoditas Segar';
        final num price = (product['price_per_kg'] as num?) ?? (product['price'] as num?) ?? 0;
        final num stock = (product['stock_kg'] as num?) ?? (product['stock'] as num?) ?? 0;
        final String grade = product['grade']?.toString() ?? 'Grade A';
        final String rawImg = product['image_url']?.toString() ?? '';
        final String imageUrl = _resolveImageUrl(rawImg);

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: AspectRatio(
                        aspectRatio: 1.1,
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
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006E04),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          grade,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rp ${_currencyFormat.format(price)} / kg',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF006E04),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stok: ${stock.toStringAsFixed(0)} kg',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWholesaleList() {
    if (_wholesalePools.isEmpty) {
      return Center(
        child: Text(
          'Belum ada bursa penawaran partai aktif dari mitra ini.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _wholesalePools.length,
      itemBuilder: (context, index) {
        final pool = _wholesalePools[index];
        final String commodity = pool['commodity_name'] ?? 'Komoditas Partai';
        final double totalKg = (pool['total_quota_kg'] as num?)?.toDouble() ?? 100.0;
        final double remainingKg = (pool['remaining_quota_kg'] as num?)?.toDouble() ?? 50.0;
        final double takenKg = (totalKg - remainingKg).clamp(0.0, totalKg);
        final double progress = totalKg > 0 ? (takenKg / totalKg).clamp(0.0, 1.0) : 0.0;
        final double priceKg = (pool['price_per_kg'] as num?)?.toDouble() ?? 0.0;
        final double minOrder = (pool['min_order_kg'] as num?)?.toDouble() ?? 50.0;
        final String harvestDate = pool['target_harvest_date'] ?? pool['est_harvest_date'] ?? '15 Nov 2026';
        final String grade = pool['grade'] ?? 'Grade A Super';
        final String rawImg = pool['image_url']?.toString() ?? '';
        final String imageUrl = _resolveImageUrl(rawImg);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WholesaleDetailScreen(pool: pool),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: CustomSoftCard(
              padding: const EdgeInsets.all(14),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: const Color(0xFFDCFCE7),
                                    child: const Icon(LucideIcons.package, color: AppColors.primary),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFFDCFCE7),
                                  child: const Icon(LucideIcons.package, color: AppColors.primary),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                grade,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              commodity,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${_currencyFormat.format(priceKg)} / kg',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF006E04),
                              ),
                            ),
                            Text(
                              'Min. Pesanan ${minOrder.toStringAsFixed(0)} kg',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Terserap: ${_currencyFormat.format(takenKg)} / ${_currencyFormat.format(totalKg)} kg',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Sisa: ${_currencyFormat.format(remainingKg)} kg',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        'Estimasi Panen: $harvestDate',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Lihat Detail →',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF006E04),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
