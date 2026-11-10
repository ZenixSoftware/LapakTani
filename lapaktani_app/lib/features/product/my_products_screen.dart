import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'services/stock_service.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  bool _isStoreOpen = true;

  static const String _defaultFarmerPhoto =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAYrwsStPtJO0HY3riSclVguw_MiWyGVUOPRq6V2x2AvRBOV23WSDcAoPzLzcgxxE5Wtphh-B0fFcCi4aTOKKIsugJWJdun-0DVQIRzl9AXagHxbikg9K-1RTtOvK9PWMGUgp6idMuAqdvtpEs-QyVSNbSKNdCPTDsNzFt0elDVrLQnQUkeJudRuyjAlxkpV6Ze0ktgemZY0yFM6gD6yT0wHVhGlcMhrm5XHHxq76T00jr2cr8VL1E1';

  static final List<Map<String, dynamic>> _sampleEtalaseProducts = [
    {
      'id': 'demo-1',
      'title': 'Kangkung Organik',
      'price_per_kg': 6000,
      'unit': '/ikat',
      'stock_kg': 25,
      'stock_unit': 'ikat',
      'image_url':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB3rIVPKLxodKJWCW67zwoXJ7y_XenPDHJ9mmfo2U6SPDgGFJHw_R7Za0jp0ub32XtO1aXBqjSWhUmY217DvzoS5E6ARs_khbupcV_U5ebI-JiuLaNjPEOB-pMYyP5YjbW4KNUSQll2wvRhdQNmz75Mf2oWjyj76aPIEOG-m3uJVawoOhyJ2KVRD9OSKpNIGDgjALOLtraj1cQXqzF9ErzSEQNuWT8xtlnFrgBdpWK_Z7Un2MyC9FGl',
    },
    {
      'id': 'demo-2',
      'title': 'Tomat Merah Segar',
      'price_per_kg': 12000,
      'unit': '/kg',
      'stock_kg': 150,
      'stock_unit': 'kg',
      'image_url':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBGTZJ8WQsuQ0O8R17YnJd-vxNVtpzMkVt13qTW5ZcD1TXBbeZY4G4R6l2PERAlMtyErdA8vKC5_27q9iG4gKLI5kaXpPsY26wnGH3-8Wxv3JihU6grikvp6R4HmdVvIgassZ_gFW-C9jT5p8-YE9bsl6MbidBt5ZzUl038HKoWSS8UFfT9OGwsFvTt3p9pwydzWsdoxzla45PwxuPkTnnlada5VKgueyrJ_ux9sricRwDDxIB-2taa',
    },
    {
      'id': 'demo-3',
      'title': 'Kentang Dieng Super',
      'price_per_kg': 16000,
      'unit': '/kg',
      'stock_kg': 80,
      'stock_unit': 'kg',
      'image_url':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDdKQWpRsBToPR3bdv00NLjc0iYWXwwhxjN5CuPLMW3l96FGg2J9suFVFegVM9j3kG4V5NF6CQbPyGcF0QJSInzbD84CDL07t6qEekSWmSliorbGwYOiv8C8oeoyDvoavlEjJNaJRXvk8uoq13kFhFNMt30v4CAOd--ZlUsf58fQPmAYMw5LXb4lfroed89K54uNJQFHlY9rNXmdmFOobmGnuzSxOxlf8lzcrE_lyFBADKVir-Q_zH7',
    },
  ];

  @override
  void initState() {
    super.initState();
    StockService().init();
    fetchFarmerProducts();
  }

  Future<void> fetchFarmerProducts() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get('/products/me');
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);
        if (body is Map && body['data'] is List && (body['data'] as List).isNotEmpty) {
          setState(() {
            _products = body['data'] as List<dynamic>;
          });
          return;
        }
      }

      final fallback = await ApiService.get('/products');
      if (fallback.statusCode == 200) {
        final dynamic body = jsonDecode(fallback.body);
        if (body is Map && body['data'] is List && (body['data'] as List).isNotEmpty) {
          setState(() {
            _products = body['data'] as List<dynamic>;
          });
          return;
        }
      }

      setState(() {
        _products = List.from(_sampleEtalaseProducts);
      });
    } catch (_) {
      setState(() {
        _products = List.from(_sampleEtalaseProducts);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showQuickStockDialog(String id, String title, int currentStock) {
    final controller = TextEditingController(text: currentStock.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Atur Stok Komoditas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF121C2A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF121C2A),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Jumlah Stok Tersedia',
                hintText: 'Misal: 50',
                suffixText: 'kg',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stok berkurang otomatis saat pembeli membuat pesanan dan bertambah jika pesanan dibatalkan.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(controller.text) ?? currentStock;
              await StockService().updateStock(id, val);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Stok $title berhasil disesuaikan menjadi $val kg.'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Simpan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Komoditas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF121C2A),
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "$title" dari etalase LapakTani?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (id.startsWith('demo-')) {
        setState(() {
          _products.removeWhere((p) => p['id'] == id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Komoditas "$title" berhasil dihapus.'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final response = await ApiService.delete('/products/$id');
      final dynamic body = jsonDecode(response.body);

      if (response.statusCode == 200 || (body is Map && body['success'] == true)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Komoditas "$title" berhasil dihapus.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        fetchFarmerProducts();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kendala jaringan: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatRupiah(dynamic price) {
    if (price == null) return '0';
    final parsed = double.tryParse(price.toString()) ?? 0;
    final intPrice = parsed.toInt();
    final str = intPrice.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF121C2A), size: 22),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.sprout, color: Color(0xFF006E04), size: 14),
                const SizedBox(width: 4),
                Text(
                  'KEBUN MANIK SARI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFF2C694C),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB0F1CB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Mitra',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF327052),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              'Katalog Produk Saya',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF121C2A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, color: Color(0xFF64748B), size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings, color: Color(0xFF64748B), size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProductScreen(),
            ),
          );
          if (result == true) {
            fetchFarmerProducts();
          }
        },
        backgroundColor: const Color(0xFF006E04),
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(LucideIcons.plus, size: 28),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: fetchFarmerProducts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStoreHeaderCard(),
                    const SizedBox(height: 14),
                    _buildEtalaseSection(),
                    const SizedBox(height: 16),
                    _buildFieldPickupBanner(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStoreHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: NetworkImage(_defaultFarmerPhoto),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: const Color(0xFFD1F2D6), width: 1.5),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF006E04),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.check, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Kebun Manik Sari',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121C2A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Pro',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 13, color: Color(0xFF6D7B67)),
                    const SizedBox(width: 3),
                    Text(
                      'Lembang, Bandung Barat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _isStoreOpen = !_isStoreOpen;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isStoreOpen ? const Color(0xFFB0F1CB) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _isStoreOpen ? const Color(0xFF006E04) : const Color(0xFF64748B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isStoreOpen ? 'Buka' : 'Tutup',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _isStoreOpen ? const Color(0xFF002113) : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtalaseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Komoditas di Etalase',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF121C2A),
                  ),
                ),
                Text(
                  '${_products.length} komoditas aktif panen hari ini',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
                if (result == true) fetchFarmerProducts();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFB0F1CB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.plusCircle, size: 14, color: Color(0xFF005302)),
                    const SizedBox(width: 4),
                    Text(
                      '+ Tambah Komoditas Panen',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF005302),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: _products.map((item) {
            final id = (item['id'] ?? '').toString();
            final title = (item['title'] ?? item['name'] ?? 'Komoditas').toString();
            final price = item['price_per_kg'] ?? item['price'] ?? 0;
            final unit = (item['unit'] ?? '/kg').toString();
            final stockUnit = (item['stock_unit'] ?? 'kg').toString();
            final imageUrl = (item['image_url'] ?? '').toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFFF1F5F9),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                LucideIcons.image,
                                color: Color(0xFF94A3B8),
                                size: 24,
                              ),
                            )
                          : const Icon(
                              LucideIcons.image,
                              color: Color(0xFF94A3B8),
                              size: 24,
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
                            color: const Color(0xFF121C2A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Rp ${_formatRupiah(price)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF006E04),
                              ),
                            ),
                            Text(
                              unit.startsWith('/') ? unit : '/$unit',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        ValueListenableBuilder<Map<String, int>>(
                          valueListenable: StockService().stockNotifier,
                          builder: (context, stockMap, _) {
                            final rawStock = item['stock_kg'] ?? item['stock'] ?? 0;
                            final fallbackStock = (rawStock is num) ? rawStock.toInt() : 0;
                            final liveStock = stockMap[id] ?? fallbackStock;
                            final bool isOutOfStock = liveStock <= 0;
                            final bool isLowStock = liveStock > 0 && liveStock <= 10;

                            final Color statusColor = isOutOfStock
                                ? const Color(0xFFEF4444)
                                : isLowStock
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF006E04);
                            final String statusText = isOutOfStock
                                ? 'Stok Habis'
                                : isLowStock
                                    ? 'Stok Menipis'
                                    : 'Tersedia';

                            return Row(
                              children: [
                                Text(
                                  'Stok: ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  '$liveStock $stockUnit',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isOutOfStock
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF121C2A),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          final rawStock = item['stock_kg'] ?? item['stock'] ?? 0;
                          final fallbackStock = (rawStock is num) ? rawStock.toInt() : 0;
                          final liveStock = StockService().getStock(id, fallback: fallbackStock);
                          _showQuickStockDialog(id, title, liveStock);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.packagePlus, size: 16, color: Color(0xFF006E04)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProductScreen(product: item),
                            ),
                          );
                          if (result == true) fetchFarmerProducts();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.edit2, size: 16, color: Color(0xFF475569)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _deleteProduct(id, title),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFEF4444)),
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
    );
  }

  Widget _buildFieldPickupBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFB0F1CB),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.headphones, color: Color(0xFF005302), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bantuan Armada Penjemputan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF121C2A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Perlu pikap logistik dingin untuk hasil tani >50kg? Hubungi Tim Lapangan LapakTani Lembang.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006E04),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Hubungi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
