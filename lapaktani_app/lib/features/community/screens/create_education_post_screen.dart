import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/auth_repository.dart';
import '../community_repository.dart';
import '../models/education_article.dart';
import '../widgets/penyuluh_official_badge.dart';

class CreateEducationPostScreen extends StatefulWidget {
  const CreateEducationPostScreen({super.key});

  @override
  State<CreateEducationPostScreen> createState() => _CreateEducationPostScreenState();
}

class _CreateEducationPostScreenState extends State<CreateEducationPostScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _commodityController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _readDurationController =
      TextEditingController(text: '5');

  String _selectedCategory = 'Teknik Budidaya';
  final List<String> _categories = [
    'Teknik Budidaya',
    'Hama & Penyakit',
    'Pemupukan',
    'Irigasi',
    'Pasca Panen',
  ];

  final List<TextEditingController> _stepControllers = [
    TextEditingController(text: 'Persiapan lahan dan pengecekan kelembapan tanah.'),
    TextEditingController(text: 'Aplikasi benih unggul bersertifikasi dan nutrisi dasar.'),
  ];

  // Dynamic profile state loaded from session/auth
  bool _isLoadingProfile = true;
  bool _isVerifiedPenyuluh = false;
  String _authorName = 'Penyuluh Pertanian';
  String _authorRole = 'Penyuluh Pertanian';
  String _authorBpp = 'BPP Lembang';
  String? _authorNip;

  bool _agreementChecked = true;
  bool _isSubmitting = false;

  final List<Map<String, String>> _sampleCovers = [
    {
      'label': 'Jagung',
      'url':
          'https://images.unsplash.com/photo-1551754655-cd27e38d2076?auto=format&fit=crop&w=900&q=80',
    },
    {
      'label': 'Tomat',
      'url':
          'https://images.unsplash.com/photo-1592841200221-a6898f307baa?auto=format&fit=crop&w=900&q=80',
    },
    {
      'label': 'Kebun',
      'url':
          'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&w=900&q=80',
    },
    {
      'label': 'Wortel',
      'url':
          'https://images.unsplash.com/photo-1447175008436-054170c2e979?auto=format&fit=crop&w=900&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _commodityController.text = 'Jagung Manis';
    _imageUrlController.text = _sampleCovers[0]['url']!;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userMap = await ApiService().getUser();
      final currentUser = AuthRepository().currentUser;

      final roleStr = userMap?['role']?.toString() ?? currentUser?.role ?? '';
      final roleId = userMap?['role_id'];
      final fullName = userMap?['full_name']?.toString() ??
          userMap?['name']?.toString() ??
          currentUser?.fullName ??
          'Ir. Ahmad Hidayat';
      final verificationStatus = userMap?['verification_status']?.toString();
      final isOfficial = roleStr.toLowerCase() == 'penyuluh' ||
          roleId == 2 ||
          verificationStatus == 'verified' ||
          userMap?['is_verified'] == true ||
          userMap?['is_verified'] == 1;

      if (mounted) {
        setState(() {
          _authorName = fullName;
          _isVerifiedPenyuluh = isOfficial;
          _authorRole = isOfficial ? 'Penyuluh Pertanian Lapangan' : 'Petani Komunitas';
          _authorBpp = userMap?['bpp_unit']?.toString() ?? 'BPP Lembang';
          _authorNip = userMap?['nip']?.toString() ?? '198205142008011003';
          _isLoadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _commodityController.dispose();
    _imageUrlController.dispose();
    _readDurationController.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addStepField() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStepField(int index) {
    if (_stepControllers.length <= 1) return;
    setState(() {
      final controller = _stepControllers.removeAt(index);
      controller.dispose();
    });
  }

  Future<void> _handleSubmit() async {
    if (!_agreementChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap konfirmasi kesesuaian pedoman teknis penyuluhan BPP.',
          ),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final steps = _stepControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal sertakan 1 langkah praktis budidaya.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final newArticle = EducationArticle(
        id: '', // Will be assigned by backend UUID
        title: _titleController.text.trim(),
        category: _selectedCategory,
        commodity: _commodityController.text.trim(),
        summary: _summaryController.text.trim(),
        content: _contentController.text.trim(),
        steps: steps,
        authorName: _authorName,
        authorRole: _authorRole,
        authorAvatar: null,
        bppOffice: _authorBpp,
        isOfficialPenyuluh: _isVerifiedPenyuluh,
        nip: _authorNip,
        imageUrl: _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : _sampleCovers[0]['url']!,
        publishedAt: DateTime.now(),
        readDurationMinutes: int.tryParse(_readDurationController.text.trim()) ?? 5,
        likesCount: 0,
        commentsCount: 0,
        tags: [
          _commodityController.text.trim(),
          _selectedCategory,
          if (_isVerifiedPenyuluh) 'Penyuluh Resmi',
        ],
      );

      await CommunityRepository().createArticle(newArticle);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Materi budidaya "${newArticle.title}" berhasil dipublikasikan ke server.',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menerbitkan materi: ${e.toString()}'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
          'Postingan Materi Penyuluh',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF334155), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  _buildPenyuluhIdentityCard(),
                  const SizedBox(height: 16),
                  _buildPostFormSection(),
                  const SizedBox(height: 16),
                  _buildStepsSection(),
                  const SizedBox(height: 16),
                  _buildCoverImageSection(),
                  const SizedBox(height: 16),
                  _buildComplianceCheckbox(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildPenyuluhIdentityCard() {
    final initials = _authorName.trim().isNotEmpty
        ? _authorName.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : 'PT';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isVerifiedPenyuluh ? const Color(0xFF14532D) : const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
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
                            _authorName,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isVerifiedPenyuluh) ...[
                          const SizedBox(width: 6),
                          const PenyuluhOfficialBadge(
                            size: PenyuluhBadgeSize.small,
                            showTooltip: false,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _authorNip != null && _authorNip!.isNotEmpty
                          ? '$_authorRole • NIP $_authorNip'
                          : _authorRole,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Wilayah Binaan: $_authorBpp',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.checkCircle2,
                  size: 15,
                  color: Color(0xFF15803D),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isVerifiedPenyuluh
                        ? 'Setiap artikel yang Anda terbitkan otomatis diberi lencana verifikasi resmi BPP.'
                        : 'Artikel Anda akan dipublikasikan ke kanal komunitas petani terverifikasi.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF166534),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostFormSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Materi',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // Title
          _buildFieldLabel('Judul Materi Budidaya'),
          TextFormField(
            controller: _titleController,
            decoration: _inputDecoration('Contoh: Panduan Pemupukan Berimbang Padi Sawah'),
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Judul materi wajib diisi.';
              }
              if (val.trim().length < 8) {
                return 'Judul minimal 8 karakter.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Category Chips
          _buildFieldLabel('Kategori Pertanian'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(
                  cat,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: const Color(0xFFF1F5F9),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedCategory = cat);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Commodity and Reading duration
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Komoditas'),
                    TextFormField(
                      controller: _commodityController,
                      decoration: _inputDecoration('Jagung, Tomat, Cabai...'),
                      style: GoogleFonts.inter(fontSize: 13),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Waktu Baca'),
                    TextFormField(
                      controller: _readDurationController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Menit').copyWith(
                        suffixText: 'mnt',
                        suffixStyle: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      style: GoogleFonts.inter(fontSize: 13),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Isi angka' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Summary
          _buildFieldLabel('Ringkasan Singkat (Abstrak)'),
          TextFormField(
            controller: _summaryController,
            maxLines: 2,
            decoration: _inputDecoration(
              'Tuliskan poin utama materi dalam 1 atau 2 kalimat ringkas untuk pengantar.',
            ),
            style: GoogleFonts.inter(fontSize: 13),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Ringkasan singkat wajib diisi.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Content
          _buildFieldLabel('Uraian Lengkap Materi Budidaya'),
          TextFormField(
            controller: _contentController,
            maxLines: 5,
            decoration: _inputDecoration(
              'Jelaskan latar belakang teknis, analisis tanah, dosis yang disarankan, dan penanganan di lahan...',
            ),
            style: GoogleFonts.inter(fontSize: 13),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Isi uraian materi wajib diisi.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    'Langkah Praktis Budidaya',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Panduan berurutan yang dapat langsung dipraktikkan petani',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _addStepField,
                icon: const Icon(LucideIcons.plusCircle, size: 15, color: AppColors.primary),
                label: Text(
                  'Tambah',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stepControllers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF14532D),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stepControllers[index],
                      maxLines: 2,
                      decoration: _inputDecoration('Langkah ${index + 1}...'),
                      style: GoogleFonts.inter(fontSize: 12.5),
                    ),
                  ),
                  if (_stepControllers.length > 1)
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFF94A3B8)),
                      onPressed: () => _removeStepField(index),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foto Dokumentasi Lapangan',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih salah satu preset foto berkualitas tinggi atau cantumkan tautan foto ladang Anda',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _sampleCovers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final item = _sampleCovers[idx];
                final isSelected = _imageUrlController.text == item['url'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _imageUrlController.text = item['url']!;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(item['url']!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      color: Colors.black.withValues(alpha: 0.55),
                      child: Text(
                        item['label']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 10,
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
          const SizedBox(height: 12),
          TextFormField(
            controller: _imageUrlController,
            decoration: _inputDecoration('URL Gambar dokumentasi'),
            style: GoogleFonts.inter(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceCheckbox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _agreementChecked,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _agreementChecked = val ?? false);
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Saya menyatakan materi ini disusun berdasarkan standar operasional prosedur pertanian yang sahih dan dapat dipertanggungjawabkan kepada petani.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF94A3B8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
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
                  const Icon(LucideIcons.send, size: 17),
                  const SizedBox(width: 8),
                  Text(
                    'Publikasikan Materi Resmi',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
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
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF94A3B8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
