import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../orders/models/order_model.dart';
import '../orders/services/order_service.dart';

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
  final OrderService _orderService = OrderService();

  static const Color _tokopediaGreen = Color(0xFF03AC0E);
  static const Color _bgCanvas = Color(0xFFF4F5F7);

  @override
  void initState() {
    super.initState();
    _orderService.init();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard.'),
        backgroundColor: _tokopediaGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showContactModal(String title, String contactInfo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  contactInfo,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tokopediaGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Tutup', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
      backgroundColor: _bgCanvas,
      body: SafeArea(
        child: ValueListenableBuilder<List<OrderModel>>(
          valueListenable: _orderService.ordersNotifier,
          builder: (context, orders, _) {
            final order = _orderService.getOrderById(widget.orderId) ??
                (orders.isNotEmpty
                    ? orders.first
                    : OrderModel(
                        id: widget.orderId,
                        trackingNumber: 'LT-2024-8841-B',
                        createdAt: DateTime.now(),
                        buyerName: 'Budi Santoso',
                        buyerAddress: 'Jl. Maribaya No. 42, Lembang, Kab. Bandung Barat',
                        buyerPhone: '081234567890',
                        sellerName: 'Kebun Manik Sari (Pak Wayan)',
                        sellerLocation: 'Lembang, Bandung Barat',
                        status: OrderStatus.inTransit,
                        totalPrice: 58000,
                        shippingFee: 0,
                        paymentMethod: 'LapakPay (Lunas)',
                        paymentStatus: 'Lunas',
                        estimatedDelivery: 'Hari ini, 15:30 WIB',
                        temperature: '4.2°C',
                        items: [],
                        courier: const CourierInfo(
                          name: 'Kang Asep Kurnia',
                          phone: '0813-8821-9902',
                          vehicle: 'Honda Vario • D 4821 ABZ',
                          serviceName: 'Kurir Pendingin Mitra',
                          photoUrl:
                              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                        ),
                        checkpoints: [],
                      ));

            final courier = order.courier;

            return Column(
              children: [
                _buildStickyHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildStatusHeroCard(order),
                        _buildMapInteractiveCard(order),
                        _buildCourierProfileCard(courier),
                        _buildTimelineStepperCard(order),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(LucideIcons.arrowLeft, size: 20, color: Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Lacak Pengiriman',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.shieldCheck, size: 11, color: Color(0xFF059669)),
                    const SizedBox(width: 4),
                    Text(
                      'Aman',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.share2, size: 18, color: Color(0xFF475569)),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(LucideIcons.bell, size: 18, color: Color(0xFF475569)),
                onPressed: () {},
              ),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: _tokopediaGreen,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'B',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeroCard(OrderModel order) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'No. Pesanan',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    order.trackingNumber,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _copyToClipboard(order.trackingNumber, 'Nomor resi'),
                    child: const Icon(LucideIcons.copy, size: 13, color: _tokopediaGreen),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF059669),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.status == OrderStatus.completed ? 'Pesanan Selesai' : 'Sedang Diantar Kurir Instan',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.status == OrderStatus.completed ? 'Telah Tiba di Tujuan' : 'Tiba Hari Ini, 07:45 WIB',
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(LucideIcons.clock, size: 13, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Text(
                order.status == OrderStatus.completed
                    ? 'Pesanan berhasil diserahterimakan ke pembeli'
                    : 'Perkiraan 15 menit lagi sampai di tujuan',
                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.thermometerSnowflake, size: 12, color: Color(0xFF059669)),
                  const SizedBox(width: 4),
                  Text(
                    'Rantai Pendingin Aktif 4°C',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF047857)),
                  ),
                ],
              ),
              Text(
                order.status == OrderStatus.completed ? '100% Selesai' : '75% Perjalanan',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF047857)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: order.status == OrderStatus.completed ? 1.0 : 0.75,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(_tokopediaGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapInteractiveCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuC5Fiej1WQc5r68GOTf0FRKHdsbtV-gJ-Y-fYzf1pe7U082mHGXp0cBEmdTIn2s3KUE10zDltcSeflldCRfxfLY_mn1YZ9R03NbYWn8UZxFnBjP8RguGAsKcsJ4o_JoTOZnOYPsO_mix4JB4Aaaei56A2dKxecusBcunE_qNbVRIQQJ1JZOigiVNYphb9crzuNrXBfNE_60-Os6m7B-bYNJmFscaNMVkAV15NPielGHrJ85BA7hywjW',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFF1F5F9),
                  child: const Center(
                    child: Icon(LucideIcons.map, size: 40, color: Color(0xFF94A3B8)),
                  ),
                ),
              ),
            ),
            // Top origin farm chip
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
                      child: const Icon(LucideIcons.wheat, size: 11, color: _tokopediaGreen),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ASAL KEBUN', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
                        Text('Kebun Manik Sari (Lembang)', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Top right zoom controls
            Positioned(
              top: 10,
              right: 10,
              child: Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(LucideIcons.plus, size: 14, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(LucideIcons.minus, size: 14, color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
            // Destination address chip
            Positioned(
              bottom: 34,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(color: Color(0xFFFFE4E6), shape: BoxShape.circle),
                      child: const Icon(LucideIcons.home, size: 11, color: Color(0xFFE11D48)),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TUJUAN ANDA', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
                        Text('Jl. Maribaya No. 42', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Bottom GPS indicator
            Positioned(
              bottom: 8,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: _tokopediaGreen, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'GPS Kurir Diperbarui secara Realtime',
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourierProfileCard(CourierInfo courier) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(horizontal: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: const Color(0xFFD1FAE5),
                      child: Image.network(
                        courier.photoUrl ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.user, size: 24, color: _tokopediaGreen),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: _tokopediaGreen, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.check, size: 9, color: Colors.white),
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
                          courier.name,
                          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.star, size: 9, color: Color(0xFFD97706)),
                              SizedBox(width: 2),
                              Text(
                                '4.9',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      courier.serviceName,
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                    Text(
                      courier.vehicle,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
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
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showContactModal('Panggilan Telepon Kurir', 'Menghubungi ${courier.name} (${courier.phone})...'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _tokopediaGreen, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.phone, size: 14, color: _tokopediaGreen),
                      const SizedBox(width: 6),
                      Text(
                        'Telepon',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _tokopediaGreen),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showContactModal('Chat Langsung Kurir', 'Membuka sesi pesan instan dengan ${courier.name}...'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tokopediaGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.messageSquare, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Chat Kurir',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStepperCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(horizontal: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.navigation, size: 15, color: _tokopediaGreen),
                  const SizedBox(width: 6),
                  Text(
                    'Status Perjalanan Hasil Tani',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  'Farm-to-Door',
                  style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFF065F46)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Vertical stepper list
          _buildTimelineStep(
            isFirst: true,
            isCompleted: true,
            isActive: false,
            title: 'Dipetik Segar di Ladang',
            time: '05:00 WIB',
            description: 'Petani Pak Wayan selesai memetik sayur berembun subuh di petak hidroponik Blok B.',
          ),
          _buildTimelineStep(
            isCompleted: true,
            isActive: false,
            title: 'Sortir Mutu & Kemasan Daun Pisang',
            time: '05:45 WIB',
            description: 'Melewati quality control bebas pestisida dan dikemas higienis dengan pembungkus daun alami ramah lingkungan.',
          ),
          _buildTimelineStep(
            isCompleted: true,
            isActive: order.status != OrderStatus.completed,
            isColdboxActive: true,
            title: 'Paket Dibawa Kurir',
            time: '06:30 WIB',
            description: 'Kurir Kang Asep membawa boks pendingin termal terisolasi menuju alamat pemesan. Suhu terpantau stabil di 4°C.',
          ),
          _buildTimelineStep(
            isLast: true,
            isCompleted: order.status == OrderStatus.completed,
            isActive: false,
            title: 'Tiba di Alamat Pembeli',
            time: order.status == OrderStatus.completed ? '07:40 WIB' : 'Estimasi 07:45 WIB',
            description: 'Sayuran segar diserahterimakan langsung ke tangan pembeli dengan jaminan pasti segar 100%.',
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    bool isFirst = false,
    bool isLast = false,
    required bool isCompleted,
    required bool isActive,
    bool isColdboxActive = false,
    required String title,
    required String time,
    required String description,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isCompleted ? _tokopediaGreen : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? const Color(0xFFD1FAE5) : Colors.transparent,
                      width: isActive ? 3 : 0,
                    ),
                  ),
                  child: Icon(
                    isCompleted ? LucideIcons.check : LucideIcons.circle,
                    size: 10,
                    color: isCompleted ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? _tokopediaGreen : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive ? _tokopediaGreen : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isActive ? _tokopediaGreen : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B), height: 1.3),
                  ),
                  if (isColdboxActive) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.snowflake, size: 11, color: _tokopediaGreen),
                          const SizedBox(width: 4),
                          Text(
                            'Suhu Boks: 4.2°C (Optimal Segar)',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF065F46)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
