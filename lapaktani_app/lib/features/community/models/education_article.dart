class EducationArticle {
  final String id;
  final String title;
  final String category;
  final String commodity;
  final String summary;
  final String content;
  final List<String> steps;
  final String authorName;
  final String authorRole;
  final String? authorAvatar;
  final String? bppOffice;
  final bool isOfficialPenyuluh;
  final String? nip;
  final String imageUrl;
  final DateTime publishedAt;
  final int readDurationMinutes;
  final int likesCount;
  final int commentsCount;
  final List<String> tags;

  const EducationArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.commodity,
    required this.summary,
    required this.content,
    required this.steps,
    required this.authorName,
    required this.authorRole,
    this.authorAvatar,
    this.bppOffice,
    required this.isOfficialPenyuluh,
    this.nip,
    required this.imageUrl,
    required this.publishedAt,
    required this.readDurationMinutes,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.tags = const [],
  });

  factory EducationArticle.fromJson(Map<String, dynamic> json) {
    return EducationArticle(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Teknik Budidaya',
      commodity: json['commodity']?.toString() ?? 'Umum',
      summary: json['summary']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      steps: json['steps'] is List
          ? (json['steps'] as List).map((e) => e.toString()).toList()
          : <String>[],
      authorName: json['author_name']?.toString() ??
          json['authorName']?.toString() ??
          'Penyuluh Pertanian',
      authorRole: json['author_role']?.toString() ??
          json['authorRole']?.toString() ??
          'Penyuluh Lapangan',
      authorAvatar: json['author_avatar']?.toString() ??
          json['authorAvatar']?.toString(),
      bppOffice: json['bpp_office']?.toString() ??
          json['bppOffice']?.toString(),
      isOfficialPenyuluh: json['is_official_penyuluh'] == true ||
          json['is_official_penyuluh'] == 1 ||
          json['isOfficialPenyuluh'] == true,
      nip: json['nip']?.toString(),
      imageUrl: json['image_url']?.toString() ??
          json['imageUrl']?.toString() ??
          '',
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString()) ?? DateTime.now()
          : (json['publishedAt'] != null
              ? DateTime.tryParse(json['publishedAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      readDurationMinutes: int.tryParse(json['read_duration_minutes']?.toString() ?? '') ??
          int.tryParse(json['readDurationMinutes']?.toString() ?? '') ??
          4,
      likesCount: int.tryParse(json['likes_count']?.toString() ?? '') ??
          int.tryParse(json['likesCount']?.toString() ?? '') ??
          0,
      commentsCount: int.tryParse(json['comments_count']?.toString() ?? '') ??
          int.tryParse(json['commentsCount']?.toString() ?? '') ??
          0,
      tags: json['tags'] is List
          ? (json['tags'] as List).map((e) => e.toString()).toList()
          : <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'commodity': commodity,
      'summary': summary,
      'content': content,
      'steps': steps,
      'author_name': authorName,
      'author_role': authorRole,
      'author_avatar': authorAvatar,
      'bpp_office': bppOffice,
      'is_official_penyuluh': isOfficialPenyuluh,
      'nip': nip,
      'image_url': imageUrl,
      'published_at': publishedAt.toIso8601String(),
      'read_duration_minutes': readDurationMinutes,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'tags': tags,
    };
  }

  EducationArticle copyWith({
    String? id,
    String? title,
    String? category,
    String? commodity,
    String? summary,
    String? content,
    List<String>? steps,
    String? authorName,
    String? authorRole,
    String? authorAvatar,
    String? bppOffice,
    bool? isOfficialPenyuluh,
    String? nip,
    String? imageUrl,
    DateTime? publishedAt,
    int? readDurationMinutes,
    int? likesCount,
    int? commentsCount,
    List<String>? tags,
  }) {
    return EducationArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      commodity: commodity ?? this.commodity,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      steps: steps ?? this.steps,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      bppOffice: bppOffice ?? this.bppOffice,
      isOfficialPenyuluh: isOfficialPenyuluh ?? this.isOfficialPenyuluh,
      nip: nip ?? this.nip,
      imageUrl: imageUrl ?? this.imageUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      readDurationMinutes: readDurationMinutes ?? this.readDurationMinutes,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      tags: tags ?? this.tags,
    );
  }
}

