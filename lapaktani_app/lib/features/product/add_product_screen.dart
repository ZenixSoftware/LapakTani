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
  final TextEditingController _minOrderController = TextEditingController(text: '1');
  final TextEditingController _descriptionController = TextEditingController();

  List<Map<String, dynamic>> _commodities = [];
  List<Map<String, dynamic>> _grades = [];

  String? _selectedCommodity;
  String? _selectedGrade;
  String _selectedCultivation = 'Organik Bersertifikat';
  bool _needCoolBox = true;
  bool _isLoadingMaster = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchMasterData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minOrderController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchMasterData() async {
    setState(() {
      _isLoadingMaster = true;
    });

    try {
      final comRes = await ApiService.get('/master/commodities');
      final grdRes = await ApiService.get('/master/grades');

      if (comRes.statusCode == 200) {
        final dynamic body = jsonDecode(comRes.body);
        if (body is Map && body['data'] is List) {
          _commodities = List<Map<String, dynamic>>.from(body['data']);
          if (_commodities.isNotEmpty) {
            _selectedCommodity = _commodities.first['id']?.toString();
          }
        }
      }

      if (grdRes.statusCode == 200) {
        final dynamic body = jsonDecode(grdRes.body);
        if (body is Map && body['data'] is List) {
          _grades = List<Map<String, dynamic>>.from(body['data']);
          if (_grades.isNotEmpty) {
            _selectedGrade = _grades.first['id']?.toString();
          }
        }
      }
    } catch (e) {
      debugPrint('[ADD_PRODUCT] Error fetching master data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMaster = false;
        });
      }
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCommodity == null || _selectedGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jenis komoditas dan grade kualitas.'),
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
      'description': _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    };

    try {
      final response = await ApiService.post('/products', payload);
      final dynamic body = jsonDecode(response.body);

      if (response.statusCode == 201 || (body is Map && body['success'] == true)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komoditas berhasil disimpan ke etalase katalog.'),
            backgroundColor: Color(0xFF03AC0E),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final message = body is Map && body['message'] != null
            ? body['message'].toString()
            : 'Gagal menambahkan komoditas.';
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
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'Tambah Produk Tani',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF121C2A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF121C2A), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.helpCircle, color: Color(0xFF64748B), size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoadingMaster
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF03AC0E),
              ),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  children: [
                    // Banner Tips Komoditas Segar
                    _buildGuidanceBanner(),
                    const SizedBox(height: 14),

                    // Section 1: Foto Panen
                    _buildSectionContainer(
                      title: 'Foto Panen Komoditas',
                      subtitle: 'Maksimal 5 foto komoditas asli dari ladang',
                      trailingBadge: '1 / 5',
                      child: _buildPhotoSection(),
                    ),
                    const SizedBox(height: 14),

                    // Section 2: Informasi Dasar Produk
                    _buildSectionContainer(
                      title: 'Informasi Dasar Produk',
                      subtitle: 'Klasifikasi komoditas hasil panen binaan',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Nama Komoditas *'),
                          TextFormField(
                            controller: _titleController,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: const Color(0xFF121C2A),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: _buildInputDecoration(
                              hintText: 'Contoh: Tomat Merah Organik Lembang Super',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama komoditas wajib diisi';
                              }
                              if (value.trim().length < 3) {
                                return 'Nama minimal 3 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Dynamic Commodities Dropdown (US-07)
                          _buildFieldLabel('Jenis Komoditas (Master Data) *'),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCommodity,
                            isExpanded: true,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: const Color(0xFF121C2A),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: _buildInputDecoration(
                              hintText: 'Pilih jenis komoditas',
                            ),
                            items: _commodities.map((item) {
                              final id = item['id'].toString();
                              final name = item['specific_name'].toString();
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCommodity = val;
                              });
                            },
                            validator: (val) => val == null ? 'Pilih jenis komoditas' : null,
                          ),
                          const SizedBox(height: 14),

                          // Dynamic Grades Dropdown (US-07)
                          _buildFieldLabel('Kualitas / Grade *'),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedGrade,
                            isExpanded: true,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: const Color(0xFF121C2A),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: _buildInputDecoration(
                              hintText: 'Pilih grade komoditas',
                            ),
                            items: _grades.map((item) {
                              final id = item['id'].toString();
                              final label = item['grade_label'].toString();
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(label),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedGrade = val;
                              });
                            },
                            validator: (val) => val == null ? 'Pilih grade kualitas' : null,
                          ),
                          const SizedBox(height: 14),

                          // Metode Budidaya
                          _buildFieldLabel('Metode Budidaya'),
                          _buildCultivationSelector(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section 3: Harga & Satuan Penjualan
                    _buildSectionContainer(
                      title: 'Harga & Satuan Penjualan',
                      subtitle: 'Nilai jual per kilogram baku timbangan',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Harga Normal per Kg *'),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF03AC0E),
                            ),
                            decoration: _buildInputDecoration(
                              hintText: '14000',
                              prefixText: 'Rp ',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Harga per kg wajib diisi';
                              }
                              final parsed = double.tryParse(value.trim());
                              if (parsed == null || parsed <= 0) {
                                return 'Harga harus lebih dari 0';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section 4: Stok & Pengiriman
                    _buildSectionContainer(
                      title: 'Stok & Pengiriman Panen',
                      subtitle: 'Ketersediaan kuota hasil panen di kebun',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Total Siap Jual *'),
                                    TextFormField(
                                      controller: _stockController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF121C2A),
                                      ),
                                      decoration: _buildInputDecoration(
                                        hintText: '150',
                                        suffixText: 'Kg',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Stok wajib diisi';
                                        }
                                        final parsed = double.tryParse(value.trim());
                                        if (parsed == null || parsed < 0) {
                                          return 'Stok tidak boleh minus';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Min. Beli *'),
                                    TextFormField(
                                      controller: _minOrderController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF121C2A),
                                      ),
                                      decoration: _buildInputDecoration(
                                        hintText: '1',
                                        suffixText: 'Kg',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Toggle Cool Box
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFB0F1CB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.snowflake,
                                    size: 18,
                                    color: Color(0xFF2C694C),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Wajib Insulated Cool Box',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF121C2A),
                                        ),
                                      ),
                                      Text(
                                        'Menjaga suhu 4-8°C selama pengantaran.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _needCoolBox,
                                  activeThumbColor: const Color(0xFF03AC0E),
                                  activeTrackColor: const Color(0xFFB0F1CB),
                                  onChanged: (val) {
                                    setState(() {
                                      _needCoolBox = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section 5: Deskripsi
                    _buildSectionContainer(
                      title: 'Deskripsi Komoditas',
                      subtitle: 'Ceritakan kesegaran dan standar penanganan panen',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF121C2A),
                            ),
                            decoration: _buildInputDecoration(
                              hintText:
                                  'Ceritakan rasa, tingkat kematangan, tekstur, dan rekomendasi penyimpanan...',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Batal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF03AC0E),
                  disabledBackgroundColor: const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.check, size: 18, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Simpan Produk',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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

  Widget _buildGuidanceBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDEE9FC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFB0F1CB),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.sprout, size: 18, color: Color(0xFF2C694C)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Komoditas Segar Cepat Laku',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF121C2A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sertakan foto asli saat pemetikan subuh dan grade mutu teruji untuk menarik pembeli horeka & grosir.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required String subtitle,
    String? trailingBadge,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121C2A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              if (trailingBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6EEFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trailingBadge,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3E4A39),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFFE6EEFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBCCBB4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.camera, size: 32, color: Color(0xFF03AC0E)),
              const SizedBox(height: 6),
              Text(
                'Foto Utama Komoditas',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121C2A),
                ),
              ),
              Text(
                'Rasio 1:1 • Cahaya alami subuh',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF121C2A),
        ),
      ),
    );
  }

  Widget _buildCultivationSelector() {
    final options = [
      'Organik Bersertifikat',
      'Hidroponik Non-Pestisida',
      'Konvensional Prima',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: options.map((opt) {
        final isSelected = _selectedCultivation == opt;
        return ChoiceChip(
          label: Text(opt),
          selected: isSelected,
          selectedColor: const Color(0xFFB0F1CB),
          backgroundColor: const Color(0xFFEFF4FF),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF005302) : const Color(0xFF64748B),
          ),
          onSelected: (val) {
            if (val) {
              setState(() {
                _selectedCultivation = opt;
              });
            }
          },
        );
      }).toList(),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
      prefixText: prefixText,
      prefixStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF121C2A),
      ),
      suffixText: suffixText,
      suffixStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF64748B),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFEFF4FF).withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF03AC0E), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}
