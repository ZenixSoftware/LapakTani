import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/api_service.dart';

class CreateWholesalePoolSheet {
  static Future<bool?> show(
    BuildContext context, {
    String mitraName = 'Mitra Tani Makmur',
    VoidCallback? onCreated,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateWholesalePoolContent(
        mitraName: mitraName,
        onCreated: onCreated,
      ),
    );
  }
}

class _CreateWholesalePoolContent extends StatefulWidget {
  final String mitraName;
  final VoidCallback? onCreated;

  const _CreateWholesalePoolContent({
    required this.mitraName,
    this.onCreated,
  });

  @override
  State<_CreateWholesalePoolContent> createState() =>
      _CreateWholesalePoolContentState();
}

class _CreateWholesalePoolContentState
    extends State<_CreateWholesalePoolContent> {
  final ApiService _apiService = ApiService();

  final _formKey = GlobalKey<FormState>();
  final _commodityController =
      TextEditingController(text: 'Cabai Merah Keriting Super');
  final _varietyController = TextEditingController(text: 'Kencana Tropis');
  final _quotaController = TextEditingController(text: '500');
  final _minOrderController = TextEditingController(text: '50');
  final _priceController = TextEditingController(text: '28000');
  final _dateController = TextEditingController(text: '20 Nov 2026');
  final _packagingController =
      TextEditingController(text: 'Krat Plastik & Cold Storage (10-12°C)');
  final _notesController =
      TextEditingController(text: 'Konsolidasi panen serentak 11.10 Ha anggota');

  String _selectedGrade = 'Grade A Super';
  bool _autoSpillover = true;
  bool _isSubmitting = false;

  final List<String> _gradeOptions = [
    'Grade A Super',
    'Grade B Standard',
    'Kualitas Ekspor',
  ];

  final List<Map<String, String>> _presetCommodities = [
    {
      'name': 'Cabai Merah Keriting',
      'variety': 'Kencana Tropis',
      'image': 'uploads/products/cabai.jpg',
      'url':
          'https://images.unsplash.com/photo-1588252303782-cb80119abd6d?auto=format&fit=crop&w=400&q=80',
    },
    {
      'name': 'Tomat Beef Segar',
      'variety': 'Beef Lembang Super',
      'image': 'uploads/products/tomat.jpg',
      'url':
          'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=400&q=80',
    },
    {
      'name': 'Kentang Granola',
      'variety': 'Granola Dieng',
      'image': 'uploads/products/kentang.jpg',
      'url':
          'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=400&q=80',
    },
    {
      'name': 'Bawang Merah Brebes',
      'variety': 'Bima Brebes',
      'image': 'uploads/products/bawang.jpg',
      'url':
          'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?auto=format&fit=crop&w=400&q=80',
    },
  ];

  int _selectedPresetIndex = 0;

  @override
  void dispose() {
    _commodityController.dispose();
    _varietyController.dispose();
    _quotaController.dispose();
    _minOrderController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    _packagingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) {
      final formatter = DateFormat('dd MMM yyyy', 'id_ID');
      setState(() {
        _dateController.text = formatter.format(picked);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final quota = double.tryParse(_quotaController.text.trim()) ?? 0.0;
    final minOrder = double.tryParse(_minOrderController.text.trim()) ?? 50.0;
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    if (quota <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total kuota dan harga per kg harus lebih dari 0.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final selectedPreset = _presetCommodities[_selectedPresetIndex];

    final success = await _apiService.createB2BHarvestPool(
      commodityName: _commodityController.text.trim(),
      variety: _varietyController.text.trim(),
      grade: _selectedGrade,
      totalQuotaKg: quota,
      minOrderKg: minOrder,
      pricePerKg: price,
      targetHarvestDate: _dateController.text.trim(),
      packagingSop: _packagingController.text.trim(),
      autoSpillover: _autoSpillover,
      imageUrl: selectedPreset['image'] ?? 'uploads/products/cabai.jpg',
      notes: _notesController.text.trim(),
      mitraName: widget.mitraName,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context, true);
      widget.onCreated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bursa penawaran partai panen berhasil dibuka!'),
          backgroundColor: Color(0xFF006E04),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuka penawaran partai. Silakan periksa kembali.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buka Penawaran Partai (B2B)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.mitraName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF006E04),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 1. Foto Komoditas (Preset Selector)
              Text(
                'Pilih Foto Komoditas Pertanian',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetCommodities.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = _presetCommodities[index];
                    final isSelected = _selectedPresetIndex == index;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPresetIndex = index;
                          _commodityController.text = item['name']!;
                          _varietyController.text = item['variety']!;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 90,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF006E04) : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['url']!,
                                width: double.infinity,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 48,
                                  color: const Color(0xFFE2E8F0),
                                  child: const Icon(LucideIcons.image, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['name']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? const Color(0xFF006E04) : const Color(0xFF475569),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 2. Nama Komoditas & Varietas
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nama Komoditas', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _commodityController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Cabai Keriting',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Varietas', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _varietyController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Tropis',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Pilihan Grade Mutu
              Text('Pilihan Grade Mutu', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedGrade,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _gradeOptions.map((g) {
                  return DropdownMenuItem(value: g, child: Text(g, style: GoogleFonts.plusJakartaSans(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedGrade = val);
                },
              ),
              const SizedBox(height: 14),

              // 4. Total Kuota & Minimal Pesanan
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Kuota Panen (kg)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _quotaController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            suffixText: 'kg',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Min. Pesanan (kg)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _minOrderController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            suffixText: 'kg',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 5. Harga Grosir & Tanggal Panen
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Harga Grosir per kg', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixText: 'Rp ',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estimasi Panen', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _selectDate,
                          child: IgnorePointer(
                            child: TextFormField(
                              controller: _dateController,
                              decoration: InputDecoration(
                                suffixIcon: const Icon(LucideIcons.calendar, size: 18),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 6. SOP Kemasan & Pengiriman
              Text('SOP Kemasan & Pengiriman', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _packagingController,
                decoration: InputDecoration(
                  hintText: 'e.g. Krat plastik, cold-chain, dll.',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              // 7. Catatan Konsolidasi
              Text('Catatan Konsolidasi Lahan', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. Hasil panen lahan konsolidasi Lembang bergaransi',
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              // 8. Switch: Zero-Waste Spillover otomatis
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _autoSpillover,
                  onChanged: (val) => setState(() => _autoSpillover = val),
                  activeThumbColor: const Color(0xFF006E04),
                  title: Text(
                    'Mekanisme Zero-Waste Otomatis',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Otomatis alihkan sisa kuota ke etalase retail jika tidak habis saat tanggal panen tiba.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006E04),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Buka Penawaran Sekarang',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
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
