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

  static final List<EducationArticle> _defaultSeedArticles = [
    EducationArticle(
      id: 'edu-1',
      title: 'Panduan Pengendalian Hama Ulat Grayak pada Tanaman Jagung Manis',
      category: 'Hama & Penyakit',
      commodity: 'Jagung Manis',
      summary:
          'Strategi terpadu mengatasi serangan Spodoptera frugiperda pada pucuk tanaman jagung menggunakan biopestisida ramah lingkungan.',
      content:
          'Ulat grayak frugiperda (FAW) dapat merusak hingga 70% pucuk jagung muda jika tidak segera ditangani. Pendekatan ramah lingkungan mengutamakan agens hayati Beauveria bassiana dipadukan dengan sanitasi gulma di sekitar bedengan. Jangan melakukan penyemprotan insektisida kimia spektrum luas di siang terik agar musuh alami parasitoid telur tidak musnah.',
      steps: [
        'Inspeksi berkala pada daun muda di pagi hari, tandai tanaman yang berlubang serbuk gergaji.',
        'Pasang perangkap feromonoid setinggi pucuk daun untuk memantau populasi ngengat jantan.',
        'Aplikasikan suspensi Beauveria bassiana dosis 5 gram/liter pada sore hari menjelang magrib.',
        'Lakukan rotasi komoditas legum setelah masa panen jagung selesai untuk memutus siklus pupa.',
      ],
      authorName: 'Ir. Ahmad Hidayat',
      authorRole: 'Koordinator Penyuluh BPP Lembang',
      authorAvatar: null,
      bppOffice: 'BPP Lembang',
      isOfficialPenyuluh: true,
      nip: '198205142008011003',
      imageUrl:
          'https://images.unsplash.com/photo-1551754655-cd27e38d2076?auto=format&fit=crop&w=900&q=80',
      publishedAt: DateTime.now().subtract(const Duration(hours: 6)),
      readDurationMinutes: 5,
      likesCount: 142,
      commentsCount: 28,
      tags: ['Jagung', 'Organik', 'Penyuluh Resmi', 'Hama'],
    ),
    EducationArticle(
      id: 'edu-2',
      title: 'Teknik Efisiensi Irigasi Tetes Kebun Tomat Musim Kemarau',
      category: 'Irigasi',
      commodity: 'Tomat',
      summary:
          'Optimalisasi air irigasi dataran tinggi dengan dripper hemat energi dan mulsa perak untuk menjaga kelembapan tanah.',
      content:
          'Kekurangan air pada masa pembungaan tomat dapat memicu busuk pantat buah (blossom end rot). Metode irigasi tetes (drip irrigation) mampu menghemat penggunaan air sumur bor hingga 55% sekaligus mendistribusikan nutrisi larut secara merata ke zona perakaran aktif tanaman.',
      steps: [
        'Gelar selang drip lateral berdiameter 16 mm di sepanjang barisan tanaman dengan jarak emiter 20 cm.',
        'Atur jadwal fertigasi pada pukul 06.30 - 08.00 pagi dengan debit 800 ml per pohon setiap hari.',
        'Pasang mulsa plastik hitam perak (MPHP) untuk menahan laju evaporasi tanah lereng pegunungan.',
        'Cek tekanan filter air secara mingguan untuk mencegah penyumbatan endapan lumut dan pasir.',
      ],
      authorName: 'Siti Rahmawati, S.P.',
      authorRole: 'Penyuluh Hortikultura Ahli Pertama',
      authorAvatar: null,
      bppOffice: 'BPP Parongpong',
      isOfficialPenyuluh: true,
      nip: '198909212015022004',
      imageUrl:
          'https://images.unsplash.com/photo-1592841200221-a6898f307baa?auto=format&fit=crop&w=900&q=80',
      publishedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      readDurationMinutes: 4,
      likesCount: 98,
      commentsCount: 15,
      tags: ['Tomat', 'Irigasi', 'Hemat Air', 'Penyuluh Resmi'],
    ),
    EducationArticle(
      id: 'edu-3',
      title: 'Formulasi Pupuk Organik Cair (POC) Daun Gamal & Air Kelapa',
      category: 'Pemupukan',
      commodity: 'Sayuran Hijau',
      summary:
          'Resep mandiri penyuluh untuk membuat nutrisi vegetatif kaya Nitrogen alami tanpa bahan kimia pabrikan.',
      content:
          'Daun gamal (Gliricidia sepium) mengandung kadar nitrogen daun mencapai 3.5% bobot kering. Dengan fermentasi bersama air kelapa tua dan molase, petani dapat memangkas biaya pupuk dasar hingga 40% untuk komoditas bayam, sawi sendok, dan selada hijau hidroponik maupun ladang terbuka.',
      steps: [
        'Cincang halus 5 kg daun gamal segar lalu masukkan ke dalam drum plastik berkapasitas 25 liter.',
        'Tuangkan 10 liter air kelapa tua, 300 ml molase cair (tetes tebu), dan 150 ml starter dekomposer.',
        'Tutup rapat drum dan buat lubang aerasi airlock selang kecil ke botol air untuk buang gas gas fermentasi.',
        'Buka drum setelah 14 hari, saring cairan lalu semprotkan ke daun dengan rasio 1:20 air bersih.',
      ],
      authorName: 'Ir. Hendra Kusuma',
      authorRole: 'Penyuluh Madya Pertanian Organik',
      authorAvatar: null,
      bppOffice: 'BPP Cisarua',
      isOfficialPenyuluh: true,
      nip: '197603122001121002',
      imageUrl:
          'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&w=900&q=80',
      publishedAt: DateTime.now().subtract(const Duration(days: 2)),
      readDurationMinutes: 6,
      likesCount: 215,
      commentsCount: 34,
      tags: ['POC', 'Organik', 'Pupuk Alami', 'Penyuluh Resmi'],
    ),
    EducationArticle(
      id: 'edu-4',
      title: 'Tips Pengeringan Cabai Rawit Merah agar Warna Segar Mengkilap',
      category: 'Pasca Panen',
      commodity: 'Cabai Rawit',
      summary:
          'Pengalaman petani mengeringkan cabai merah tanpa oven untuk menjaga aroma tajam dan daya simpan.',
      content:
          'Cabai rawit yang dipanen pada tingkat kemerahan 90% perlu diangin-anginkan sebelum proses simpan atau distribusi jarak jauh. Menghindari penjemuran langsung di atas terpal panas menjaga kilau alami minyak atsiri cabai.',
      steps: [
        'Pisahkan tangkai cabai yang layu atau busuk ujung saat sortasi panen pagi.',
        'Hamparkan merata di tampah anyaman bambu dengan ketebalan maksimal dua lapis cabai.',
        'Tempatkan di ruang beratap transparan dengan ventilasi silang udara yang lancar.',
      ],
      authorName: 'Pak Ujang Supriatna',
      authorRole: 'Petani Cabai Poktan Tani Makmur',
      authorAvatar: null,
      bppOffice: null,
      isOfficialPenyuluh: false,
      nip: null,
      imageUrl:
          'https://images.unsplash.com/photo-1588252303782-cb80119abd6d?auto=format&fit=crop&w=900&q=80',
      publishedAt: DateTime.now().subtract(const Duration(days: 3)),
      readDurationMinutes: 3,
      likesCount: 45,
      commentsCount: 6,
      tags: ['Cabai', 'Tips Petani', 'Pasca Panen'],
    ),
    EducationArticle(
      id: 'edu-5',
      title: 'Manajemen pH Tanah Vulkanik untuk Umbi Wortel Lurus Tanpa Cabang',
      category: 'Teknik Budidaya',
      commodity: 'Wortel',
      summary:
          'Pengapuran dolomit terukur dan olah tanah gembur dalam untuk mencegah wortel bercabang dan pucat.',
      content:
          'Tanah dataran tinggi sering kali mengalami penurunan pH hingga di bawah 5.2 akibat curah hujan intensif. Kondisi asam mengikat fosfat sehingga pertumbuhan akar tunggang wortel terhambat dan bercabang. Panduan ini menjelaskan takaran kapur pertanian yang presisi sebelum tanam.',
      steps: [
        'Ukur pH tanah menggunakan pH meter tusuk minimal di lima titik acak kebun seminggu sebelum olah tanah.',
        'Taburkan kapur dolomit dosis 1.5 - 2 ton per hektar bila pH tanah berada di rentang 4.8 hingga 5.5.',
        'Bajak atau cangkul tanah sedalam 35 cm dan biarkan terkena sinar matahari selama 7 hari.',
        'Buat guludan setinggi 30 cm dengan lebar 100 cm agar drainase air hujan mengalir lancar.',
      ],
      authorName: 'Dr. Ir. Taufik Gunawan, M.P.',
      authorRole: 'Penyuluh Utama Hortikultura',
      authorAvatar: null,
      bppOffice: 'BPP Berastagi',
      isOfficialPenyuluh: true,
      nip: '197108151998031001',
      imageUrl:
          'https://images.unsplash.com/photo-1447175008436-054170c2e979?auto=format&fit=crop&w=900&q=80',
      publishedAt: DateTime.now().subtract(const Duration(days: 4)),
      readDurationMinutes: 7,
      likesCount: 180,
      commentsCount: 22,
      tags: ['Wortel', 'pH Tanah', 'Teknik Budidaya', 'Penyuluh Resmi'],
    ),
  ];

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    _memoryArticles.clear();
    _memoryArticles.addAll(_defaultSeedArticles);

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_storageKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(savedJson) as List<dynamic>;
        final userArticles = list.map((item) {
          return EducationArticle.fromJson(item as Map<String, dynamic>);
        }).toList();

        for (final userArt in userArticles) {
          final index = _memoryArticles.indexWhere((a) => a.id == userArt.id);
          if (index >= 0) {
            _memoryArticles[index] = userArt;
          } else {
            _memoryArticles.insert(0, userArt);
          }
        }
      }
    } catch (_) {
      // Local cache error fallback
    }

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
    String? searchQuery,
  }) async {
    await _ensureInitialized();

    // Check remote backend if reachable
    try {
      final queryParams = <String, String>{};
      if (verifiedOnly == true) queryParams['verified_only'] = 'true';
      if (category != null && category != 'Semua') queryParams['category'] = category;
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

          if (remoteArticles.isNotEmpty) {
            for (final rem in remoteArticles) {
              final idx = _memoryArticles.indexWhere((a) => a.id == rem.id);
              if (idx >= 0) {
                _memoryArticles[idx] = rem;
              } else {
                _memoryArticles.insert(0, rem);
              }
            }
          }
        }
      }
    } catch (_) {
      // Offline fallback: rely on local database
    }

    Iterable<EducationArticle> results = List.from(_memoryArticles);

    if (verifiedOnly == true) {
      results = results.where((a) => a.isOfficialPenyuluh);
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
      return _memoryArticles.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<EducationArticle> createArticle(EducationArticle article) async {
    await _ensureInitialized();

    _memoryArticles.insert(0, article);
    await _persistArticles();

    // Sync to backend asynchronously
    try {
      await ApiService.post('/education/articles', article.toJson());
    } catch (_) {}

    return article;
  }

  Future<void> toggleLike(String articleId) async {
    await _ensureInitialized();
    final index = _memoryArticles.indexWhere((a) => a.id == articleId);
    if (index >= 0) {
      final existing = _memoryArticles[index];
      _memoryArticles[index] = existing.copyWith(
        likesCount: existing.likesCount + 1,
      );
      await _persistArticles();
    }
  }
}

