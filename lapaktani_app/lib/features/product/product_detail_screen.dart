import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../cart/cart_screen.dart';
import '../orders/models/order_model.dart';
import '../orders/services/order_service.dart';
import '../orders/screens/order_tracking_screen.dart';
import 'services/stock_service.dart';
import 'widgets/soil_telemetry_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final dynamic product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isWishlisted = false;
  bool _isFollowingShop = false;
  bool _isDescriptionExpanded = false;
  int _cartItemCount = 4;

  @override
  void initState() {
    super.initState();
    StockService().init();
  }

  Map<String, dynamic> get _data {
    if (widget.product is Map) {
      return Map<String, dynamic>.from(widget.product as Map);
    }
    return <String, dynamic>{};
  }

  String get _productId {
    final raw = _data['id']?.toString().trim();
    return (raw != null && raw.isNotEmpty && !raw.startsWith('demo-')) ? raw : '';
  }

  int get _currentStock {
    final raw = _data['stock_kg'] ?? _data['stock'] ?? 50;
    final fallback = (raw is num) ? raw.toInt() : int.tryParse(raw.toString()) ?? 50;
    return StockService().getStock(_productId, fallback: fallback);
  }

  String _formatRupiah(dynamic price) {
    if (price == null) return 'Rp0';
    final num? val = num.tryParse(price.toString());
    if (val == null) {
      final s = price.toString().trim();
      return s.startsWith('Rp') ? s : 'Rp$s';
    }
    final int intVal = val.round();
    final String strVal = intVal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < strVal.length; i++) {
      if (i > 0 && (strVal.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(strVal[i]);
    }
    return 'Rp${buffer.toString()}';
  }

  void _handleAddToCart() {
    if (_productId.isEmpty || _productId.startsWith('mock-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Komoditas tidak valid atau belum terdaftar di sistem.',
            style: GoogleFonts.inter(fontSize: 12),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_currentStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maaf, stok komoditas ini telah habis.',
            style: GoogleFonts.inter(fontSize: 12),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _cartItemCount++;
    });
    ApiService().addToCart(productId: _productId, quantity: 1).catchError((err) {
      debugPrint('[CART] Gagal menambahkan ke keranjang: $err');
      return false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ditambahkan ke keranjang',
          style: GoogleFonts.inter(fontSize: 12),
        ),
        backgroundColor: const Color(0xFF03AC0E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleBuyNow() {
    if (_currentStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maaf, komoditas ini sedang habis stok dan tidak dapat dipesan.',
            style: GoogleFonts.inter(fontSize: 12),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Beli Langsung',
                      style: GoogleFonts.inter(
                        fontSize: 16,
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 64,
                        height: 64,
                        color: const Color(0xFFF1F5F9),
                        child: _buildNetworkImage(_data['image_url'] ?? _data['imageUrl'] ?? ''),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _data['title']?.toString() ?? 'Komoditas Segar',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatRupiah(_data['price_per_kg'] ?? _data['price'] ?? 15000),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFE11D48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final title = _data['title']?.toString() ?? 'Produk Tani Segar';
                      final priceNum = _data['price_per_kg'] ?? _data['price'] ?? 15000;
                      final price = priceNum is num ? priceNum.toInt() : 15000;
                      final image = _data['image_url']?.toString() ?? '';
                      final grade = _data['grade']?.toString() ?? 'Grade A';

                      final newOrder = await OrderService().createNewOrder(
                        buyerName: 'Ibu Ratna Dewi',
                        buyerAddress: 'Jl. Maribaya No. 42, Lembang, Kab. Bandung Barat',
                        buyerPhone: '0813-2940-1182',
                        items: [
                          OrderItem(
                            id: 'item-${DateTime.now().millisecondsSinceEpoch}',
                            productId: _productId,
                            title: title,
                            qty: 1,
                            unit: 'kg',
                            price: price,
                            imageUrl: image,
                            grade: grade,
                          ),
                        ],
                        totalPrice: price,
                        shippingFee: 8000,
                        paymentMethod: 'LapakPay (Saldo Terpotong)',
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Pesanan ${newOrder.id} berhasil dibuat.'),
                            backgroundColor: const Color(0xFF03AC0E),
                            behavior: SnackBarBehavior.floating,
                            action: SnackBarAction(
                              label: 'Lacak Logistik',
                              textColor: Colors.white,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderTrackingScreen(orderId: newOrder.id),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03AC0E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Lanjut ke Pembayaran',
                      style: GoogleFonts.inter(
                        fontSize: 14,
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
    );
  }

  Widget _buildNetworkImage(String url) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFE2E8F0),
        child: const Icon(LucideIcons.image, size: 28, color: Color(0xFF94A3B8)),
      );
    }
    final resolvedUrl = url.startsWith('http')
        ? url
        : '${ApiService.baseUrl.replaceAll('/api', '')}/${url.startsWith('/') ? url.substring(1) : url}';

    return Image.network(
      resolvedUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFE2E8F0),
        child: const Icon(LucideIcons.image, size: 28, color: Color(0xFF94A3B8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _data['title']?.toString() ?? 'Tomat Merah Segar Organik (Petik Subuh Lembang)';
    final rawPrice = _data['price_per_kg'] ?? _data['price'] ?? 12000;
    final priceStr = _formatRupiah(rawPrice);
    final num numericPrice = num.tryParse(rawPrice.toString()) ?? 12000;
    final strikethroughPriceStr = _formatRupiah((numericPrice * 1.25).round());
    final unit = _data['unit_name']?.toString() ?? _data['unit']?.toString() ?? '/kg';
    final location = _data['village_name']?.toString() ?? _data['location']?.toString() ?? 'Lembang, Bandung Barat';
    final poktan = _data['poktan_name']?.toString() ??
        _data['farm_name']?.toString() ??
        _data['merchant_name']?.toString() ??
        'Poktan Manik Sari';
    final grade = _data['grade_label']?.toString() ?? _data['grade']?.toString() ?? 'Grade A (Super)';
    final category = _data['category']?.toString() ?? 'Sayuran Segar Organik';
    final imageUrl = _data['image_url']?.toString() ?? _data['imageUrl']?.toString() ?? '';
    final defaultDesc =
        'Tomat merah segar organik dipanen langsung dari ladang pegunungan di pagi hari. Memiliki tekstur padat, kaya antioksidan likopen, rasa manis-asam seimbang, dan bebas pestisida kimia sintetis.';
    final description = _data['description']?.toString() ?? defaultDesc;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.interTextTheme(),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildStickyTopBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroProductImage(imageUrl),
                    _buildFreshnessStripBanner(),
                    _buildPriceAndBenefitsBlock(
                      priceStr: priceStr,
                      strikethroughPriceStr: strikethroughPriceStr,
                      unit: unit,
                      title: title,
                      grade: grade,
                      poktan: poktan,
                    ),
                    _buildSectionDivider(),
                    _buildReviewsSection(),
                    _buildSectionDivider(),
                    _buildMerchantCard(location),
                    _buildSectionDivider(),
                    _buildSpecsAndDescriptionSection(
                      category: category,
                      location: location,
                      poktan: poktan,
                      grade: grade,
                      description: description,
                    ),
                    _buildSectionDivider(),
                    SoilTelemetryCard(productId: _productId),
                    _buildSectionDivider(),
                    _buildMoreFromShopSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildStickyBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyTopBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  child: const Icon(
                    LucideIcons.arrowLeft,
                    size: 20,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.search,
                        size: 15,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cari di LapakTani...',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _buildTopBarIconButton(
                icon: LucideIcons.share2,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tautan produk berhasil disalin.'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildTopBarIconButton(
                icon: LucideIcons.shoppingCart,
                badgeText: '$_cartItemCount',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CartScreen(),
                    ),
                  );
                },
              ),
              _buildTopBarIconButton(
                icon: LucideIcons.moreVertical,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Menu opsi produk.'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF334155),
            ),
            if (badgeText != null)
              Positioned(
                top: -3,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 15,
                    minHeight: 13,
                  ),
                  child: Center(
                    child: Text(
                      badgeText,
                      style: GoogleFonts.inter(
                        fontSize: 8.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroProductImage(String imageUrl) {
    return AspectRatio(
      aspectRatio: 1.05,
      child: Stack(
        children: [
          Positioned.fill(
            child: _buildNetworkImage(imageUrl),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF34D399),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Panen Subuh Tadi (05.00 WIB)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '1/5',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreshnessStripBanner() {
    return Container(
      color: const Color(0xFF03AC0E),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildBannerFeatureItem(
              title: 'Panen Subuh Tadi',
              subtitle: 'Petik jam 05.00 WIB',
            ),
          ),
          Container(
            width: 1,
            height: 26,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          Expanded(
            child: _buildBannerFeatureItem(
              title: '100% Organik',
              subtitle: 'Bebas residu pestisida',
            ),
          ),
          Container(
            width: 1,
            height: 26,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          Expanded(
            child: _buildBannerFeatureItem(
              title: 'Garansi 2 Jam',
              subtitle: 'Ganti baru jika layu',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerFeatureItem({
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 9.0,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceAndBenefitsBlock({
    required String priceStr,
    required String strikethroughPriceStr,
    required String unit,
    required String title,
    required String grade,
    required String poktan,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                priceStr,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFE11D48),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                strikethroughPriceStr,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '-20%',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFE11D48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPromoBadge('Diskon 8% (Rp1.000)'),
                const SizedBox(width: 6),
                _buildPromoBadge('Bonus 1% Koin Tani'),
                const SizedBox(width: 6),
                _buildPromoBadge('Bebas Ongkir min 30rb >'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: LucideIcons.coins,
            iconColor: const Color(0xFFD97706),
            text: 'Lebih hemat s.d. 3% pakai Koin LapakTani di checkout',
          ),
          _buildInfoRow(
            icon: LucideIcons.creditCard,
            iconColor: const Color(0xFF475569),
            text: 'Bayar di Tempat (COD) / LapakPayLater',
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF03AC0E),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.check, size: 10, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                'Mitra Official',
                                style: GoogleFonts.inter(
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ValueListenableBuilder<Map<String, int>>(
                          valueListenable: StockService().stockNotifier,
                          builder: (context, stockMap, _) {
                            final liveStock = stockMap[_productId] ?? _currentStock;
                            final bool isOut = liveStock <= 0;
                            final bool isLow = liveStock > 0 && liveStock <= 10;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOut
                                    ? const Color(0xFFFEE2E2)
                                    : isLow
                                        ? const Color(0xFFFEF3C7)
                                        : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isOut
                                      ? const Color(0xFFEF4444)
                                      : isLow
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFF03AC0E),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isOut
                                        ? LucideIcons.alertCircle
                                        : isLow
                                            ? LucideIcons.alertTriangle
                                            : LucideIcons.packageCheck,
                                    size: 11,
                                    color: isOut
                                        ? const Color(0xFFEF4444)
                                        : isLow
                                            ? const Color(0xFFB45309)
                                            : const Color(0xFF006E04),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOut
                                        ? 'Stok Habis'
                                        : isLow
                                            ? 'Sisa $liveStock kg (Stok Menipis)'
                                            : 'Stok: $liveStock kg',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: isOut
                                          ? const Color(0xFFEF4444)
                                          : isLow
                                              ? const Color(0xFFB45309)
                                              : const Color(0xFF006E04),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF4FF),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            'Grade: $grade',
                            style: GoogleFonts.inter(
                              fontSize: 9.0,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            'Asal: $poktan',
                            style: GoogleFonts.inter(
                              fontSize: 9.0,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF047857),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Varian: 1 Kg Standar',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isWishlisted = !_isWishlisted;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isWishlisted
                            ? 'Ditambahkan ke daftar favorit.'
                            : 'Dihapus dari daftar favorit.',
                      ),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    LucideIcons.heart,
                    size: 22,
                    color: _isWishlisted ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.star, size: 13, color: Color(0xFFF59E0B)),
              const SizedBox(width: 3),
              Text(
                '4.9',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(42)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 6),
              const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
              const SizedBox(width: 6),
              Text(
                '26 foto ulasan',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 6),
              const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
              const SizedBox(width: 6),
              Text(
                '350+ terjual',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.truck, size: 16, color: Color(0xFF03AC0E)),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF1E293B),
                      ),
                      children: const [
                        TextSpan(
                          text: 'Ongkir mulai dari Rp0 ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: '(Tiba 1-2 Jam Kirim Instan)',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 15, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF03AC0E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.check, size: 10, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gratis pengembalian • Pasti Segar • Penggantian 2 Jam jika layu',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 15, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE11D48),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF334155),
              ),
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      height: 8,
      color: const Color(0xFFF1F5F9),
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ulasan pembeli',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Membuka semua ulasan pembeli.'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  'Lihat semua',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF03AC0E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(LucideIcons.star, size: 13, color: Color(0xFFF59E0B)),
              const SizedBox(width: 3),
              Text(
                '4.9',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Dari 42 rating • 22 ulasan',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildReviewChip('berfungsi baik & segar (18)', true),
                const SizedBox(width: 6),
                _buildReviewChip('manis asam pas (12)', false),
                const SizedBox(width: 6),
                _buildReviewChip('packing rapi (9)', false),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (int i = 0; i < 4; i++)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildNetworkImage(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuB7MFNm6fGiAm5QTKbvDcHMQ3fNnfFYJO_Kyt9JrlLi9bdKKdnbkUUFDVEY7mCNRqoT57wyH6E0LUIC1jGc0D-kArTwJmp2e_5daQ-YOhbRz6XPP7EYvLTgq5ALb_-pvxAwxa6jFCLpDRll8ED4v4Ji4zgioDov57ptO20jhk2yg-AMXM58Y1QEp-gsPaWJsmltO5szzG6PzNOWC0-PNC7sN4gPpfDUDJMz25zaMnEVC1MiKNDOCJB_',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE2E8F0),
                ),
                child: const Icon(LucideIcons.user, size: 16, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Praditya',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '302 ulasan lengkap • 282 terbantu',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (int i = 0; i < 5; i++)
                const Icon(LucideIcons.star, size: 11, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              Text(
                '1 minggu lalu',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Paket sudah diterima sesuai pesanan dalam keadaan baik. Tomat beneran segar banget langsung petik subuh, masih ada embun dan packing daun pisang kokoh. Recommended seller!',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF334155),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewChip(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? const Color(0xFF065F46) : const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildMerchantCard(String location) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  color: Colors.white,
                ),
                child: const Icon(
                  LucideIcons.store,
                  color: Color(0xFF03AC0E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF03AC0E),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'Mitra Mall',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Kebun Manik Sari (Pak Wayan)',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isFollowingShop = !_isFollowingShop;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isFollowingShop
                            ? 'Berhasil mengikuti toko.'
                            : 'Batal mengikuti toko.',
                      ),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF03AC0E)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isFollowingShop ? 'Mengikuti' : 'Follow',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF03AC0E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.star, size: 12, color: Color(0xFFF59E0B)),
              const SizedBox(width: 3),
              Text(
                '5.0',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(4.2 rb)',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 14),
              const Icon(LucideIcons.package, size: 12, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                '48 total barang',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsAndDescriptionSection({
    required String category,
    required String location,
    required String poktan,
    required String grade,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spesifikasi Produk',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          _buildSpecRow('Grade Kualitas', grade, isGreen: true),
          _buildSpecRow('Asal Poktan/Kebun', '$poktan ($location)'),
          _buildSpecRow('Etalase Kategori', category),
          _buildSpecRow('Berat Satuan', '1 Kg'),
          _buildSpecRow('Masa Simpan', '5 - 7 Hari (Kulkas)'),
          const SizedBox(height: 12),
          Text(
            'Deskripsi',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            maxLines: _isDescriptionExpanded ? null : 3,
            overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF334155),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Text(
              _isDescriptionExpanded ? 'Tutup Deskripsi' : 'Selengkapnya',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF03AC0E),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldCheck, size: 16, color: Color(0xFF03AC0E)),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF334155),
                      ),
                      children: const [
                        TextSpan(text: 'Tambah Proteksi Kesegaran mulai '),
                        TextSpan(
                          text: 'Rp500',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(LucideIcons.alertTriangle, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                'Produk bermasalah? ',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Laporan produk telah dicatat.'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  'Laporkan',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF03AC0E),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {bool isGreen = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: isGreen ? FontWeight.w700 : FontWeight.w600,
              color: isGreen ? const Color(0xFF03AC0E) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreFromShopSection() {
    final relatedItems = [
      {
        'title': 'Beras Organik Pandan Wangi Petik Pilihan 2.5 Kg',
        'price': 'Rp45.000',
        'discount': '-8%',
        'strikethrough': 'Rp49.000',
        'sold': '128 terjual',
        'imageUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBRQxQP9qYYr3rrTap5mEm8WI56DP71TPTgvjVR47iU89uMg4X9Xv3xufzIIWAONoplIq5fPHfRjD0RKepwQC_vz-lPMF2BXJ3kcdCPFca0ula4lttZWS4R61YFhtKGL4jpfLDX8pWOw3T1UUW9VNVHb1Oe9Oxr6LIp2UkrM6OmkSO3QgK6POdI7mLyG6E5XWUW80e9yzIIZFfaPurnQuElqE7bFWXYGCOcqIKoupp2JRBiMvUIlBo2',
      },
      {
        'title': 'Kentang Granola Super Batu Malang 1 Kg',
        'price': 'Rp16.000',
        'discount': '-12%',
        'strikethrough': 'Rp18.500',
        'sold': '779 terjual',
        'imageUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDQfZ8rlRVHk2qkSfC0zsPq1XBOalKVCjz-SK27JBESez2nkF4XHUYWP-swEAKZngWukUvo9Df9G4f9trDz2JqjpoyfGClJ80yD76cURQ-33wsz7GIkmINCKucwTcWZEnF2pKg9NyLwAzB8N_BqidBu0XttzgLQW9bD7fi9kRgYANzWxfO6nmsMw7hQFcHN0cewb8hFiACXv_6zfeZxZ3i9LjW0DRx3RO8-cnPTrZIREWEzmDEUovQr',
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lainnya di toko ini',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Membuka etalase toko.'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  'Lihat semua',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF03AC0E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: relatedItems.map((item) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: item == relatedItems.first ? 8 : 0,
                  ),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: _buildNetworkImage(item['imageUrl']!),
                              ),
                              Positioned(
                                top: 3,
                                right: 3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    item['discount']!,
                                    style: GoogleFonts.inter(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['title']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['price']!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE11D48),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            item['strikethrough']!,
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              decoration: TextDecoration.lineThrough,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item['sold']!,
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Menghubungkan ke chat petani...'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Icon(
                  LucideIcons.messageSquare,
                  size: 20,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ValueListenableBuilder<Map<String, int>>(
                valueListenable: StockService().stockNotifier,
                builder: (context, stockMap, _) {
                  final liveStock = stockMap[_productId] ?? _currentStock;
                  final bool isOut = liveStock <= 0;

                  if (isOut) {
                    return SizedBox(
                      height: 44,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          'Stok Habis (Menunggu Panen)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: _handleBuyNow,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF03AC0E), width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Beli langsung',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF03AC0E),
                                  ),
                                ),
                                Text(
                                  'dengan voucher',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _handleAddToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF03AC0E),
                              foregroundColor: Colors.white,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.shoppingCart, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '+ Keranjang',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
