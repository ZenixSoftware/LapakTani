import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../cart/cart_screen.dart';
import '../orders/models/order_model.dart';
import '../orders/services/order_service.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItemModel>? cartItems;
  final bool protectionActive;

  const CheckoutScreen({
    super.key,
    this.cartItems,
    this.protectionActive = true,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color _tokopediaGreen = Color(0xFF03AC0E);
  static const Color _bgCanvas = Color(0xFFF4F5F7);

  String _recipientName = 'Budi Santoso';
  String _recipientPhone = '081234567890';
  String _deliveryAddress = 'Jl. Maribaya No. 42, Lembang, Kab. Bandung Barat, 40391';
  String _pinpointNote = 'Titik jemput akurat: Depan Pos Kamling RT 03';

  int _selectedLogisticsIndex = 0;
  String _selectedPaymentMethod = 'LapakPay';
  bool _useCoins = true;
  bool _isSubmitting = false;

  late List<CartItemModel> _items;

  @override
  void initState() {
    super.initState();
    if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
      _items = List.from(widget.cartItems!);
    } else {
      _items = [
        CartItemModel(
          id: 'item-101',
          productId: 'prod-101',
          title: 'Tomat Merah Segar Organik',
          price: 18000,
          originalPrice: 20000,
          unit: '1 Kg • Dipanen H-0',
          imageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBBUeQQkLkwA0I2VXF5irHUKe8vRN40RaSKjeYY3tcfETF6lLLZ9RBEBp5c9Uz7pvCNf1i_gTNYJGXD53u57_ySh7-pSMw0VHVhKykayGa8she-MFBkA8F4Yy13pKEmifO2be2NjHwc0go6tKNOLBxw5UvnJWGspjM6Mvjm3GaW3ELU96QY67buby_ENZE4rK7sXyot9QBF8eI8QMsQ2HNZ3XYjf12xKn59wyj-PsbmVAOb2bvo5Omi',
          farmerId: 'farmer-wayan',
          farmerName: 'Kebun Manik Sari (Pak Wayan)',
          originLocation: 'Lembang, Jawa Barat',
          quantity: 1,
        ),
        CartItemModel(
          id: 'item-102',
          productId: 'prod-102',
          title: 'Kangkung Hidroponik Bebas Pestisida',
          price: 12000,
          originalPrice: 15000,
          unit: '3 Ikat (±750 gr)',
          imageUrl:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuAT_eYBcUG1R1OC_LNsuwsPoDDZ7z1EY5DeJbWlyFaniPn_pCcLN2qEZfGPDPJtPjgAVT97xV64X9hq1kSZWldMt96SjOkuPARKczQOVwiOXu3AbfUNOMbi66iOVPvYglml_Q4G2ZqihHtwkTpA1hDCAzoUBtoJasQtz8nA7NGsHeZguW7VNlsgJY9qTnerIeYk3ZPuthD45YxBSTFwarUKhD2TME7R9Pc2Mngb_oQgW01w3DKjOo95',
          farmerId: 'farmer-wayan',
          farmerName: 'Kebun Manik Sari (Pak Wayan)',
          originLocation: 'Lembang, Jawa Barat',
          quantity: 1,
        ),
      ];
    }
  }

  int get _itemsSubtotal => _items.fold(0, (sum, i) => sum + (i.price * i.quantity));

  int get _shippingCost => _selectedLogisticsIndex == 0 ? 0 : 8000;
  int get _shippingOriginalCost => _selectedLogisticsIndex == 0 ? 10000 : 15000;
  int get _shippingDiscount => _shippingOriginalCost - _shippingCost;
  int get _shoppingDiscount => 5000;
  int get _serviceFee => 1000;
  int get _coinDiscount => _useCoins ? 350 : 0;

  int get _totalBilling {
    final raw = _itemsSubtotal + _shippingCost - _shoppingDiscount + _serviceFee - _coinDiscount;
    return raw > 0 ? raw : 0;
  }

  String _formatRupiah(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(s[i]);
    }
    return 'Rp${buffer.toString()}';
  }

  void _showChangeAddressModal() {
    final nameCtrl = TextEditingController(text: _recipientName);
    final phoneCtrl = TextEditingController(text: _recipientPhone);
    final addrCtrl = TextEditingController(text: _deliveryAddress);
    final noteCtrl = TextEditingController(text: _pinpointNote);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
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
                      'Ubah Alamat Pengiriman',
                      style: GoogleFonts.inter(
                        fontSize: 16,
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
                const SizedBox(height: 14),
                _buildModalTextField('Nama Penerima', nameCtrl),
                const SizedBox(height: 10),
                _buildModalTextField('No. Handphone', phoneCtrl, keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                _buildModalTextField('Alamat Lengkap', addrCtrl, maxLines: 2),
                const SizedBox(height: 10),
                _buildModalTextField('Catatan Titik Jemput', noteCtrl),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _recipientName = nameCtrl.text.trim();
                        _recipientPhone = phoneCtrl.text.trim();
                        _deliveryAddress = addrCtrl.text.trim();
                        _pinpointNote = noteCtrl.text.trim();
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tokopediaGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Simpan Alamat', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalTextField(String label, TextEditingController ctrl, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _tokopediaGreen, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Future<void> _handleCreateOrder() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final orderItems = _items.map((i) {
        return OrderItem(
          id: 'item-${DateTime.now().millisecondsSinceEpoch}-${i.id}',
          productId: i.productId,
          title: i.title,
          qty: i.quantity,
          unit: i.unit,
          price: i.price,
          imageUrl: i.imageUrl,
          grade: i.badgeText,
        );
      }).toList();

      final newOrder = await OrderService().createNewOrder(
        buyerName: _recipientName,
        buyerAddress: _deliveryAddress,
        buyerPhone: _recipientPhone,
        items: orderItems,
        totalPrice: _totalBilling,
        shippingFee: _shippingCost,
        paymentMethod: '$_selectedPaymentMethod (Lunas)',
      );

      // Clean ordered items from backend cart
      for (final item in _items) {
        try {
          await ApiService().removeCartItem(item.id);
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pesanan ${newOrder.id} berhasil dibuat. Kurir agribisnis siap menjemput panen.',
              style: GoogleFonts.inter(fontSize: 12),
            ),
            backgroundColor: _tokopediaGreen,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: newOrder.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat pesanan: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCanvas,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildAddressCard(),
                    _buildOrderDetailsCard(),
                    _buildLogisticsSelectorCard(),
                    _buildVouchersAndBenefitsCard(),
                    _buildPaymentMethodCard(),
                    _buildCostBreakdownCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildStickyBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                'Pengiriman & Pembayaran',
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

  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(color: _tokopediaGreen, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('1', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 6),
              Text(
                'Pengiriman',
                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: _tokopediaGreen),
              ),
            ],
          ),
          Container(width: 32, height: 2, color: _tokopediaGreen),
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(color: _tokopediaGreen, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('2', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 6),
              Text(
                'Pembayaran',
                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: _tokopediaGreen),
              ),
            ],
          ),
          Container(width: 32, height: 2, color: const Color(0xFFE2E8F0)),
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('3', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
              ),
              const SizedBox(width: 6),
              Text(
                'Selesai',
                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
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
                  const Icon(LucideIcons.mapPin, size: 15, color: _tokopediaGreen),
                  const SizedBox(width: 6),
                  Text(
                    'Alamat Pengiriman',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _showChangeAddressModal,
                child: Text(
                  'Ganti Alamat',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _tokopediaGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(left: 10),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: _tokopediaGreen, width: 2.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _recipientName,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Rumah',
                        style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFF065F46)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _recipientPhone,
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _deliveryAddress,
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF334155), height: 1.3),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.crosshair, size: 11, color: _tokopediaGreen),
                    const SizedBox(width: 4),
                    Text(
                      _pinpointNote,
                      style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
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
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD1FAE5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.sprout, size: 14, color: _tokopediaGreen),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Kebun Manik Sari (Pak Wayan)',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.checkCircle2, size: 11, color: _tokopediaGreen),
                        ],
                      ),
                      Text(
                        'Lembang, Jawa Barat • Panen Subuh 04:30 WIB',
                        style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B)),
                      ),
                    ],
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
                  'Petani Langsung',
                  style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFF065F46)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          ..._items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: const Color(0xFFF1F5F9),
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.image, size: 18, color: Color(0xFFCBD5E1)),
                      ),
                    ),
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
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        ),
                        Text(
                          item.unit,
                          style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                        ),
                        Text(
                          _formatRupiah(item.price),
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.quantity}x',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal Pesanan (${_items.length} Barang)',
                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
              ),
              Text(
                _formatRupiah(_itemsSubtotal),
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsSelectorCard() {
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
          Text(
            'Pilih Pengiriman LapakTani',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          _buildLogisticsOption(
            index: 0,
            title: 'Kurir Instan Panen Subuh (1–2 Jam)',
            eta: 'Estimasi tiba hari ini, 07:00 - 08:30 WIB',
            originalPrice: 'Rp10.000',
            price: 'Rp0',
            icon: LucideIcons.bike,
            featureBadge: 'Dikirim langsung via Thermal Insulated Bag (Cold-Box 4°C)',
          ),
          const SizedBox(height: 8),
          _buildLogisticsOption(
            index: 1,
            title: 'Kurir Pendingin Mitra Tani (Sameday)',
            eta: 'Tiba sore ini, 15:00 - 17:00 WIB',
            originalPrice: 'Rp15.000',
            price: 'Rp8.000',
            icon: LucideIcons.truck,
            featureBadge: 'Pendingin aktif komoditas rentan layu',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldAlert, size: 15, color: _tokopediaGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF065F46), height: 1.3),
                      children: const [
                        TextSpan(text: 'Garansi Pasti Segar 2 Jam: ', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: 'Sayur layu diganti 100% baru atau pengembalian saldo instan.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsOption({
    required int index,
    required String title,
    required String eta,
    required String originalPrice,
    required String price,
    required IconData icon,
    required String featureBadge,
  }) {
    final bool isSelected = _selectedLogisticsIndex == index;

    return InkWell(
      onTap: () {
        setState(() => _selectedLogisticsIndex = index);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _tokopediaGreen : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: _tokopediaGreen),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      originalPrice,
                      style: GoogleFonts.inter(fontSize: 10, decoration: TextDecoration.lineThrough, color: const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      price,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _tokopediaGreen),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Text(
                eta,
                style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF475569)),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.snowflake, size: 10, color: Color(0xFF059669)),
                  const SizedBox(width: 4),
                  Text(
                    featureBadge,
                    style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w600, color: const Color(0xFF065F46)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVouchersAndBenefitsCard() {
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
              Text(
                'Voucher & Keuntungan',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
              Text(
                'Makin Hemat',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _tokopediaGreen),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFECFDF5), Color(0xFFCCFBF1)]),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _tokopediaGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.tag, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BEBAS ONGKIR & Diskon Panen 10%',
                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        ),
                        Text(
                          'Hemat total Rp15.000 untuk pengiriman instan',
                          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF047857)),
                        ),
                      ],
                    ),
                  ],
                ),
                const Icon(LucideIcons.checkCircle2, size: 18, color: _tokopediaGreen),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.coins, size: 14, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tukarkan 350 Koin LapakTani',
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      ),
                      Text(
                        'Hemat Rp350 dari saldo koin panen',
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: _useCoins,
                onChanged: (val) => setState(() => _useCoins = val),
                activeThumbColor: _tokopediaGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
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
              Text(
                'Metode Pembayaran',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
              Text(
                'Lihat Semua',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _tokopediaGreen),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            title: 'LapakPay',
            subtitle: 'Saldo Aktif: Rp250.000',
            badge: 'Bebas Biaya Jasa',
            icon: LucideIcons.wallet,
            iconBg: const Color(0xFFECFDF5),
            iconColor: _tokopediaGreen,
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            title: 'BCA Virtual Account',
            subtitle: 'Verifikasi otomatis instan 24/7',
            icon: LucideIcons.creditCard,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            title: 'GoPay / QRIS',
            subtitle: 'Pindai kode QR via aplikasi perbankan',
            icon: LucideIcons.qrCode,
            iconBg: const Color(0xFFF0FDFA),
            iconColor: const Color(0xFF0D9488),
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            title: 'COD (Bayar di Tempat)',
            subtitle: 'Bayar tunai ke kurir saat sayur tiba',
            icon: LucideIcons.banknote,
            iconBg: const Color(0xFFF1F5F9),
            iconColor: const Color(0xFF475569),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    String? badge,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    final bool isSelected = _selectedPaymentMethod == title;

    return InkWell(
      onTap: () {
        setState(() => _selectedPaymentMethod = title);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _tokopediaGreen : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF065F46)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
            Icon(
              isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              size: 18,
              color: isSelected ? _tokopediaGreen : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostBreakdownCard() {
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
          Text(
            'Rincian Pembayaran',
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          _buildBreakdownRow('Total Harga Barang (${_items.length} barang)', _formatRupiah(_itemsSubtotal)),
          const SizedBox(height: 6),
          _buildBreakdownRow('Total Ongkos Kirim', _formatRupiah(_shippingOriginalCost)),
          const SizedBox(height: 6),
          _buildBreakdownRow('Diskon Ongkos Kirim', '-${_formatRupiah(_shippingDiscount)}', isHighlight: true),
          const SizedBox(height: 6),
          _buildBreakdownRow('Diskon Belanja Pertanian', '-${_formatRupiah(_shoppingDiscount)}', isHighlight: true),
          if (_useCoins) ...[
            const SizedBox(height: 6),
            _buildBreakdownRow('Penggunaan Koin LapakTani', '-${_formatRupiah(_coinDiscount)}', isHighlight: true),
          ],
          const SizedBox(height: 6),
          _buildBreakdownRow('Biaya Jasa Aplikasi', _formatRupiah(_serviceFee)),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Tagihan',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
              Text(
                _formatRupiah(_totalBilling),
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: _tokopediaGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: isHighlight ? _tokopediaGreen : const Color(0xFF64748B),
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isHighlight ? _tokopediaGreen : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Tagihan',
                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
              ),
              Text(
                _formatRupiah(_totalBilling),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  const Icon(LucideIcons.lock, size: 10, color: _tokopediaGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Terenkripsi 256-bit • LapakTani Guarantee',
                    style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleCreateOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: _tokopediaGreen,
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              foregroundColor: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Bayar Sekarang',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }
}
