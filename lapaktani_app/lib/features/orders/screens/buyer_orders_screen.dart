import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
                        color: const Color(0xFFE2E8F0),
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
                          color: const Color(0xFF121C2A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8EC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.status.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF03AC0E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      color: const Color(0xFF121C2A),
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
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: item.imageUrl.isNotEmpty
                                ? Image.network(item.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(LucideIcons.sprout, size: 16))
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
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
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
                  const Divider(color: Color(0xFFE2E8F0)),
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
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF121C2A)),
                      ),
                      Text(
                        'Rp ${(order.totalPrice + order.shippingFee).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF006E04)),
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
                        backgroundColor: const Color(0xFF03AC0E),
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

  Widget _buildSheetRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF121C2A)),
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
            labelColor: const Color(0xFF03AC0E),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF03AC0E),
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
        backgroundColor: const Color(0xFFF8F9FF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          automaticallyImplyLeading: false,
          title: Text(
            'Riwayat Pesanan Panen',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF121C2A),
            ),
          ),
        ),
        body: bodyContent,
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
        title: Text(
          'Riwayat Pesanan Panen',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF121C2A),
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
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.receipt, size: 28, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Pesanan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF121C2A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tidak ada transaksi panen pada status "$tabName".',
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

  Widget _buildBuyerOrderCard(OrderModel order) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final totalQty = order.items.fold<int>(0, (sum, i) => sum + i.qty);

    Color badgeBg;
    Color badgeTextColor;
    switch (order.status) {
      case OrderStatus.pendingPayment:
        badgeBg = const Color(0xFFFEF3C7);
        badgeTextColor = const Color(0xFF92400E);
        break;
      case OrderStatus.needHarvest:
        badgeBg = const Color(0xFFE8F8EC);
        badgeTextColor = const Color(0xFF006E04);
        break;
      case OrderStatus.readyToShip:
        badgeBg = const Color(0xFFE0E7FF);
        badgeTextColor = const Color(0xFF3730A3);
        break;
      case OrderStatus.inTransit:
        badgeBg = const Color(0xFFEFF6FF);
        badgeTextColor = const Color(0xFF1E40AF);
        break;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        badgeBg = const Color(0xFFDCFCE7);
        badgeTextColor = const Color(0xFF166534);
        break;
      case OrderStatus.cancelled:
        badgeBg = const Color(0xFFFEE2E2);
        badgeTextColor = const Color(0xFF991B1B);
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
            color: Color(0x06000000),
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
                  const Icon(LucideIcons.store, size: 14, color: Color(0xFF006E04)),
                  const SizedBox(width: 6),
                  Text(
                    order.sellerName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121C2A),
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
              color: const Color(0xFF94A3B8),
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
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: firstItem.imageUrl.isNotEmpty
                      ? Image.network(
                          firstItem.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(LucideIcons.sprout, size: 20, color: Color(0xFF03AC0E)),
                        )
                      : const Icon(LucideIcons.sprout, size: 20, color: Color(0xFF03AC0E)),
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
                          color: const Color(0xFF121C2A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${firstItem.qty} ${firstItem.unit} ${order.items.length > 1 ? '(+${order.items.length - 1} produk lain)' : ''}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'Kurir: ${order.courier.serviceName}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: const Color(0xFF03AC0E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                    'Total Belanja ($totalQty barang)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    'Rp ${(order.totalPrice + order.shippingFee).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF006E04),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => _showOrderDetailSheet(order),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      'Rincian',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(LucideIcons.truck, size: 14),
                    label: Text(
                      'Lacak',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03AC0E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
