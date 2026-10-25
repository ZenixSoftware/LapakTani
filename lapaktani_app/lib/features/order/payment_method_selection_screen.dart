import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentMethodOption {
  final String code;
  final String title;
  final String subtitle;
  final String category;
  final String? badge;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const PaymentMethodOption({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.category,
    this.badge,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}

class PaymentMethodSelectionScreen extends StatefulWidget {
  final String currentSelectedCode;

  const PaymentMethodSelectionScreen({
    super.key,
    required this.currentSelectedCode,
  });

  @override
  State<PaymentMethodSelectionScreen> createState() => _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState extends State<PaymentMethodSelectionScreen> {
  static const Color _tokopediaGreen = Color(0xFF03AC0E);
  static const Color _forestDark = Color(0xFF0F172A);
  static const Color _bgCanvas = Color(0xFFF8F9FA);

  late String _selectedCode;

  static const List<PaymentMethodOption> _allMethods = [
    // LapakPay / Dompet Internal
    PaymentMethodOption(
      code: 'LAPAKPAY_SIMULATOR',
      title: 'LapakPay (Simulasi Saldo)',
      subtitle: 'Saldo dompet instan, terpotong otomatis tanpa biaya admin',
      category: 'Dompet Digital LapakTani',
      badge: 'Instan & Bebas Biaya',
      icon: LucideIcons.wallet,
      iconBg: Color(0xFFECFDF5),
      iconColor: _tokopediaGreen,
    ),

    // Virtual Account
    PaymentMethodOption(
      code: 'BCA_VA',
      title: 'BCA Virtual Account',
      subtitle: 'Verifikasi otomatis 24 jam via m-BCA, KlikBCA, atau ATM BCA',
      category: 'Virtual Account (Otomatis)',
      badge: 'Paling Populer',
      icon: LucideIcons.creditCard,
      iconBg: Color(0xFFEFF6FF),
      iconColor: Color(0xFF2563EB),
    ),
    PaymentMethodOption(
      code: 'MANDIRI_VA',
      title: 'Mandiri Virtual Account',
      subtitle: 'Bayar mudah via Livin\' by Mandiri atau ATM Mandiri',
      category: 'Virtual Account (Otomatis)',
      icon: LucideIcons.creditCard,
      iconBg: Color(0xFFEFF6FF),
      iconColor: Color(0xFF1D4ED8),
    ),
    PaymentMethodOption(
      code: 'BNI_VA',
      title: 'BNI Virtual Account',
      subtitle: 'Transaksi instan via BNI Mobile Banking atau ATM BNI',
      category: 'Virtual Account (Otomatis)',
      icon: LucideIcons.creditCard,
      iconBg: Color(0xFFEFF6FF),
      iconColor: Color(0xFF0284C7),
    ),
    PaymentMethodOption(
      code: 'BRI_VA',
      title: 'BRI Virtual Account (BRIVA)',
      subtitle: 'Dukungan luas jaringan BRImo dan ATM BRI di seluruh nusantara',
      category: 'Virtual Account (Otomatis)',
      icon: LucideIcons.creditCard,
      iconBg: Color(0xFFEFF6FF),
      iconColor: Color(0xFF0369A1),
    ),

    // QRIS & E-Wallet
    PaymentMethodOption(
      code: 'QRIS',
      title: 'QRIS (Semua Bank & E-Wallet)',
      subtitle: 'Pindai satu QR via GoPay, OVO, Dana, ShopeePay, atau m-Banking',
      category: 'QRIS & E-Wallet',
      badge: 'Scan Cepat',
      icon: LucideIcons.qrCode,
      iconBg: Color(0xFFF0FDFA),
      iconColor: Color(0xFF0D9488),
    ),
    PaymentMethodOption(
      code: 'GOPAY',
      title: 'GoPay / GoPay Later',
      subtitle: 'Bayar instan langsung terhubung ke aplikasi Gojek',
      category: 'QRIS & E-Wallet',
      icon: LucideIcons.smartphone,
      iconBg: Color(0xFFF0FDFA),
      iconColor: Color(0xFF0284C7),
    ),

    // Transfer Bank Manual
    PaymentMethodOption(
      code: 'TRANSFER_BANK',
      title: 'Transfer Bank Manual',
      subtitle: 'Kirim dana ke rekening resmi LapakTani, verifikasi sistem 1x24 jam',
      category: 'Transfer Manual',
      icon: LucideIcons.building,
      iconBg: Color(0xFFF1F5F9),
      iconColor: Color(0xFF475569),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.currentSelectedCode;
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>[];
    for (final m in _allMethods) {
      if (!categories.contains(m.category)) {
        categories.add(m.category);
      }
    }

    return Scaffold(
      backgroundColor: _bgCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: _forestDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pilih Metode Pembayaran',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _forestDark,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: categories.length,
              itemBuilder: (context, catIdx) {
                final category = categories[catIdx];
                final methodsInCat = _allMethods.where((m) => m.category == category).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
                      child: Text(
                        category,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: List.generate(methodsInCat.length, (idx) {
                          final method = methodsInCat[idx];
                          final isSelected = _selectedCode == method.code;
                          final isLast = idx == methodsInCat.length - 1;

                          return InkWell(
                            onTap: () {
                              setState(() => _selectedCode = method.code);
                            },
                            borderRadius: BorderRadius.vertical(
                              top: idx == 0 ? const Radius.circular(12) : Radius.zero,
                              bottom: isLast ? const Radius.circular(12) : Radius.zero,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFF0FDF4) : Colors.transparent,
                                border: isLast
                                    ? null
                                    : const Border(
                                        bottom: BorderSide(color: Color(0xFFF1F5F9)),
                                      ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: method.iconBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(method.icon, size: 20, color: method.iconColor),
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
                                                method.title,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: _forestDark,
                                                ),
                                              ),
                                            ),
                                            if (method.badge != null) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFD1FAE5),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  method.badge!,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF065F46),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          method.subtitle,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF64748B),
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                                    size: 20,
                                    color: isSelected ? _tokopediaGreen : const Color(0xFFCBD5E1),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    final selected = _allMethods.firstWhere(
                      (m) => m.code == _selectedCode,
                      orElse: () => _allMethods[0],
                    );
                    Navigator.pop(context, selected);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tokopediaGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Pilih Metode Pembayaran',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
