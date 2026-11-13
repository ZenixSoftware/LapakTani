import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../community_repository.dart';
import '../models/education_article.dart';
import '../widgets/create_post_sheet.dart';
import '../widgets/discussion_comment_sheet.dart';
import '../widgets/penyuluh_official_badge.dart';
import 'create_education_post_screen.dart';
import 'education_detail_screen.dart';

class EducationFeedScreen extends StatefulWidget {
  final bool initialVerifiedOnly;

  const EducationFeedScreen({
    super.key,
    this.initialVerifiedOnly = false,
  });

  @override
  State<EducationFeedScreen> createState() => _EducationFeedScreenState();
}

class _EducationFeedScreenState extends State<EducationFeedScreen> {
  final CommunityRepository _repository = CommunityRepository();
  final TextEditingController _searchController = TextEditingController();

  List<EducationArticle> _articles = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool _verifiedOnly = false;
  String _selectedCategory = 'Semua';

  final Set<String> _likedArticleIds = {};

  final List<String> _categories = [
    'Semua',
    'Teknik Budidaya',
    'Hama & Penyakit',
    'Pemupukan',
    'Irigasi',
    'Pasca Panen',
  ];

  @override
  void initState() {
    super.initState();
    _verifiedOnly = widget.initialVerifiedOnly;
    _loadArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _repository.getArticles(
        verifiedOnly: _verifiedOnly,
        category: _selectedCategory,
        searchQuery: _searchController.text,
      );

      if (!mounted) return;
      setState(() {
        _articles = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat materi edukasi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _verifiedOnly = false;
      _selectedCategory = 'Semua';
      _searchController.clear();
    });
    _loadArticles();
  }

  void _toggleLike(EducationArticle article) {
    final isLiked = _likedArticleIds.contains(article.id);
    final newCount = isLiked
        ? (article.likesCount > 0 ? article.likesCount - 1 : 0)
        : article.likesCount + 1;

    setState(() {
      if (isLiked) {
        _likedArticleIds.remove(article.id);
      } else {
        _likedArticleIds.add(article.id);
      }
      final idx = _articles.indexWhere((a) => a.id == article.id);
      if (idx >= 0) {
        _articles[idx] = _articles[idx].copyWith(likesCount: newCount);
      }
    });

    _repository.toggleArticleLike(article.id, !isLiked);
  }

  void _openDiscussionCommentSheet(EducationArticle article) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DiscussionCommentSheet(
        article: article,
        onCommentAdded: (newCount) {
          setState(() {
            final idx = _articles.indexWhere((a) => a.id == article.id);
            if (idx >= 0) {
              _articles[idx] = _articles[idx].copyWith(commentsCount: newCount);
            }
          });
        },
      ),
    );
  }

  void _openCreatePostSheet() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreatePostSheet(
        onPostPublished: () {
          _loadArticles();
        },
      ),
    ).then((result) {
      if (result == true) {
        _loadArticles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePostSheet,
        backgroundColor: const Color(0xFF03AC0E),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(LucideIcons.messageSquarePlus, size: 18),
        label: Text(
          '+ Buat Diskusi',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edukasi Pertanian',
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Materi budidaya resmi BPP & Penyuluh',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const CreateEducationPostScreen(),
                  ),
                );
                if (result == true) {
                  _loadArticles();
                }
              },
              icon: const Icon(LucideIcons.plus, size: 14),
              label: Text(
                'Tulis Materi',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF03AC0E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadArticles,
        color: const Color(0xFF03AC0E),
        child: Column(
          children: [
            _buildSearchAndFilters(),
            Expanded(child: _buildFeedBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search box
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Icon(LucideIcons.search, size: 17, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _loadArticles(),
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari tips budidaya, jagung, tomat, penyuluh...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 15, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      _searchController.clear();
                      _loadArticles();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Primary Filter Toggle: All vs Official Verified Badge
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (_verifiedOnly) {
                      setState(() => _verifiedOnly = false);
                      _loadArticles();
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: !_verifiedOnly
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Semua Materi',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: !_verifiedOnly ? FontWeight.w700 : FontWeight.w500,
                        color: !_verifiedOnly ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (!_verifiedOnly) {
                      setState(() => _verifiedOnly = true);
                      _loadArticles();
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: _verifiedOnly
                          ? const Color(0xFF03AC0E)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _verifiedOnly
                            ? const Color(0xFF03AC0E)
                            : const Color(0xFFA5D6A7),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.badgeCheck,
                          size: 14,
                          color: _verifiedOnly ? Colors.white : const Color(0xFF15803D),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Penyuluh Resmi',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _verifiedOnly
                                ? Colors.white
                                : const Color(0xFF14532D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Category Chips Scroll
          SizedBox(
            height: 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return InkWell(
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    _loadArticles();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
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

  Widget _buildFeedBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF03AC0E)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertCircle, size: 40, color: Color(0xFFEF4444)),
              const SizedBox(height: 10),
              Text(
                'Terjadi Kendala',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadArticles,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF03AC0E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.bookOpen,
                  size: 28,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tidak Ada Materi Ditemukan',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _verifiedOnly
                    ? 'Belum ada panduan budidaya terverifikasi untuk kategori ini.'
                    : 'Tidak ada materi yang sesuai kata kunci pencarian.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(LucideIcons.rotateCcw, size: 14),
                label: const Text('Reset Filter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: _articles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final article = _articles[index];
        return _buildArticleCard(article);
      },
    );
  }

  Widget _buildArticleCard(EducationArticle article) {
    final bool isLiked = _likedArticleIds.contains(article.id);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: article.isOfficialPenyuluh
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFE2E8F0),
          width: article.isOfficialPenyuluh ? 1.2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EducationDetailScreen(article: article),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row with Badge
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: article.isOfficialPenyuluh
                            ? const Color(0xFF14532D)
                            : const Color(0xFF475569),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          article.authorName.isNotEmpty
                              ? article.authorName.substring(0, 1).toUpperCase()
                              : 'P',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  article.authorName,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (article.isOfficialPenyuluh) ...[
                                const SizedBox(width: 6),
                                PenyuluhOfficialBadge(
                                  size: PenyuluhBadgeSize.small,
                                  bppAffiliation: article.bppOffice,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            article.authorRole,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Cover Image + Tags
                if (article.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Image.network(
                          article.imageUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 110,
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: Icon(LucideIcons.image, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              article.commodity,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF03AC0E),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              article.category,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),

                // Title
                Text(
                  article.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),

                // Summary
                Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),

                // Meta footer & interactive actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Reading time & BPP
                    Row(
                      children: [
                        const Icon(LucideIcons.clock, size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          '${article.readDurationMinutes} mnt baca',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        if (article.bppOffice != null) ...[
                          const SizedBox(width: 6),
                          const Text('•', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                          const SizedBox(width: 6),
                          Text(
                            article.bppOffice!,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: const Color(0xFF15803D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Interactive Action Buttons
                    Row(
                      children: [
                        // Interactive Like / Upvote Button with toggleable counter
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _toggleLike(article),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isLiked ? const Color(0xFFFEE2E2) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isLiked ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isLiked ? LucideIcons.heart : LucideIcons.heart,
                                    size: 13,
                                    color: isLiked ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${article.likesCount}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: isLiked ? FontWeight.w700 : FontWeight.w600,
                                      color: isLiked ? const Color(0xFFDC2626) : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Interactive Comment Button opening DiscussionCommentSheet
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openDiscussionCommentSheet(article),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFBBF7D0),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.messageSquare,
                                    size: 13,
                                    color: Color(0xFF15803D),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${article.commentsCount}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF15803D),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Komentar',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: const Color(0xFF166534),
                                      fontWeight: FontWeight.w500,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

