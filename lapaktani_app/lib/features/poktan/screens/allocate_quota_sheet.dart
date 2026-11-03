import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_soft_card.dart';
import '../models/b2b_order_model.dart';
import '../models/poktan_member_model.dart';
import '../services/poktan_service.dart';

class AllocateQuotaSheet extends StatefulWidget {
  final B2BOrderModel order;
  final List<PoktanMemberModel> members;
  final VoidCallback onAllocationSuccess;

  const AllocateQuotaSheet({
    super.key,
    required this.order,
    required this.members,
    required this.onAllocationSuccess,
  });

  @override
  State<AllocateQuotaSheet> createState() => _AllocateQuotaSheetState();
}

class _AllocateQuotaSheetState extends State<AllocateQuotaSheet> {
  final PoktanService _poktanService = PoktanService();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, DateTime> _plantingDeadlines = {};
  final Map<String, DateTime> _harvestDeadlines = {};

  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final defaultHarvestDate = DateTime.tryParse(widget.order.deadline) ??
        DateTime.now().add(const Duration(days: 60));
    final defaultPlantingDate = DateTime.now().add(const Duration(days: 14));

    for (final member in widget.members) {
      _controllers[member.farmerId] = TextEditingController();
      _plantingDeadlines[member.farmerId] = defaultPlantingDate;
      _harvestDeadlines[member.farmerId] = defaultHarvestDate;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _currentAllocatedSum {
    double sum = 0;
    for (final c in _controllers.values) {
      final val = double.tryParse(c.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
      sum += val;
    }
    return sum;
  }

  double get _availableQuotaToAllocate {
    return widget.order.remainingQuotaKg;
  }

  double get _remainingAfterCurrentInput {
    return _availableQuotaToAllocate - _currentAllocatedSum;
  }

  void _distributeProportionally() {
    final double totalAvailable = _availableQuotaToAllocate;
    if (totalAvailable <= 0) return;

    double totalLandArea = 0;
    for (final m in widget.members) {
      totalLandArea += m.landAreaHa;
    }

    if (totalLandArea <= 0) return;

    setState(() {
      for (final m in widget.members) {
        final share = (m.landAreaHa / totalLandArea) * totalAvailable;
        final rounded = (share / 50).round() * 50; // Round to nearest 50 kg
        _controllers[m.farmerId]?.text = rounded.toString();
      }
    });
  }

  Future<void> _pickDate(BuildContext context, String farmerId, bool isPlanting) async {
    final initialDate = isPlanting
        ? (_plantingDeadlines[farmerId] ?? DateTime.now())
        : (_harvestDeadlines[farmerId] ?? DateTime.now().add(const Duration(days: 30)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      setState(() {
        if (isPlanting) {
          _plantingDeadlines[farmerId] = picked;
        } else {
          _harvestDeadlines[farmerId] = picked;
        }
      });
    }
  }

  Future<void> _submitAllocation() async {
    final currentSum = _currentAllocatedSum;
    if (currentSum <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan kuota panen (kg) untuk minimal satu petani anggota.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (currentSum > _availableQuotaToAllocate + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Total alokasi (${_currencyFormat.format(currentSum)} kg) melebihi sisa kuota yang tersedia (${_currencyFormat.format(_availableQuotaToAllocate)} kg).',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final List<Map<String, dynamic>> payloadAllocations = [];
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (final member in widget.members) {
      final text = _controllers[member.farmerId]?.text.trim() ?? '';
      final kg = double.tryParse(text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
      if (kg > 0) {
        final pDate = _plantingDeadlines[member.farmerId] != null
            ? dateFormat.format(_plantingDeadlines[member.farmerId]!)
            : null;
        final hDate = _harvestDeadlines[member.farmerId] != null
            ? dateFormat.format(_harvestDeadlines[member.farmerId]!)
            : widget.order.deadline;

        payloadAllocations.add({
          'farmer_id': member.farmerId,
          'allocated_kg': kg,
          'planting_deadline': pDate,
          'harvest_deadline': hDate,
        });
      }
    }

    setState(() => _isSubmitting = true);

    final res = await _poktanService.allocateQuota(
      b2bOrderId: widget.order.id,
      allocations: payloadAllocations,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (res['success'] == true) {
      Navigator.of(context).pop();
      widget.onAllocationSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Alokasi kuota panen berhasil didistribusikan.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal mendistribusikan kuota panen.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remainingAfterCurrentInput;
    final isOverQuota = remaining < -0.01;
    final isFullyAllocated = remaining.abs() <= 0.01 && _currentAllocatedSum > 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),

            // Header title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.split, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bagi Alokasi Kuota Panen',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF121C2A),
                          ),
                        ),
                        Text(
                          '${widget.order.commodityName} - ${widget.order.buyerName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),

            // Live quota status card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isOverQuota
                      ? const Color(0xFFFEF2F2)
                      : (isFullyAllocated ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOverQuota
                        ? const Color(0xFFFCA5A5)
                        : (isFullyAllocated ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Pesanan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '${_currencyFormat.format(widget.order.totalQuotaKg)} kg',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF121C2A),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Input Alokasi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '${_currencyFormat.format(_currentAllocatedSum)} kg',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isOverQuota ? const Color(0xFFDC2626) : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Sisa Kuota',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '${_currencyFormat.format(remaining)} kg',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isOverQuota
                                    ? const Color(0xFFDC2626)
                                    : (isFullyAllocated
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF334155)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isOverQuota
                                ? 'Peringatan: Total alokasi melebihi sisa kuota yang tersedia!'
                                : (isFullyAllocated
                                    ? 'Sempurna: Seluruh kuota telah terbagi habis.'
                                    : 'Isi kuota petani atau gunakan tombol bagi otomatis.'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOverQuota
                                  ? const Color(0xFFB91C1C)
                                  : (isFullyAllocated
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _distributeProportionally,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: const Size(44, 36),
                          ),
                          icon: const Icon(LucideIcons.wand2, size: 14, color: AppColors.primary),
                          label: Text(
                            'Bagi Sesuai Lahan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Members allocation list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: widget.members.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final member = widget.members[index];
                  final controller = _controllers[member.farmerId]!;
                  final pDate = _plantingDeadlines[member.farmerId];
                  final hDate = _harvestDeadlines[member.farmerId];
                  final dateFormat = DateFormat('dd MMM yyyy');

                  return CustomSoftCard(
                    padding: const EdgeInsets.all(14),
                    borderRadius: BorderRadius.circular(16),
                    backgroundColor: const Color(0xFFFBFBFC),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: member.isChairman
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFE2E8F0),
                              child: Icon(
                                member.isChairman ? Icons.stars : Icons.person,
                                size: 18,
                                color: member.isChairman
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF475569),
                              ),
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
                                          member.fullName,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF121C2A),
                                          ),
                                        ),
                                      ),
                                      if (member.isChairman) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Ketua',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFB45309),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Luas Lahan: ${member.landAreaHa.toStringAsFixed(2)} ha | Tanah: ${member.soilType}',
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
                        const SizedBox(height: 12),

                        // Kuota input
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: controller,
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setState(() {}),
                                        decoration: const InputDecoration(
                                          hintText: '0',
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF121C2A),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'kg',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Tenggat Tanam Button
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: () => _pickDate(context, member.farmerId, true),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tenggat Tanam',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      Text(
                                        pDate != null ? dateFormat.format(pDate) : 'Pilih',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Tenggat Panen Button
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: () => _pickDate(context, member.farmerId, false),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tenggat Panen',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      Text(
                                        hDate != null ? dateFormat.format(hDate) : 'Pilih',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || isOverQuota || _currentAllocatedSum <= 0)
                      ? null
                      : _submitAllocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
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
                          'Kirim Alokasi & Terbitkan Tugas',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

