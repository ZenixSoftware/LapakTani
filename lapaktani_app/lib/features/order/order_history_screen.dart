import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../cart/cart_screen.dart';
import '../orders/models/order_model.dart';
import '../orders/services/order_service.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final bool isTabEmbedded;
  final String? initialFilter;

  const OrderHistoryScreen({
    super.key,
    this.isTabEmbedded = false,
    this.initialFilter,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService _orderService = OrderService();
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  static const Color _tokopediaGreen = Color(0xFF03AC0E);
  static const Color _bgCanvas = Color(0xFFF4F6F8);

  String _searchQuery = '';
  String _selectedStatusFilter = 'Semua status';
  String _selectedProductFilter = 'Semua produk';
  String _selectedDateFilter = 'Semua tanggal';

  List<OrderModel> _serverOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null && widget.initialFilter!.isNotEmpty) {
      final f = widget.initialFilter!;
      if (f.toLowerCase().contains('bayar')) {
        _selectedStatusFilter = 'Menunggu Bayar';
      } else if (f.toLowerCase().contains('kirim')) {
        _selectedStatusFilter = 'Sedang Dikirim';
      } else if (f.toLowerCase().contains('selesai')) {
        _selectedStatusFilter = 'Selesai';
      } else if (f.toLowerCase().contains('proses') || f.toLowerCase().contains('petik')) {
        _selectedStatusFilter = 'Diproses';
      } else if (f.toLowerCase().contains('batal')) {
        _selectedStatusFilter = 'Dibatalkan';
      } else {
        _selectedStatusFilter = f;
      }
    }
    _orderService.init();
    _fetchOrdersFromBackend();
  }

  Future<void> _fetchOrdersFromBackend() async {
    setState(() => _isLoading = true);
    try {
      final List<Map<String, dynamic>> rawOrders = await _apiService.getMyOrders();
      final parsed = rawOrders.map((row) => OrderModel.fromMap(row)).toList();

      if (mounted) {
        setState(() {
          _serverOrders = parsed.isNotEmpty ? parsed : _orderService.ordersNotifier.value;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[ORDER_HISTORY] Error fetching orders: $e');
      if (mounted) {
        setState(() {
          _serverOrders = _orderService.ordersNotifier.value;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _showOrderCompletionModal(BuildContext context, OrderModel order) {
    bool isFreshConfirmed = false;
    bool isWeightConfirmed = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bool canConfirm = isFreshConfirmed && isWeightConfirmed;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Verifikasi Penerimaan Panen',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pastikan komoditas pertanian yang Anda terima dalam kondisi terbaik sebelum menyelesaikan pesanan.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setModalState(() {
                                isFreshConfirmed = !isFreshConfirmed;
                              });
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: isFreshConfirmed,
                                    onChanged: (val) {
                                      setModalState(() {
                                        isFreshConfirmed = val ?? false;
                                      });
                                    },
                                    activeColor: _tokopediaGreen,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hasil panen segar dan sesuai mutu',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        'Sayur & buah tidak layu, busuk, atau cacat berlebih saat tiba.',
                                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                          ),
                          InkWell(
                            onTap: () {
                              setModalState(() {
                                isWeightConfirmed = !isWeightConfirmed;
                              });
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: isWeightConfirmed,
                                    onChanged: (val) {
                                      setModalState(() {
                                        isWeightConfirmed = val ?? false;
                                      });
                                    },
                                    activeColor: _tokopediaGreen,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Timbangan kuantitas (kg) sesuai pesanan',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        'Berat bersih dan kemasan sesuai nota pesanan LapakTani.',
                                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: canConfirm
                            ? () async {
                                Navigator.pop(ctx);
                                await _orderService.updateOrderStatus(
                                  order.id,
                                  OrderStatus.completed,
                                  checkpointTitle: 'Pesanan Selesai',
                                  checkpointDesc: 'Pembeli mengonfirmasi kualitas dan timbangan panen prima.',
                                );
                                await _fetchOrdersFromBackend();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Pesanan ${order.id} telah diselesaikan.'),
                                      backgroundColor: _tokopediaGreen,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tokopediaGreen,
                          disabledBackgroundColor: const Color(0xFFCBD5E1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Konfirmasi Selesai',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterModal(String filterType, List<String> options, String currentVal, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    filterType,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(height: 8),
                ...options.map((opt) {
                  final isSelected = opt == currentVal;
                  return ListTile(
                    title: Text(
                      opt,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? _tokopediaGreen : const Color(0xFF1E293B),
                      ),
                    ),
                    trailing: isSelected ? const Icon(LucideIcons.check, size: 18, color: _tokopediaGreen) : null,
                    onTap: () {
                      onSelect(opt);
                      Navigator.pop(ctx);
                    },
                  );
                }),
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
      appBar: widget.isTabEmbedded ? null : _buildTopAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _tokopediaGreen),
                    )
                  : RefreshIndicator(
                      color: _tokopediaGreen,
                      onRefresh: _fetchOrdersFromBackend,
                      child: Builder(
                        builder: (context) {
                          final orders = _serverOrders;
                          var filtered = orders.where((order) {
                            if (_searchQuery.isNotEmpty) {
                              final q = _searchQuery.toLowerCase();
                              final matchId = order.id.toLowerCase().contains(q);
                              final matchSeller = order.sellerName.toLowerCase().contains(q);
                              final matchProduct = order.items.any((i) => i.title.toLowerCase().contains(q));
                              if (!matchId && !matchSeller && !matchProduct) return false;
                            }

                            if (_selectedStatusFilter != 'Semua status') {
                              if (_selectedStatusFilter == 'Diproses' &&
                                  order.status != OrderStatus.needHarvest &&
                                  order.status != OrderStatus.readyToShip) {
                                return false;
                              }
                              if (_selectedStatusFilter == 'Sedang Dikirim' &&
                                  order.status != OrderStatus.inTransit &&
                                  order.status != OrderStatus.delivered) {
                                return false;
                              }
                              if (_selectedStatusFilter == 'Selesai' && order.status != OrderStatus.completed) {
                                return false;
                              }
                              if (_selectedStatusFilter == 'Menunggu Bayar' && order.status != OrderStatus.pendingPayment) {
                                return false;
                              }
                              if (_selectedStatusFilter == 'Dibatalkan' && order.status != OrderStatus.cancelled) {
                                return false;
                              }
                            }

                            return true;
                          }).toList();

                          if (filtered.isEmpty) {
                            return SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: _buildEmptyState(),
                              ),
                            );
                          }

                          return ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, idx) {
                              return _buildTokopediaOrderCard(filtered[idx]);
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, size: 20, color: Color(0xFF1E293B)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Riwayat Transaksi',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                },
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF94A3B8)),
                  hintText: 'Cari transaksi',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.messageSquare, size: 20, color: Color(0xFF475569)),
                    onPressed: () {},
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Color(0xFFE11D48), shape: BoxShape.circle),
                      child: Text('3', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.shoppingCart, size: 20, color: Color(0xFF475569)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Color(0xFFE11D48), shape: BoxShape.circle),
                      child: Text('2', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
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

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChipItem(
              label: _selectedStatusFilter,
              onTap: () {
                _showFilterModal(
                  'Pilih Status Pesanan',
                  ['Semua status', 'Menunggu Bayar', 'Diproses', 'Sedang Dikirim', 'Selesai', 'Dibatalkan'],
                  _selectedStatusFilter,
                  (val) => setState(() => _selectedStatusFilter = val),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChipItem(
              label: _selectedProductFilter,
              onTap: () {
                _showFilterModal(
                  'Pilih Kategori Produk',
                  ['Semua produk', 'Sayuran Segar', 'Buah Segar', 'Beras & Umbi'],
                  _selectedProductFilter,
                  (val) => setState(() => _selectedProductFilter = val),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChipItem(
              label: _selectedDateFilter,
              onTap: () {
                _showFilterModal(
                  'Pilih Rentang Tanggal',
                  ['Semua tanggal', '30 hari terakhir', '90 hari terakhir'],
                  _selectedDateFilter,
                  (val) => setState(() => _selectedDateFilter = val),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChipItem({required String label, required VoidCallback onTap}) {
    final bool isFiltered = !label.startsWith('Semua');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFiltered ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFiltered ? _tokopediaGreen : const Color(0xFFE2E8F0),
            width: isFiltered ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isFiltered ? FontWeight.w700 : FontWeight.w500,
                color: isFiltered ? _tokopediaGreen : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 12, color: isFiltered ? _tokopediaGreen : const Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildTokopediaOrderCard(OrderModel order) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final int otherItemsCount = order.items.length - 1;

    final String statusLabel;
    final Color badgeBg;
    final Color badgeText;
    final Color badgeBorder;

    switch (order.status) {
      case OrderStatus.completed:
        statusLabel = 'Selesai';
        badgeBg = const Color(0xFFECFDF5);
        badgeText = const Color(0xFF047857);
        badgeBorder = const Color(0xFFA7F3D0);
        break;
      case OrderStatus.inTransit:
      case OrderStatus.delivered:
        statusLabel = 'Sedang Dikirim';
        badgeBg = const Color(0xFFEFF6FF);
        badgeText = const Color(0xFF1D4ED8);
        badgeBorder = const Color(0xFFBFDBFE);
        break;
      case OrderStatus.needHarvest:
      case OrderStatus.readyToShip:
        statusLabel = 'Diproses';
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFB45309);
        badgeBorder = const Color(0xFFFDE68A);
        break;
      case OrderStatus.pendingPayment:
        statusLabel = 'Menunggu Bayar';
        badgeBg = const Color(0xFFFFF7ED);
        badgeText = const Color(0xFFC2410C);
        badgeBorder = const Color(0xFFFED7AA);
        break;
      case OrderStatus.cancelled:
        statusLabel = 'Dibatalkan';
        badgeBg = const Color(0xFFFFF1F2);
        badgeText = const Color(0xFFBE123C);
        badgeBorder = const Color(0xFFFECDD3);
        break;
    }

    final bool isCompleted = order.status == OrderStatus.completed;
    final bool isInProgress = order.status == OrderStatus.needHarvest ||
        order.status == OrderStatus.readyToShip ||
        order.status == OrderStatus.inTransit ||
        order.status == OrderStatus.delivered;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
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
                  const Icon(LucideIcons.shoppingBag, size: 16, color: Color(0xFF475569)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Belanja',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      ),
                      Text(
                        '${order.createdAt.day} ${_monthShort(order.createdAt.month)} ${order.createdAt.year}',
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: badgeBorder),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: badgeText),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.moreVertical, size: 16, color: Color(0xFF94A3B8)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (firstItem != null)
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: const Color(0xFFF1F5F9),
                    child: Image.network(
                      firstItem.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.image, size: 20, color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstItem.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        otherItemsCount > 0 ? '${firstItem.qty} barang (+ $otherItemsCount lainnya)' : '${firstItem.qty} barang (${firstItem.unit})',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total belanja',
                      style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                    ),
                    Text(
                      _formatRupiah(order.totalPrice),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    Text(
                      'Hemat Rp12.000 • 360 Koin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF047857), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isCompleted)
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menambahkan barang ke keranjang...'),
                        backgroundColor: _tokopediaGreen,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tokopediaGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    'Beli lagi',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                )
              else if (isInProgress)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderTrackingScreen(orderId: order.id),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _tokopediaGreen, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      child: Text(
                        'Lacak',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _tokopediaGreen),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: () => _showOrderCompletionModal(context, order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tokopediaGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      child: Text(
                        'Selesai',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.receipt, size: 32, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 14),
            Text(
              'Belum Ada Transaksi',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              'Riwayat belanja hasil tani dan pesanan Anda akan muncul di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  String _monthShort(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}
