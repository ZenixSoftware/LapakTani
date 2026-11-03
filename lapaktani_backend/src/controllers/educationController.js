const pool = require('../config/db');

// In-memory / initial seed data when database table is not yet migrated
let memoryArticles = [
  {
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
      'Lakukan rotasi komoditas legum setelah masa panen jagung selesai untuk memutus siklus pupa.'
    ],
    author_name: 'Ir. Ahmad Hidayat',
    author_role: 'Koordinator Penyuluh BPP Lembang',
    bpp_office: 'BPP Lembang',
    is_official_penyuluh: true,
    nip: '198205142008011003',
    image_url:
      'https://images.unsplash.com/photo-1551754655-cd27e38d2076?auto=format&fit=crop&w=900&q=80',
    published_at: new Date(Date.now() - 6 * 3600 * 1000).toISOString(),
    read_duration_minutes: 5,
    likes_count: 142,
    comments_count: 28,
    tags: ['Jagung', 'Organik', 'Penyuluh Resmi', 'Hama']
  },
  {
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
      'Cek tekanan filter air secara mingguan untuk mencegah penyumbatan endapan lumut dan pasir.'
    ],
    author_name: 'Siti Rahmawati, S.P.',
    author_role: 'Penyuluh Hortikultura Ahli Pertama',
    bpp_office: 'BPP Parongpong',
    is_official_penyuluh: true,
    nip: '198909212015022004',
    image_url:
      'https://images.unsplash.com/photo-1592841200221-a6898f307baa?auto=format&fit=crop&w=900&q=80',
    published_at: new Date(Date.now() - 26 * 3600 * 1000).toISOString(),
    read_duration_minutes: 4,
    likes_count: 98,
    comments_count: 15,
    tags: ['Tomat', 'Irigasi', 'Hemat Air', 'Penyuluh Resmi']
  },
  {
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
      'Buka drum setelah 14 hari, saring cairan lalu semprotkan ke daun dengan rasio 1:20 air bersih.'
    ],
    author_name: 'Ir. Hendra Kusuma',
    author_role: 'Penyuluh Madya Pertanian Organik',
    bpp_office: 'BPP Cisarua',
    is_official_penyuluh: true,
    nip: '197603122001121002',
    image_url:
      'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&w=900&q=80',
    published_at: new Date(Date.now() - 48 * 3600 * 1000).toISOString(),
    read_duration_minutes: 6,
    likes_count: 215,
    comments_count: 34,
    tags: ['POC', 'Organik', 'Pupuk Alami', 'Penyuluh Resmi']
  },
  {
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
      'Tempatkan di ruang beratap transparan dengan ventilasi silang udara yang lancar.'
    ],
    author_name: 'Pak Ujang Supriatna',
    author_role: 'Petani Cabai Poktan Tani Makmur',
    bpp_office: null,
    is_official_penyuluh: false,
    nip: null,
    image_url:
      'https://images.unsplash.com/photo-1588252303782-cb80119abd6d?auto=format&fit=crop&w=900&q=80',
    published_at: new Date(Date.now() - 72 * 3600 * 1000).toISOString(),
    read_duration_minutes: 3,
    likes_count: 45,
    comments_count: 6,
    tags: ['Cabai', 'Tips Petani', 'Pasca Panen']
  },
  {
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
      'Buat guludan setinggi 30 cm dengan lebar 100 cm agar drainase air hujan mengalir lancar.'
    ],
    author_name: 'Dr. Ir. Taufik Gunawan, M.P.',
    author_role: 'Penyuluh Utama Hortikultura',
    bpp_office: 'BPP Berastagi',
    is_official_penyuluh: true,
    nip: '197108151998031001',
    image_url:
      'https://images.unsplash.com/photo-1447175008436-054170c2e979?auto=format&fit=crop&w=900&q=80',
    published_at: new Date(Date.now() - 96 * 3600 * 1000).toISOString(),
    read_duration_minutes: 7,
    likes_count: 180,
    comments_count: 22,
    tags: ['Wortel', 'pH Tanah', 'Teknik Budidaya', 'Penyuluh Resmi']
  }
];

const getArticles = async (req, res) => {
  try {
    const { verified_only, category, search } = req.query;

    let filtered = [...memoryArticles];

    if (verified_only === 'true' || verified_only === '1') {
      filtered = filtered.filter((a) => a.is_official_penyuluh === true);
    }

    if (category && category !== 'Semua') {
      filtered = filtered.filter(
        (a) => a.category.toLowerCase() === category.toLowerCase()
      );
    }

    if (search && search.trim().length > 0) {
      const q = search.trim().toLowerCase();
      filtered = filtered.filter(
        (a) =>
          a.title.toLowerCase().includes(q) ||
          a.commodity.toLowerCase().includes(q) ||
          a.author_name.toLowerCase().includes(q) ||
          a.summary.toLowerCase().includes(q)
      );
    }

    return res.status(200).json({
      success: true,
      message: 'Materi edukasi pertanian berhasil diambil.',
      total: filtered.length,
      data: filtered
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil data materi edukasi.',
      error: error.message
    });
  }
};

const getArticleById = async (req, res) => {
  try {
    const { id } = req.params;
    const article = memoryArticles.find((a) => a.id === id);

    if (!article) {
      return res.status(404).json({
        success: false,
        message: 'Materi edukasi tidak ditemukan.'
      });
    }

    return res.status(200).json({
      success: true,
      data: article
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil detail materi.',
      error: error.message
    });
  }
};

const createArticle = async (req, res) => {
  try {
    const {
      title,
      category,
      commodity,
      summary,
      content,
      steps,
      author_name,
      author_role,
      bpp_office,
      is_official_penyuluh,
      nip,
      image_url,
      read_duration_minutes,
      tags
    } = req.body;

    if (!title || !category || !content) {
      return res.status(400).json({
        success: false,
        message: 'Judul, kategori, dan isi materi wajib diisi.'
      });
    }

    const newArticle = {
      id: `edu-${Date.now()}`,
      title: title.trim(),
      category: category.trim(),
      commodity: commodity ? commodity.trim() : 'Umum',
      summary: summary ? summary.trim() : '',
      content: content.trim(),
      steps: Array.isArray(steps) ? steps : [],
      author_name: author_name || 'Ir. Ahmad Hidayat',
      author_role: author_role || 'Koordinator BPP Lembang',
      bpp_office: bpp_office || 'BPP Lembang',
      is_official_penyuluh:
        is_official_penyuluh !== undefined ? Boolean(is_official_penyuluh) : true,
      nip: nip || '198205142008011003',
      image_url:
        image_url ||
        'https://images.unsplash.com/photo-1551754655-cd27e38d2076?auto=format&fit=crop&w=900&q=80',
      published_at: new Date().toISOString(),
      read_duration_minutes: parseInt(read_duration_minutes, 10) || 4,
      likes_count: 0,
      comments_count: 0,
      tags: Array.isArray(tags) ? tags : ['Penyuluh Resmi', category]
    };

    memoryArticles.unshift(newArticle);

    return res.status(201).json({
      success: true,
      message: 'Materi edukasi budidaya resmi berhasil dipublikasikan.',
      data: newArticle
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Gagal membuat materi edukasi.',
      error: error.message
    });
  }
};

module.exports = {
  getArticles,
  getArticleById,
  createArticle
};

