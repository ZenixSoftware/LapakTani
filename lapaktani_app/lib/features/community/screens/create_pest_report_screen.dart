import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/pest_alert_service.dart';

class CreatePestReportScreen extends StatefulWidget {
  final String? initialPestName;
  final String? initialCropType;
  final String? initialPoktanName;

  const CreatePestReportScreen({
    super.key,
    this.initialPestName,
    this.initialCropType,
    this.initialPoktanName,
  });

  @override
  State<CreatePestReportScreen> createState() => _CreatePestReportScreenState();
}

class _CreatePestReportScreenState extends State<CreatePestReportScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _pestNameController;
  late final TextEditingController _cropTypeController;
  late final TextEditingController _affectedAreaController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _handlingController;

  String _selectedSeverity = 'Sedang'; // Ringan, Sedang, Berat
  String _selectedPoktan = 'Poktan Tani Makmur';
  String _selectedVillage = 'Desa Lembang';
  bool _enableEmergencyAlert = false;
  bool _isSubmitting = false;

  XFile? _pickedImage;
  String? _sampleImageUrl;

  final List<Map<String, String>> _poktanOptions = [
    {
      'id': 'fg-lembang-01',
      'name': 'Poktan Tani Makmur',
      'village': 'Desa Lembang',
    },
    {
      'id': 'fg-cibodas-02',
      'name': 'Poktan Sumber Rejeki',
      'village': 'Desa Cibodas',
    },
    {
      'id': 'fg-cikole-03',
      'name': 'Poktan Subur Mandiri',
      'village': 'Desa Cikole',
    },
    {
      'id': 'fg-parongpong-04',
      'name': 'Poktan Harapan Jaya',
      'village': 'Desa Parongpong',
    },
  ];

  final List<String> _commonPests = [
    'Ulat Grayak (Spodoptera frugiperda)',
    'Wereng Batang Coklat',
    'Kutu Daun (Aphids)',
    'Hawar Daun (Phytophthora)',
    'Penggerek Batang',
    'Busuk Buah Antraknosa',
    'Layu Bakteri (Ralstonia)',
  ];

  final List<String> _commonCrops = [
    'Cabai Merah',
    'Tomat Segar',
    'Kentang Granola',
    'Padi Sawah',
    'Jagung Manis',
    'Bawang Merah',
    'Wortel Brastagi',
  ];

  final List<String> _areaPresets = [
    '500 m²',
    '1.000 m²',
    '0.5 Hektar',
    '1.0 Hektar',
    '2.0 Hektar',
  ];

  final List<Map<String, String>> _sampleEvidencePhotos = [
    {
      'label': 'Ulat Grayak',
      'url':
          'https://images.unsplash.com/photo-1592417817098-8f3d6910985c?auto=format&fit=crop&w=800&q=80',
    },
    {
      'label': 'Hawar Daun',
      'url':
          'https://images.unsplash.com/photo-1599818816942-88ec0c39f03d?auto=format&fit=crop&w=800&q=80',
    },
    {
      'label': 'Kutu / Hama Tanaman',
      'url':
          'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pestNameController = TextEditingController(text: widget.initialPestName ?? '');
    _cropTypeController = TextEditingController(text: widget.initialCropType ?? '');
    _affectedAreaController = TextEditingController(text: '0.5 Hektar');
    _descriptionController = TextEditingController();
    _handlingController = TextEditingController();

    if (widget.initialPoktanName != null) {
      _selectedPoktan = widget.initialPoktanName!;
    }
    _sampleImageUrl = _sampleEvidencePhotos.first['url'];
  }

  @override
  void dispose() {
    _pestNameController.dispose();
    _cropTypeController.dispose();
    _affectedAreaController.dispose();
    _descriptionController.dispose();
    _handlingController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _pickedImage = picked;
          _sampleImageUrl = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil gambar: $e')),
      );
    }
  }

  void _onSeverityChanged(String severity) {
    setState(() {
      _selectedSeverity = severity;
      if (severity == 'Berat') {
        _enableEmergencyAlert = true;
      }
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua kolom wajib dengan benar.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final selectedPoktanMap = _poktanOptions.firstWhere(
        (p) => p['name'] == _selectedPoktan,
        orElse: () => _poktanOptions.first,
      );

      final result = await PestAlertService().submitPestReport(
        pestName: _pestNameController.text.trim(),
        cropType: _cropTypeController.text.trim(),
        severity: _selectedSeverity,
        affectedArea: _affectedAreaController.text.trim(),
        farmerGroupName: _selectedPoktan,
        farmerGroupId: selectedPoktanMap['id'] ?? 'fg-lembang-01',
        villageName: _selectedVillage,
        description: _descriptionController.text.trim(),
        imageUrl: _sampleImageUrl ??
            'https://images.unsplash.com/photo-1592417817098-8f3d6910985c?auto=format&fit=crop&w=800&q=80',
        handlingRecommendation: _handlingController.text.trim(),
        emergencyAlert: _enableEmergencyAlert || _selectedSeverity == 'Berat',
      );

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      final notifCount = result['notifications_sent'] ?? 4;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 24),
              const SizedBox(width: 8),
              Text(
                'Laporan Terkirim!',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laporan serangan hama berhasil disimpan ke sistem.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.bellRing, size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Peringatan dini (Pest Alert) telah dikirimkan ke $notifCount petani & penyuluh di $_selectedPoktan.',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Selesai',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim laporan: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Lapor Serangan Hama',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice Header Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.info, color: Color(0xFF2563EB), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pest Alert akan menyebarkan peringatan otomatis kepada sesama petani dan penyuluh pembina di wilayah Poktan yang Anda pilih.',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF1E40AF),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 1. Nama Hama / Gejala
              _buildSectionLabel('Nama Hama / Gejala Serangan *'),
              TextFormField(
                controller: _pestNameController,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: _inputDecoration(
                  hintText: 'Contoh: Ulat Grayak, Wereng Coklat, Hawar Daun...',
                  prefixIcon: LucideIcons.bug,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama hama atau gejala serangan wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              _buildChipsRecommendation(
                items: _commonPests,
                onSelected: (p) => setState(() => _pestNameController.text = p),
              ),

              const SizedBox(height: 16),

              // 2. Jenis Tanaman Terdampak
              _buildSectionLabel('Jenis Tanaman Terdampak *'),
              TextFormField(
                controller: _cropTypeController,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: _inputDecoration(
                  hintText: 'Contoh: Cabai Merah, Tomat, Padi, Jagung...',
                  prefixIcon: LucideIcons.sprout,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Jenis tanaman terdampak wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              _buildChipsRecommendation(
                items: _commonCrops,
                onSelected: (c) => setState(() => _cropTypeController.text = c),
              ),

              const SizedBox(height: 16),

              // 3. Tingkat Keparahan
              _buildSectionLabel('Tingkat Keparahan Serangan *'),
              _buildSeveritySelector(),

              const SizedBox(height: 16),

              // 4. Estimasi Luas Lahan Terdampak
              _buildSectionLabel('Estimasi Luas Lahan Terdampak *'),
              TextFormField(
                controller: _affectedAreaController,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: _inputDecoration(
                  hintText: 'Contoh: 0.5 Hektar, 1.2 Ha, 500 m²...',
                  prefixIcon: LucideIcons.maximize2,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Estimasi luas lahan wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              _buildChipsRecommendation(
                items: _areaPresets,
                onSelected: (a) => setState(() => _affectedAreaController.text = a),
              ),

              const SizedBox(height: 16),

              // 5. Lokasi / Wilayah Poktan & Desa
              _buildSectionLabel('Wilayah Poktan (Kelompok Tani) *'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPoktan,
                    isExpanded: true,
                    icon: const Icon(LucideIcons.chevronDown, size: 18),
                    items: _poktanOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt['name'],
                        child: Row(
                          children: [
                            const Icon(LucideIcons.users, size: 16, color: Color(0xFF059669)),
                            const SizedBox(width: 8),
                            Text(
                              '${opt['name']} (${opt['village']})',
                              style: GoogleFonts.inter(fontSize: 12.5),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedPoktan = val;
                          final match = _poktanOptions.firstWhere((p) => p['name'] == val);
                          _selectedVillage = match['village'] ?? 'Desa Lembang';
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 6. Foto Bukti Serangan Hama
              _buildSectionLabel('Foto Bukti Serangan (Kamera / Galeri) *'),
              _buildPhotoPickerSection(),

              const SizedBox(height: 16),

              // 7. Catatan Deskripsi
              _buildSectionLabel('Catatan Deskripsi Kondisi Lapangan *'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Jelaskan gejala daun berlubang, tanaman menguning, layu mendadak, atau kepadatan hama...',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 5) {
                    return 'Deskripsi kondisi serangan minimal 5 karakter.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 8. Rekomendasi / Tindakan Awal (Opsional)
              _buildSectionLabel('Tindakan Awal yang Sudah Diambil (Opsional)'),
              TextFormField(
                controller: _handlingController,
                maxLines: 2,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Contoh: Pemangkasan daun terinfeksi, penyemprotan ekstrak mimba...',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 16),

              // 9. Emergency Alert Switch Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _enableEmergencyAlert
                      ? const Color(0xFFFEF2F2)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _enableEmergencyAlert
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      color: _enableEmergencyAlert
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aktifkan Peringatan Dini (Pest Alert)',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _enableEmergencyAlert
                                  ? const Color(0xFF991B1B)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Siarkan banner darurat ke seluruh anggota Poktan sewilayah.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _enableEmergencyAlert || _selectedSeverity == 'Berat',
                      activeColor: const Color(0xFFEF4444),
                      onChanged: _selectedSeverity == 'Berat'
                          ? null // Locked to true if severity is Berat
                          : (val) => setState(() => _enableEmergencyAlert = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReport,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.send, size: 18),
                  label: Text(
                    _isSubmitting ? 'Mengirim Laporan...' : 'Kirim Laporan & Aktifkan Alert',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03AC0E),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
      prefixIcon: Icon(prefixIcon, size: 16, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
    );
  }

  Widget _buildChipsRecommendation({
    required List<String> items,
    required Function(String) onSelected,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              label: Text(item, style: GoogleFonts.inter(fontSize: 11)),
              backgroundColor: const Color(0xFFF1F5F9),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              onPressed: () => onSelected(item),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSeveritySelector() {
    final severities = [
      {
        'level': 'Ringan',
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFFECFDF5),
        'desc': '< 15% tanaman',
      },
      {
        'level': 'Sedang',
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
        'desc': '15% - 40% tanaman',
      },
      {
        'level': 'Berat',
        'color': const Color(0xFFEF4444),
        'bg': const Color(0xFFFEF2F2),
        'desc': '> 40% (Darurat)',
      },
    ];

    return Row(
      children: severities.map((s) {
        final isSelected = _selectedSeverity == s['level'];
        final color = s['color'] as Color;
        final bg = s['bg'] as Color;

        return Expanded(
          child: GestureDetector(
            onTap: () => _onSeverityChanged(s['level'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? bg : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFCBD5E1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s['level'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? color : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s['desc'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoPickerSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_pickedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_pickedImage!.path),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else if (_sampleImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _sampleImageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(LucideIcons.camera, size: 16),
                  label: Text('Kamera', style: GoogleFonts.inter(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF03AC0E),
                    side: const BorderSide(color: Color(0xFF03AC0E)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(LucideIcons.image, size: 16),
                  label: Text('Galeri', style: GoogleFonts.inter(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3B82F6),
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Atau pilih sampel bukti foto hama:',
            style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Row(
            children: _sampleEvidencePhotos.map((s) {
              final isSelected = _sampleImageUrl == s['url'] && _pickedImage == null;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(s['label']!, style: GoogleFonts.inter(fontSize: 10.5)),
                  selected: isSelected,
                  selectedColor: const Color(0xFFDCFCE7),
                  onSelected: (val) {
                    setState(() {
                      _pickedImage = null;
                      _sampleImageUrl = s['url'];
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

