import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_soft_card.dart';
import '../models/precision_soil_models.dart';

class PplSoilCheckupScreen extends StatefulWidget {
  const PplSoilCheckupScreen({super.key});

  @override
  State<PplSoilCheckupScreen> createState() => _PplSoilCheckupScreenState();
}

class _PplSoilCheckupScreenState extends State<PplSoilCheckupScreen> {
  final ImagePicker _picker = ImagePicker();

  int _currentStep = 0;
  CommodityModel _selectedCommodity = CommodityModel.defaultCommodities.first;
  SumenepVillagePreset _selectedVillage = SumenepVillagePreset.presets.first;

  late TextEditingController _desaCtrl;
  late TextEditingController _kecamatanCtrl;
  late TextEditingController _poktanCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lonCtrl;
  late TextEditingController _harvestCtrl;
  late TextEditingController _recommendationCtrl;

  String _satuanPanen = 'ton';
  SoilTelemetry8In1 _telemetry = SoilTelemetry8In1.sampleOptimal();
  bool _isReadingProbe = false;
  bool _isUploading = false;

  String? _fotoDaunPath;
  String? _fotoPohonPath;
  String? _fotoTanahPath;

  @override
  void initState() {
    super.initState();
    _desaCtrl = TextEditingController(text: _selectedVillage.desa);
    _kecamatanCtrl = TextEditingController(text: _selectedVillage.kecamatan);
    _poktanCtrl = TextEditingController(text: _selectedVillage.poktan);
    _latCtrl =
        TextEditingController(text: _selectedVillage.latitude.toStringAsFixed(6));
    _lonCtrl =
        TextEditingController(text: _selectedVillage.longitude.toStringAsFixed(6));
    _harvestCtrl = TextEditingController(text: '5.2');
    _recommendationCtrl = TextEditingController(
      text: SoilSamplePayload.buildChemicalRemediation(
        _selectedCommodity,
        _telemetry,
      ),
    );
  }

  @override
  void dispose() {
    _desaCtrl.dispose();
    _kecamatanCtrl.dispose();
    _poktanCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _harvestCtrl.dispose();
    _recommendationCtrl.dispose();
    super.dispose();
  }

  void _applyVillagePreset(SumenepVillagePreset preset) {
    setState(() {
      _selectedVillage = preset;
      _desaCtrl.text = preset.desa;
      _kecamatanCtrl.text = preset.kecamatan;
      _poktanCtrl.text = preset.poktan;
      _latCtrl.text = preset.latitude.toStringAsFixed(6);
      _lonCtrl.text = preset.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _simulateProbeRead({required bool critical}) async {
    setState(() => _isReadingProbe = true);
    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    setState(() {
      _isReadingProbe = false;
      _telemetry = critical
          ? SoilTelemetry8In1.sampleCritical()
          : SoilTelemetry8In1.sampleOptimal();
      _recommendationCtrl.text = SoilSamplePayload.buildChemicalRemediation(
        _selectedCommodity,
        _telemetry,
      );
    });
  }

  Future<void> _pickPhoto(String slot, ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
      if (file == null || !mounted) return;
      setState(() {
        if (slot == 'daun') _fotoDaunPath = file.path;
        if (slot == 'pohon') _fotoPohonPath = file.path;
        if (slot == 'tanah') _fotoTanahPath = file.path;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showPhotoSourceSheet(String slot, String label) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dokumentasi $label',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(LucideIcons.camera, color: AppColors.primary),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(slot, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.image, color: AppColors.primary),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(slot, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _syncSampleToCloud() async {
    setState(() => _isUploading = true);
    try {
      final payload = SoilSamplePayload(
        latitude: double.tryParse(_latCtrl.text.trim()) ?? _selectedVillage.latitude,
        longitude: double.tryParse(_lonCtrl.text.trim()) ?? _selectedVillage.longitude,
        namaDesa: _desaCtrl.text.trim().isEmpty ? _selectedVillage.desa : _desaCtrl.text.trim(),
        kecamatan: _kecamatanCtrl.text.trim().isEmpty
            ? _selectedVillage.kecamatan
            : _kecamatanCtrl.text.trim(),
        kelompokTani: _poktanCtrl.text.trim(),
        komoditas: _selectedCommodity.name,
        varietas: _selectedCommodity.variety,
        hasilPanenLalu: double.tryParse(_harvestCtrl.text.trim()) ?? 4.5,
        satuanPanen: _satuanPanen,
        telemetry: _telemetry,
        fotoDaunPath: _fotoDaunPath,
        fotoPohonPath: _fotoPohonPath,
        fotoTanahPath: _fotoTanahPath,
        rekomendasiPpl: _recommendationCtrl.text.trim(),
      );

      final files = <String, String>{};
      if (_fotoDaunPath != null) files['foto_daun'] = _fotoDaunPath!;
      if (_fotoPohonPath != null) files['foto_pohon'] = _fotoPohonPath!;
      if (_fotoTanahPath != null) files['foto_tanah'] = _fotoTanahPath!;

      final result = await ApiService().saveMonitoringLahan(
        payload.toPayloadMap(),
        filePaths: files.isEmpty ? null : files,
      );

      if (!mounted) return;
      setState(() => _isUploading = false);

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sampel Tersinkron',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            result['message']?.toString() ??
                'Sampel 8-in-1 & rekomendasi agronomis PPL berhasil dikirim ke server LapakTani.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal sinkronisasi sampel: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uji Sampel Tanah Presisi (PPL)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Probe 8-in-1 • Sumenep & Wilayah Binaan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStepHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _currentStep == 0
                  ? _buildStep1Commodity()
                  : _currentStep == 1
                      ? _buildStep2ProbeAndGps()
                      : _buildStep3Remediation(),
            ),
          ),
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    const labels = [
      '1. Komoditas',
      '2. Probe & GPS',
      '3. Analisis PPL',
    ];
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: List.generate(labels.length, (idx) {
          final active = idx == _currentStep;
          final completed = idx < _currentStep;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (idx == 2) {
                  _recommendationCtrl.text =
                      SoilSamplePayload.buildChemicalRemediation(
                    _selectedCommodity,
                    _telemetry,
                  );
                }
                setState(() => _currentStep = idx);
              },
              child: Container(
                margin: EdgeInsets.only(right: idx == 2 ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : (completed ? AppColors.surfaceMint : AppColors.background),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active || completed
                        ? AppColors.primary
                        : AppColors.outline,
                  ),
                ),
                child: Text(
                  labels[idx],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? Colors.white
                        : (completed
                            ? AppColors.primary
                            : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1Commodity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomSoftCard(
          backgroundColor: AppColors.surfaceSoft,
          border: Border.all(color: AppColors.surfaceSoftBorder),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(LucideIcons.sprout, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pilih komoditas target agar sistem membandingkan hasil probe 8-in-1 terhadap ambang batas hara optimal.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...CommodityModel.defaultCommodities.map((commodity) {
          final selected = commodity.id == _selectedCommodity.id;
          final th = commodity.threshold;
          return CustomSoftCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            backgroundColor: selected ? AppColors.surfaceSoft : AppColors.surface,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outline,
              width: selected ? 1.6 : 1,
            ),
            onTap: () {
              setState(() {
                _selectedCommodity = commodity;
                _recommendationCtrl.text =
                    SoilSamplePayload.buildChemicalRemediation(
                  commodity,
                  _telemetry,
                );
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceMint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.leaf,
                        size: 18,
                        color: selected ? Colors.white : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            commodity.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${commodity.variety} • ${commodity.regionTag}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(
                        LucideIcons.checkCircle2,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _pill('pH ${th.minPh}–${th.maxPh}'),
                    _pill('Air ${th.minMoisture.toInt()}–${th.maxMoisture.toInt()}%'),
                    _pill('N ${th.minNitrogen}–${th.maxNitrogen}'),
                    _pill('P ${th.minPhosphorus}–${th.maxPhosphorus}'),
                    _pill('K ${th.minPotassium}–${th.maxPotassium}'),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep2ProbeAndGps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 8-in-1 Probe Capture Card
        CustomSoftCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sensor Probe Tanah 8-in-1',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'RS485 / Simulasi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isReadingProbe
                          ? null
                          : () => _simulateProbeRead(critical: false),
                      icon: const Icon(LucideIcons.cpu, size: 15),
                      label: const Text('Sampel Subur'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isReadingProbe
                          ? null
                          : () => _simulateProbeRead(critical: true),
                      icon: const Icon(LucideIcons.alertTriangle, size: 15),
                      label: const Text('Sampel Kritis'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.15,
                children: [
                  _probeTile('pH', _telemetry.ph.toStringAsFixed(1)),
                  _probeTile('Air', '${_telemetry.moisture.toStringAsFixed(1)}%'),
                  _probeTile('Suhu', '${_telemetry.temp.toStringAsFixed(1)}°C'),
                  _probeTile('EC', '${_telemetry.conductivity}'),
                  _probeTile('N', '${_telemetry.nitrogen} mg'),
                  _probeTile('P', '${_telemetry.phosphorus} mg'),
                  _probeTile('K', '${_telemetry.potassium} mg'),
                  _probeTile('Subur', '${_telemetry.fertility}/100'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Kalibrasi Cepat pH (${_telemetry.ph.toStringAsFixed(1)}) & Kelembapan (${_telemetry.moisture.toStringAsFixed(0)}%)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              Slider(
                value: _telemetry.ph.clamp(4.0, 8.5),
                min: 4.0,
                max: 8.5,
                divisions: 45,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  setState(() {
                    _telemetry = SoilTelemetry8In1(
                      temp: _telemetry.temp,
                      moisture: _telemetry.moisture,
                      conductivity: _telemetry.conductivity,
                      ph: double.parse(v.toStringAsFixed(1)),
                      nitrogen: _telemetry.nitrogen,
                      phosphorus: _telemetry.phosphorus,
                      potassium: _telemetry.potassium,
                      fertility: _telemetry.fertility,
                      timestamp: DateTime.now(),
                    );
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Sumenep Location & Harvest Yield Card
        CustomSoftCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lokasi Desa Sumenep, GPS & Produktivitas',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<SumenepVillagePreset>(
                initialValue: _selectedVillage,
                decoration: InputDecoration(
                  labelText: 'Preset Desa & Poktan Binaan Sumenep',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                ),
                items: SumenepVillagePreset.presets
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text('${p.desa} (Kec. ${p.kecamatan})'),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) _applyVillagePreset(val);
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Latitude GPS',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _lonCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Longitude GPS',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _harvestCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Hasil Panen Lalu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _satuanPanen,
                      decoration: const InputDecoration(
                        labelText: 'Satuan',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ton', child: Text('Ton')),
                        DropdownMenuItem(value: 'sak', child: Text('Sak')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _satuanPanen = v);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3 Evidence Photos
        CustomSoftCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dokumentasi 3 Sudut Lahan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _photoBox(
                      label: 'Foto Daun',
                      path: _fotoDaunPath,
                      onTap: () => _showPhotoSourceSheet('daun', 'Daun'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _photoBox(
                      label: 'Foto Pohon',
                      path: _fotoPohonPath,
                      onTap: () => _showPhotoSourceSheet('pohon', 'Pohon'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _photoBox(
                      label: 'Foto Tanah',
                      path: _fotoTanahPath,
                      onTap: () => _showPhotoSourceSheet('tanah', 'Tanah'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Remediation() {
    final th = _selectedCommodity.threshold;
    final checks = [
      (
        'pH Tanah',
        _telemetry.ph.toStringAsFixed(1),
        '${th.minPh}–${th.maxPh}',
        th.evaluate(_telemetry.ph, th.minPh, th.maxPh),
      ),
      (
        'Kelembapan',
        '${_telemetry.moisture.toStringAsFixed(1)}%',
        '${th.minMoisture.toInt()}–${th.maxMoisture.toInt()}%',
        th.evaluate(_telemetry.moisture, th.minMoisture, th.maxMoisture),
      ),
      (
        'Nitrogen (N)',
        '${_telemetry.nitrogen} mg/kg',
        '${th.minNitrogen}–${th.maxNitrogen}',
        th.evaluate(_telemetry.nitrogen, th.minNitrogen, th.maxNitrogen),
      ),
      (
        'Fosfor (P)',
        '${_telemetry.phosphorus} mg/kg',
        '${th.minPhosphorus}–${th.maxPhosphorus}',
        th.evaluate(_telemetry.phosphorus, th.minPhosphorus, th.maxPhosphorus),
      ),
      (
        'Kalium (K)',
        '${_telemetry.potassium} mg/kg',
        '${th.minPotassium}–${th.maxPotassium}',
        th.evaluate(_telemetry.potassium, th.minPotassium, th.maxPotassium),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomSoftCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Justifikasi Kimia vs Ambang ${_selectedCommodity.name}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ...checks.map((row) {
                final (label, currentVal, idealRange, status) = row;
                final isOptimal = status == NutrientStatus.optimal;
                final isDeficit = status == NutrientStatus.deficit;
                final statusColor = isOptimal
                    ? AppColors.primary
                    : (isDeficit ? AppColors.error : AppColors.warning);
                final statusBg = isOptimal
                    ? AppColors.surfaceMint
                    : (isDeficit ? AppColors.errorSoft : AppColors.warningSoft);
                final statusLabel = isOptimal
                    ? 'Optimal'
                    : (isDeficit ? 'Defisit' : 'Berlebih');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '$currentVal (Ideal $idealRange)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        CustomSoftCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rekomendasi Remediasi & Dosis Pupuk PPL',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _recommendationCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isUploading
                      ? null
                      : () => setState(() => _currentStep -= 1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.outline),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Kembali'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isUploading
                    ? null
                    : () {
                        if (_currentStep < 2) {
                          if (_currentStep == 1) {
                            _recommendationCtrl.text =
                                SoilSamplePayload.buildChemicalRemediation(
                              _selectedCommodity,
                              _telemetry,
                            );
                          }
                          setState(() => _currentStep += 1);
                        } else {
                          _syncSampleToCloud();
                        }
                      },
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _currentStep == 2
                            ? LucideIcons.upload
                            : LucideIcons.arrowRight,
                        size: 16,
                      ),
                label: Text(
                  _currentStep == 2
                      ? (_isUploading
                          ? 'Menyinkronkan...'
                          : 'Sinkronkan Sampel ke Cloud')
                      : 'Lanjutkan',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _probeTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoBox({
    required String label,
    required String? path,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: path != null ? AppColors.primary : AppColors.outline,
          ),
        ),
        child: path != null && !kIsWeb
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(path), fit: BoxFit.cover),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        color: Colors.black54,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.camera,
                      size: 20, color: AppColors.primary),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
