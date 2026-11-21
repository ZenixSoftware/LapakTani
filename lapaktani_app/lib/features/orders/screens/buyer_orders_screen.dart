import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../chat/screens/chat_room_screen.dart';
import '../../chat/services/chat_service.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'order_tracking_screen.dart';

class BuyerOrdersScreen extends StatefulWidget {
  final OrderStatus? initialStatus;
  final bool isTabEmbedded;

  const BuyerOrdersScreen({
    super.key,
    this.initialStatus,
    this.isTabEmbedded = false,
  });

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;

  final List<String> _tabs = [
    'Semua',
    'Menunggu Bayar',
    'Perlu Dipetik',
    'Dalam Pengiriman',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _orderService.init();

    int initialIndex = 0;
    if (widget.initialStatus != null) {
      switch (widget.initialStatus!) {
        case OrderStatus.pendingPayment:
          initialIndex = 1;
          break;
        case OrderStatus.needHarvest:
        case OrderStatus.readyToShip:
          initialIndex = 2;
          break;
        case OrderStatus.inTransit:
        case OrderStatus.delivered:
          initialIndex = 3;
          break;
        case OrderStatus.completed:
          initialIndex = 4;
          break;
        case OrderStatus.cancelled:
          initialIndex = 5;
          break;
      }
    }

    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openOrderChat(OrderModel order) async {
    try {
      final conv = await ChatService().openDirectConversation(
        targetRole: 'admin',
        orderId: order.id,
        title: 'Pesanan #${order.id}',
        initialMessage:
            'Halo Admin Poktan, mohon informasi status pesanan #${order.id}.',
        messageType: 'ORDER_CARD',
        metadata: {
          'order_id': order.id,
          'total_amount': order.totalPrice + order.shippingFee,
        },
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatRoomScreen(conversation: conv)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka chat pesanan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders, int tabIndex) {
    switch (tabIndex) {
      case 1:
        return orders.where((o) => o.status == OrderStatus.pendingPayment).toList();
      case 2:
        return orders.where((o) => o.status == OrderStatus.needHarvest || o.status == OrderStatus.readyToShip).toList();
      case 3:
        return orders.where((o) => o.status == OrderStatus.inTransit || o.status == OrderStatus.delivered).toList();
      case 4:
        return orders.where((o) => o.status == OrderStatus.completed).toList();
      case 5:
        return orders.where((o) => o.status == OrderStatus.cancelled).toList();
      case 0:
      default:
        return orders;
    }
  }

  void _showOrderDetailSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rincian Pesanan Panen',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutral,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.status.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCanvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildSheetRow('No. Pesanan', order.id),
                        const SizedBox(height: 6),
                        _buildSheetRow('No. Resi Logistik', order.trackingNumber),
                        const SizedBox(height: 6),
                        _buildSheetRow('Metode Pembayaran', '${order.paymentMethod} (${order.paymentStatus})'),
                        const SizedBox(height: 6),
                        _buildSheetRow('Layanan Pengiriman', order.courier.serviceName),
                        const SizedBox(height: 6),
                        _buildSheetRow('Kontrol Suhu', order.temperature),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Daftar Produk Segar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCanvas,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: item.imageUrl.isNotEmpty
                                ? Image.network(item.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.sprout, size: 16))
                                : const Icon(LucideIcons.sprout, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${item.qty} ${item.unit} • ${item.grade ?? 'Grade Standar'}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.neutralMuted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rp ${item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 10),
                  _buildSheetRow('Subtotal Produk', 'Rp ${order.totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'),
                  const SizedBox(height: 6),
                  _buildSheetRow('Ongkos Kirim Cold-Chain', 'Rp ${order.shippingFee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Pembayaran',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.neutral),
                      ),
                      Text(
                        'Rp ${(order.totalPrice + order.shippingFee).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      icon: const Icon(LucideIcons.truck, size: 16),
                      label: Text('Lacak Logistik Pengiriman', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderTrackingScreen(orderId: order.id),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCancelRefundDialog(OrderModel order) async {
    final reasonCtrl = TextEditingController(
      text: 'Perubahan jadwal pengadaan pembeli',
    );
    final double gross = (order.totalPrice + order.shippingFee).toDouble();
    final double rawPct = (gross * 0.02).roundToDouble();
    final double feePreview = gross <= 0
        ? 0
        : rawPct.clamp(10000.0, 50000.0).clamp(0.0, gross);
    final double refundPreview = (gross - feePreview).clamp(0.0, gross);
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text(
            'Batalkan Pesanan (Refund Hybrid 2%)',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pembatalan sepihak oleh pembeli dikenakan biaya layanan 2% (Min. Rp 10.000, Maks. Rp 50.000):',
                style: GoogleFonts.plusJakartaSans(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                '• Nilai Pesanan: Rp ${gross.toStringAsFixed(0)}\n'
                '• Potongan Fee Platform: Rp ${feePreview.toStringAsFixed(0)}\n'
                '• Estimasi Dana Kembali: Rp ${refundPreview.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alasan Pembatalan',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(ctx),
              child: const Text('Kembali'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      setDlgState(() => submitting = true);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final res = await ApiService().cancelOrderWithRefund(
                          order.id,
                          cancelledBy: 'BUYER',
                          reason: reasonCtrl.text.trim(),
                        );
                        await _orderService.updateOrderStatus(
                          order.id,
                          OrderStatus.cancelled,
                          checkpointTitle: 'Dibatalkan Pembeli (Refund Hybrid 2%)',
                          checkpointDesc:
                              res['message']?.toString() ?? 'Dana dikembalikan sesuai kebijakan Hybrid 2%.',
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              res['message']?.toString() ??
                                  'Pesanan dibatalkan & refund tercatat.',
                            ),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      } catch (e) {
                        setDlgState(() => submitting = false);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text(submitting ? 'Memproses...' : 'Konfirmasi Batalkan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.neutralMuted),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.neutral),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.neutralMuted,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            tabAlignment: TabAlignment.start,
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<List<OrderModel>>(
            valueListenable: _orderService.ordersNotifier,
            builder: (context, orders, _) {
              return TabBarView(
                controller: _tabController,
                children: List.generate(_tabs.length, (tabIndex) {
                  final filtered = _filterOrders(orders, tabIndex);

                  if (filtered.isEmpty) {
                    return _buildEmptyState(_tabs[tabIndex]);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      return _buildBuyerOrderCard(order);
                    },
                  );
                }),
              );
            },
          ),
        ),
      ],
    );

    if (widget.isTabEmbedded) {
      return Scaffold(
        backgroundColor: AppColors.surfaceCanvas,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          automaticallyImplyLeading: false,
          title: Text(
            'Riwayat Pesanan Panen',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppColors.neutral,
            ),
          ),
        ),
        body: bodyContent,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.neutral, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Riwayat Pesanan Panen',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: AppColors.neutral,
          ),
        ),
      ),
      body: bodyContent,
    );
  }

  Widget _buildEmptyState(String tabName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.surfaceCanvas,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.receipt, size: 28, color: AppColors.neutralSubtle),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Pesanan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.neutral,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tidak ada transaksi panen pada status "$tabName".',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.neutralMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerOrderCard(OrderModel order) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final totalQty = order.items.fold<int>(0, (sum, i) => sum + i.qty);

    Color badgeBg;
    Color badgeTextColor;
    switch (order.status) {
      case OrderStatus.pendingPayment:
        badgeBg = AppColors.tertiaryTint;
        badgeTextColor = AppColors.tertiaryText;
        break;
      case OrderStatus.needHarvest:
        badgeBg = AppColors.primaryTint;
        badgeTextColor = AppColors.primary;
        break;
      case OrderStatus.readyToShip:
        badgeBg = AppColors.secondaryTint;
        badgeTextColor = AppColors.secondaryDark;
        break;
      case OrderStatus.inTransit:
        badgeBg = AppColors.secondaryTint;
        badgeTextColor = AppColors.secondaryDark;
        break;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        badgeBg = AppColors.primaryTint;
        badgeTextColor = AppColors.primary;
        break;
      case OrderStatus.cancelled:
        badgeBg = AppColors.errorTint;
        badgeTextColor = AppColors.error;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowFaint,
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
              Row(
                children: [
                  const Icon(LucideIcons.store, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    order.sellerName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${order.id} • ${order.createdAt.day} Okt ${order.createdAt.year}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              color: AppColors.neutralSubtle,
            ),
          ),
          const SizedBox(height: 10),
          if (firstItem != null)
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: firstItem.imageUrl.isNotEmpty
                      ? Image.network(
                          firstItem.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.sprout, size: 20, color: AppColors.primary),
                        )
                      : const Icon(LucideIcons.sprout, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstItem.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutral,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${firstItem.qty} ${firstItem.unit} ${order.items.length > 1 ? '(+${order.items.length - 1} produk lain)' : ''}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.neutralMuted,
                        ),
                      ),
                      Text(
                        'Kurir: ${order.courier.serviceName}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.surfaceCanvas),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Belanja ($totalQty barang)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: AppColors.neutralSubtle,
                      ),
                    ),
                    Text(
                      'Rp ${(order.totalPrice + order.shippingFee).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openOrderChat(order),
                    icon: const Icon(
                      LucideIcons.messageCircle,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      'Chat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.surfaceSoftBorder),
                      backgroundColor: AppColors.surfaceSoft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _showOrderDetailSheet(order),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.neutralBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    child: Text(
                      'Rincian',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutral,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(LucideIcons.truck, size: 13),
                    label: Text(
                      'Lacak',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(orderId: order.id),
                        ),
                      );
                    },
                  ),
                  if (order.status == OrderStatus.pendingPayment ||
                      order.status == OrderStatus.needHarvest ||
                      order.status == OrderStatus.readyToShip)
                    OutlinedButton.icon(
                      onPressed: () => _showCancelRefundDialog(order),
                      icon: const Icon(
                        LucideIcons.xCircle,
                        size: 13,
                        color: AppColors.error,
                      ),
                      label: Text(
                        'Batalkan (Refund 2%)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.errorBorder),
                        backgroundColor: AppColors.errorSoft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
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
}
