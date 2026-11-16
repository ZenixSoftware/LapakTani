import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lapaktani_app/core/services/api_service.dart';
import 'package:lapaktani_app/core/theme/app_colors.dart';
import 'package:lapaktani_app/features/product/product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({
    super.key,
    this.initialQuery,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const String _prefRecentSearchesKey = 'lapaktani_recent_searches';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _searchQuery = '';
  bool _isLoading = false;
  Timer? _debounceTimer;

  List<dynamic> _searchResults = [];
  List<dynamic> _recommendedProducts = [];
  List<String> _recentSearches = [
    'Tomat Lembang',
    'Cabai Rawit Merah',
    'Beras Organik',
    'Wortel Berastagi',
    'Kentang Granola',
  ];

  static final List<Map<String, dynamic>> _fallbackRecommended = [
    {
      'id': 'rec-1',
      'title': 'Tomat Merah Organik Segar (Petik Subuh Lembang)',
      'price_per_kg': 12000,
      'unit': '/kg',
      'category': 'Sayuran Segar Organik',
      'grade': 'Grade A (Super)',
      'poktan_name': 'Poktan Manik Sari',
      'village_name': 'Lembang, Bandung Barat',
      'rating': '4.9',
      'soldCount': '890+ terjual',
      'image_url':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB7MFNm6fGiAm5QTKbvDcHMQ3fNnfFYJO_Kyt9JrlLi9bdKKdnbkUUFDVEY7mCNRqoT57wyH6E0LUIC1jGc0D-kArTwJmp2e_5daQ-YOhbRz6XPP7EYvLTgq5ALb_-pvxAwxa6jFCLpDRll8ED4v4Ji4zgioDov57ptO20jhk2yg-AMXM58Y1QEp-gsPaWJsmltO5szzG6PzNOWC0-PNC7sN4gPpfDUDJMz25zaMnEVC1MiKNDOCJB_',
      'description':
          'Tomat merah segar organik dipanen langsung dari ladang pegunungan di pagi hari.',
    },
    {
      'id': 'rec-2',
      'title': 'Wortel Manis Berastagi Super Renyah (Grade A)',
      'price_per_kg': 11000,
      'unit': '/500 gram',
      'category': 'Umbi-umbian',
      'grade': 'Grade A',
      'poktan_name': 'Poktan Karo Makmur',
      'village_name': 'Karo, Sumut',
      'rating': '5.0',
      'soldCount': '1.5rb terjual',
      'image_url':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBrS3ZtwnKUuZ4K0rT35rQua4KG1cyajZF_8MR1EroaYQyWIjp0_37qFaYqRl4G781JAABaiB_i4NVVSNsggcBvAjzV60ku1UH47FgTptcO92_3CABgJrOuztx_31wSGDZDWounJkqI8_FqYKa1jAvsPrKAQFkk8PIOpgcZM4DaVeZP_9LfJcN8wIx3LY6PBpvsWbpN_uMVUCnCcjr0SXnEcFsxdqgFnj8K6GiGFBP_riuNrkM15QV6',
      'description':
          'Wortel Berastagi kualitas ekspor yang dipanen dari tanah vulkanik dataran tinggi Karo.',
    },
    {
      'id': 'rec-3',
      'title': 'Cabai Rawit Merah Segar Pedas Juara',
      'price_per_kg': 35000,
      'unit': '/kg',
      'category': 'Sayur Buah',
      'grade': 'Pedas Juara',
      'poktan_name': 'Poktan Subur Cianjur',
      'village_name': 'Cianjur, Jabar',
      'rating': '5.0',
      'soldCount': '2.5rb terjual',
      'image_url':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBrEzlx59eqGOtnBIamg68cvQ14I5nY00p7Vu2vo0A9vlk5b2HhjT1eRPqxWnJcFISTjZ2yhPWA3mU3vPoK9YLit0ItITTn3Cz1aFo2Z9_lgj6vBer1s1adzaI8ifh7qodffy2ZnUrHf0g78ye5KkXuLVqh4q0VuJoC75wcVb7l7YY2NvpT0yFGr2A3GBXkWUD7FxGsJ2toIIs2NosOcihuT4EbtGBSpZgd-Y4eO2CFyPID9SH9gtGu',
      'description':
          'Cabai rawit domba merah petik langsung dari pohon di Cianjur.',
    },
    {
      'id': 'rec-4',
      'title': 'Kentang Granola Dieng Super',
      'price_per_kg': 16000,
      'unit': '/kg',
      'category': 'Umbi-umbian',
      'grade': 'Grade A',
      'poktan_name': 'Poktan Dataran Dieng',
      'village_name': 'Dieng, Jateng',
      'rating': '4.9',
      'soldCount': '1.2rb terjual',
      'image_url':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDQfZ8rlRVHk2qkSfC0zsPq1XBOalKVCjz-SK27JBESez2nkF4XHUYWP-swEAKZngWukUvo9Df9G4f9trDz2JqjpoyfGClJ80yD76cURQ-33wsz7GIkmINCKucwTcWZEnF2pKg9NyLwAzB8N_BqidBu0XttzgLQW9bD7fi9kRgYANzWxfO6nmsMw7hQFcHN0cewb8hFiACXv_6zfeZxZ3i9LjW0DRx3RO8-cnPTrZIREWEzmDEUovQr',
      'description':
          'Kentang granola pilihan dari dataran tinggi Dieng. Kulit mulus bersih, daging kuning pulen.',
    },
  ];

  static const List<String> _popularKeywords = [
    'Jagung Manis',
    'Bayam Hijau',
    'Selada Hidroponik',
    'Bawang Merah',
    'Alpukat Mentega',
    'Kangkung Darat',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _fetchRecommendations();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _searchQuery = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefRecentSearchesKey);
      if (saved != null && saved.isNotEmpty && mounted) {
        setState(() {
          _recentSearches = saved;
        });
      }
    } catch (_) {
      // SharedPreferences failure fallback to defaults
    }
  }

  Future<void> _saveRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefRecentSearchesKey, _recentSearches);
    } catch (_) {
      // Non-blocking persistent write failure
    }
  }

  void _addRecentSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _recentSearches.remove(trimmed);
      _recentSearches.insert(0, trimmed);
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.sublist(0, 10);
      }
    });
    _saveRecentSearches();
  }

  void _removeRecentSearch(String query) {
    setState(() {
      _recentSearches.remove(query);
    });
    _saveRecentSearches();
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
    _saveRecentSearches();
  }

  Future<void> _fetchRecommendations() async {
    try {
      final products = await ApiService().getProducts();
      if (mounted) {
        setState(() {
          _recommendedProducts =
              products.isNotEmpty ? products.take(6).toList() : _fallbackRecommended;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _recommendedProducts = _fallbackRecommended;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _searchQuery = value;
      _isLoading = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(trimmed);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await ApiService().getProducts(query: query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final q = query.toLowerCase();
        final localFiltered = _fallbackRecommended.where((p) {
          final t = (p['title'] ?? '').toString().toLowerCase();
          final c = (p['category'] ?? '').toString().toLowerCase();
          return t.contains(q) || c.contains(q);
        }).toList();
        setState(() {
          _searchResults = localFiltered;
          _isLoading = false;
        });
      }
    }
  }

  void _applySearchTerm(String term) {
    _searchController.text = term;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    _addRecentSearch(term);
    _onSearchChanged(term);
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.interTextTheme(),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildSearchAppBar(),
        body: _searchQuery.trim().isEmpty
            ? _buildStateEmptyQuery()
            : _buildStateActiveQuery(),
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          LucideIcons.arrowLeft,
          color: Color(0xFF1E293B),
          size: 22,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Container(
        height: 40,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.search,
              size: 16,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                autofocus: true,
                onChanged: _onSearchChanged,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _addRecentSearch(value);
                    _performSearch(value.trim());
                  }
                },
                textInputAction: TextInputAction.search,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Cari komoditas, sayur, buah...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              InkWell(
                onTap: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    LucideIcons.x,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: const Color(0xFFE2E8F0),
          height: 1,
        ),
      ),
    );
  }

  Widget _buildStateEmptyQuery() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecentSearchesSection(),
          const SizedBox(height: 18),
          _buildPopularSearchesSection(),
          const SizedBox(height: 22),
          _buildRecommendedSection(),
        ],
      ),
    );
  }

  Widget _buildRecentSearchesSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
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
                'Riwayat Pencarian',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (_recentSearches.isNotEmpty)
                InkWell(
                  onTap: _clearRecentSearches,
                  child: Text(
                    'Hapus Semua',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE11D48),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_recentSearches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada riwayat pencarian.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((term) {
                return InkWell(
                  onTap: () => _applySearchTerm(term),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.clock,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          term,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => _removeRecentSearch(term),
                          child: const Icon(
                            LucideIcons.x,
                            size: 13,
                            color: Color(0xFF94A3B8),
                          ),
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

  Widget _buildPopularSearchesSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.trendingUp,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Pencarian Populer',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularKeywords.map((keyword) {
              return InkWell(
                onTap: () => _applySearchTerm(keyword),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    keyword,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection() {
    final list = _recommendedProducts.isNotEmpty
        ? _recommendedProducts
        : _fallbackRecommended;

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
                  'Anda mungkin suka',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Komoditas segar pilihan langsung dari petani',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            final product = Map<String, dynamic>.from(list[index] as Map);
            return _buildProductCard(product);
          },
        ),
      ],
    );
  }

  Widget _buildStateActiveQuery() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 12),
            Text(
              'Mencari komoditas "$_searchQuery"...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.searchX,
                  size: 32,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Produk tidak ditemukan',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tidak ada hasil untuk "$_searchQuery". Coba kata kunci lain seperti tomat, cabai, atau wortel.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Lihat Rekomendasi',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: Colors.white,
          child: Text(
            'Ditemukan ${_searchResults.length} produk untuk "$_searchQuery"',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _searchResults.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final product =
                  Map<String, dynamic>.from(_searchResults[index] as Map);
              return _buildProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final title = product['title']?.toString() ?? 'Komoditas Segar';
    final priceStr = _formatRupiah(product['price_per_kg'] ?? product['price']);
    final unit = product['unit_name']?.toString() ??
        product['unit']?.toString() ??
        '/kg';
    final grade = product['grade']?.toString() ?? 'Grade A';
    final location = product['village_name']?.toString() ??
        product['location']?.toString() ??
        'Lokal';
    final imageUrl = product['image_url']?.toString() ??
        product['imageUrl']?.toString() ??
        '';

    return InkWell(
      onTap: () {
        _addRecentSearch(title);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: AspectRatio(
                aspectRatio: 1.15,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl.startsWith('http')
                            ? imageUrl
                            : '${ApiService.baseUrl.replaceAll('/api', '')}/${imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(
                            LucideIcons.image,
                            size: 20,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(
                          LucideIcons.image,
                          size: 20,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    grade,
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
                height: 1.25,
              ),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  priceStr,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFE11D48),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 28,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ditambahkan ke keranjang'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  '+ Keranjang',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
