import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../order/checkout_screen.dart';

class CartItemModel {
  final String id;
  final String productId;
  final String title;
  final int price;
  final int originalPrice;
  final String unit;
  final String imageUrl;
  final String farmerId;
  final String farmerName;
  final String originLocation;
  final String badgeText;
  int quantity;
  bool isChecked;
  String notes;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.title,
    required this.price,
    this.originalPrice = 0,
    required this.unit,
    required this.imageUrl,
    required this.farmerId,
    required this.farmerName,
    required this.originLocation,
    this.badgeText = 'Mitra Official',
    this.quantity = 1,
    this.isChecked = true,
    this.notes = '',
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final priceVal = json['price_per_kg'] ?? json['price'] ?? 0;
    final int price = priceVal is num ? priceVal.toInt() : int.tryParse(priceVal.toString()) ?? 0;
    final int origPrice = (price * 1.2).round();

    return CartItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['product_title']?.toString() ?? json['title']?.toString() ?? 'Komoditas Segar',
      price: price > 0 ? price : 15000,
      originalPrice: origPrice > price ? origPrice : (price + 3000),
      unit: json['unit_name']?.toString() ?? json['unit']?.toString() ?? '1 Kg',
      imageUrl: json['image_url']?.toString() ?? '',
      farmerId: json['farmer_id']?.toString() ?? 'farmer-1',
      farmerName: json['farmer_name']?.toString() ?? 'Kebun Manik Sari (Pak Wayan)',
      originLocation: json['origin_location']?.toString() ?? 'Lembang, Bandung Barat',
      badgeText: 'Mitra Official',
      quantity: json['quantity'] is num ? (json['quantity'] as num).toInt() : 1,
      isChecked: true,
      notes: '',
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<CartItemModel> _cartItems = [];

  static const Color _tokopediaGreen = AppColors.primary;
  static const Color _bgCanvas = AppColors.background;

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  Future<void> _loadCartData() async {
    setState(() => _isLoading = true);
    try {
      final backendItems = await _apiService.getCartItems();
      if (backendItems.isNotEmpty) {
        _cartItems = backendItems.map((e) => CartItemModel.fromJson(e)).toList();
      } else {
        _cartItems = [];
      }
    } catch (_) {
      _cartItems = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  bool get _isAllSelected => _cartItems.isNotEmpty && _cartItems.every((item) => item.isChecked);

  int get _selectedItemCount => _cartItems.where((i) => i.isChecked).fold(0, (sum, i) => sum + i.quantity);

  int get _totalPrice {
    return _cartItems.where((i) => i.isChecked).fold(0, (sum, i) => sum + (i.price * i.quantity));
  }

  int get _totalSavings {
    return _cartItems.where((i) => i.isChecked).fold(0, (sum, i) {
      final diff = i.originalPrice > i.price ? (i.originalPrice - i.price) * i.quantity : 0;
      return sum + diff;
    });
  }

  void _toggleSelectAll(bool? val) {
    final target = val ?? false;
    setState(() {
      for (final item in _cartItems) {
        item.isChecked = target;
      }
    });
  }

  void _toggleFarmerGroup(String farmerId, bool val) {
    setState(() {
      for (final item in _cartItems.where((i) => i.farmerId == farmerId)) {
        item.isChecked = val;
      }
    });
  }

  Future<void> _updateQuantity(CartItemModel item, int newQty) async {
    if (newQty <= 0) {
      _confirmDeleteItem(item);
      return;
    }
    setState(() {
      item.quantity = newQty;
    });
    try {
      await _apiService.updateCartQty(cartItemId: item.id, quantity: newQty);
    } catch (_) {}
  }

  void _confirmDeleteItem(CartItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Barang?',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${item.title}" dari keranjang?',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _cartItems.removeWhere((i) => i.id == item.id);
              });
              try {
                await _apiService.removeCartItem(item.id);
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Hapus', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _deleteSelectedItems() {
    final selectedCount = _cartItems.where((i) => i.isChecked).length;
    if (selectedCount == 0) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus $selectedCount Barang Terpilih?',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Barang yang dipilih akan dihapus dari keranjang belanja Anda.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final idsToRemove = _cartItems.where((i) => i.isChecked).map((i) => i.id).toList();
              setState(() {
                _cartItems.removeWhere((i) => i.isChecked);
              });
              for (final id in idsToRemove) {
                try {
                  await _apiService.removeCartItem(id);
                } catch (_) {}
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Hapus Semua', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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

  void _proceedToCheckout() {
    final selectedItems = _cartItems.where((i) => i.isChecked).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan pilih minimal 1 produk untuk checkout.',
            style: GoogleFonts.inter(fontSize: 12),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          cartItems: selectedItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group items by farmerId
    final Map<String, List<CartItemModel>> groupedItems = {};
    for (final item in _cartItems) {
      groupedItems.putIfAbsent(item.farmerId, () => []).add(item);
    }

    return Scaffold(
      backgroundColor: _bgCanvas,
      body: SafeArea(
        child: Column(
          children: [
            _buildStickyHeader(),
            _buildFreeShippingBanner(),
            _buildSelectAllRow(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _tokopediaGreen),
                    )
                  : _cartItems.isEmpty
                      ? _buildEmptyCart()
                      : RefreshIndicator(
                          onRefresh: _loadCartData,
                          color: _tokopediaGreen,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                ...groupedItems.entries.map((entry) {
                                  return _buildFarmerGroupCard(entry.key, entry.value);
                                }),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
            ),
            _buildStickyBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader() {
    return Container(
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
                'Keranjang',
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tautan keranjang disalin.'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
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

  Widget _buildFreeShippingBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFCCFBF1), Color(0xFFD1FAE5)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFA7F3D0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(LucideIcons.truck, size: 15, color: _tokopediaGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF064E3B)),
                      children: const [
                        TextSpan(text: 'Bebas Ongkir s.d. '),
                        TextSpan(text: 'Rp20.000', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: ' min. belanja Rp30.000'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6EE7B7)),
            ),
            child: Text(
              'Tersisa Rp0!',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF065F46),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectAllRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => _toggleSelectAll(!_isAllSelected),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _isAllSelected,
                    onChanged: _toggleSelectAll,
                    activeColor: _tokopediaGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Pilih Semua (${_cartItems.length})',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _deleteSelectedItems,
            child: Text(
              'Hapus',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE11D48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerGroupCard(String farmerId, List<CartItemModel> items) {
    final first = items.first;
    final bool isGroupAllSelected = items.every((i) => i.isChecked);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: isGroupAllSelected,
                        onChanged: (val) => _toggleFarmerGroup(farmerId, val ?? false),
                        activeColor: _tokopediaGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Text(
                        first.badgeText,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF047857),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        first.farmerName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.messageSquare, size: 16, color: Color(0xFF94A3B8)),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 2, bottom: 8),
            child: Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 11, color: _tokopediaGreen),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    first.originLocation,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
          ...items.map((item) => _buildCartItemTile(item)),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(CartItemModel item) {
    final int discountPct = item.originalPrice > item.price
        ? (((item.originalPrice - item.price) / item.originalPrice) * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF8FAFC))),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: item.isChecked,
                    onChanged: (val) {
                      setState(() {
                        item.isChecked = val ?? false;
                      });
                    },
                    activeColor: _tokopediaGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 68,
                  height: 68,
                  color: const Color(0xFFF1F5F9),
                  child: Image.network(
                    item.imageUrl.startsWith('http')
                        ? item.imageUrl
                        : '${ApiService.baseUrl.replaceAll('/api', '')}/${item.imageUrl.startsWith('/') ? item.imageUrl.substring(1) : item.imageUrl}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      LucideIcons.image,
                      size: 24,
                      color: Color(0xFFCBD5E1),
                    ),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.unit,
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF475569)),
                          ),
                        ),
                        if (discountPct > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFFECDD3)),
                            ),
                            child: Text(
                              '-$discountPct%',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFE11D48),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatRupiah(item.price),
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        if (item.originalPrice > item.price) ...[
                          const SizedBox(width: 6),
                          Text(
                            _formatRupiah(item.originalPrice),
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              decoration: TextDecoration.lineThrough,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () {},
                              child: const Icon(LucideIcons.heart, size: 16, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(width: 14),
                            InkWell(
                              onTap: () => _confirmDeleteItem(item),
                              child: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(6),
                            color: const Color(0xFFF8FAFC),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => _updateQuantity(item, item.quantity - 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    '-',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                color: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                child: Text(
                                  '${item.quantity}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => _updateQuantity(item, item.quantity + 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    '+',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _tokopediaGreen,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 8),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                onChanged: (val) => item.notes = val,
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF334155)),
                decoration: InputDecoration(
                  hintText: 'Tulis catatan untuk petani (misal: pilih yang mengkal)...',
                  hintStyle: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.shoppingBag, size: 36, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            Text(
              'Keranjang Belanja Masih Kosong',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ayo temukan komoditas sayur dan buah segar langsung dari kebun petani!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tokopediaGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'Mulai Belanja Panen',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
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
          InkWell(
            onTap: () => _toggleSelectAll(!_isAllSelected),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _isAllSelected,
                    onChanged: _toggleSelectAll,
                    activeColor: _tokopediaGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Semua',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Belanja:',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                      ),
                      Text(
                        _formatRupiah(_totalPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      if (_totalSavings > 0)
                        Text(
                          'Hemat ${_formatRupiah(_totalSavings)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: _tokopediaGreen,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _selectedItemCount > 0 ? _proceedToCheckout : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tokopediaGreen,
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  ),
                  child: Text(
                    'Beli ($_selectedItemCount)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
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
