import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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
  final TextEditingController _promoPriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _minOrderController = TextEditingController(text: '1');
  final TextEditingController _descriptionController = TextEditingController();

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _commodities = [];
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _units = [];


  String? _selectedCommodity;
  String? _selectedGrade;
  String? _selectedUnitId = 'unit-kg';
  String _selectedCultivation = 'Organik Bersertifikat';
  bool _needCoolBox = true;
  bool _isLoadingMaster = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_onPriceChanged);
    _promoPriceController.addListener(_onPriceChanged);
    _fetchMasterData();
  }

  void _onPriceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _priceController.removeListener(_onPriceChanged);
    _promoPriceController.removeListener(_onPriceChanged);
    _titleController.dispose();
    _priceController.dispose();
    _promoPriceController.dispose();
    _stockController.dispose();
    _minOrderController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _promoDiscountLabel {
    final normal = double.tryParse(_priceController.text.trim());
    final promo = double.tryParse(_promoPriceController.text.trim());
    if (normal != null && promo != null && normal > 0 && promo < normal && promo > 0) {
      final pct = (((normal - promo) / normal) * 100).round();
      return 'Hemat $pct%';
    }
    return 'Hemat 14%';
  }

  Future<void> _fetchMasterData() async {
    setState(() {
      _isLoadingMaster = true;
    });

    try {
      final comRes = await ApiService.get('/master/commodities');
      final grdRes = await ApiService.get('/master/grades');
      final untRes = await ApiService.get('/master/units');

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

      if (untRes.statusCode == 200) {
        final dynamic body = jsonDecode(untRes.body);
        if (body is Map && body['data'] is List) {
          _units = List<Map<String, dynamic>>.from(body['data']);
          if (_units.isNotEmpty) {
            final found = _units.firstWhere(
              (u) => u['id'] == 'unit-kg',
              orElse: () => _units.first,
            );
            _selectedUnitId = found['id']?.toString();
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

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 5 foto komoditas.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      if (source == ImageSource.gallery) {
        final List<XFile> pickedList = await _picker.pickMultiImage(
          imageQuality: 85,
          limit: 5 - _selectedImages.length,
        );
        if (pickedList.isNotEmpty) {
          setState(() {
            for (final xFile in pickedList) {
              if (_selectedImages.length < 5) {
                _selectedImages.add(File(xFile.path));
              }
            }
          });
        }
      } else {
        final XFile? photo = await _picker.pickImage(
          source: source,
          imageQuality: 85,
        );
        if (photo != null) {
          setState(() {
            _selectedImages.add(File(photo.path));
          });
        }
      }
    } catch (e) {
      debugPrint('[ADD_PRODUCT] Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Sumber Foto Panen',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121C2A),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.camera, color: Color(0xFF03AC0E), size: 22),
                ),
                title: Text(
                  'Kamera',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  'Ambil foto langsung dari kebun/ladang',
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.image, color: Color(0xFF2563EB), size: 22),
                ),
                title: Text(
                  'Galeri Foto',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  'Pilih dari album/galeri smartphone',
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
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

    try {
      final List<String> uploadedUrls = [];
      if (_selectedImages.isNotEmpty) {
        for (int i = 0; i < _selectedImages.length; i++) {
          try {
            final res = await ApiService.uploadImage('/upload/product-image', _selectedImages[i]);
            if (res['data'] != null && res['data']['image_url'] != null) {
              uploadedUrls.add(res['data']['image_url'].toString());
            }
          } catch (uploadErr) {
            debugPrint('[ADD_PRODUCT] Gagal mengunggah foto ke-$i: $uploadErr');
          }
        }
      }

      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'price_per_kg': double.parse(_priceController.text.trim()),
        'stock_kg': double.parse(_stockController.text.trim()),
        'commodity_id': _selectedCommodity,
        'grade_id': _selectedGrade,
        'unit_id': _selectedUnitId ?? 'unit-kg',
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      };

      if (uploadedUrls.isNotEmpty) {
        payload['image_urls'] = uploadedUrls;
        payload['image_url'] = uploadedUrls.first;
      }

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
                      trailingBadge: '${_selectedImages.length} / 5',
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
                      subtitle: 'Pilihan satuan komoditas dan penetapan nilai jual panen',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Satuan Komoditas *
                          _buildFieldLabel('Satuan Komoditas *'),
                          _buildUnitSelector(),
                          const SizedBox(height: 16),

                          // Harga Normal per Satuan *
                          _buildFieldLabel('Harga Normal per Satuan *'),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF121C2A),
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: Container(
                                width: 44,
                                alignment: Alignment.center,
                                child: Text(
                                  'Rp',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
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
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Harga normal wajib diisi';
                              }
                              final parsed = double.tryParse(value.trim());
                              if (parsed == null || parsed <= 0) {
                                return 'Harga harus lebih dari 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Harga Promo Komoditas (Opsional)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildFieldLabel('Harga Promo Komoditas'),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE4E6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _promoDiscountLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFE11D48),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: _promoPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF03AC0E),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Opsional (Harga coret)',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: Container(
                                width: 44,
                                alignment: Alignment.center,
                                child: Text(
                                  'Rp',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
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
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Harga promo akan memicu label diskon merah menarik di katalog.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: const Color(0xFF64748B),
                            ),
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
                                        suffixText: _unitSuffix,
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
                                        suffixText: _unitSuffix,
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
    if (_selectedImages.isEmpty) {
      return InkWell(
        onTap: _showImageSourceDialog,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                'Pilih / Ambil Foto Komoditas',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121C2A),
                ),
              ),
              Text(
                'Rasio 1:1 • Cahaya alami subuh (Maks 5 foto)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImages.first,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF03AC0E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.star, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Foto Utama',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: InkWell(
                onTap: () => _removeImage(0),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.trash2, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + (_selectedImages.length < 5 ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index < _selectedImages.length) {
                final isPrimary = index == 0;
                return Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPrimary ? const Color(0xFF03AC0E) : const Color(0xFFE2E8F0),
                          width: isPrimary ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (!isPrimary)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.x, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                );
              } else {
                return InkWell(
                  onTap: _showImageSourceDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF93C5FD), width: 1.2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.plus, size: 20, color: Color(0xFF2563EB)),
                        const SizedBox(height: 2),
                        Text(
                          'Tambah',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
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

  String get _unitSuffix {
    if (_selectedUnitId == 'unit-ikat') return 'Ikat';
    if (_selectedUnitId == 'unit-keranjang') return 'Kjg';
    if (_selectedUnitId == 'unit-karung') return 'Sak';
    return 'Kg';
  }

  Widget _buildUnitSelector() {
    final displayUnits = _units.isNotEmpty
        ? _units
        : [
            {'id': 'unit-kg', 'unit_name': 'Per Kilogram', 'description': '1 Kg baku timbangan'},
            {'id': 'unit-ikat', 'unit_name': 'Per Ikat', 'description': 'Bundel sayur daun'},
            {'id': 'unit-keranjang', 'unit_name': 'Per Keranjang', 'description': 'Karton / peti 10 Kg'},
            {'id': 'unit-karung', 'unit_name': 'Per Karung (Sak)', 'description': 'Sak grosir 25-50 Kg'},
          ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: displayUnits.map((unit) {
            final id = unit['id']?.toString() ?? '';
            final isSelected = _selectedUnitId == id;
            final name = unit['unit_name']?.toString() ?? '';
            final desc = unit['description']?.toString() ?? '';

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedUnitId = id;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: itemWidth,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE8F7EE)
                      : const Color(0xFFEFF4FF).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF03AC0E)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF03AC0E)
                              : const Color(0xFF94A3B8),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF03AC0E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: const Color(0xFF121C2A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            desc,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
