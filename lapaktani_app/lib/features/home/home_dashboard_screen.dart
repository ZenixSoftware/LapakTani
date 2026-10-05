import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/api_service.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentBottomNavIndex = 0;
  int _selectedCategoryTabIndex = 0;
  final Set<dynamic> _wishlistIds = {};
  int _cartItemCount = 4;
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final httpResponse = await ApiService.get('/products');
      if (httpResponse.statusCode == 200) {
        final Map<String, dynamic> response =
            jsonDecode(httpResponse.body) as Map<String, dynamic>;
        final List<dynamic> data = (response['data'] as List<dynamic>?) ?? [];
        if (mounted) {
          setState(() {
            _products = data;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('[CATALOG] Gagal memuat data produk: $e');
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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

  final List<String> _categoryTabs = [
    'Untuk Kamu',
    'Panen 10.10',
    'Petani Terpilih',
    'Sayur Daun',
    'Buah Segar',
    'Bumbu Dapur',
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {
      'id': 'langganan',
      'title': 'Langganan PLUS',
      'colors': [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
      'icon': LucideIcons.star,
      'badge': null,
    },
    {
      'id': 'panen-raya',
      'title': 'Panen Raya',
      'colors': [Color(0xFF10B981), Color(0xFF0F766E)],
      'icon': LucideIcons.shoppingBag,
      'badge': '10.10',
    },
    {
      'id': 'petik-subuh',
      'title': 'Petik Subuh',
      'colors': [Color(0xFF38BDF8), Color(0xFF2563EB)],
      'icon': LucideIcons.zap,
      'badge': null,
    },
    {
      'id': 'mitra-tani',
      'title': 'Mitra Tani',
      'colors': [Color(0xFFA855F7), Color(0xFF4F46E5)],
      'icon': LucideIcons.users,
      'badge': null,
    },
    {
      'id': 'beli-lokal',
      'title': 'Beli Lokal',
      'colors': [Color(0xFFFB7185), Color(0xFFDC2626)],
      'icon': LucideIcons.heart,
      'badge': null,
    },
    {
      'id': 'lapak-pay',
      'title': 'LapakPay',
      'colors': [Color(0xFF059669), Color(0xFF166534)],
      'icon': LucideIcons.wallet,
      'badge': null,
    },
  ];

  final List<Map<String, String>> _recentlyViewed = [
    {
      'title': 'Balik lihat',
      'category': 'Sayur & Daun Hijau',
      'badge': 'Panen Baru',
      'badgeColor': '0xFF059669',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBk603kJTTwyMZijNDcrTCQgKIriau9_3zXu-iSr0KlFkT4JKRLGwCHqT38CRGh7rX8YlQRTlXidz0qrQyxKK8-yNR7RsajVjAQH58sYuLdzip0DJzER-4O7icu9gSJDM71DnKZ12cY43Lf7DFN_pIkAEYEvTbBYuHggoR9z4jJjhWssKmZNbASdUOvhnI5_ZigVsPYHONWe7EwzMXIFgMJSL3CIrQtwQzk52zRvcamluL15gDpiPRJ',
    },
    {
      'title': 'Terakhir cek',
      'category': 'Buah & Sayur Segar',
      'badge': 'Hidroponik',
      'badgeColor': '0xFFDC2626',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuD8Eqfhsv22uPEELae8HtrhA_aoJjqPPcyMx0XMkPwYuVg00PJgZglsTZF3UQOFRpv3BnMOOP6KbsUaMurybJU1WNEwVKI6YSSVmNBzA6RMDYVRRcqIcxThIvVRh4JWjiWZ6MqqhmahaDt9XUYObA-cS_eyaTxDfZ8vVsymdEPltylegsUmU3bnf0DnUMhYRB3P1nrdx8H4AEWRjnJaR65nCRLpBs2b-bItH_SRaEct5koAudYm5D-y',
    },
    {
      'title': 'Incaranmu',
      'category': 'Buah Pilihan Subuh',
      'badge': 'Grade A',
      'badgeColor': '0xFFD97706',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBPcQz7r-BeW332-246iq6rpbS6BXUUUA32VFj9RgFP2q4EhEgK6bfMd8LE3-_N3cHtNQqVVY0Zu40FOV5XOW0W39E7asaQ4xQl3LmpDXFvJb_kvEH8NVB63cW23OMLe54iyQWf-007AM2TMKI83sjhoUN-nK0wXe8P8-pyWsrNQOfJ3Qiil16FX_aB0H8ysE1LRvN2ndUnREvgVsXc4VzBk93CoqElEiZBdVh-FU-j2otTlJdGhk-W',
    },
    {
      'title': 'Siap diorder',
      'category': 'Beras & Biji-bijian',
      'badge': 'Organik',
      'badgeColor': '0xFF03AC0E',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBJDaJ-Pofumldvv-NxLrvsFj7mwyo48JB9Uk29VnJuvkyA2bR3H1hRdCq77kocU16eSNvOTFKKvvcHMoK6YxCr25WbxhSq5DZzAvP0X_asgv_EEAJlnyKeW51So_eIWTtFovyQQ1ySMDHn17M8pONmHe083BT50s2qn_IsA5Jh2gLDu2EurScGmtpr3OrZqfIGEtvkDR4J_Ae_Kezf8vIM50bK4wT6F7EtVF2wJxS_KjC7cppJBXWj',
    },
  ];

  final List<Map<String, dynamic>> _flashSaleProducts = [
    {
      'id': 101,
      'title': 'Cabai Rawit',
      'price': 'Rp18.000',
      'originalPrice': 'Rp28.000',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBnPoW3HPF8GLUmmG2vG5fWEouwSHKDvC5EAdtt8SU2Yf5lxMSxo6D9QvIXGpi-pmhCVhkjT2MeM98MI0vN5Kj3dpufyOgEnqP5tPRO14aBgh8pRhlIzkcpna8uDLEF4ihWOZYxghcdhIUe1BwfWXcoB3t1c1YzaO8TeytQvW5bCCYe37NlUjZt7ip_d724pBise3360VVF7kkatrxoAgiB3iwPpCCF837HTuVwUTXXMdArxZMFyGsg',
    },
    {
      'id': 102,
      'title': 'Jeruk Garut',
      'price': 'Rp14.500',
      'originalPrice': 'Rp22.000',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuArN-Lyoid5DpvFrH9DKcOQL9NQA-NYSNrpbolqBJoHOERsOS67X9IzZeUuJtA9pF5ZxEelaU5fdSUjj_n_C8gLeyqM_cQ8UgMwv8JFNJt5DX_-HNPyTci9rTfr8XvoZ3kYUuUZRHVcjAL1vQqpffnq2Gg4X-Col3hn-XV74MJvwELBgr4K3_WB8eGJUmsaAZZTbmOinqi-QNwmDGFyofQSQPyjASl8Y65o4O4NuLmB55Kdvl3hg7oj',
    },
    {
      'id': 103,
      'title': 'Jamur Tiram',
      'price': 'Rp8.500',
      'originalPrice': 'Rp12.000',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA19PZV-0-evC8z3G_xTKePsNfdfwtNhOQo2x_y5o-Q_zRNRUD_YU_dD81wvVCkE3VVgxi7b7BcVHtZPiBb-ZXJLnbQHPPKiLredVLdW9gsgUId6L_YWb_Dw7Hz47LosEVhd8uuBL8iBG-P9t_L0Cko2wrQzqcpHgQITy6erbV2IpRnYt1qOEHRTtHzlI4sDO_yuis0v9lKqwa3-eOL8BXebxbCQAGQbFcnEVSp-jz9uugE_jjEp_ez',
    },
    {
      'id': 104,
      'title': 'Bawang Merah',
      'price': 'Rp24.000',
      'originalPrice': 'Rp32.000',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuC5dwR9LdFz_gwSFKBq0oYs39uUS46E2wAZmuRsuW6w1DZozkRFFwX9p8Rz_akKAN0mRhAxt66cg0sq_OMyssrIiYNneR4xPgI3rw9Yz2SmQwGUI7uceoiKiifcZi7mERId9D-ZQ7qHDjb3oiaQRazdH4cQ2P9iGWkm0D-JSdD06nlTopgnij3MOoLsMIzXYtTV9Mt97lXpUM3Psioa4j_imGYvAQ3jPEQXczqHEXbXi4irjbCqBDE8',
    },
  ];

  void _handleAddToCart(String productName) {
    setState(() {
      _cartItemCount++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$productName berhasil ditambahkan ke keranjang.'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF03AC0E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleWishlist(dynamic id) {
    setState(() {
      if (_wishlistIds.contains(id)) {
        _wishlistIds.remove(id);
      } else {
        _wishlistIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.interTextTheme(),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildTopStickyHeader(),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuickActionServices(),
                          _buildRecentlyViewedSection(),
                          _buildCategoryTabBar(),
                          _buildMainFeedSection(),
                          _buildTrustGuaranteeBanner(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildTopStickyHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE5F7E7),
            Color(0xFFEFF9F0),
            Color(0xFFF5F6F8),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Color(0x1F64748B),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.search,
                            size: 15,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cari sayur hidroponik, buah segar...',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fitur pemindai panen aktif.'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                LucideIcons.camera,
                                size: 15,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          Container(
                            height: 14,
                            width: 1,
                            color: const Color(0xFFE2E8F0),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          Text(
                            'Cari',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildHeaderIconButton(
                    icon: LucideIcons.messageCircle,
                    badgeText: '12',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Membuka pesan petani.'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  _buildHeaderIconButton(
                    icon: LucideIcons.shoppingCart,
                    badgeText: _cartItemCount > 0 ? '$_cartItemCount' : null,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Keranjang belanja: $_cartItemCount barang.'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    size: 12,
                    color: Color(0xFF03AC0E),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: const Color(0xFF4B5563),
                        ),
                        children: const [
                          TextSpan(text: 'Dikirim ke '),
                          TextSpan(
                            text: 'Rumah (Lembang, Kab. Bandung Barat)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    LucideIcons.chevronDown,
                    size: 12,
                    color: Color(0xFF6B7280),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
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
              size: 21,
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

  Widget _buildQuickActionServices() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _quickActions.map((action) {
              return Expanded(
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Membuka layanan ${action['title']}.'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: action['colors'] as List<Color>,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              action['icon'] as IconData,
                              size: 19,
                              color: Colors.white,
                            ),
                          ),
                          if (action['badge'] != null)
                            Positioned(
                              top: -3,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3.5,
                                  vertical: 0.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  action['badge'] as String,
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
                      const SizedBox(height: 4),
                      Text(
                        action['title'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9.0,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 14,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF03AC0E),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyViewedSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lanjut cek ini, yuk',
                style: GoogleFonts.inter(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Menampilkan riwayat penelusuran.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.inter(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF03AC0E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 138,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recentlyViewed.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final item = _recentlyViewed[index];
                final badgeColorVal = int.parse(item['badgeColor']!);

                return Container(
                  width: 104,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Image.network(
                                item['imageUrl']!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: const Color(0xFFE2E8F0),
                                  child: const Icon(
                                    LucideIcons.image,
                                    size: 20,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 3,
                            left: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3.5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: Color(badgeColorVal).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                item['badge']!,
                                style: GoogleFonts.inter(
                                  fontSize: 7.0,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['title']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        item['category']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9.0,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.white,
      child: SizedBox(
        height: 28,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _categoryTabs.length,
          separatorBuilder: (context, index) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final isSelected = _selectedCategoryTabIndex == index;
            final label = _categoryTabs[index];

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategoryTabIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE8F8EA)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF03AC0E)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11.0,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF03AC0E)
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainFeedSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildFlashSaleWidget()),
              const SizedBox(width: 6),
              Expanded(child: _buildOfficialFarmerHeroCard()),
            ],
          ),
          const SizedBox(height: 6),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF03AC0E),
                ),
              ),
            )
          else if (_products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.packageOpen,
                      size: 36,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada produk tersedia.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                mainAxisExtent: 320,
              ),
              itemBuilder: (context, index) {
                final product =
                    Map<String, dynamic>.from(_products[index] as Map);
                return _buildStandardProductCard(product);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFlashSaleWidget() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFEE2E2)),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Flash Sale',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      size: 8.5,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '04:18:22',
                      style: GoogleFonts.inter(
                        fontSize: 8.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _flashSaleProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              mainAxisExtent: 110,
            ),
            itemBuilder: (context, index) {
              final item = _flashSaleProducts[index];
              return Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.network(
                          item['imageUrl']!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: const Color(0xFFE2E8F0),
                            child: const Icon(LucideIcons.image, size: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item['price']!,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                            Text(
                              item['originalPrice']!,
                              style: GoogleFonts.inter(
                                fontSize: 7.5,
                                color: const Color(0xFF94A3B8),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Center(
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Menampilkan katalog flash sale.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Text(
                'Lihat Semua Flash Sale',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF03AC0E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialFarmerHeroCard() {
    return Container(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF03AC0E),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'MITRA UTAMA',
                  style: GoogleFonts.inter(
                    fontSize: 7.0,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '-15%',
                  style: GoogleFonts.inter(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuALDDiNd4kkcbVgjbcQUTzmuQJULFGslfxZfpr6pWVhd7b8tdw5-wGxEupE4H6sArX9vEoHPJayMGt5Q_d0jTT8H1fprQ8UXm9cznmtX0XopfNUr4QvmuF0ZOG7CwBTaJ7ZncHBoAfAlMmdaKZRc3TGFcwcfS_0uSGy7w0HKVbu9MI5D7bLFtiBGbgVqWYWa-FHJkz8lewhG3UB6CEGuTAp1LeGI297Q0oBHs0FL6dm5CM5yhLbEjFO',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Icon(LucideIcons.image, size: 20),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 3,
                    left: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'Petik Hari Ini',
                        style: GoogleFonts.inter(
                          fontSize: 7.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'Prioritas',
                  style: GoogleFonts.inter(
                    fontSize: 7.0,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7E22CE),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Kebun Lembang Segar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.0,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Paket Sayur Sop Komplit & Segar Lembang (1 Kg)',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Rp22.500',
            style: GoogleFonts.inter(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF028A0B),
            ),
          ),
          Row(
            children: [
              Text(
                'Rp28.000',
                style: GoogleFonts.inter(
                  fontSize: 8.0,
                  color: const Color(0xFF94A3B8),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Hemat 15%',
                style: GoogleFonts.inter(
                  fontSize: 8.0,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                LucideIcons.star,
                size: 10,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 2),
              Text(
                '5.0',
                style: GoogleFonts.inter(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '1.2rb terjual',
                style: GoogleFonts.inter(
                  fontSize: 9.0,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStandardProductCard(Map<String, dynamic> product) {
    final productId = product['id'];
    final isWishlisted = _wishlistIds.contains(productId);
    final String title = product['title']?.toString() ?? 'Produk Tani';
    final String price =
        _formatRupiah(product['price_per_kg'] ?? product['price']);
    final String location = product['village_name']?.toString() ??
        product['location']?.toString() ??
        'Lokal';
    final String grade = product['grade']?.toString() ??
        product['originBadge']?.toString() ??
        'Grade A';
    final String imageUrl = product['image_url']?.toString() ??
        product['imageUrl']?.toString() ??
        '';
    final bool freeShipping = product['freeShipping'] == true;
    final String unit = product['unit']?.toString() ?? '/kg';
    final String rating = product['rating']?.toString() ?? '5.0';
    final String soldCount = product['soldCount']?.toString() ?? 'Panen Baru';

    return Container(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFFE2E8F0),
                            child: const Icon(
                              LucideIcons.image,
                              size: 20,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(
                            LucideIcons.image,
                            size: 20,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 3,
                right: 3,
                child: InkWell(
                  onTap: () => _toggleWishlist(productId),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.heart,
                      size: 13,
                      color: isWishlisted
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 3,
                left: 3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF047857).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    grade,
                    style: GoogleFonts.inter(
                      fontSize: 7.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          if (freeShipping)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1),
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                'Bebas Ongkir',
                style: GoogleFonts.inter(
                  fontSize: 7.0,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF03AC0E),
                ),
              ),
            ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(
                LucideIcons.mapPin,
                size: 9.5,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 2.5),
              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.0,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price,
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF028A0B),
                    ),
                  ),
                  Text(
                    unit,
                    style: GoogleFonts.inter(
                      fontSize: 8.0,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _handleAddToCart(title),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF03AC0E),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    LucideIcons.plus,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.only(top: 3),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFF1F5F9),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.star,
                      size: 9.5,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      rating,
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                Text(
                  soldCount,
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustGuaranteeBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFECFDF5),
            Color(0xFFF0FDF4),
            Color(0xFFF0FDFA),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF03AC0E),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.checkCircle2,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jaminan Segar 100%',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Sayur layu saat sampai? Foto dan dapatkan penggantian instan tanpa ribet.',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: const Color(0xFF047857),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final navItems = [
      {'label': 'Beranda', 'icon': LucideIcons.home},
      {'label': 'Feed', 'icon': LucideIcons.compass},
      {'label': 'Mitra Tani', 'icon': LucideIcons.store},
      {'label': 'Transaksi', 'icon': LucideIcons.receipt},
      {'label': 'Akun', 'icon': LucideIcons.user},
    ];

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
            blurRadius: 6,
            offset: Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final item = navItems[index];
          final isActive = _currentBottomNavIndex == index;

          return InkWell(
            onTap: () {
              setState(() {
                _currentBottomNavIndex = index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 19,
                        color: isActive
                            ? const Color(0xFF03AC0E)
                            : const Color(0xFF94A3B8),
                      ),
                      if (isActive)
                        Positioned(
                          top: -1,
                          right: -3,
                          child: Container(
                            width: 4.5,
                            height: 4.5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF03AC0E),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 9.0,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF03AC0E)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
