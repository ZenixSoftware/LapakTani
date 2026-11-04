import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../home/home_dashboard_screen.dart';
import 'order_success_screen.dart';

class PaymentInstructionScreen extends StatefulWidget {
  final String orderId;
  final String invoiceNumber;
  final int totalAmount;
  final int shippingFee;
  final String paymentChannel;
  final String? channelName;
  final String paymentReference;
  final String deliveryAddress;
  final String? recipientName;
  final List<dynamic>? items;
  final DateTime? expiredAt;
  final List<dynamic>? customInstructions;
  final String? qrUrl;
  final String? billCode;
  final String? deepLink;

  const PaymentInstructionScreen({
    super.key,
    required this.orderId,
    required this.invoiceNumber,
    required this.totalAmount,
    this.shippingFee = 0,
    required this.paymentChannel,
    this.channelName,
    required this.paymentReference,
    required this.deliveryAddress,
    this.recipientName,
    this.items,
    this.expiredAt,
    this.customInstructions,
    this.qrUrl,
    this.billCode,
    this.deepLink,
  });

  @override
  State<PaymentInstructionScreen> createState() => _PaymentInstructionScreenState();
}

class _PaymentInstructionScreenState extends State<PaymentInstructionScreen> with SingleTickerProviderStateMixin {
  static const Color _tokopediaGreen = Color(0xFF03AC0E);
  static const Color _forestDark = Color(0xFF0F172A);
  static const Color _warningOrange = Color(0xFFD97706);
  static const Color _bgCanvas = Color(0xFFF8F9FA);

  late DateTime _deadline;
  late Duration _remainingTime;
  Timer? _countdownTimer;
  Timer? _pollingTimer;

  bool _isCheckingStatus = false;
  bool _isSimulatingPayment = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _deadline = widget.expiredAt ?? DateTime.now().add(const Duration(hours: 24));
    _remainingTime = _deadline.difference(DateTime.now());
    if (_remainingTime.isNegative) _remainingTime = Duration.zero;

    _startCountdown();
    _startPeriodicPolling();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final diff = _deadline.difference(DateTime.now());
      if (diff.isNegative) {
        timer.cancel();
        setState(() => _remainingTime = Duration.zero);
      } else {
        setState(() => _remainingTime = diff);
      }
    });
  }

  void _startPeriodicPolling() {
    // Poll payment status every 10 seconds automatically
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await _checkPaymentStatus(silent: true);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  String _formatRupiah(num amount) {
    return 'Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours : $minutes : $seconds';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard.'),
        backgroundColor: _forestDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _checkPaymentStatus({bool silent = false}) async {
    if (_isCheckingStatus) return;
    if (!silent) setState(() => _isCheckingStatus = true);

    try {
      final statusData = await ApiService().checkPaymentStatus(widget.orderId);
      if (statusData != null && mounted) {
        final paymentStatus = statusData['payment_status']?.toString().toUpperCase();
        final orderStatus = statusData['order_status']?.toString().toUpperCase();
        if (paymentStatus == 'PAID' || paymentStatus == 'SETTLEMENT' || orderStatus == 'PROCESSING' || orderStatus == 'COMPLETED') {
          _countdownTimer?.cancel();
          _pollingTimer?.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderSuccessScreen(
                orderId: widget.orderId,
                invoiceNumber: widget.invoiceNumber,
                totalAmount: widget.totalAmount,
                shippingFee: widget.shippingFee,
                paymentMethod: widget.channelName ?? widget.paymentChannel,
                deliveryAddress: widget.deliveryAddress,
                recipientName: widget.recipientName,
                items: widget.items,
                createdAt: DateTime.now(),
              ),
            ),
          );
          return;
        } else if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status saat ini: Menunggu Pembayaran ($paymentStatus)'),
              backgroundColor: const Color(0xFF334155),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum ada pembayaran yang terverifikasi. Silakan selesaikan transaksi.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memeriksa status pembayaran. Coba beberapa saat lagi.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted && !silent) setState(() => _isCheckingStatus = false);
    }
  }

  Future<void> _handleSimulateWebhookPayment() async {
    if (_isSimulatingPayment) return;
    setState(() => _isSimulatingPayment = true);

    try {
      final success = await ApiService().simulatePaymentWebhook(widget.orderId, status: 'settlement');
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulasi Webhook Berhasil: Pembayaran Gateway Terverifikasi (Settlement)!'),
            backgroundColor: _tokopediaGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          _countdownTimer?.cancel();
          _pollingTimer?.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderSuccessScreen(
                orderId: widget.orderId,
                invoiceNumber: widget.invoiceNumber,
                totalAmount: widget.totalAmount,
                shippingFee: widget.shippingFee,
                paymentMethod: widget.channelName ?? widget.paymentChannel,
                deliveryAddress: widget.deliveryAddress,
                recipientName: widget.recipientName,
                items: widget.items,
                createdAt: DateTime.now(),
              ),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim simulasi webhook ke server.'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSimulatingPayment = false);
    }
  }

  bool get _isQris => widget.paymentChannel.toUpperCase().contains('QRIS');

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
          (route) => false,
        );
      },
      child: Scaffold(
        backgroundColor: _bgCanvas,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: _forestDark, size: 20),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
                (route) => false,
              );
            },
          ),
          title: Text(
            'Instruksi Pembayaran',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _forestDark),
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.home, color: _forestDark, size: 20),
              tooltip: 'Ke Beranda',
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    children: [
                      _buildCountdownCard(),
                      const SizedBox(height: 14),
                      _buildPaymentReferenceCard(),
                      const SizedBox(height: 14),
                      _buildOrderSummaryCard(),
                      const SizedBox(height: 14),
                      _buildInstructionTabs(),
                      const SizedBox(height: 14),
                      _buildMidtransSandboxNoticeCard(),
                      const SizedBox(height: 14),
                      _buildSimulatorActionCard(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildStickyBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.clock, size: 22, color: _warningOrange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selesaikan Pembayaran Dalam',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDuration(_remainingTime),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _warningOrange,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Jatuh tempo: ${_deadline.day.toString().padLeft(2, '0')}/${_deadline.month.toString().padLeft(2, '0')}/${_deadline.year} ${_deadline.hour.toString().padLeft(2, '0')}:${_deadline.minute.toString().padLeft(2, '0')} WIB',
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentReferenceCard() {
    final title = widget.channelName ?? widget.paymentChannel.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _forestDark),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Verifikasi Otomatis',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF1D4ED8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          if (_isQris) ...[
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        widget.qrUrl != null && widget.qrUrl!.isNotEmpty
                            ? Image.network(
                                widget.qrUrl!,
                                height: 140,
                                width: 140,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.qrCode, size: 140, color: _forestDark),
                              )
                            : const Icon(LucideIcons.qrCode, size: 140, color: _forestDark),
                        const SizedBox(height: 8),
                        Text(
                          'QRIS Standar Nasional (NMID: ID102488921)',
                          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pindai kode QRIS menggunakan e-Wallet atau aplikasi m-Banking Anda',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Nomor Virtual Account / Rekening',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SelectableText(
                      widget.paymentReference,
                      style: GoogleFonts.robotoMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _copyToClipboard(widget.paymentReference, 'Nomor Pembayaran'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.copy, size: 14, color: _tokopediaGreen),
                          const SizedBox(width: 4),
                          Text(
                            'Salin',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _tokopediaGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Nominal Transfer',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              Row(
                children: [
                  Text(
                    _formatRupiah(widget.totalAmount),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _tokopediaGreen,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _copyToClipboard(widget.totalAmount.toString(), 'Nominal Total'),
                    child: const Icon(LucideIcons.copy, size: 14, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nomor Invoice',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              SelectableText(
                widget.invoiceNumber,
                style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.w700, color: _forestDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Transaksi',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Menunggu Pembayaran',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alamat Pengiriman',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              Expanded(
                child: Text(
                  widget.deliveryAddress,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: _forestDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, left: 16, right: 16),
            child: Text(
              'Tata Cara Pembayaran',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _forestDark),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: _tokopediaGreen,
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: _tokopediaGreen,
            labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'm-Banking'),
              Tab(text: 'ATM'),
              Tab(text: 'i-Banking'),
            ],
          ),
          SizedBox(
            height: 180,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGuideList([
                  'Buka aplikasi mobile banking pada ponsel Anda dan lakukan login.',
                  'Pilih menu "Transfer" atau "Bayar" lalu pilih "Virtual Account".',
                  'Ketik nomor virtual account ${widget.paymentReference} atau pilih dari daftar.',
                  'Pastikan nama merchant LapakTani dan nominal ${_formatRupiah(widget.totalAmount)} sesuai.',
                  'Masukkan PIN m-Banking untuk menyelesaikan transaksi.',
                ]),
                _buildGuideList([
                  'Masukkan kartu ATM dan 6 digit PIN Anda.',
                  'Pilih menu "Transaksi Lainnya" > "Transfer" / "Pembayaran".',
                  'Pilih opsi "Ke Rekening Virtual Account".',
                  'Masukkan nomor virtual account: ${widget.paymentReference}.',
                  'Periksa rincian pesanan LapakTani pada layar lalu tekan "Benar" untuk membayar.',
                ]),
                _buildGuideList([
                  'Login ke portal Internet Banking bank yang Anda gunakan.',
                  'Pilih menu "Transfer Tagihan" atau "Multi Payment".',
                  'Masukkan kode perusahaan/biller dan nomor pembayaran ${widget.paymentReference}.',
                  'Otorisasi pembayaran menggunakan token atau kode SMS OTP.',
                  'Simpan bukti transfer elektronik sebagai arsip pesanan Anda.',
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideList(List<String> steps) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: steps.length,
      itemBuilder: (context, idx) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${idx + 1}',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  steps[idx],
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF334155), height: 1.35),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMidtransSandboxNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.info, size: 16, color: Color(0xFF1D4ED8)),
              const SizedBox(width: 6),
              Text(
                'Mode Sandbox Midtrans Aktif',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E40AF)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Uji pembayaran menggunakan simulator resmi Midtrans di simulator.sandbox.midtrans.com dengan memasukkan Nomor VA di atas.',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1E3A8A), height: 1.35),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _copyToClipboard('https://simulator.sandbox.midtrans.com/', 'Link Simulator Midtrans'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.externalLink, size: 13, color: Color(0xFF2563EB)),
                const SizedBox(width: 4),
                Text(
                  'Salin link simulator.sandbox.midtrans.com',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatorActionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.terminal, size: 16, color: _tokopediaGreen),
              const SizedBox(width: 6),
              Text(
                'Demo Simulator Webhook Payment Gateway',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF166534)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Klik tombol di bawah untuk menyimulasikan notifikasi HTTP POST webhook (settlement) dari payment gateway ke server lokal secara otomatis.',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF15803D)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: _isSimulatingPayment ? null : _handleSimulateWebhookPayment,
              icon: _isSimulatingPayment
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.zap, size: 14),
              label: Text(
                _isSimulatingPayment ? 'Mengirim Webhook...' : 'Simulasi Callback Pembayaran Berhasil',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _tokopediaGreen,
                side: const BorderSide(color: _tokopediaGreen, width: 1.2),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Belanja Lagi',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isCheckingStatus ? null : () => _checkPaymentStatus(silent: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tokopediaGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isCheckingStatus
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      'Cek Status',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
