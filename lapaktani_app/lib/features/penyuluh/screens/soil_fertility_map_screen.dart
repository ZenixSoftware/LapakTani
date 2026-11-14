import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import 'ppl_soil_checkup_screen.dart';

class SoilPlotModel {
  final String farmId;
  final String farmerId;
  final String farmerName;
  final String poktanName;
  final String villageName;
  final double landAreaHa;
  final String soilType;
  final String commodity;
  final double gpsLatitude;
  final double gpsLongitude;
  final double phLevel;
  final double nitrogenMgKg;
  final double phosphorusMgKg;
  final double potassiumMgKg;
  final double moisturePercentage;
  final String fertilityIndex;
  final double? temperatureCelsius;
  final int? conductivity;
  final int? fertilityScore;
  final String? irigasi;
  final String? pompaAir;
  final String? sumberAir;
  final String? kondisiAir;
  final String? pembajak;
  final String? rekomendasiPpl;

  const SoilPlotModel({
    required this.farmId,
    required this.farmerId,
    required this.farmerName,
    required this.poktanName,
    required this.villageName,
    required this.landAreaHa,
    required this.soilType,
    required this.commodity,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.phLevel,
    required this.nitrogenMgKg,
    required this.phosphorusMgKg,
    required this.potassiumMgKg,
    required this.moisturePercentage,
    required this.fertilityIndex,
    this.temperatureCelsius,
    this.conductivity,
    this.fertilityScore,
    this.irigasi,
    this.pompaAir,
    this.sumberAir,
    this.kondisiAir,
    this.pembajak,
    this.rekomendasiPpl,
  });

  factory SoilPlotModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val, double fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString().replaceAll(',', '.')) ?? fallback;
    }

    int? parseOptInt(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString());
    }

    return SoilPlotModel(
      farmId: (json['farm_id'] ?? json['id'] ?? '').toString(),
      farmerId: (json['farmer_id'] ?? '').toString(),
      farmerName: (json['farmer_name'] ?? 'Petani LapakTani').toString(),
      poktanName: (json['poktan_name'] ?? 'Poktan Tani Makmur').toString(),
      villageName: (json['village_name'] ?? 'Desa Lembang').toString(),
      landAreaHa: parseDouble(json['land_area_ha'] ?? json['land_area'], 1.0),
      soilType: (json['soil_type'] ?? 'Andosol Vulkanik').toString(),
      commodity: (json['commodity'] ?? 'Komoditas Pangan').toString(),
      gpsLatitude: parseDouble(json['gps_latitude'], -6.815200),
      gpsLongitude: parseDouble(json['gps_longitude'], 107.618600),
      phLevel: parseDouble(json['ph_level'], 6.4),
      nitrogenMgKg: parseDouble(json['nitrogen_mg_kg'], 140.0),
      phosphorusMgKg: parseDouble(json['phosphorus_mg_kg'], 35.0),
      potassiumMgKg: parseDouble(json['potassium_mg_kg'], 210.0),
      moisturePercentage: parseDouble(json['moisture_percentage'], 70.0),
      fertilityIndex: (json['fertility_index'] ?? 'Subur').toString(),
      temperatureCelsius: json['temperature_celsius'] != null
          ? parseDouble(json['temperature_celsius'], 29.0)
          : null,
      conductivity: parseOptInt(json['conductivity']),
      fertilityScore: parseOptInt(json['fertility_score']),
      irigasi: json['irigasi']?.toString(),
      pompaAir: json['pompa_air']?.toString(),
      sumberAir: json['sumber_air']?.toString(),
      kondisiAir: json['kondisi_air']?.toString(),
      pembajak: json['pembajak']?.toString(),
      rekomendasiPpl: json['rekomendasi_ppl']?.toString(),
    );
  }

  /// Evaluates pH status category
  String get phCategory {
    if (phLevel >= 6.0 && phLevel <= 7.0) {
      return 'Optimal';
    } else if (phLevel >= 5.0 && phLevel < 6.0) {
      return 'Masam';
    } else if (phLevel < 5.0) {
      return 'Sangat Masam';
    } else {
      return 'Basa';
    }
  }

  /// Evaluates nutrient status for filter matching
  String get haraStatus {
    if (phLevel < 6.0) {
      return 'Masam';
    } else if (nitrogenMgKg < 120 || phosphorusMgKg < 25 || potassiumMgKg < 180) {
      return 'Defisiensi NPK';
    } else {
      return 'Optimal';
    }
  }

  /// Generates agronomic recommendation based on soil parameters
  String get recommendation {
    if (rekomendasiPpl != null && rekomendasiPpl!.trim().isNotEmpty) {
      return rekomendasiPpl!.trim();
    }
    if (phLevel < 5.0) {
      return 'Aplikasi Dolomit 2-3 Ton/Ha & Pengapuran Tanah Intensif';
    } else if (phLevel < 6.0) {
      return 'Aplikasi Dolomit 1.5 - 2 Ton/Ha & Kompos Organik';
    } else if (nitrogenMgKg < 120 && phosphorusMgKg < 25) {
      return 'Pemupukan NPK Berimbang (15-15-15) + Tambahan Urea';
    } else if (phosphorusMgKg < 25) {
      return 'Aplikasi Pupuk Fosfat (SP-36) untuk Perakaran Optimal';
    } else if (potassiumMgKg < 180) {
      return 'Aplikasi Pupuk KCl / Kalium Nitrat untuk Pembungaan';
    } else if (moisturePercentage < 50) {
      return 'Tingkatkan Frekuensi Irigasi Tetes & Mulsa Jerami';
    } else {
      return 'Kondisi Tanah Prima • Pertahankan Pemupukan Berkala';
    }
  }
}

class SoilFertilityMapScreen extends StatefulWidget {
  const SoilFertilityMapScreen({super.key});

  @override
  State<SoilFertilityMapScreen> createState() => _SoilFertilityMapScreenState();
}

class _SoilFertilityMapScreenState extends State<SoilFertilityMapScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;

  String _selectedDesa = 'Semua Desa';
  String _selectedHara = 'Semua';

  final List<String> _desaOptions = [
    'Semua Desa',
    'Mandala',
    'Pakondang',
    'Karangnangka',
    'Pasongsongan',
    'Guluk-Guluk',
    'Talango',
    'Ambunten',
    'Desa Lembang',
    'Desa Cikole',
  ];

  final List<String> _haraOptions = [
    'Semua',
    'Optimal',
    'Masam',
    'Defisiensi NPK',
  ];

  List<SoilPlotModel> _plots = [];

  // Default fallback data if remote endpoint returns empty or offline
  static final List<SoilPlotModel> _fallbackPlots = [
    const SoilPlotModel(
      farmId: 'FARM-001',
      farmerId: 'USR-001',
      farmerName: 'Pak Joko Subagyo',
      poktanName: 'Poktan Tani Makmur Mandiri',
      villageName: 'Desa Lembang',
      landAreaHa: 1.85,
      soilType: 'Andosol Vulkanik Kaya Humus',
      commodity: 'Cabai Merah Keriting',
      gpsLatitude: -6.818450,
      gpsLongitude: 107.617820,
      phLevel: 6.5,
      nitrogenMgKg: 155.0,
      phosphorusMgKg: 42.0,
      potassiumMgKg: 220.0,
      moisturePercentage: 74.0,
      fertilityIndex: 'Sangat Subur',
    ),
    const SoilPlotModel(
      farmId: 'FARM-002',
      farmerId: 'USR-002',
      farmerName: 'Kang Herman Syah',
      poktanName: 'Poktan Giri Mukti Bersatu',
      villageName: 'Desa Cikole',
      landAreaHa: 1.20,
      soilType: 'Latosol Coklat Kering',
      commodity: 'Kentang Granola Super',
      gpsLatitude: -6.786520,
      gpsLongitude: 107.632410,
      phLevel: 5.4,
      nitrogenMgKg: 130.0,
      phosphorusMgKg: 31.0,
      potassiumMgKg: 195.0,
      moisturePercentage: 62.5,
      fertilityIndex: 'Cukup Masam',
    ),
    const SoilPlotModel(
      farmId: 'FARM-003',
      farmerId: 'USR-003',
      farmerName: 'Ibu Enung Sukarsih',
      poktanName: 'Poktan Harapan Jaya Lembang',
      villageName: 'Desa Lembang',
      landAreaHa: 2.10,
      soilType: 'Regosol Vulkanik Pasir',
      commodity: 'Tomat Beef Hibrida',
      gpsLatitude: -6.824100,
      gpsLongitude: 107.621050,
      phLevel: 4.8,
      nitrogenMgKg: 105.0,
      phosphorusMgKg: 20.0,
      potassiumMgKg: 160.0,
      moisturePercentage: 58.0,
      fertilityIndex: 'Sangat Masam & Defisit',
    ),
    const SoilPlotModel(
      farmId: 'FARM-004',
      farmerId: 'USR-004',
      farmerName: 'Pak Dedi Mulyadi',
      poktanName: 'Poktan Sinar Harapan',
      villageName: 'Desa Cikole',
      landAreaHa: 1.45,
      soilType: 'Andosol Pegunungan',
      commodity: 'Brokoli Hijau Segar',
      gpsLatitude: -6.791240,
      gpsLongitude: 107.628900,
      phLevel: 6.2,
      nitrogenMgKg: 95.0,
      phosphorusMgKg: 18.0,
      potassiumMgKg: 170.0,
      moisturePercentage: 69.0,
      fertilityIndex: 'Defisiensi NPK',
    ),
    const SoilPlotModel(
      farmId: 'FARM-005',
      farmerId: 'USR-005',
      farmerName: 'Mang Aep Saepudin',
      poktanName: 'Poktan Tani Makmur Mandiri',
      villageName: 'Desa Lembang',
      landAreaHa: 2.40,
      soilType: 'Andosol Hitam Vulkanik',
      commodity: 'Bawang Daun Prei',
      gpsLatitude: -6.812300,
      gpsLongitude: 107.615400,
      phLevel: 6.8,
      nitrogenMgKg: 160.0,
      phosphorusMgKg: 45.0,
      potassiumMgKg: 235.0,
      moisturePercentage: 78.0,
      fertilityIndex: 'Optimal Prima',
    ),
    const SoilPlotModel(
      farmId: 'SMP-001',
      farmerId: 'USR-SMP-01',
      farmerName: 'Poktan Sumber Lestari (Gapura)',
      poktanName: 'Poktan Sumber Lestari (Gapura)',
      villageName: 'Mandala, Kec. Gapura',
      landAreaHa: 0.70,
      soilType: 'Aluvial Mediteran Sumenep',
      commodity: 'Jagung Hibrida (Bisi 18)',
      gpsLatitude: -6.977160,
      gpsLongitude: 113.804530,
      phLevel: 6.4,
      nitrogenMgKg: 145.0,
      phosphorusMgKg: 32.0,
      potassiumMgKg: 185.0,
      moisturePercentage: 64.5,
      fertilityIndex: 'Sangat Subur',
      temperatureCelsius: 31.0,
      conductivity: 1420,
      fertilityScore: 84,
      irigasi: 'ya',
      pompaAir: 'ya',
      sumberAir: 'sumur bor',
      kondisiAir: 'lancar',
      pembajak: 'traktor',
    ),
    const SoilPlotModel(
      farmId: 'SMP-002',
      farmerId: 'USR-SMP-02',
      farmerName: 'Poktan Anugrah (Rubaru)',
      poktanName: 'Poktan Anugrah (Rubaru)',
      villageName: 'Karangnangka, Kec. Rubaru',
      landAreaHa: 0.60,
      soilType: 'Mediteran Kering Sumenep',
      commodity: 'Cabai Rawit (Ori 212)',
      gpsLatitude: -6.956892,
      gpsLongitude: 113.778940,
      phLevel: 5.1,
      nitrogenMgKg: 42.0,
      phosphorusMgKg: 14.0,
      potassiumMgKg: 72.0,
      moisturePercentage: 11.4,
      fertilityIndex: 'Kritis',
      temperatureCelsius: 32.6,
      conductivity: 290,
      fertilityScore: 16,
      irigasi: 'tidak',
      pompaAir: 'ya',
      sumberAir: 'sumur bor',
      kondisiAir: 'sulit',
      pembajak: 'manual',
      rekomendasiPpl:
          'TITIK KRITIS: Tanah asam (pH 5.1) & kekeringan (11.4%). Berikan Dolomit 1.5 Ton/Ha + mulsa jerami.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSoilMapData();
  }

  Future<void> _loadSoilMapData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final remoteData = await _apiService.getSpatialSoilMap();
      if (!mounted) return;

      if (remoteData.isNotEmpty) {
        final parsed = remoteData.map((e) => SoilPlotModel.fromJson(e)).toList();
        setState(() {
          _plots = parsed;
          _isLoading = false;
        });
      } else {
        // Fallback to rich pre-configured agronomic data
        setState(() {
          _plots = _fallbackPlots;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _plots = _fallbackPlots;
        _isLoading = false;
      });
    }
  }

  List<SoilPlotModel> get _filteredPlots {
    return _plots.where((plot) {
      // Village Filter
      if (_selectedDesa != 'Semua Desa') {
        final desaTarget = _selectedDesa.toLowerCase().replaceAll('desa ', '').trim();
        final plotDesa = plot.villageName.toLowerCase().replaceAll('desa ', '').trim();
        if (!plotDesa.contains(desaTarget)) return false;
      }

      // Hara Status Filter
      if (_selectedHara != 'Semua') {
        if (_selectedHara == 'Optimal') {
          if (plot.haraStatus != 'Optimal') return false;
        } else if (_selectedHara == 'Masam') {
          if (plot.phLevel >= 6.0) return false;
        } else if (_selectedHara == 'Defisiensi NPK') {
          if (plot.nitrogenMgKg >= 120 &&
              plot.phosphorusMgKg >= 25 &&
              plot.potassiumMgKg >= 180) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  double get _totalLuasanHa {
    return _filteredPlots.fold<double>(0.0, (sum, item) => sum + item.landAreaHa);
  }

  double get _productivePercentage {
    if (_filteredPlots.isEmpty) return 0.0;
    final suburCount = _filteredPlots.where((p) => p.phLevel >= 6.0 && p.phLevel <= 7.0).length;
    return (suburCount / _filteredPlots.length) * 100.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text(
          'Peta Kesuburan Tanah Wilayah Binaan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Segarkan Data Telemetri',
            onPressed: _loadSoilMapData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadSoilMapData,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Filter Bar Section
                  SliverToBoxAdapter(
                    child: _buildFilterSection(),
                  ),

                  // Summary Card Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildSummaryCard(),
                    ),
                  ),

                  // Header of list
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(LucideIcons.mapPin, size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Plot Lahan Terpantau (${_filteredPlots.length})',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.surfaceSoftBorder),
                            ),
                            child: Text(
                              'GIS Real-Time IoT',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Spatial Grid Cards
                  if (_filteredPlots.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.layers,
                                size: 48,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak Ada Data Plot Sesuai Filter',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Silakan ubah filter desa binaan atau status hara tanah.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final plot = _filteredPlots[index];
                            return _buildPlotCard(plot);
                          },
                          childCount: _filteredPlots.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final refreshed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const PplSoilCheckupScreen(),
            ),
          );
          if (refreshed == true) {
            _loadSoilMapData();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: Text(
          'Uji Sampel 8-in-1',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Desa Binaan
          Text(
            'Wilayah Desa Binaan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _desaOptions.map((desa) {
                final isSelected = _selectedDesa == desa;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(desa),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedDesa = desa;
                      });
                    },
                    backgroundColor: AppColors.background,
                    selectedColor: AppColors.surfaceMint,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.secondary : AppColors.outline,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Status Hara
          Text(
            'Status Kesuburan / Hara',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _haraOptions.map((hara) {
                final isSelected = _selectedHara == hara;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(hara),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedHara = hara;
                      });
                    },
                    backgroundColor: AppColors.background,
                    selectedColor: AppColors.warningSoft,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.warning : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.accent : AppColors.outline,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.activity, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Agronomi Lapangan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Monitoring Wilayah Binaan PPL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Luasan Lahan
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.maximize2, size: 14, color: AppColors.surfaceSoftBorder),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Luas Terpantau',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.surfaceSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_totalLuasanHa.toStringAsFixed(2)} Ha',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_filteredPlots.length} Plot Petani',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Persentase Lahan Produktif
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.checkCircle, size: 14, color: AppColors.surfaceSoftBorder),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Produktif Subur',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.surfaceSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_productivePercentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'pH 6.0 - 7.0 Optimal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlotCard(SoilPlotModel plot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Plot Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plot.poktanName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Petani: ${plot.farmerName} • ${plot.villageName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildPhIndicatorPill(plot.phLevel),
              ],
            ),
          ),

          // Commodity & Geo Coordinates (Wrap prevents overflow on 360dp screens)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.surfaceSoftBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.sprout, size: 12, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            plot.commodity,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${plot.landAreaHa.toStringAsFixed(2)} Ha',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.crosshair, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${plot.gpsLatitude.toStringAsFixed(4)}, ${plot.gpsLongitude.toStringAsFixed(4)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Soil NPK & Moisture Metrics Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  _buildMetricItem(
                    label: 'Nitrogen (N)',
                    value: '${plot.nitrogenMgKg.toStringAsFixed(0)} mg/kg',
                    isLow: plot.nitrogenMgKg < 120,
                  ),
                  _buildMetricDivider(),
                  _buildMetricItem(
                    label: 'Fosfor (P)',
                    value: '${plot.phosphorusMgKg.toStringAsFixed(0)} mg/kg',
                    isLow: plot.phosphorusMgKg < 25,
                  ),
                  _buildMetricDivider(),
                  _buildMetricItem(
                    label: 'Kalium (K)',
                    value: '${plot.potassiumMgKg.toStringAsFixed(0)} mg/kg',
                    isLow: plot.potassiumMgKg < 180,
                  ),
                  _buildMetricDivider(),
                  _buildMetricItem(
                    label: 'Kelembaban',
                    value: '${plot.moisturePercentage.toStringAsFixed(0)}%',
                    isLow: plot.moisturePercentage < 50,
                  ),
                ],
              ),
            ),
          ),

          if (plot.temperatureCelsius != null ||
              plot.conductivity != null ||
              plot.sumberAir != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (plot.temperatureCelsius != null)
                    _buildMetaPill(
                      'Suhu ${plot.temperatureCelsius!.toStringAsFixed(1)}°C',
                    ),
                  if (plot.conductivity != null)
                    _buildMetaPill('EC ${plot.conductivity} uS/cm'),
                  if (plot.sumberAir != null)
                    _buildMetaPill(
                      'Air: ${plot.sumberAir} (${plot.kondisiAir ?? 'tersedia'})',
                    ),
                  if (plot.irigasi == 'ya') _buildMetaPill('Irigasi Aktif'),
                  if (plot.pompaAir == 'ya') _buildMetaPill('Pompa Air'),
                ],
              ),
            ),

          // PPL Action Recommendation Box
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningSoft.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.lightbulb,
                    size: 15,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rekomendasi Tindakan PPL:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plot.recommendation,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
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

  Widget _buildPhIndicatorPill(double ph) {
    Color bgColor;
    Color textColor;
    Color borderColor;
    String label;

    if (ph >= 6.0 && ph <= 7.0) {
      // Hijau: Optimal
      bgColor = AppColors.surfaceMint;
      textColor = AppColors.primary;
      borderColor = AppColors.surfaceSoftBorder;
      label = 'pH ${ph.toStringAsFixed(1)} • Optimal';
    } else if (ph >= 5.0 && ph < 6.0) {
      // Kuning: Masam
      bgColor = AppColors.warningSoft;
      textColor = AppColors.warning;
      borderColor = AppColors.accent;
      label = 'pH ${ph.toStringAsFixed(1)} • Masam';
    } else {
      // Merah: Sangat Masam (< 5.0)
      bgColor = AppColors.errorSoft;
      textColor = AppColors.error;
      borderColor = AppColors.errorBorder;
      label = 'pH ${ph.toStringAsFixed(1)} • Sangat Masam';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required bool isLow,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isLow ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      height: 24,
      width: 1,
      color: AppColors.outline,
    );
  }

  Widget _buildMetaPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceSoftBorder),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
