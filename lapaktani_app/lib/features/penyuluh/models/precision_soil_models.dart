enum NutrientStatus { optimal, deficit, excess }

class NutrientThreshold {
  final double minPh;
  final double maxPh;
  final double minMoisture;
  final double maxMoisture;
  final int minConductivity;
  final int maxConductivity;
  final int minNitrogen;
  final int maxNitrogen;
  final int minPhosphorus;
  final int maxPhosphorus;
  final int minPotassium;
  final int maxPotassium;

  const NutrientThreshold({
    required this.minPh,
    required this.maxPh,
    required this.minMoisture,
    required this.maxMoisture,
    required this.minConductivity,
    required this.maxConductivity,
    required this.minNitrogen,
    required this.maxNitrogen,
    required this.minPhosphorus,
    required this.maxPhosphorus,
    required this.minPotassium,
    required this.maxPotassium,
  });

  NutrientStatus evaluate(num value, num min, num max) {
    if (value < min) return NutrientStatus.deficit;
    if (value > max) return NutrientStatus.excess;
    return NutrientStatus.optimal;
  }
}

class CommodityModel {
  final String id;
  final String name;
  final String variety;
  final bool isRecommended;
  final int sampleCount;
  final String regionTag;
  final NutrientThreshold threshold;

  const CommodityModel({
    required this.id,
    required this.name,
    required this.variety,
    this.isRecommended = false,
    this.sampleCount = 0,
    this.regionTag = 'Sumenep & Lembang',
    required this.threshold,
  });

  static const List<CommodityModel> defaultCommodities = [
    CommodityModel(
      id: 'padi',
      name: 'Padi',
      variety: 'Inpari 32 / Ciherang',
      isRecommended: true,
      sampleCount: 42,
      regionTag: 'Sumenep',
      threshold: NutrientThreshold(
        minPh: 6.0,
        maxPh: 6.8,
        minMoisture: 60.0,
        maxMoisture: 80.0,
        minConductivity: 1000,
        maxConductivity: 2000,
        minNitrogen: 100,
        maxNitrogen: 150,
        minPhosphorus: 25,
        maxPhosphorus: 40,
        minPotassium: 150,
        maxPotassium: 220,
      ),
    ),
    CommodityModel(
      id: 'jagung',
      name: 'Jagung Hibrida',
      variety: 'Bisi 18 / Lamuru Sumenep',
      isRecommended: true,
      sampleCount: 68,
      regionTag: 'Sumenep',
      threshold: NutrientThreshold(
        minPh: 5.6,
        maxPh: 7.2,
        minMoisture: 55.0,
        maxMoisture: 75.0,
        minConductivity: 1100,
        maxConductivity: 2100,
        minNitrogen: 130,
        maxNitrogen: 190,
        minPhosphorus: 25,
        maxPhosphorus: 45,
        minPotassium: 140,
        maxPotassium: 210,
      ),
    ),
    CommodityModel(
      id: 'cabai',
      name: 'Cabai Rawit',
      variety: 'Ori 212 / Keriting Lembang',
      sampleCount: 34,
      regionTag: 'Sumenep & Lembang',
      threshold: NutrientThreshold(
        minPh: 5.8,
        maxPh: 6.8,
        minMoisture: 50.0,
        maxMoisture: 70.0,
        minConductivity: 1200,
        maxConductivity: 2200,
        minNitrogen: 120,
        maxNitrogen: 180,
        minPhosphorus: 30,
        maxPhosphorus: 50,
        minPotassium: 160,
        maxPotassium: 240,
      ),
    ),
    CommodityModel(
      id: 'tembakau',
      name: 'Tembakau Sumenep',
      variety: 'Prancak-95 Khas Madura',
      isRecommended: true,
      sampleCount: 29,
      regionTag: 'Sumenep',
      threshold: NutrientThreshold(
        minPh: 5.8,
        maxPh: 6.8,
        minMoisture: 45.0,
        maxMoisture: 65.0,
        minConductivity: 1000,
        maxConductivity: 1900,
        minNitrogen: 90,
        maxNitrogen: 140,
        minPhosphorus: 22,
        maxPhosphorus: 40,
        minPotassium: 170,
        maxPotassium: 240,
      ),
    ),
    CommodityModel(
      id: 'bawang',
      name: 'Bawang Merah',
      variety: 'Batu Ijo / Rubaru Sumenep',
      sampleCount: 30,
      regionTag: 'Sumenep',
      threshold: NutrientThreshold(
        minPh: 5.8,
        maxPh: 6.8,
        minMoisture: 55.0,
        maxMoisture: 70.0,
        minConductivity: 1000,
        maxConductivity: 2000,
        minNitrogen: 90,
        maxNitrogen: 150,
        minPhosphorus: 25,
        maxPhosphorus: 45,
        minPotassium: 150,
        maxPotassium: 220,
      ),
    ),
    CommodityModel(
      id: 'tomat',
      name: 'Tomat Dataran Tinggi',
      variety: 'Servo F1',
      sampleCount: 15,
      regionTag: 'Lembang',
      threshold: NutrientThreshold(
        minPh: 6.0,
        maxPh: 6.8,
        minMoisture: 60.0,
        maxMoisture: 80.0,
        minConductivity: 1400,
        maxConductivity: 2500,
        minNitrogen: 110,
        maxNitrogen: 170,
        minPhosphorus: 30,
        maxPhosphorus: 55,
        minPotassium: 180,
        maxPotassium: 260,
      ),
    ),
    CommodityModel(
      id: 'singkong',
      name: 'Singkong',
      variety: 'Manggu Lokal',
      sampleCount: 12,
      regionTag: 'Sumenep',
      threshold: NutrientThreshold(
        minPh: 5.5,
        maxPh: 7.0,
        minMoisture: 45.0,
        maxMoisture: 65.0,
        minConductivity: 800,
        maxConductivity: 1800,
        minNitrogen: 80,
        maxNitrogen: 140,
        minPhosphorus: 20,
        maxPhosphorus: 35,
        minPotassium: 130,
        maxPotassium: 200,
      ),
    ),
    CommodityModel(
      id: 'kacang',
      name: 'Kacang Tanah',
      variety: 'Tuban Lokal',
      sampleCount: 9,
      regionTag: 'Sumenep',
      threshold: NutrientThreshold(
        minPh: 6.0,
        maxPh: 6.5,
        minMoisture: 50.0,
        maxMoisture: 70.0,
        minConductivity: 900,
        maxConductivity: 1900,
        minNitrogen: 70,
        maxNitrogen: 120,
        minPhosphorus: 20,
        maxPhosphorus: 40,
        minPotassium: 120,
        maxPotassium: 190,
      ),
    ),
  ];
}

class SoilTelemetry8In1 {
  final double temp;
  final double moisture;
  final int conductivity;
  final double ph;
  final int nitrogen;
  final int phosphorus;
  final int potassium;
  final int fertility;
  final DateTime timestamp;

  const SoilTelemetry8In1({
    required this.temp,
    required this.moisture,
    required this.conductivity,
    required this.ph,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.fertility,
    required this.timestamp,
  });

  factory SoilTelemetry8In1.sampleOptimal() => SoilTelemetry8In1(
        temp: 30.4,
        moisture: 64.5,
        conductivity: 1420,
        ph: 6.4,
        nitrogen: 138,
        phosphorus: 34,
        potassium: 185,
        fertility: 84,
        timestamp: DateTime.now(),
      );

  factory SoilTelemetry8In1.sampleCritical() => SoilTelemetry8In1(
        temp: 32.8,
        moisture: 12.2,
        conductivity: 310,
        ph: 5.1,
        nitrogen: 45,
        phosphorus: 14,
        potassium: 76,
        fertility: 18,
        timestamp: DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'temp': temp,
        'moisture': moisture,
        'conductivity': conductivity,
        'ph': ph,
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'fertility': fertility,
      };
}

class SumenepVillagePreset {
  final String desa;
  final String kecamatan;
  final String poktan;
  final double latitude;
  final double longitude;

  const SumenepVillagePreset({
    required this.desa,
    required this.kecamatan,
    required this.poktan,
    required this.latitude,
    required this.longitude,
  });

  static const List<SumenepVillagePreset> presets = [
    SumenepVillagePreset(
      desa: 'Mandala',
      kecamatan: 'Gapura',
      poktan: 'Poktan Sumber Lestari (Gapura)',
      latitude: -6.9771599,
      longitude: 113.8045302,
    ),
    SumenepVillagePreset(
      desa: 'Pakondang',
      kecamatan: 'Rubaru',
      poktan: 'Poktan Anugrah (Rubaru)',
      latitude: -6.9754773,
      longitude: 113.8007316,
    ),
    SumenepVillagePreset(
      desa: 'Karangnangka',
      kecamatan: 'Rubaru',
      poktan: 'Poktan Anugrah (Rubaru)',
      latitude: -6.9568917,
      longitude: 113.7789397,
    ),
    SumenepVillagePreset(
      desa: 'Tambak Sari',
      kecamatan: 'Rubaru',
      poktan: 'Poktan Anugrah (Rubaru)',
      latitude: -6.9688906,
      longitude: 113.7921022,
    ),
    SumenepVillagePreset(
      desa: 'Pasongsongan',
      kecamatan: 'Pasongsongan',
      poktan: 'Poktan Sekar Sari (Pasongsongan)',
      latitude: -6.9062410,
      longitude: 113.6798500,
    ),
    SumenepVillagePreset(
      desa: 'Guluk-Guluk',
      kecamatan: 'Guluk-Guluk',
      poktan: 'Poktan Bukit Johar (Guluk-Guluk)',
      latitude: -7.0641800,
      longitude: 113.6943200,
    ),
    SumenepVillagePreset(
      desa: 'Talango',
      kecamatan: 'Talango',
      poktan: 'Poktan Al Hikmah (Talango)',
      latitude: -7.0789100,
      longitude: 113.9245100,
    ),
    SumenepVillagePreset(
      desa: 'Ambunten',
      kecamatan: 'Ambunten',
      poktan: 'Poktan Sumber Patemon (Ambunten)',
      latitude: -6.8894200,
      longitude: 113.7582400,
    ),
    SumenepVillagePreset(
      desa: 'Dungkek',
      kecamatan: 'Dungkek',
      poktan: 'Poktan Harapan Dungkek (Dungkek)',
      latitude: -6.9942000,
      longitude: 114.0725000,
    ),
  ];
}

class SoilSamplePayload {
  final double latitude;
  final double longitude;
  final String namaDesa;
  final String kecamatan;
  final String kelompokTani;
  final String komoditas;
  final String varietas;
  final double hasilPanenLalu;
  final String satuanPanen; // 'ton' or 'sak'
  final SoilTelemetry8In1 telemetry;
  final String? fotoDaunPath;
  final String? fotoPohonPath;
  final String? fotoTanahPath;
  final String rekomendasiPpl;

  const SoilSamplePayload({
    required this.latitude,
    required this.longitude,
    required this.namaDesa,
    required this.kecamatan,
    required this.kelompokTani,
    required this.komoditas,
    required this.varietas,
    required this.hasilPanenLalu,
    required this.satuanPanen,
    required this.telemetry,
    this.fotoDaunPath,
    this.fotoPohonPath,
    this.fotoTanahPath,
    required this.rekomendasiPpl,
  });

  Map<String, dynamic> toPayloadMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'nama_desa': namaDesa,
        'kecamatan': kecamatan,
        'kelompok_tani': kelompokTani,
        'komoditas': komoditas,
        'varietas': varietas,
        'hasil_panen_lalu': hasilPanenLalu,
        'satuan_panen': satuanPanen,
        'temp': telemetry.temp,
        'moisture': telemetry.moisture,
        'conductivity': telemetry.conductivity,
        'ph': telemetry.ph,
        'nitrogen': telemetry.nitrogen,
        'phosphorus': telemetry.phosphorus,
        'potassium': telemetry.potassium,
        'fertility': telemetry.fertility,
        'tipe_penginput': 'penyuluh',
        'rekomendasi_ppl': rekomendasiPpl,
      };

  static String buildChemicalRemediation(
    CommodityModel commodity,
    SoilTelemetry8In1 t,
  ) {
    final th = commodity.threshold;
    final notes = <String>[];

    if (t.ph < th.minPh) {
      notes.add(
        'Tanah masam (pH ${t.ph.toStringAsFixed(1)} < ${th.minPh}): aplikasikan Kapur Dolomit 1.5–2 Ton/Ha 14 hari pra-tanam.',
      );
    } else if (t.ph > th.maxPh) {
      notes.add(
        'Tanah basa (pH ${t.ph.toStringAsFixed(1)} > ${th.maxPh}): berikan Belerang (Sulfur) & bahan organik matang.',
      );
    }

    if (t.nitrogen < th.minNitrogen) {
      notes.add(
        'Defisit Nitrogen (${t.nitrogen} mg/kg): berikan Urea 100–150 kg/Ha atau ZA terbagi pada HST ke-14 & ke-30.',
      );
    }
    if (t.phosphorus < th.minPhosphorus) {
      notes.add(
        'Defisit Fosfor (${t.phosphorus} mg/kg): tambahkan SP-36 100 kg/Ha pada olah tanah dasar untuk perakaran.',
      );
    }
    if (t.potassium < th.minPotassium) {
      notes.add(
        'Defisit Kalium (${t.potassium} mg/kg): aplikasikan KCl 100–125 kg/Ha untuk pengisian bobot & ketahanan rebah.',
      );
    }
    if (t.moisture < th.minMoisture) {
      notes.add(
        'Kelembapan rendah (${t.moisture.toStringAsFixed(1)}%): aktifkan pompa sumur bor & gunakan mulsa jerami untuk retensi air.',
      );
    }

    if (notes.isEmpty) {
      return 'Seluruh parameter pH, kelembapan, dan hara NPK optimal untuk ${commodity.name} (${commodity.variety}). Pertahankan pemupukan berimbang.';
    }
    return notes.join(' ');
  }
}
