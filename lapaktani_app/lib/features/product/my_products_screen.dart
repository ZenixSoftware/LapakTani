import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/api_service.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  bool _isStoreOpen = true;
  int _selectedChipIndex = 0;

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

      // Default sample items for high-fidelity demonstration
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
              backgroundColor: const Color(0xFF03AC0E),
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
            backgroundColor: const Color(0xFF03AC0E),
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
          onPressed: () => Navigator.pop(context),
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
              'Pesanan & Produk Saya',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF121C2A),
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell, color: Color(0xFF64748B), size: 20),
                onPressed: () {},
              ),
              Positioned(
                top: 11,
                right: 11,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBA1A1A),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
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
              child: CircularProgressIndicator(color: Color(0xFF03AC0E)),
            )
          : RefreshIndicator(
              color: const Color(0xFF03AC0E),
              onRefresh: fetchFarmerProducts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStoreHeaderCard(),
                    const SizedBox(height: 14),
                    _buildFarmerWalletCard(),
                    const SizedBox(height: 14),
                    _buildFilterChips(),
                    const SizedBox(height: 14),
                    _buildUrgencyNoticeBanner(),
                    const SizedBox(height: 16),
                    _buildIncomingOrdersSection(),
                    const SizedBox(height: 18),
                    _buildEtalaseSection(),
                    const SizedBox(height: 16),
                    _buildFieldPickupBanner(),
                    const SizedBox(height: 80), // Padding for FloatingActionButton
                  ],
                ),
              ),
            ),
    );
  }

  /// 1. Store Profile & Status Bar Card matching Stitch HTML:
  /// bg-surface-container-lowest p-space-md rounded-xl shadow-sm
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
                        color: const Color(0xFF03AC0E),
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
          // Interactive Toggle Status Button
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

  /// 2. Farmer Wallet & Performance Summary (Gradient Green Card) matching Stitch HTML:
  /// bg-gradient-to-br from-secondary to-on-secondary-fixed-variant text-on-secondary rounded-xl p-space-lg
  Widget _buildFarmerWalletCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF084E33), Color(0xFF0D5136)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2B084E33),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SALDO PENGHASILAN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: const Color(0xFF95D4B0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp 2.450.000',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF03AC0E),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(LucideIcons.wallet, size: 16),
                label: Text(
                  'Tarik Saldo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 3-column stats divider grid
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '3',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF76FF64),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pesanan Baru',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: const Color(0xFFD0DBED),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2)),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_products.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFB0F1CB),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Komoditas Aktif',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: const Color(0xFFD0DBED),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2)),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '100%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFFDEA8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Terkirim Segar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: const Color(0xFFD0DBED),
                        ),
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

  /// 3. Segment Filter Chips matching Stitch HTML:
  /// flex gap-space-sm overflow-x-auto
  Widget _buildFilterChips() {
    final chips = [
      {'label': 'Semua (8)', 'badge': null},
      {'label': 'Perlu Diproses', 'badge': '3'},
      {'label': 'Siap Dikirim', 'badge': '2'},
      {'label': 'Selesai (3)', 'badge': null},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(chips.length, (index) {
          final isSelected = _selectedChipIndex == index;
          final item = chips[index];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedChipIndex = index);
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF006E04) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF3E4A39),
                      ),
                    ),
                    if (item['badge'] != null) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : const Color(0xFFBA1A1A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item['badge'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? const Color(0xFF006E04) : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 4. Urgency Notice Banner matching Stitch HTML:
  /// bg-tertiary-fixed/30 text-on-tertiary-fixed rounded-xl p-space-md
  Widget _buildUrgencyNoticeBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.alarmClock, size: 20, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: 'Batas Petik & Serah Kurir: 10.00 WIB ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF92400E),
                ),
                children: [
                  TextSpan(
                    text: 'untuk menjaga garansi kesegaran daun dan buah di konsumen.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFB45309),
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

  /// 5. Section: Pesanan Masuk Terbaru matching Stitch HTML:
  /// Order Card 1 (#TANI-89211) & Order Card 2 (#TANI-89204)
  Widget _buildIncomingOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.checkSquare, size: 18, color: Color(0xFF006E04)),
                const SizedBox(width: 6),
                Text(
                  'Pesanan Masuk Terbaru',
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
                color: const Color(0xFFB0F1CB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '3 Perlu Dipetik',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF005302),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Order Card 1: #TANI-89211
        _buildOrderCard(
          orderId: '#TANI-89211',
          timeAgo: '15 menit lalu',
          badgeText: 'LapakPay (Lunas)',
          badgeColor: const Color(0xFFB0F1CB),
          badgeTextColor: const Color(0xFF005302),
          buyerName: 'Ibu Ratna Dewi • Lembang',
          courier: 'Kurir Instan (Motor)',
          courierIcon: LucideIcons.bike,
          items: const [
            {'title': 'Tomat Merah Segar Organik', 'qty': 'x2 kg', 'price': 'Rp 24.000'},
            {'title': 'Kangkung Organik Segar', 'qty': 'x3 ikat', 'price': 'Rp 18.000'},
          ],
          totalPrice: 'Rp 42.000',
          secondaryActionText: 'Chat',
          primaryActionText: 'Petik & Siapkan',
        ),
        const SizedBox(height: 12),
        // Order Card 2: #TANI-89204
        _buildOrderCard(
          orderId: '#TANI-89204',
          timeAgo: '1 jam lalu',
          badgeText: 'COD (Tunai)',
          badgeColor: const Color(0xFFFFDEA8),
          badgeTextColor: const Color(0xFF5E4200),
          buyerName: 'Resto Sambal Cobek • Bandung',
          courier: 'Kargo Pendingin Mitra',
          courierIcon: LucideIcons.truck,
          items: const [
            {'title': 'Kentang Dieng Super', 'qty': 'x5 kg', 'price': 'Rp 80.000'},
          ],
          totalPrice: 'Rp 80.000',
          secondaryActionText: 'Rincian',
          primaryActionText: 'Siapkan',
        ),
      ],
    );
  }

  Widget _buildOrderCard({
    required String orderId,
    required String timeAgo,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String buyerName,
    required String courier,
    required IconData courierIcon,
    required List<Map<String, String>> items,
    required String totalPrice,
    required String secondaryActionText,
    required String primaryActionText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderId,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121C2A),
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.checkCircle2, size: 12, color: badgeTextColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Buyer Info Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(courierIcon, size: 18, color: const Color(0xFF2C694C)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buyerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF121C2A),
                        ),
                      ),
                      Text(
                        courier,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Items Mini List
          Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF03AC0E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item['title']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF121C2A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item['qty']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      item['price']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF121C2A),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          // Total & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Belanja',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    totalPrice,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF006E04),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      backgroundColor: const Color(0xFFF8F9FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: Text(
                      secondaryActionText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03AC0E),
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: Text(
                      primaryActionText,
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
    );
  }

  /// 6. Section: Komoditas di Etalase matching Stitch HTML:
  /// Item Card with image, title, price, stock, edit & delete buttons
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
            final stock = item['stock_kg'] ?? item['stock'] ?? 0;
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
                        Row(
                          children: [
                            Text(
                              'Stok: ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '$stock $stockUnit',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF121C2A),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Tersedia',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF006E04),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                            color: const Color(0xFFFFDAD6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFBA1A1A)),
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

  /// 7. Bantuan Armada Penjemputan Banner matching Stitch HTML:
  /// bg-surface-container-low rounded-xl p-space-md flex items-center gap-space-md
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
