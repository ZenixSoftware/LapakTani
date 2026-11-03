import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/lapaktani_text_field.dart';
import '../services/poktan_service.dart';

class CreateB2BOrderSheet extends StatefulWidget {
  final VoidCallback onOrderCreated;

  const CreateB2BOrderSheet({
    super.key,
    required this.onOrderCreated,
  });

  @override
  State<CreateB2BOrderSheet> createState() => _CreateB2BOrderSheetState();
}

class _CreateB2BOrderSheetState extends State<CreateB2BOrderSheet> {
  final PoktanService _poktanService = PoktanService();
  final TextEditingController _buyerController = TextEditingController();
  final TextEditingController _quotaController = TextEditingController();

  List<Map<String, String>> _commodities = [];
  String? _selectedCommodityId;
  String? _selectedCommodityName;
  DateTime? _selectedDeadline;
  bool _isLoadingCommodities = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCommodities();
    _selectedDeadline = DateTime.now().add(const Duration(days: 45));
  }

  @override
  void dispose() {
    _buyerController.dispose();
    _quotaController.dispose();
    super.dispose();
  }

  Future<void> _loadCommodities() async {
    final list = await _poktanService.fetchCommodities();
    if (!mounted) return;
    setState(() {
      _commodities = list;
      if (list.isNotEmpty) {
        _selectedCommodityId = list.first['id'];
        _selectedCommodityName = list.first['name'];
      }
      _isLoadingCommodities = false;
    });
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Color(0xFF121C2A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _submitOrder() async {
    final buyer = _buyerController.text.trim();
    final quotaText = _quotaController.text.trim().replaceAll('.', '').replaceAll(',', '.');
    final quota = double.tryParse(quotaText) ?? 0;

    if (buyer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nama mitra / pembeli B2B.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedCommodityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih komoditas panen yang dipesan.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (quota <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total kuota panen (kg) harus lebih besar dari 0.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tentukan tenggat waktu penyelesaian panen.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final dateFormat = DateFormat('yyyy-MM-dd');
    final success = await _poktanService.createB2BOrder(
      commodityId: _selectedCommodityId!,
      commodityName: _selectedCommodityName ?? 'Komoditas',
      totalQuotaKg: quota,
      buyerName: buyer,
      deadline: dateFormat.format(_selectedDeadline!),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      widget.onOrderCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan kontrak B2B berhasil didaftarkan.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mendaftarkan pesanan B2B. Coba beberapa saat lagi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy');

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.fileText, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pendaftaran Kontrak B2B Baru',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF121C2A),
                          ),
                        ),
                        Text(
                          'Input pesanan borongan institusi untuk kelompok tani',
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
              const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),

              // Buyer Name
              Text(
                'Nama Pembeli / Industri / Mitra B2B',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              LapaktaniTextField(
                controller: _buyerController,
                hintText: 'Contoh: PT Indofood CBP Sukses Makmur',
                prefixIcon: LucideIcons.building,
              ),
              const SizedBox(height: 16),

              // Commodity Dropdown
              Text(
                'Komoditas Pertanian',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: _isLoadingCommodities
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCommodityId,
                          isExpanded: true,
                          icon: const Icon(LucideIcons.chevronDown, size: 20, color: Color(0xFF64748B)),
                          items: _commodities.map((c) {
                            return DropdownMenuItem<String>(
                              value: c['id'],
                              child: Text(
                                c['name'] ?? 'Komoditas',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF121C2A),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCommodityId = val;
                              final match = _commodities.firstWhere(
                                (c) => c['id'] == val,
                                orElse: () => {'id': '', 'name': 'Komoditas'},
                              );
                              _selectedCommodityName = match['name'];
                            });
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Total Quota
              Text(
                'Total Target Kuota Panen (kg)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              LapaktaniTextField(
                controller: _quotaController,
                keyboardType: TextInputType.number,
                hintText: 'Contoh: 10000 (untuk 10 ton)',
                prefixIcon: LucideIcons.scale,
              ),
              const SizedBox(height: 16),

              // Deadline Picker
              Text(
                'Tenggat Waktu Pengiriman Kontrak',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDeadline,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 20, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDeadline != null
                              ? dateFormat.format(_selectedDeadline!)
                              : 'Pilih Tanggal Tenggat',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF121C2A),
                          ),
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Simpan Kontrak B2B',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

