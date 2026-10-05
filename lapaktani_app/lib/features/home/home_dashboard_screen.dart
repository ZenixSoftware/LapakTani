import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentBottomNavIndex = 0;
  int _selectedCategoryTabIndex = 0;
  final Set<int> _wishlistIds = {};
  int _cartItemCount = 4;

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

  final List<Map<String, dynamic>> _catalogProducts = [
    {
      'id': 1,
      'title': 'Jagung Manis Madu Organik Segar (Isi 3-4 Tongkol)',
      'price': 'Rp14.500',
      'unit': '/pack 1kg',
      'location': 'Malang, Jatim',
      'originBadge': 'Petani Batu',
      'rating': '4.9',
      'soldCount': '850+ terjual',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBNcxC9AeGcJKDIKXvZnkUXpXQZacY4jyGWOKanfYvqS4ASLYkIBwQjNacsUbP2-m6R_Y9vclnMXfhUcZxPTWuAfY8jNDLTyotuWyQ4yQvMPJJIw1-ajA8Ma5dYzNElMD1xuF8PZCuWe3pzX6ndDMhLxrGhW0IPRZv-3PiQi5iIj32W5nns2mpa2U_Npkhkj2u1hAAXDVuhrzE4Mc7gwvqybgAI30IdJCwbwqHEIqVoZEYZ5WnQs2lh',
      'freeShipping': true,
    },
    {
      'id': 2,
      'title': 'Wortel Manis Berastagi Super Renyah (Grade A)',
      'price': 'Rp11.000',
      'unit': '/500 gram',
      'location': 'Karo, Sumut',
      'originBadge': 'Petani Berastagi',
      'rating': '5.0',
      'soldCount': '1.5rb terjual',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBrS3ZtwnKUuZ4K0rT35rQua4KG1cyajZF_8MR1EroaYQyWIjp0_37qFaYqRl4G781JAABaiB_i4NVVSNsggcBvAjzV60ku1UH47FgTptcO92_3CABgJrOuztx_31wSGDZDWounJkqI8_FqYKa1jAvsPrKAQFkk8PIOpgcZM4DaVeZP_9LfJcN8wIx3LY6PBpvsWbpN_uMVUCnCcjr0SXnEcFsxdqgFnj8K6GiGFBP_riuNrkM15QV6',
      'freeShipping': true,
    },
    {
      'id': 3,
      'title': 'Brokoli Organik Lembang Pilihan (Segar Hijau)',
      'price': 'Rp16.000',
      'unit': '/500 gram',
      'location': 'Lembang, Jabar',
      'originBadge': 'Kebun Lembang',
      'rating': '4.8',
      'soldCount': '620+ terjual',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBk603kJTTwyMZijNDcrTCQgKIriau9_3zXu-iSr0KlFkT4JKRLGwCHqT38CRGh7rX8YlQRTlXidz0qrQyxKK8-yNR7RsajVjAQH58sYuLdzip0DJzER-4O7icu9gSJDM71DnKZ12cY43Lf7DFN_pIkAEYEvTbBYuHggoR9z4jJjhWssKmZNbASdUOvhnI5_ZigVsPYHONWe7EwzMXIFgMJSL3CIrQtwQzk52zRvcamluL15gDpiPRJ',
      'freeShipping': true,
    },
    {
      'id': 4,
      'title': 'Kentang Dieng Super Pulen & Lembut (Kualitas Super)',
      'price': 'Rp19.000',
      'unit': '/kg',
      'location': 'Wonosobo, Jateng',
      'originBadge': 'Petani Dieng',
      'rating': '4.9',
      'soldCount': '2.1rb terjual',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBJDaJ-Pofumldvv-NxLrvsFj7mwyo48JB9Uk29VnJuvkyA2bR3H1hRdCq77kocU16eSNvOTFKKvvcHMoK6YxCr25WbxhSq5DZzAvP0X_asgv_EEAJlnyKeW51So_eIWTtFovyQQ1ySMDHn17M8pONmHe083BT50s2qn_IsA5Jh2gLDu2EurScGmtpr3OrZqfIGEtvkDR4J_Ae_Kezf8vIM50bK4wT6F7EtVF2wJxS_KjC7cppJBXWj',
      'freeShipping': false,
    },
    {
      'id': 5,
      'title': 'Tomat Ceri Hidroponik Manis Segar Langsung Petik',
      'price': 'Rp15.000',
      'unit': '/pack 250g',
      'location': 'Ciwidey, Jabar',
      'originBadge': 'Hidroponik',
      'rating': '4.9',
      'soldCount': '980 terjual',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuD8Eqfhsv22uPEELae8HtrhA_aoJjqPPcyMx0XMkPwYuVg00PJgZglsTZF3UQOFRpv3BnMOOP6KbsUaMurybJU1WNEwVKI6YSSVmNBzA6RMDYVRRcqIcxThIvVRh4JWjiWZ6MqqhmahaDt9XUYObA-cS_eyaTxDfZ8vVsymdEPltylegsUmU3bnf0DnUMhYRB3P1nrdx8H4AEWRjnJaR65nCRLpBs2b-bItH_SRaEct5koAudYm5D-y',
      'freeShipping': true,
    },
    {
      'id': 6,
      'title': 'Bawang Putih Tunggal Lanang Obat Alami Super',
      'price': 'Rp32.000',
      'unit': '/250 gram',
      'location': 'Brebes, Jateng',
      'originBadge': 'Grade Super',
      'rating': '5.0',
      'soldCount': '480+ terjual',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuC5dwR9LdFz_gwSFKBq0oYs39uUS46E2wAZmuRsuW6w1DZozkRFFwX9p8Rz_akKAN0mRhAxt66cg0sq_OMyssrIiYNneR4xPgI3rw9Yz2SmQwGUI7uceoiKiifcZi7mERId9D-ZQ7qHDjb3oiaQRazdH4cQ2P9iGWkm0D-JSdD06nlTopgnij3MOoLsMIzXYtTV9Mt97lXpUM3Psioa4j_imGYvAQ3jPEQXczqHEXbXi4irjbCqBDE8',
      'freeShipping': true,
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

  void _toggleWishlist(int id) {
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
    final themeFont = GoogleFonts.interTextTheme();

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: themeFont,
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
                          const SizedBox(height: 20),
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
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
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
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cari sayur hidroponik, buah segar...',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
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
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          Container(
                            height: 16,
                            width: 1,
                            color: const Color(0xFFE2E8F0),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          Text(
                            'Cari',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
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
                  const SizedBox(width: 2),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    size: 13,
                    color: Color(0xFF03AC0E),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 11,
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
                    size: 13,
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
        width: 38,
        height: 38,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              size: 22,
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
                    minWidth: 16,
                    minHeight: 14,
                  ),
                  child: Center(
                    child: Text(
                      badgeText,
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
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
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
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
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: action['colors'] as List<Color>,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              action['icon'] as IconData,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                          if (action['badge'] != null)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  action['badge'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        action['title'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
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
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 3.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF03AC0E),
                    borderRadius: BorderRadius.circular(4),
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
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
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
                  fontSize: 13.5,
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
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF03AC0E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 156,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recentlyViewed.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _recentlyViewed[index];
                final badgeColorVal = int.parse(item['badgeColor']!);

                return Container(
                  width: 116,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
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
                                    size: 24,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Color(badgeColorVal).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item['badge']!,
                                style: GoogleFonts.inter(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['title']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        item['category']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
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
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Colors.white,
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _categoryTabs.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE8F8EA)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF03AC0E)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF03AC0E)
                        : const Color(0xFF475569),
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
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildFlashSaleWidget()),
              const SizedBox(width: 8),
              Expanded(child: _buildOfficialFarmerHeroCard()),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _catalogProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (context, index) {
              final product = _catalogProducts[index];
              return _buildStandardProductCard(product);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFlashSaleWidget() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
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
                'Flash Sale',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      size: 9,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '04:18:22',
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _flashSaleProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 0.64,
            ),
            itemBuilder: (context, index) {
              final item = _flashSaleProducts[index];
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            child: const Icon(LucideIcons.image, size: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['price']!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    Text(
                      item['originalPrice']!,
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        color: const Color(0xFF94A3B8),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
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
                  fontSize: 10,
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF03AC0E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'MITRA UTAMA',
                  style: GoogleFonts.inter(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '-15%',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
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
                        child: const Icon(LucideIcons.image, size: 24),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Petik Hari Ini',
                        style: GoogleFonts.inter(
                          fontSize: 7.5,
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
          const SizedBox(height: 6),
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
                    fontSize: 7.5,
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
                    fontSize: 9.5,
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rp22.500',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF028A0B),
            ),
          ),
          Row(
            children: [
              Text(
                'Rp28.000',
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  color: const Color(0xFF94A3B8),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Hemat 15%',
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                LucideIcons.star,
                size: 11,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 2),
              Text(
                '5.0',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '1.2rb terjual',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
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
    final isWishlisted = _wishlistIds.contains(product['id']);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    product['imageUrl'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFE2E8F0),
                      child: const Icon(LucideIcons.image, size: 24),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: () => _toggleWishlist(product['id'] as int),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isWishlisted ? LucideIcons.heart : LucideIcons.heart,
                      size: 14,
                      color: isWishlisted
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF047857).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product['originBadge'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (product['freeShipping'] == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                'Bebas Ongkir',
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF03AC0E),
                ),
              ),
            ),
          Text(
            product['title'] as String,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                LucideIcons.mapPin,
                size: 10,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  product['location'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
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
                    product['price'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF028A0B),
                    ),
                  ),
                  Text(
                    product['unit'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _handleAddToCart(product['title'] as String),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF03AC0E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.plus,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.only(top: 4),
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
                      size: 10,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      product['rating'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                Text(
                  product['soldCount'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 9,
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
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFECFDF5),
            Color(0xFFF0FDF4),
            Color(0xFFF0FDFA),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF03AC0E),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.checkCircle2,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jaminan Segar 100%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sayur layu saat sampai? Foto dan dapatkan penggantian instan tanpa ribet.',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF047857),
                    height: 1.25,
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
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 20,
                        color: isActive
                            ? const Color(0xFF03AC0E)
                            : const Color(0xFF94A3B8),
                      ),
                      if (isActive)
                        Positioned(
                          top: -1,
                          right: -3,
                          child: Container(
                            width: 5,
                            height: 5,
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
                      fontSize: 9.5,
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
