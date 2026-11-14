import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_service.dart';
import 'models/education_article.dart';

class CommunityRepository {
  static final CommunityRepository _instance = CommunityRepository._internal();
  factory CommunityRepository() => _instance;
  CommunityRepository._internal();

  static const String _storageKey = 'local_education_articles_v1';

  final List<EducationArticle> _memoryArticles = [];
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_storageKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(cachedJson) as List<dynamic>;
        _memoryArticles.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _memoryArticles.add(EducationArticle.fromJson(item));
          }
        }
      }
    } catch (_) {}
    _isInitialized = true;
  }

  Future<void> _persistArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _memoryArticles.map((a) => a.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (_) {}
  }

  Future<List<EducationArticle>> getArticles({
    bool? verifiedOnly,
    String? category,
    String? commodity,
    String? searchQuery,
  }) async {
    await _ensureInitialized();

    // Check remote backend if reachable
    try {
      final queryParams = <String, String>{};
      if (verifiedOnly == true) queryParams['verified_only'] = 'true';
      if (category != null && category.isNotEmpty && category != 'Semua') {
        queryParams['category'] = category;
      }
      if (commodity != null && commodity.isNotEmpty && commodity != 'Semua') {
        queryParams['commodity'] = commodity;
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        queryParams['search'] = searchQuery.trim();
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final path = '/education/articles${queryString.isNotEmpty ? '?$queryString' : ''}';

      final response = await ApiService.get(path);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is List) {
          final remoteArticles = (body['data'] as List)
              .map((item) => EducationArticle.fromJson(item as Map<String, dynamic>))
              .toList();

          // Remote backend takes authoritative precedence
          if (remoteArticles.isNotEmpty) {
            _memoryArticles.clear();
            _memoryArticles.addAll(remoteArticles);
            await _persistArticles();
            return remoteArticles;
          }
        }
      }
    } catch (_) {
      // Offline fallback: rely on local cached database
    }

    Iterable<EducationArticle> results = List.from(_memoryArticles);

    if (verifiedOnly == true) {
      results = results.where((a) => a.isOfficialPenyuluh);
    }

    if (commodity != null && commodity.isNotEmpty && commodity != 'Semua') {
      results = results.where(
        (a) => a.commodity.toLowerCase() == commodity.toLowerCase(),
      );
    }

    if (category != null && category.isNotEmpty && category != 'Semua') {
      results = results.where(
        (a) => a.category.toLowerCase() == category.toLowerCase(),
      );
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      results = results.where((a) {
        return a.title.toLowerCase().contains(q) ||
            a.commodity.toLowerCase().contains(q) ||
            a.authorName.toLowerCase().contains(q) ||
            a.summary.toLowerCase().contains(q) ||
            a.tags.any((t) => t.toLowerCase().contains(q));
      });
    }

    final sorted = results.toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    return sorted;
  }

  Future<EducationArticle?> getArticleById(String id) async {
    await _ensureInitialized();

    try {
      final response = await ApiService.get('/education/articles/$id');
      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is Map<String, dynamic>) {
          final article = EducationArticle.fromJson(body['data'] as Map<String, dynamic>);
          final idx = _memoryArticles.indexWhere((a) => a.id == article.id);
          if (idx >= 0) {
            _memoryArticles[idx] = article;
          } else {
            _memoryArticles.insert(0, article);
          }
          await _persistArticles();
          return article;
        }
      }
    } catch (_) {}

    try {
      return _memoryArticles.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<EducationArticle> createArticle(EducationArticle article) async {
    await _ensureInitialized();

    final payload = {
      'title': article.title,
      'category': article.category,
      'commodity': article.commodity,
      'summary': article.summary,
      'content': article.content,
      'steps': article.steps,
      'image_url': article.imageUrl,
      'read_duration_minutes': article.readDurationMinutes,
    };

    try {
      final response = await ApiService.post('/education/articles', payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is Map<String, dynamic>) {
          final createdArticle =
              EducationArticle.fromJson(body['data'] as Map<String, dynamic>);
          _memoryArticles.insert(0, createdArticle);
          await _persistArticles();
          return createdArticle;
        }
      }
    } catch (_) {
      // Offline fallback: continue to local persistence below
    }

    _memoryArticles.insert(0, article);
    await _persistArticles();
    return article;
  }

  Future<void> toggleLike(String articleId) async {
    await toggleArticleLike(articleId, true);
  }

  Future<int> toggleArticleLike(String articleId, bool isLiked) async {
    await _ensureInitialized();
    final index = _memoryArticles.indexWhere((a) => a.id == articleId);
    if (index >= 0) {
      final existing = _memoryArticles[index];
      final newCount = isLiked
          ? existing.likesCount + 1
          : (existing.likesCount > 0 ? existing.likesCount - 1 : 0);
      _memoryArticles[index] = existing.copyWith(likesCount: newCount);
      await _persistArticles();
      return newCount;
    }
    return 0;
  }

  static const String _commentsStoragePrefix = 'local_discussion_comments_v1_';
  final Map<String, List<Map<String, dynamic>>> _memoryComments = {};

  Future<List<Map<String, dynamic>>> getComments(String articleId) async {
    await _ensureInitialized();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_commentsStoragePrefix$articleId');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        final result = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _memoryComments[articleId] = result;
        return result;
      }
    } catch (_) {}

    if (_memoryComments.containsKey(articleId)) {
      return List<Map<String, dynamic>>.from(_memoryComments[articleId]!);
    }

    return [];
  }

  Future<void> addComment(String articleId, Map<String, dynamic> comment) async {
    await _ensureInitialized();
    final list = await getComments(articleId);
    list.add(comment);
    _memoryComments[articleId] = list;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_commentsStoragePrefix$articleId',
        jsonEncode(list),
      );
    } catch (_) {}

    // Update comments_count in article
    final index = _memoryArticles.indexWhere((a) => a.id == articleId);
    if (index >= 0) {
      final existing = _memoryArticles[index];
      _memoryArticles[index] = existing.copyWith(
        commentsCount: existing.commentsCount + 1,
      );
      await _persistArticles();
    }
  }
}
