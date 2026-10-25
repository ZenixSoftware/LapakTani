import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../orders/models/order_model.dart';
import '../orders/models/notification_model.dart';
import '../orders/services/order_service.dart';
import '../orders/services/notification_service.dart';
import '../orders/screens/order_tracking_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final ApiService _apiService = ApiService();
  final OrderService _orderService = OrderService();
  bool _isStoreOpen = true;
  int _selectedChipIndex = 0;
  List<OrderModel> _farmerOrders = [];
  bool _isLoadingOrders = false;

  @override
  void initState() {
    super.initState();
    _orderService.init();
    NotificationService().init();
    _fetchFarmerOrders();
  }

  Future<void> _fetchFarmerOrders() async {
    if (!mounted) return;
    setState(() => _isLoadingOrders = true);
    try {
      final rawList = await _apiService.getFarmerOrders();
      if (rawList.isNotEmpty) {
        final parsed = rawList.map((m) => OrderModel.fromMap(m)).toList();
        if (mounted) {
          setState(() {
            _farmerOrders = parsed;
            _isLoadingOrders = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('[SELLER_DASHBOARD] Error fetching farmer orders: $e');
    }
    if (mounted) {
      setState(() {
        _farmerOrders = _orderService.ordersNotifier.value;
        _isLoadingOrders = false;
      });
    }
  }

  static const String _defaultFarmerPhoto =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAYrwsStPtJO0HY3riSclVguw_MiWyGVUOPRq6V2x2AvRBOV23WSDcAoPzLzcgxxE5Wtphh-B0fFcCi4aTOKKIsugJWJdun-0DVQIRzl9AXagHxbikg9K-1RTtOvK9PWMGUgp6idMuAqdvtpEs-QyVSNbSKNdCPTDsNzFt0elDVrLQnQUkeJudRuyjAlxkpV6Ze0ktgemZY0yFM6gD6yT0wHVhGlcMhrm5XHHxq76T00jr2cr8VL1E1';

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  void _showNotificationCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.bellRing, color: Color(0xFF006E04), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pusat Notifikasi Pesanan Masuk',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF121C2A),
                              ),
                            ),
                            ValueListenableBuilder<int>(
                              valueListenable: NotificationService().unreadCountNotifier,
                              builder: (context, unread, _) {
                                return Text(
                                  unread > 0 ? '$unread pesanan baru belum dibaca' : 'Semua notifikasi telah dibaca',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: unread > 0 ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                    fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await NotificationService().markAllAsRead();
                        },
                        child: Text(
                          'Tandai Semua Dibaca',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF03AC0E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                Expanded(
                  child: ValueListenableBuilder<List<NotificationModel>>(
                    valueListenable: NotificationService().notificationsNotifier,
                    builder: (context, notifs, _) {
                      if (notifs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.bellOff, size: 48, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum Ada Notifikasi Pesanan',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF121C2A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Setiap ada pembeli memesan komoditas panen, pemberitahuan instan akan muncul di sini.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: notifs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final notif = notifs[index];
                          final isOrder = notif.type == 'order_incoming';
                          final isCourier = notif.type == 'courier_pickup';

                          final Color iconBg = isOrder
                              ? const Color(0xFFDCFCE7)
                              : isCourier
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFFEF3C7);
                          final Color iconColor = isOrder
                              ? const Color(0xFF006E04)
                              : isCourier
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFD97706);
                          final IconData icon = isOrder
                              ? LucideIcons.sprout
                              : isCourier
                                  ? LucideIcons.truck
                                  : LucideIcons.checkCircle;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: notif.isRead ? Colors.white : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: notif.isRead ? const Color(0xFFE2E8F0) : const Color(0xFF86EFAC),
                                width: notif.isRead ? 1 : 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: iconBg,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(icon, color: iconColor, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif.title,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 13,
                                                    fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                                    color: const Color(0xFF121C2A),
                                                  ),
                                                ),
                                              ),
                                              if (!notif.isRead)
                                                Container(
                                                  width: 7,
                                                  height: 7,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF03AC0E),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatTimeAgo(notif.createdAt),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            notif.message,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: const Color(0xFF475569),
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!notif.isRead)
                                      TextButton(
                                        onPressed: () {
                                          NotificationService().markAsRead(notif.id);
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          minimumSize: const Size(44, 32),
                                        ),
                                        child: Text(
                                          'Tandai Dibaca',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 6),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        NotificationService().markAsRead(notif.id);
                                        final targetOrder = _orderService.getOrderById(notif.orderId);
                                        if (targetOrder != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => OrderTrackingScreen(orderId: targetOrder.id),
                                            ),
                                          );
                                        } else {
                                          setState(() => _selectedChipIndex = 1);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF03AC0E),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        minimumSize: const Size(80, 32),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Text(
                                        'Lihat Detail Pesanan',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
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
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
              'Pesanan Masuk & Dompet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF121C2A),
              ),
            ),
          ],
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: NotificationService().unreadCountNotifier,
            builder: (context, unreadCount, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.bell, color: Color(0xFF121C2A), size: 21),
                    onPressed: () => _showNotificationCenter(context),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings, color: Color(0xFF64748B), size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pengaturan operasional kebun & integrasi kurir aktif.'),
                  backgroundColor: Color(0xFF006E04),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchFarmerOrders,
        color: const Color(0xFF006E04),
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
              const SizedBox(height: 16),
              _buildFieldPickupBanner(),
              const SizedBox(height: 30),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _isStoreOpen,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF03AC0E),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFCBD5E1),
                  onChanged: (val) {
                    setState(() {
                      _isStoreOpen = val;
                    });
                  },
                ),
              ),
              Text(
                _isStoreOpen ? 'Buka Toko' : 'Tutup Toko',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _isStoreOpen ? const Color(0xFF006E04) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerWalletCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF084E33),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20084E33),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.wallet, color: Colors.white, size: 15),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Saldo LapakPay Petani',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB0F1CB),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF03AC0E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tarik Dana',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.arrowUpRight, size: 13, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rp 2.450.000',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.trendingUp, size: 14, color: Color(0xFF76FF64)),
                    const SizedBox(width: 6),
                    Text(
                      'Hasil Panen Terjual',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Text(
                  '1.250 kg',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Container(width: 1, height: 14, color: Colors.white24),
                Text(
                  'Performa Toko',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '98%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF76FF64),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final orders = _farmerOrders.isNotEmpty ? _farmerOrders : _orderService.ordersNotifier.value;
    final needHarvestCount = orders.where((o) => o.status == OrderStatus.needHarvest).length;
    final readyCount = orders.where((o) => o.status == OrderStatus.readyToShip).length;
    final inTransitCount = orders.where((o) => o.status == OrderStatus.inTransit).length;
    final completedCount = orders.where((o) => o.status == OrderStatus.completed).length;

    final chips = [
      {'label': 'Semua', 'badge': '${orders.length}'},
      {'label': 'Perlu Dipetik', 'badge': '$needHarvestCount'},
      {'label': 'Siap Kirim', 'badge': '$readyCount'},
      {'label': 'Dalam Perjalanan', 'badge': '$inTransitCount'},
      {'label': 'Selesai', 'badge': '$completedCount'},
    ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(chips.length, (index) {
              final isSelected = _selectedChipIndex == index;
              final item = chips[index];

              return Padding(
                padding: EdgeInsets.only(right: index == chips.length - 1 ? 0 : 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedChipIndex = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF006E04) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF006E04) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
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

  void _showHarvestProcessingDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool checkedQuality = true;
        bool checkedCoolBox = true;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.sprout, color: Color(0xFF006E04), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Proses Petik Panen',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF121C2A),
                          ),
                        ),
                        Text(
                          'Pesanan ${order.id}',
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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Hasil Panen yang Perlu Dipetik:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121C2A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...order.items.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.qty} ${item.unit}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF006E04),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: checkedQuality,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF006E04),
                      title: Text(
                        'Panen segar dipetik pagi & lolos sortir kualitas grade A.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF334155)),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          checkedQuality = val ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      value: checkedCoolBox,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF006E04),
                      title: Text(
                        'Sudah dikemas rapi dalam insulated cool box dengan ice gel.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF334155)),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          checkedCoolBox = val ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: (!checkedQuality || !checkedCoolBox)
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(ctx);
                          await _apiService.updateOrderStatus(order.id, 'IN_TRANSIT');
                          await _orderService.processHarvest(
                            order.id,
                            notes: 'Petani telah memetik panen segar di ladang dan mengemas dengan insulated box dingin.',
                          );
                          await _fetchFarmerOrders();
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Pesanan ${order.id} siap dijemput kurir logistik.'),
                              backgroundColor: const Color(0xFF03AC0E),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03AC0E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Siap Dijemput Kurir',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCourierHandoverDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.truck, color: Color(0xFF2563EB), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Serah Terima Kurir',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121C2A),
                      ),
                    ),
                    Text(
                      order.courier.serviceName,
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Nama Kurir', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                        Text(order.courier.name, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kendaraan', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                        Text(order.courier.vehicle, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Nomor Resi', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                        Text(order.trackingNumber, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF03AC0E))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.thermometerSnowflake, size: 18, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pastikan segel kotak dingin terpasang rapat dan suhu 4-8°C terverifikasi.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF065F46)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Tutup',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _apiService.updateOrderStatus(order.id, 'DELIVERED');
                await _orderService.handoverToCourier(order.id);
                await _fetchFarmerOrders();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pesanan ${order.id} telah diserahkan ke kurir logistik.'),
                      backgroundColor: const Color(0xFF03AC0E),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF03AC0E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Konfirmasi Penjemputan',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showOrderChatModal(OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kontak Pembeli: ${order.buyerName}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF121C2A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Alamat: ${order.buyerAddress}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F8EC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.phone, color: Color(0xFF03AC0E), size: 20),
                  ),
                  title: Text(order.buyerPhone, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  subtitle: Text('Telepon Pembeli', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                  trailing: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Menghubungkan telepon ke ${order.buyerName}...'),
                          backgroundColor: const Color(0xFF03AC0E),
                        ),
                      );
                    },
                    child: const Text('Hubungi'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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

  Widget _buildIncomingOrdersSection() {
    final orders = _farmerOrders.isNotEmpty ? _farmerOrders : _orderService.ordersNotifier.value;
    List<OrderModel> filtered;
    switch (_selectedChipIndex) {
      case 1:
        filtered = orders.where((o) => o.status == OrderStatus.needHarvest).toList();
        break;
      case 2:
        filtered = orders.where((o) => o.status == OrderStatus.readyToShip).toList();
        break;
      case 3:
        filtered = orders.where((o) => o.status == OrderStatus.inTransit).toList();
        break;
      case 4:
        filtered = orders.where((o) => o.status == OrderStatus.completed).toList();
        break;
      case 0:
      default:
        filtered = orders;
    }

    final needHarvestTotal = orders.where((o) => o.status == OrderStatus.needHarvest).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoadingOrders) ...[
          const LinearProgressIndicator(
            backgroundColor: Color(0xFFDCFCE7),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006E04)),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.checkSquare, size: 18, color: Color(0xFF006E04)),
                const SizedBox(width: 6),
                Text(
                  'Pemrosesan Pesanan Ladang',
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
                '$needHarvestTotal Perlu Dipetik',
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
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.inbox, size: 36, color: Color(0xFF94A3B8)),
                const SizedBox(height: 8),
                Text(
                  'Tidak ada pesanan pada filter ini.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          ...filtered.map((order) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDynamicOrderCard(order),
            );
          }),
      ],
    );
  }

  Widget _buildDynamicOrderCard(OrderModel order) {
    Color badgeColor;
    Color badgeTextColor;
    String primaryText;
    VoidCallback? onPrimaryPressed;

    switch (order.status) {
      case OrderStatus.needHarvest:
        badgeColor = const Color(0xFFB0F1CB);
        badgeTextColor = const Color(0xFF005302);
        primaryText = 'Petik & Siapkan';
        onPrimaryPressed = () => _showHarvestProcessingDialog(order);
        break;
      case OrderStatus.readyToShip:
        badgeColor = const Color(0xFFE0E7FF);
        badgeTextColor = const Color(0xFF3730A3);
        primaryText = 'Serahkan ke Kurir';
        onPrimaryPressed = () => _showCourierHandoverDialog(order);
        break;
      case OrderStatus.inTransit:
        badgeColor = const Color(0xFFEFF6FF);
        badgeTextColor = const Color(0xFF1E40AF);
        primaryText = 'Lacak Logistik';
        onPrimaryPressed = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderTrackingScreen(orderId: order.id),
            ),
          );
        };
        break;
      case OrderStatus.completed:
        badgeColor = const Color(0xFFDCFCE7);
        badgeTextColor = const Color(0xFF166534);
        primaryText = 'Lacak Riwayat';
        onPrimaryPressed = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderTrackingScreen(orderId: order.id),
            ),
          );
        };
        break;
      case OrderStatus.pendingPayment:
        badgeColor = const Color(0xFFFFDEA8);
        badgeTextColor = const Color(0xFF5E4200);
        primaryText = 'Rincian';
        onPrimaryPressed = () => _showOrderChatModal(order);
        break;
      case OrderStatus.delivered:
        badgeColor = const Color(0xFFDCFCE7);
        badgeTextColor = const Color(0xFF166534);
        primaryText = 'Lacak';
        onPrimaryPressed = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderTrackingScreen(orderId: order.id),
            ),
          );
        };
        break;
      case OrderStatus.cancelled:
        badgeColor = const Color(0xFFFEE2E2);
        badgeTextColor = const Color(0xFF991B1B);
        primaryText = 'Dibatalkan';
        onPrimaryPressed = null;
        break;
    }

    final courierIcon = order.courier.serviceName.toLowerCase().contains('kargo')
        ? LucideIcons.truck
        : LucideIcons.bike;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.id,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121C2A),
                    ),
                  ),
                  Text(
                    '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')} WIB',
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
                      order.status.label,
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
                        order.buyerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF121C2A),
                        ),
                      ),
                      Text(
                        '${order.courier.serviceName} • Suhu ${order.temperature}',
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
          Column(
            children: order.items.map((item) {
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
                          item.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF121C2A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'x${item.qty} ${item.unit}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Rp ${(item.price * item.qty).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
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
                    'Rp ${order.totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
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
                    onPressed: () => _showOrderChatModal(order),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      backgroundColor: const Color(0xFFF8F9FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: Text(
                      'Chat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onPrimaryPressed,
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
                      primaryText,
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

  Widget _buildFieldPickupBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.truck, size: 18, color: Color(0xFF006E04)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kurir Ambil Langsung di Ladang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF14532D),
                  ),
                ),
                Text(
                  'Siapkan panen dengan insulated cool box sebelum jam penjemputan.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
