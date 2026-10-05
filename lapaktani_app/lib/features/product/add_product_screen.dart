import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/api_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  String? _selectedCommodity = 'com-1';
  String? _selectedGrade = 'grade-1';
  bool _isSubmitting = false;

  final List<Map<String, String>> _commodities = const [
    {'id': 'com-1', 'name': 'Bayam Hijau Organik'},
    {'id': 'com-2', 'name': 'Tomat Segar'},
  ];

  final List<Map<String, String>> _grades = const [
    {'id': 'grade-1', 'name': 'Grade A / Super'},
    {'id': 'grade-2', 'name': 'Grade B / Standar'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCommodity == null || _selectedGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jenis komoditas dan grade produk.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final payload = <String, dynamic>{
      'title': _titleController.text.trim(),
      'price_per_kg': double.parse(_priceController.text.trim()),
      'stock_kg': double.parse(_stockController.text.trim()),
      'commodity_id': _selectedCommodity,
      'grade_id': _selectedGrade,
    };

    try {
      final response = await ApiService.post('/products', payload);
      final dynamic body = jsonDecode(response.body);

      if (response.statusCode == 201 ||
          (body is Map && body['success'] == true)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil dipublikasikan ke katalog LapakTani.'),
            backgroundColor: Color(0xFF03AC0E),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final message = body is Map && body['message'] != null
            ? body['message'].toString()
            : 'Gagal menyimpan produk.';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kendala jaringan: $e'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Tambah Produk Petani',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF334155), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            children: [
              _buildSectionCard(
                title: 'Foto Komoditas',
                subtitle: 'Foto komoditas segar langsung dari lahan panen',
                child: _buildImagePlaceholder(),
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                title: 'Informasi Pokok',
                subtitle: 'Deskripsi dan klasifikasi produk pertanian',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Judul Produk'),
                    TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                      decoration: _buildInputDecoration(
                        hintText: 'Misal: Bayam Hijau Segar Pagi',
                        prefixIcon: LucideIcons.tag,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul produk wajib diisi';
                        }
                        if (value.trim().length < 3) {
                          return 'Judul minimal 3 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFieldLabel('Jenis Komoditas'),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCommodity,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                      decoration: _buildInputDecoration(
                        hintText: 'Pilih komoditas',
                        prefixIcon: LucideIcons.leaf,
                      ),
                      items: _commodities.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'],
                          child: Text(item['name']!),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCommodity = val;
                        });
                      },
                      validator: (val) =>
                          val == null ? 'Komoditas wajib dipilih' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildFieldLabel('Kualitas / Grade'),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGrade,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                      decoration: _buildInputDecoration(
                        hintText: 'Pilih grade',
                        prefixIcon: LucideIcons.award,
                      ),
                      items: _grades.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'],
                          child: Text(item['name']!),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedGrade = val;
                        });
                      },
                      validator: (val) =>
                          val == null ? 'Grade wajib dipilih' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                title: 'Harga & Pasokan',
                subtitle: 'Nilai jual per kilogram dan ketersediaan panen',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Harga per Kilogram'),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                      decoration: _buildInputDecoration(
                        hintText: '15000',
                        prefixIcon: LucideIcons.banknote,
                        prefixText: 'Rp ',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Harga per kg wajib diisi';
                        }
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Harga harus berupa angka lebih besar dari 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFieldLabel('Ketersediaan Stok (kg)'),
                    TextFormField(
                      controller: _stockController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                      decoration: _buildInputDecoration(
                        hintText: '50.0',
                        prefixIcon: LucideIcons.boxes,
                        suffixText: 'kg',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Jumlah stok wajib diisi';
                        }
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null || parsed < 0) {
                          return 'Stok harus berupa angka positif';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03AC0E),
                    disabledBackgroundColor: const Color(0xFF86EFAC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 1,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Simpan Produk',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F8EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.camera,
                size: 18,
                color: Color(0xFF03AC0E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Unggah Foto Komoditas',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Pratinjau visual produk (Integrasi berkas pada rilis berikutnya)',
              style: GoogleFonts.inter(
                fontSize: 9.5,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF94A3B8),
      ),
      prefixText: prefixText,
      prefixStyle: GoogleFonts.inter(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      suffixText: suffixText,
      suffixStyle: GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF64748B),
      ),
      prefixIcon: Icon(prefixIcon, size: 16, color: const Color(0xFF64748B)),
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF03AC0E), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
      ),
    );
  }
}
