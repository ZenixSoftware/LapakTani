import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/user_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_soft_card.dart';
import '../../auth/auth_repository.dart';
import '../../auth/login_screen.dart';
import '../../store/screens/store_profile_screen.dart';

class WholesaleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pool;

  const WholesaleDetailScreen({
    super.key,
    required this.pool,
  });

  @override
  State<WholesaleDetailScreen> createState() => _WholesaleDetailScreenState();
}

class _WholesaleDetailScreenState extends State<WholesaleDetailScreen> {
  final ApiService _apiService = ApiService();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  late Map<String, dynamic> _poolData;

  @override
  void initState() {
    super.initState();
    _poolData = Map<String, dynamic>.from(widget.pool);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http')) return rawUrl;
    final clean = rawUrl.startsWith('/') ? rawUrl.substring(1) : rawUrl;
    return '${ApiService.baseUrl.replaceAll('/api', '')}/$clean';
  }

  List<String> get _carouselImages {
    final raw = _poolData['image_url']?.toString();
    final primary = _resolveImageUrl(raw);
    if (primary.isNotEmpty) {
      return [
        primary,
        'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=1200&q=80',
      ];
    }
    return [
      'https://images.unsplash.com/photo-1588252303782-cb80119abd6d?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80',
    ];
  }

  bool _ensureAuthenticated() {
    final user = AuthRepository().currentUser ?? UserSession().currentUser;
    if (user != null) return true;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.lock, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Silakan Masuk Akun',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Untuk memesan kuota borongan partai panen, Anda perlu masuk ke akun LapakTani terlebih dahulu.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Nanti Saja',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006E04),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Masuk Sekarang',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return false;
  }

  void _showOrderQuotaSheet() {
    if (!_ensureAuthenticated()) return;

    final double totalQuota = (_poolData['total_quota_kg'] as num?)?.toDouble() ?? 100.0;
    final double remaining = (_poolData['remaining_quota_kg'] as num?)?.toDouble() ?? 50.0;
    final double minOrder = (_poolData['min_order_kg'] as num?)?.toDouble() ?? 50.0;
    final double pricePerKg = (_poolData['price_per_kg'] as num?)?.toDouble() ?? 0.0;

    double selectedQty = minOrder.clamp(1.0, remaining);
    final qtyController = TextEditingController(text: selectedQty.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setModalState) {
          final totalAmount = selectedQty * pricePerKg;

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
                        'Pesan Kuota Borongan',
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
                  const SizedBox(height: 6),
                  Text(
                    _poolData['commodity_name'] ?? 'Komoditas Panen',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF006E04),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Harga Partai', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text('Rp ${_currencyFormat.format(pricePerKg)} / kg', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Tersedia', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text('${_currencyFormat.format(remaining)} kg', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Jumlah Pesanan (kg)',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Minimal pemesanan partai: ${minOrder.toStringAsFixed(0)} kg',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        onPressed: selectedQty > minOrder
                            ? () {
                                setModalState(() {
                                  selectedQty -= 10;
                                  if (selectedQty < minOrder) selectedQty = minOrder;
                                  qtyController.text = selectedQty.toStringAsFixed(0);
                                });
                              }
                            : null,
                        icon: const Icon(LucideIcons.minusCircle),
                        color: const Color(0xFF006E04),
                      ),
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            suffixText: 'kg',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val) ?? minOrder;
                            setModalState(() {
                              selectedQty = parsed;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: selectedQty < remaining
                            ? () {
                                setModalState(() {
                                  selectedQty += 10;
                                  if (selectedQty > remaining) selectedQty = remaining;
                                  qtyController.text = selectedQty.toStringAsFixed(0);
                                });
                              }
                            : null,
                        icon: const Icon(LucideIcons.plusCircle),
                        color: const Color(0xFF006E04),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Estimasi:',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF166534)),
                        ),
                        Text(
                          'Rp ${_currencyFormat.format(totalAmount)}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF006E04)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final double qty = double.tryParse(qtyController.text) ?? selectedQty;
                        final messenger = ScaffoldMessenger.of(context);
                        if (qty < minOrder || qty > remaining) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Jumlah pesanan harus antara ${minOrder.toStringAsFixed(0)} sampai ${_currencyFormat.format(remaining)} kg.'),
                              backgroundColor: const Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        final success = await _apiService.takeB2BQuota(
                          poolId: (_poolData['id'] ?? '').toString(),
                          quantityKg: qty,
                        );

                        if (!mounted) return;
                        if (success) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Berhasil mengambil kuota ${qty.toStringAsFixed(0)} kg! Kontrak borongan dicatat.'),
                              backgroundColor: const Color(0xFF006E04),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          setState(() {
                            final double curRem = (_poolData['remaining_quota_kg'] as num?)?.toDouble() ?? remaining;
                            _poolData['remaining_quota_kg'] = (curRem - qty).clamp(0.0, totalQuota);
                          });
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Gagal memesan kuota borongan. Silakan coba kembali.'),
                              backgroundColor: Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006E04),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Konfirmasi Pesan Kuota',
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

  @override
  Widget build(BuildContext context) {
    final String commodity = _poolData['commodity_name'] ?? 'Komoditas Partai';
    final String variety = _poolData['variety'] ?? 'Varietas Unggul';
    final String grade = _poolData['grade'] ?? 'Grade A Super';
    final String mitraName = _poolData['mitra_name'] ?? 'Mitra Tani Makmur';
    final double totalKg = (_poolData['total_quota_kg'] as num?)?.toDouble() ?? 100.0;
    final double remainingKg = (_poolData['remaining_quota_kg'] as num?)?.toDouble() ?? 50.0;
    final double takenKg = (totalKg - remainingKg).clamp(0.0, totalKg);
    final double progress = totalKg > 0 ? (takenKg / totalKg).clamp(0.0, 1.0) : 0.0;
    final double priceKg = (_poolData['price_per_kg'] as num?)?.toDouble() ?? 0.0;
    final double minOrder = (_poolData['min_order_kg'] as num?)?.toDouble() ?? 50.0;
    final String harvestDate = _poolData['target_harvest_date'] ?? _poolData['est_harvest_date'] ?? '15 Nov 2026';
    final String packagingSop = _poolData['packaging_sop'] ?? 'Krat Plastik & Cold Storage (10-12°C)';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        title: Text(
          'Detail Bursa Partai B2B',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tautan bursa komoditas disalin!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Image Carousel
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _carouselImages.length,
                    onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                    itemBuilder: (context, index) {
                      return Image.network(
                        _carouselImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(LucideIcons.image, size: 48, color: Color(0xFF94A3B8)),
                        ),
                      );
                    },
                  ),
                ),
                // Pagination Dots
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_carouselImages.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentImageIndex == index ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentImageIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Header Section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          grade,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.shieldCheck, size: 12, color: Color(0xFF2563EB)),
                            const SizedBox(width: 4),
                            Text(
                              'Bebas Residu Pestisida',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    commodity,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Varietas: $variety',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Rp ${_currencyFormat.format(priceKg)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF006E04),
                        ),
                      ),
                      Text(
                        ' / kg',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Min. Pesanan ${minOrder.toStringAsFixed(0)} kg',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 3. Quota Status Card
                  CustomSoftCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progres Penyerapan Bursa Kuota',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: remainingKg <= 0.01 ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                remainingKg <= 0.01 ? 'Terserap Penuh' : 'Bursa Terbuka',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: remainingKg <= 0.01 ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Terserap: ${_currencyFormat.format(takenKg)} / ${_currencyFormat.format(totalKg)} kg',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Sisa: ${_currencyFormat.format(remainingKg)} kg',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF006E04)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(LucideIcons.calendar, size: 16, color: Color(0xFF006E04)),
                            const SizedBox(width: 6),
                            Text(
                              'Target Panen Serentak: $harvestDate',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Mitra Tani Store Profile Card
                  CustomSoftCard(
                    padding: const EdgeInsets.all(14),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(LucideIcons.store, color: Color(0xFF006E04), size: 24),
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
                                      mitraName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
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
                                'Rating 4.9 ★ • 42 Petani Anggota Binaan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StoreProfileScreen(storeName: mitraName),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF006E04)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Kunjungi Toko',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF006E04),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Agricultural Specifications
                  CustomSoftCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spesifikasi Budidaya & Rantai Pasok',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSpecRow(LucideIcons.mapPin, 'Lahan Asal', 'Lahan Konsolidasi Lembang (11.10 Ha)'),
                        _buildSpecRow(LucideIcons.mountain, 'Jenis Tanah', 'Andosol Vulkanik Subur (pH 6.2 - 6.8)'),
                        _buildSpecRow(LucideIcons.scissors, 'SOP Panen', 'Petik Subuh 04:30 - 07:00 WIB, Sortir Grade'),
                        _buildSpecRow(LucideIcons.thermometerSnowflake, 'Penanganan Suhu', packagingSop),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. Escrow Protection Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.shieldCheck, color: Color(0xFF006E04), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jaminan Rekber LapakTani',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF166534),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Dana ditahan aman di escrow. Jika terjadi defisit panen, sisa dana otomatis dikembalikan (instant refund) ke rekening/dompet Anda.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFF15803D),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      // 7. Sticky Bottom Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(color: Color(0x0A000000), offset: Offset(0, -3), blurRadius: 8),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Harga Grosir:',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                    Text(
                      'Rp ${_currencyFormat.format(priceKg)} / kg',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF006E04),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: remainingKg > 0 ? _showOrderQuotaSheet : null,
                icon: const Icon(LucideIcons.shoppingBag, size: 18),
                label: Text(
                  remainingKg > 0 ? 'Pesan Kuota Borongan' : 'Kuota Habis',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006E04),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  disabledForegroundColor: const Color(0xFF64748B),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF006E04)),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
