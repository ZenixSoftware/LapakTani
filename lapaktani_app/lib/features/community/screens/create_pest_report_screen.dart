import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/pest_alert_service.dart';

/// Screen to create and submit a new pest attack report (US-19)
/// Restyled with Stitch AI Design System Guidelines:
/// - Brand Primary: #2E7D32, Soft Tint: #E8F5E9 / #FFEBEE
/// - Smooth Card Radius: BorderRadius.circular(16)
/// - Clean typography and contrast
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
      'label': 'Daun Terbakar',
      'url':
          'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pestNameController = TextEditingController(text: widget.initialPestName ?? '');
    _cropTypeController = TextEditingController(text: widget.initialCropType ?? '');
    _affectedAreaController = TextEditingController(text: '1.0 Hektar');
    _descriptionController = TextEditingController();
    _handlingController = TextEditingController();

    if (widget.initialPoktanName != null) {
      final match = _poktanOptions.firstWhere(
        (p) => p['name'] == widget.initialPoktanName,
        orElse: () => _poktanOptions.first,
      );
      _selectedPoktan = match['name']!;
      _selectedVillage = match['village']!;
    }
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
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedImage = image;
          _sampleImageUrl = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih foto: $e')),
      );
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final selectedGroup = _poktanOptions.firstWhere(
      (p) => p['name'] == _selectedPoktan,
      orElse: () => _poktanOptions.first,
    );

    final result = await PestAlertService().createPestReport(
      pestName: _pestNameController.text.trim(),
      cropType: _cropTypeController.text.trim(),
      severity: _selectedSeverity,
      affectedArea: _affectedAreaController.text.trim(),
      farmerGroupId: selectedGroup['id']!,
      farmerGroupName: selectedGroup['name']!,
      villageId: 1,
      villageName: _selectedVillage,
      description: _descriptionController.text.trim(),
      handlingRecommendation: _handlingController.text.trim().isNotEmpty
          ? _handlingController.text.trim()
          : null,
      emergencyAlert: _enableEmergencyAlert || _selectedSeverity == 'Berat',
      imageFile: _pickedImage != null ? File(_pickedImage!.path) : null,
      sampleImageUrl: _sampleImageUrl,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      final notifCount = result['notifications_sent'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Laporan berhasil dikirim! $notifCount anggota Poktan & Penyuluh telah menerima peringatan.',
          ),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mengirim laporan serangan hama.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          'Lapor Serangan Hama',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF334155), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            _buildEmergencyNoticeBanner(),
            const SizedBox(height: 16),
            _buildMainInfoCard(),
            const SizedBox(height: 16),
            _buildSeverityCard(),
            const SizedBox(height: 16),
            _buildPhotoEvidenceCard(),
            const SizedBox(height: 16),
            _buildRecommendationCard(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyNoticeBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.shieldAlert, size: 20, color: Color(0xFF2E7D32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistem Peringatan Dini Wilayah',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Laporan Anda akan otomatis disiarkan ke petani di kelompok tani yang sama dan diteruskan ke Penyuluh Pertanian Lapangan (PPL).',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF166534),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Serangan',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // Pest Name
          _buildFieldLabel('Nama Hama / Gejala Penyakit'),
          TextFormField(
            controller: _pestNameController,
            decoration: _inputDecoration('Contoh: Ulat Grayak, Wereng Coklat...'),
            style: GoogleFonts.inter(fontSize: 13),
            validator: (val) => val == null || val.trim().isEmpty ? 'Nama hama wajib diisi' : null,
          ),
          const SizedBox(height: 8),
          _buildQuickChipSelection(
            items: _commonPests,
            onSelected: (val) => setState(() => _pestNameController.text = val),
          ),
          const SizedBox(height: 14),

          // Crop Type
          _buildFieldLabel('Jenis Tanaman / Komoditas Terdampak'),
          TextFormField(
            controller: _cropTypeController,
            decoration: _inputDecoration('Contoh: Jagung Manis, Cabai Merah...'),
            style: GoogleFonts.inter(fontSize: 13),
            validator: (val) => val == null || val.trim().isEmpty ? 'Jenis tanaman wajib diisi' : null,
          ),
          const SizedBox(height: 8),
          _buildQuickChipSelection(
            items: _commonCrops,
            onSelected: (val) => setState(() => _cropTypeController.text = val),
          ),
          const SizedBox(height: 14),

          // Farmer Group Dropdown
          _buildFieldLabel('Kelompok Tani (Wilayah Terdampak)'),
          DropdownButtonFormField<String>(
            initialValue: _selectedPoktan,
            items: _poktanOptions.map((opt) {
              return DropdownMenuItem(
                value: opt['name'],
                child: Text(
                  '${opt['name']} (${opt['village']})',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                final match = _poktanOptions.firstWhere((p) => p['name'] == val);
                setState(() {
                  _selectedPoktan = match['name']!;
                  _selectedVillage = match['village']!;
                });
              }
            },
            decoration: _inputDecoration(''),
          ),
          const SizedBox(height: 14),

          // Affected Area
          _buildFieldLabel('Estimasi Luas Area Terdampak'),
          TextFormField(
            controller: _affectedAreaController,
            decoration: _inputDecoration('Contoh: 1.2 Hektar / 500 m²'),
            style: GoogleFonts.inter(fontSize: 13),
            validator: (val) => val == null || val.trim().isEmpty ? 'Luas area wajib diisi' : null,
          ),
          const SizedBox(height: 8),
          _buildQuickChipSelection(
            items: _areaPresets,
            onSelected: (val) => setState(() => _affectedAreaController.text = val),
          ),
          const SizedBox(height: 14),

          // Description
          _buildFieldLabel('Deskripsi Gejala & Ciri Lapangan'),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: _inputDecoration(
              'Jelaskan bagian tanaman yang terserang, pola penyebaran, atau ciri bercak daun...',
            ),
            style: GoogleFonts.inter(fontSize: 13),
            validator: (val) => val == null || val.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityCard() {
    final severities = [
      {
        'label': 'Ringan',
        'desc': 'Bercak awal <10% populasi',
        'color': const Color(0xFF2E7D32),
        'bg': const Color(0xFFE8F5E9),
      },
      {
        'label': 'Sedang',
        'desc': 'Menyerang 10-30% lahan',
        'color': const Color(0xFFEF6C00),
        'bg': const Color(0xFFFFF3E0),
      },
      {
        'label': 'Berat',
        'desc': 'Kritis >30%, risiko gagal panen',
        'color': const Color(0xFFC62828),
        'bg': const Color(0xFFFFEBEE),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tingkat Keparahan Serangan',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tingkat keparahan Berat akan otomatis memicu status Siaga Darurat.',
            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          Row(
            children: severities.map((item) {
              final isSelected = _selectedSeverity == item['label'];
              final color = item['color'] as Color;
              final bg = item['bg'] as Color;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSeverity = item['label'] as String;
                      if (_selectedSeverity == 'Berat') {
                        _enableEmergencyAlert = true;
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? bg : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          item['label'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? color : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['desc'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            color: isSelected ? color : const Color(0xFF64748B),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _enableEmergencyAlert || _selectedSeverity == 'Berat',
                  activeColor: const Color(0xFFC62828),
                  onChanged: _selectedSeverity == 'Berat'
                      ? null
                      : (val) => setState(() => _enableEmergencyAlert = val ?? false),
                ),
                Expanded(
                  child: Text(
                    'Kirim sebagai Notifikasi Siaga Darurat (Push Alert ke semua petani sekitar)',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoEvidenceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foto Bukti Serangan di Lahan',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ambil foto langsung di lahan atau gunakan contoh dokumentasi gejala.',
            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          // Uploaded / selected preview
          if (_pickedImage != null || _sampleImageUrl != null)
            Container(
              height: 160,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _pickedImage != null
                      ? Image.file(File(_pickedImage!.path), fit: BoxFit.cover)
                      : Image.network(_sampleImageUrl!, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _pickedImage = null;
                          _sampleImageUrl = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(LucideIcons.camera, size: 16, color: Color(0xFF2E7D32)),
                  label: Text('Kamera', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF2E7D32))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(LucideIcons.image, size: 16, color: Color(0xFF2E7D32)),
                  label: Text('Galeri', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF2E7D32))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Atau pilih contoh dokumentasi gejala:',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _sampleEvidencePhotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final photo = _sampleEvidencePhotos[idx];
                final isSelected = _sampleImageUrl == photo['url'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _sampleImageUrl = photo['url'];
                      _pickedImage = null;
                    });
                  },
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(photo['url']!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      color: Colors.black.withValues(alpha: 0.55),
                      child: Text(
                        photo['label']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rekomendasi Tindakan Cepat (Opsional)',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Saran penanganan awal bagi sesama petani sebelum penyuluh tiba.',
            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _handlingController,
            maxLines: 2,
            decoration: _inputDecoration(
              'Contoh: Segera semprot agens hayati Beauveria bassiana pada sore hari...',
            ),
            style: GoogleFonts.inter(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32), // Stitch Brand Primary
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF94A3B8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.send, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Kirim Laporan & Terbitkan Peringatan',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildQuickChipSelection({
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((item) {
        return InkWell(
          onTap: () => onSelected(item),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              item,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
      ),
    );
  }
}
