import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../community_repository.dart';
import '../models/education_article.dart';
import '../widgets/discussion_comment_sheet.dart';
import '../widgets/penyuluh_official_badge.dart';

class EducationDetailScreen extends StatefulWidget {
  final EducationArticle article;

  const EducationDetailScreen({
    super.key,
    required this.article,
  });

  @override
  State<EducationDetailScreen> createState() => _EducationDetailScreenState();
}

class _EducationDetailScreenState extends State<EducationDetailScreen> {
  late EducationArticle _article;
  bool _isLiked = false;
  late int _likesCount;
  final Set<int> _completedSteps = {};

  @override
  void initState() {
    super.initState();
    _article = widget.article;
    _likesCount = _article.likesCount;
  }

  void _handleToggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
    CommunityRepository().toggleLike(_article.id);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.neutral, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.messageSquare, color: AppColors.neutralMuted, size: 19),
            tooltip: 'Komentar Diskusi',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => DiscussionCommentSheet(
                  article: _article,
                  onCommentAdded: (newCount) {
                    setState(() {
                      _article = _article.copyWith(commentsCount: newCount);
                    });
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isLiked ? LucideIcons.heart : LucideIcons.heart,
              color: _isLiked ? AppColors.error : AppColors.neutralMuted,
              size: 20,
            ),
            onPressed: _handleToggleLike,
          ),
          IconButton(
            icon: const Icon(LucideIcons.share2, color: AppColors.neutralMuted, size: 19),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tautan materi berhasil disalin ke papan klip.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Commodity & Category tags
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: Text(
                  _article.commodity,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCanvas,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _article.category,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralMuted,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${_article.readDurationMinutes} mnt baca',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.neutralSubtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            _article.title,
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.neutral,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Author Bar with Official Badge
          _buildAuthorSection(),
          const SizedBox(height: 14),

          // Hero Image
          if (_article.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _article.imageUrl,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 160,
                  color: AppColors.border,
                  child: const Center(
                    child: Icon(LucideIcons.image, color: AppColors.neutralSubtle, size: 36),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Summary box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.sparkles,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _article.summary,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content body
          Text(
            _article.content,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: AppColors.neutral,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),

          // Practical steps checklist
          if (_article.steps.isNotEmpty) _buildPracticalSteps(),
          const SizedBox(height: 20),

          // Engagement bar
          _buildEngagementBar(),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildAuthorSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _article.isOfficialPenyuluh
                  ? AppColors.primaryDark
                  : AppColors.secondaryDark,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _article.authorName.isNotEmpty
                    ? _article.authorName.substring(0, 1).toUpperCase()
                    : 'P',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _article.authorName,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutral,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_article.isOfficialPenyuluh) ...[
                      const SizedBox(width: 6),
                      PenyuluhOfficialBadge(
                        size: PenyuluhBadgeSize.small,
                        bppAffiliation: _article.bppOffice,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _article.nip != null
                      ? '${_article.authorRole} • NIP ${_article.nip}'
                      : _article.authorRole,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.neutralMuted,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _formatDate(_article.publishedAt),
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: AppColors.neutralSubtle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticalSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.listOrdered, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Langkah Praktis Budidaya',
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.neutral,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Centang langkah yang telah Anda terapkan di lahan:',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.neutralMuted,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _article.steps.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final isDone = _completedSteps.contains(index);
            return InkWell(
              onTap: () {
                setState(() {
                  if (isDone) {
                    _completedSteps.remove(index);
                  } else {
                    _completedSteps.add(index);
                  }
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDone ? AppColors.primaryTint : AppColors.surfaceCanvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDone ? AppColors.primaryBorder : AppColors.border,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.primary : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone ? AppColors.primary : AppColors.neutralBorder,
                        ),
                      ),
                      child: isDone
                          ? const Icon(LucideIcons.check, size: 13, color: Colors.white)
                          : Center(
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.neutralMuted,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _article.steps[index],
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: isDone ? AppColors.primary : AppColors.neutral,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEngagementBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.heart, size: 15, color: AppColors.error),
              const SizedBox(width: 5),
              Text(
                '$_likesCount petani menyukai ini',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutralMuted,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(LucideIcons.messageSquare, size: 15, color: AppColors.neutralMuted),
              const SizedBox(width: 5),
              Text(
                '${_article.commentsCount} diskusi',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutralMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Panduan budidaya berhasil disimpan di daftar baca.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.neutral,
                  side: const BorderSide(color: AppColors.neutralBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(LucideIcons.bookmark, size: 16),
                label: Text(
                  'Simpan Panduan',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Menghubungkan ke ruang konsultasi penyuluh ${_article.authorName}.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(LucideIcons.messageCircle, size: 16),
                label: Text(
                  'Tanya Penyuluh',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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

