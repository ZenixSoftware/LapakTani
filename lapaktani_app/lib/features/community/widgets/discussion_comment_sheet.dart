import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/user_session.dart';
import '../../../core/theme/app_colors.dart';
import '../community_repository.dart';
import '../models/education_article.dart';
import 'penyuluh_official_badge.dart';

class DiscussionComment {
  final String id;
  final String authorName;
  final String authorRole;
  final String? authorAvatar;
  final bool isOfficial;
  final String commentBody;
  final DateTime createdAt;

  const DiscussionComment({
    required this.id,
    required this.authorName,
    required this.authorRole,
    this.authorAvatar,
    this.isOfficial = false,
    required this.commentBody,
    required this.createdAt,
  });

  factory DiscussionComment.fromJson(Map<String, dynamic> json) {
    return DiscussionComment(
      id: json['id']?.toString() ?? '',
      authorName: json['author_name']?.toString() ??
          json['authorName']?.toString() ??
          'Petani LapakTani',
      authorRole: json['author_role']?.toString() ??
          json['authorRole']?.toString() ??
          'Petani',
      authorAvatar: json['author_avatar']?.toString() ??
          json['authorAvatar']?.toString(),
      isOfficial: json['is_official'] == true ||
          json['isOfficial'] == true ||
          json['is_official_penyuluh'] == true,
      commentBody: json['comment_body']?.toString() ??
          json['commentBody']?.toString() ??
          json['body']?.toString() ??
          '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_name': authorName,
      'author_role': authorRole,
      'author_avatar': authorAvatar,
      'is_official': isOfficial,
      'comment_body': commentBody,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class DiscussionCommentSheet extends StatefulWidget {
  final EducationArticle article;
  final void Function(int newCount)? onCommentAdded;

  const DiscussionCommentSheet({
    super.key,
    required this.article,
    this.onCommentAdded,
  });

  @override
  State<DiscussionCommentSheet> createState() => _DiscussionCommentSheetState();
}

class _DiscussionCommentSheetState extends State<DiscussionCommentSheet> {
  final CommunityRepository _repository = CommunityRepository();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<DiscussionComment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);

    try {
      final listData = await _repository.getComments(widget.article.id);
      final List<DiscussionComment> loaded =
          listData.map((item) => DiscussionComment.fromJson(item)).toList();

      // Seed initial realistic comments if no comments exist yet
      if (loaded.isEmpty) {
        final seedComments = _generateSeedComments();
        for (final seed in seedComments) {
          await _repository.addComment(widget.article.id, seed.toJson());
        }
        loaded.addAll(seedComments);
      }

      if (!mounted) return;
      setState(() {
        _comments.clear();
        _comments.addAll(loaded);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<DiscussionComment> _generateSeedComments() {
    final now = DateTime.now();
    return [
      DiscussionComment(
        id: 'seed_1_${widget.article.id}',
        authorName: 'Siti Rahmawati',
        authorRole: 'Penyuluh PPL BPP',
        isOfficial: true,
        commentBody:
            'Pastikan monitoring rutin kelembapan tanah dan sanitasi gulma di sekitar bedengan untuk menekan spora jamur.',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      DiscussionComment(
        id: 'seed_2_${widget.article.id}',
        authorName: 'Pak Joko Subekti',
        authorRole: 'Ketua Poktan Makmur',
        isOfficial: false,
        commentBody:
            'Metode ini sangat membantu kelompok kami saat pergantian musim lalu. Hasil panen bobotnya lebih seragam.',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 25)),
      ),
      DiscussionComment(
        id: 'seed_3_${widget.article.id}',
        authorName: 'Hendra Saputra',
        authorRole: 'Petani Cabai',
        isOfficial: false,
        commentBody:
            'Izin bertanya pak penyuluh, untuk dosis semprot perekat sebaiknya diaplikasikan pagi atau sore hari?',
        createdAt: now.subtract(const Duration(minutes: 20)),
      ),
    ];
  }

  Future<void> _handleSubmitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final currentUser = UserSession().currentUser;
    final authorName = (currentUser?.fullName != null &&
            currentUser!.fullName!.trim().isNotEmpty)
        ? currentUser.fullName!
        : 'Petani LapakTani';

    final authorRole = currentUser?.role != null &&
            currentUser!.role!.trim().isNotEmpty
        ? currentUser.role!
        : 'Petani';

    final isOfficial = authorRole.toLowerCase().contains('penyuluh') ||
        authorRole.toLowerCase().contains('ppl');

    final newComment = DiscussionComment(
      id: 'comm_${DateTime.now().millisecondsSinceEpoch}',
      authorName: authorName,
      authorRole: isOfficial ? 'Penyuluh PPL Resmi' : authorRole,
      isOfficial: isOfficial,
      commentBody: text,
      createdAt: DateTime.now(),
    );

    await _repository.addComment(widget.article.id, newComment.toJson());

    if (!mounted) return;
    setState(() {
      _comments.add(newComment);
      _commentController.clear();
      _isSending = false;
    });

    widget.onCommentAdded?.call(_comments.length);

    // Smooth scroll to latest comment
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd MMM, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    final isPplOrPoktan = widget.article.isOfficialPenyuluh ||
        widget.article.authorRole.toLowerCase().contains('penyuluh') ||
        widget.article.authorRole.toLowerCase().contains('ppl') ||
        widget.article.authorRole.toLowerCase().contains('poktan');

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.88,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Header with post title, author avatar, and official badge (if PPL/Poktan)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 12, 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.outline),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Author avatar
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: widget.article.isOfficialPenyuluh
                            ? AppColors.primaryDark
                            : AppColors.textSecondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.article.isOfficialPenyuluh
                              ? AppColors.secondary
                              : AppColors.outline,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.article.authorName.isNotEmpty
                              ? widget.article.authorName
                                  .substring(0, 1)
                                  .toUpperCase()
                              : 'P',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.surface,
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
                                  widget.article.authorName,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isPplOrPoktan) ...[
                                const SizedBox(width: 6),
                                PenyuluhOfficialBadge(
                                  size: PenyuluhBadgeSize.small,
                                  bppAffiliation: widget.article.bppOffice,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.article.authorRole,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x,
                          size: 20, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Post title in header
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.messageSquare,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.article.title,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.outline,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_comments.length} Diskusi',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable ListView of comments
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.messageCircle,
                                size: 36, color: AppColors.outline),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada komentar diskusi',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Jadilah yang pertama memberikan tanggapan budidaya!',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        itemCount: _comments.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 16, color: AppColors.outline),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return _buildCommentItem(comment);
                        },
                      ),
          ),

          // Sticky bottom input bar with TextField and send IconButton
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                top: BorderSide(color: AppColors.outline),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, -3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.outline),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _commentController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSubmitComment(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tulis komentar atau tanggapan diskusi...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.surface,
                              ),
                            )
                          : const Icon(LucideIcons.send,
                              color: AppColors.surface, size: 17),
                      onPressed: _isSending ? null : _handleSubmitComment,
                      tooltip: 'Kirim Komentar',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(DiscussionComment comment) {
    final bool isPpl = comment.isOfficial ||
        comment.authorRole.toLowerCase().contains('penyuluh') ||
        comment.authorRole.toLowerCase().contains('ppl');
    final bool isPoktan =
        comment.authorRole.toLowerCase().contains('poktan') ||
        comment.authorRole.toLowerCase().contains('kelompok tani');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User avatar
        CircleAvatar(
          radius: 17,
          backgroundColor: isPpl
              ? AppColors.surfaceMint
              : (isPoktan ? AppColors.infoSoft : AppColors.background),
          child: Text(
            comment.authorName.isNotEmpty
                ? comment.authorName.substring(0, 1).toUpperCase()
                : 'U',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isPpl
                  ? AppColors.primary
                  : (isPoktan
                      ? AppColors.info
                      : AppColors.textSecondary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username + Role chip + Timestamp
              Row(
                children: [
                  Flexible(
                    child: Text(
                      comment.authorName,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Role chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPpl
                          ? AppColors.surfaceMint
                          : (isPoktan
                              ? AppColors.infoSoft
                              : AppColors.background),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isPpl
                            ? AppColors.surfaceSoftBorder
                            : (isPoktan
                                ? AppColors.info.withValues(alpha: 0.35)
                                : AppColors.outline),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPpl) ...[
                          const Icon(LucideIcons.badgeCheck,
                              size: 10, color: AppColors.primary),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          comment.authorRole,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isPpl
                                ? AppColors.primary
                                : (isPoktan
                                    ? AppColors.info
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Timestamp
                  Text(
                    _formatTimestamp(comment.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Comment body
              Text(
                comment.commentBody,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

