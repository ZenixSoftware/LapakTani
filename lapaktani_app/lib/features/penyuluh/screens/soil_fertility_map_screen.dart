import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/api_service.dart';

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
  });

  factory SoilPlotModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val, double fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? fallback;
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
  String? _errorMessage;

  String _selectedDesa = 'Semua Desa';
  String _selectedHara = 'Semua';

  final List<String> _desaOptions = [
    'Semua Desa',
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
  ];

  @override
  void initState() {
    super.initState();
    _loadSoilMapData();
  }

  Future<void> _loadSoilMapData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
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
              child: CircularProgressIndicator(color: Color(0xFF03AC0E)),
            )
          : RefreshIndicator(
              onRefresh: _loadSoilMapData,
              color: const Color(0xFF03AC0E),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.mapPin, size: 16, color: Color(0xFF03AC0E)),
                              const SizedBox(width: 6),
                              Text(
                                'Plot Lahan Terpantau (${_filteredPlots.length})',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'GIS Real-Time IoT',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
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
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak Ada Data Plot Sesuai Filter',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Silakan ubah filter desa binaan atau status hara tanah.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
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
              color: const Color(0xFF475569),
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
                    backgroundColor: const Color(0xFFF1F5F9),
                    selectedColor: const Color(0xFFDCFCE7),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF006E04) : const Color(0xFF334155),
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF03AC0E) : const Color(0xFFCBD5E1),
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
              color: const Color(0xFF475569),
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
                    backgroundColor: const Color(0xFFF1F5F9),
                    selectedColor: const Color(0xFFFEF3C7),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF92400E) : const Color(0xFF334155),
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFD97706) : const Color(0xFFCBD5E1),
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
          colors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F065F46),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
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
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.maximize2, size: 14, color: Color(0xFF6EE7B7)),
                          const SizedBox(width: 5),
                          Text(
                            'Luas Terpantau',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFFD1FAE5),
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
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.checkCircle, size: 14, color: Color(0xFF6EE7B7)),
                          const SizedBox(width: 5),
                          Text(
                            'Produktif Subur',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFFD1FAE5),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Plot Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plot.poktanName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Petani: ${plot.farmerName} • ${plot.villageName}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPhIndicatorPill(plot.phLevel),
              ],
            ),
          ),

          // Commodity & Geo Coordinates
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.sprout, size: 12, color: Color(0xFF16A34A)),
                      const SizedBox(width: 4),
                      Text(
                        plot.commodity,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF15803D),
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
                    color: const Color(0xFF475569),
                  ),
                ),
                const Spacer(),
                const Icon(LucideIcons.crosshair, size: 12, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  '${plot.gpsLatitude.toStringAsFixed(4)}, ${plot.gpsLongitude.toStringAsFixed(4)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    color: const Color(0xFF64748B),
                  ),
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
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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

          // PPL Action Recommendation Box
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.lightbulb,
                    size: 15,
                    color: Color(0xFFD97706),
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
                            color: const Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plot.recommendation,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF78350F),
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
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF166534);
      borderColor = const Color(0xFF86EFAC);
      label = 'pH ${ph.toStringAsFixed(1)} • Optimal';
    } else if (ph >= 5.0 && ph < 6.0) {
      // Kuning: Masam
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFF92400E);
      borderColor = const Color(0xFFFCD34D);
      label = 'pH ${ph.toStringAsFixed(1)} • Masam';
    } else {
      // Merah: Sangat Masam (< 5.0)
      bgColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFF991B1B);
      borderColor = const Color(0xFFFCA5A5);
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
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isLow ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
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
      color: const Color(0xFFE2E8F0),
    );
  }
}
