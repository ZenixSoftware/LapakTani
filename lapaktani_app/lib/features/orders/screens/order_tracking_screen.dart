import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/api_service.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final ApiService _apiService = ApiService();
  final OrderService _orderService = OrderService();
  OrderModel? _serverOrder;
  bool _isLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _orderService.init();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getOrderDetails(widget.orderId);
      if (data != null) {
        if (mounted) {
          setState(() {
            _serverOrder = OrderModel.fromMap(data);
            _isLoading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('[TRACKING] Error fetching order details: $e');
    }

    if (mounted) {
      setState(() {
        _serverOrder = _orderService.getOrderById(widget.orderId);
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard'),
        backgroundColor: const Color(0xFF03AC0E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCourierContactModal(CourierInfo courier) {
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
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F8EC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.user, color: Color(0xFF03AC0E), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            courier.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF121C2A),
                            ),
                          ),
                          Text(
                            courier.serviceName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nomor Telepon / WhatsApp',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            courier.phone,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF121C2A),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.copy, size: 18, color: Color(0xFF03AC0E)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _copyToClipboard(courier.phone, 'Nomor kurir');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.phone, size: 16, color: Color(0xFF03AC0E)),
                        label: Text(
                          'Panggil',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF03AC0E),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF03AC0E)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Menghubungkan panggilan ke ${courier.name}...'),
                              backgroundColor: const Color(0xFF03AC0E),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(LucideIcons.messageSquare, size: 16, color: Colors.white),
                        label: Text(
                          'Chat WA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF03AC0E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Membuka obrolan dengan ${courier.name}...'),
                              backgroundColor: const Color(0xFF03AC0E),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleConfirmDelivery(OrderModel order) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Konfirmasi Terima Pesanan',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Apakah sayuran dan hasil panen sudah Anda terima dalam kondisi segar?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Belum',
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF03AC0E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Ya, Sudah Selesai',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isActionLoading = true);
      await _apiService.updateOrderStatus(order.id, 'COMPLETED');
      await _orderService.confirmDelivered(order.id);
      await _loadOrderDetails();
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terima kasih! Pesanan Anda telah selesai dan dana diteruskan ke petani.'),
            backgroundColor: Color(0xFF03AC0E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FF),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF03AC0E)),
        ),
      );
    }

    final order = _serverOrder ?? _orderService.getOrderById(widget.orderId);

    if (order == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FF),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              title: Text(
                'Lacak Pesanan',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: const Color(0xFF121C2A),
                ),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.packageX, size: 48, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  Text(
                    'Pesanan tidak ditemukan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FF),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF121C2A), size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pelacakan Logistik Panen',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF121C2A),
                  ),
                ),
                Text(
                  '${order.id} • ${order.status.label}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF03AC0E),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: Color(0xFF64748B), size: 18),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Status pelacakan logistik telah diperbarui.'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadOrderDetails,
            color: const Color(0xFF03AC0E),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLiveStatusHeroCard(order),
                  const SizedBox(height: 12),
                  _buildColdChainBadgeCard(order),
                  const SizedBox(height: 14),
                  _buildCourierCard(order),
                  const SizedBox(height: 14),
                  _buildRouteLocationCard(order),
                  const SizedBox(height: 16),
                  _buildStepperTimelineSection(order),
                  const SizedBox(height: 16),
                  _buildShippedItemsCard(order),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          bottomSheet: _buildBottomActionBar(order),
        );
  }

  Widget _buildLiveStatusHeroCard(OrderModel order) {
    Color badgeBg;
    Color badgeTextColor;
    IconData statusIcon;

    switch (order.status) {
      case OrderStatus.pendingPayment:
        badgeBg = const Color(0xFFFEF3C7);
        badgeTextColor = const Color(0xFF92400E);
        statusIcon = LucideIcons.clock;
        break;
      case OrderStatus.needHarvest:
        badgeBg = const Color(0xFFE8F8EC);
        badgeTextColor = const Color(0xFF006E04);
        statusIcon = LucideIcons.sprout;
        break;
      case OrderStatus.readyToShip:
        badgeBg = const Color(0xFFE0E7FF);
        badgeTextColor = const Color(0xFF3730A3);
        statusIcon = LucideIcons.package;
        break;
      case OrderStatus.inTransit:
        badgeBg = const Color(0xFFEFF6FF);
        badgeTextColor = const Color(0xFF1E40AF);
        statusIcon = LucideIcons.truck;
        break;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        badgeBg = const Color(0xFFDCFCE7);
        badgeTextColor = const Color(0xFF166534);
        statusIcon = LucideIcons.checkCircle2;
        break;
      case OrderStatus.cancelled:
        badgeBg = const Color(0xFFFEE2E2);
        badgeTextColor = const Color(0xFF991B1B);
        statusIcon = LucideIcons.xCircle;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: badgeTextColor),
                    const SizedBox(width: 5),
                    Text(
                      order.status.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    'No. Resi:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _copyToClipboard(order.trackingNumber, 'Nomor Resi'),
                    child: Row(
                      children: [
                        Text(
                          order.trackingNumber,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF121C2A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.copy, size: 12, color: Color(0xFF03AC0E)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.status == OrderStatus.completed
                ? 'Paket Berhasil Diterima'
                : 'Estimasi Tiba: ${order.estimatedDelivery}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF121C2A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order.checkpoints.isNotEmpty
                ? order.checkpoints.first.description
                : 'Pesanan sedang diproses dalam jaringan rantai pasok LapakTani.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColdChainBadgeCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
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
            child: const Icon(LucideIcons.thermometerSnowflake, size: 20, color: Color(0xFF059669)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Suhu Terjaga: ${order.temperature}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Cold-Chain Aktif',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Sayuran dan panen terlindungi dari layu dengan insulated box dingin.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: const Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourierCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.truck, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.courier.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF121C2A),
                  ),
                ),
                Text(
                  '${order.courier.serviceName} • ${order.courier.vehicle}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.phoneCall, color: Color(0xFF03AC0E), size: 20),
            onPressed: () => _showCourierContactModal(order.courier),
            tooltip: 'Hubungi Kurir',
          ),
        ],
      ),
    );
  }

  Widget _buildRouteLocationCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.sprout, size: 14, color: Color(0xFF006E04)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asal Kebun Petani',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      order.sellerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121C2A),
                      ),
                    ),
                    Text(
                      order.sellerLocation,
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
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: 18,
                color: const Color(0xFFE2E8F0),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alamat Pengantaran Pembeli',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      order.buyerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121C2A),
                      ),
                    ),
                    Text(
                      order.buyerAddress,
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
        ],
      ),
    );
  }

  Widget _buildStepperTimelineSection(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
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
              Text(
                'Riwayat Pelacakan Perjalanan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121C2A),
                ),
              ),
              Text(
                '${order.checkpoints.length} Titik Cek',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF03AC0E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.checkpoints.length,
            itemBuilder: (context, index) {
              final cp = order.checkpoints[index];
              final isLatest = index == 0;
              final isLast = index == order.checkpoints.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLatest ? const Color(0xFF03AC0E) : Colors.white,
                            border: Border.all(
                              color: isLatest ? const Color(0xFF03AC0E) : const Color(0xFF94A3B8),
                              width: 2,
                            ),
                          ),
                          child: isLatest
                              ? const Center(
                                  child: Icon(Icons.check, size: 12, color: Colors.white),
                                )
                              : null,
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cp.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: isLatest ? FontWeight.w700 : FontWeight.w600,
                                color: isLatest ? const Color(0xFF03AC0E) : const Color(0xFF121C2A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cp.description,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: const Color(0xFF475569),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  cp.timestamp,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                if (cp.location.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '• ${cp.location}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ],
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
        ],
      ),
    );
  }

  Widget _buildShippedItemsCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Produk (${order.items.length} Barang)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121C2A),
                ),
              ),
              Text(
                'Total: Rp ${order.totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF006E04),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.imageUrl.isNotEmpty
                        ? Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.sprout, size: 18, color: Color(0xFF03AC0E)),
                          )
                        : const Icon(LucideIcons.sprout, size: 18, color: Color(0xFF03AC0E)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF121C2A),
                          ),
                        ),
                        Text(
                          '${item.qty} ${item.unit} • ${item.grade ?? 'Pilihan Petani'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Rp ${item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF121C2A),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget? _buildBottomActionBar(OrderModel order) {
    if (order.status == OrderStatus.inTransit || order.status == OrderStatus.delivered) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _isActionLoading ? null : () => _handleConfirmDelivery(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF03AC0E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isActionLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Konfirmasi Pesanan Diterima',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      );
    }
    return null;
  }
}
