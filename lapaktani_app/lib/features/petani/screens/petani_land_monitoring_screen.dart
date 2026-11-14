import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_soft_card.dart';
import '../../penyuluh/models/precision_soil_models.dart';

class PetaniLandMonitoringScreen extends StatefulWidget {
  const PetaniLandMonitoringScreen({super.key});

  @override
  State<PetaniLandMonitoringScreen> createState() =>
      _PetaniLandMonitoringScreenState();
}

class _PetaniLandMonitoringScreenState
    extends State<PetaniLandMonitoringScreen> {
  final _formKey = GlobalKey<FormState>();

  SumenepVillagePreset _selectedVillage = SumenepVillagePreset.presets.first;
  SoilTelemetry8In1 _telemetry = SoilTelemetry8In1.sampleOptimal();

  late TextEditingController _latCtrl;
  late TextEditingController _lonCtrl;
  late TextEditingController _desaCtrl;
  late TextEditingController _kecamatanCtrl;
  late TextEditingController _poktanCtrl;
  final TextEditingController _luasCtrl = TextEditingController(text: '0.8 H');

  String _komoditas = 'jagung';
  String _statusLahan = 'milik sendiri';
  String _sumberAir = 'sumur bor';
  String _kondisiAir = 'lancar';
  String _sumberEnergiPompa = 'BBM';
  String _pembajak = 'traktor';

  String _irigasi = 'ya';
  String _listrik = 'tidak';
  String _pompaAir = 'ya';
  String _tadahanHujan = 'tidak';
  String _gagalPanen = 'tidak';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _latCtrl =
        TextEditingController(text: _selectedVillage.latitude.toStringAsFixed(6));
    _lonCtrl =
        TextEditingController(text: _selectedVillage.longitude.toStringAsFixed(6));
    _desaCtrl = TextEditingController(text: _selectedVillage.desa);
    _kecamatanCtrl = TextEditingController(text: _selectedVillage.kecamatan);
    _poktanCtrl = TextEditingController(text: _selectedVillage.poktan);
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _desaCtrl.dispose();
    _kecamatanCtrl.dispose();
    _poktanCtrl.dispose();
    _luasCtrl.dispose();
    super.dispose();
  }

  void _applyVillage(SumenepVillagePreset preset) {
    setState(() {
      _selectedVillage = preset;
      _latCtrl.text = preset.latitude.toStringAsFixed(6);
      _lonCtrl.text = preset.longitude.toStringAsFixed(6);
      _desaCtrl.text = preset.desa;
      _kecamatanCtrl.text = preset.kecamatan;
      _poktanCtrl.text = preset.poktan;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final payload = <String, dynamic>{
        'latitude': double.tryParse(_latCtrl.text.trim()) ?? _selectedVillage.latitude,
        'longitude': double.tryParse(_lonCtrl.text.trim()) ?? _selectedVillage.longitude,
        'nama_desa': _desaCtrl.text.trim(),
        'kecamatan': _kecamatanCtrl.text.trim(),
        'kelompok_tani': _poktanCtrl.text.trim(),
        'komoditas': _komoditas,
        'luas_lahan': _luasCtrl.text.trim(),
        'status_lahan': _statusLahan,
        'sumber_air': _sumberAir,
        'kondisi_air': _kondisiAir,
        'sumber_energi_pompa': _sumberEnergiPompa,
        'pembajak': _pembajak,
        'irigasi': _irigasi,
        'listrik': _listrik,
        'pompa_air': _pompaAir,
        'tadahan_hujan': _tadahanHujan,
        'gagal_panen': _gagalPanen,
        'tipe_penginput': 'petani',
        'submitted_by_role': 'petani',
        ..._telemetry.toMap(),
      };

      final res = await ApiService().saveMonitoringLahan(payload);
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ??
                'Kondisi lahan & data sensor 8-in-1 berhasil dikirim!',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim laporan lahan: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
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
              'Sensor 8-in-1 & Kondisi Lahan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Pemantauan Mandiri Petani Mitra Tani',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 8-in-1 Sensor Dashboard Card
            CustomSoftCard(
              backgroundColor: AppColors.surfaceSoft,
              border: Border.all(color: AppColors.surfaceSoftBorder),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.cpu,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pembacaan Probe 8-in-1',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _telemetry = _telemetry.ph >= 6.0
                                ? SoilTelemetry8In1.sampleCritical()
                                : SoilTelemetry8In1.sampleOptimal();
                          });
                        },
                        child: Text(
                          _telemetry.ph >= 6.0
                              ? 'Simulasi Kritis'
                              : 'Simulasi Subur',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.15,
                    children: [
                      _sensorTile('pH', _telemetry.ph.toStringAsFixed(1)),
                      _sensorTile('Lembab', '${_telemetry.moisture.toInt()}%'),
                      _sensorTile('Suhu', '${_telemetry.temp.toStringAsFixed(1)}°C'),
                      _sensorTile('EC', '${_telemetry.conductivity}'),
                      _sensorTile('Nitrogen', '${_telemetry.nitrogen}'),
                      _sensorTile('Fosfor', '${_telemetry.phosphorus}'),
                      _sensorTile('Kalium', '${_telemetry.potassium}'),
                      _sensorTile('Subur', '${_telemetry.fertility}%'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Section 1: Desa & GPS Sumenep
            CustomSoftCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Wilayah Desa, Poktan & GPS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<SumenepVillagePreset>(
                    initialValue: _selectedVillage,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Desa / Kecamatan Binaan Sumenep',
                      border: OutlineInputBorder(),
                    ),
                    items: SumenepVillagePreset.presets
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text('${p.desa} (Kec. ${p.kecamatan})'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _applyVillage(v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _poktanCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kelompok Tani (Poktan)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _lonCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Section 2: Komoditas, Luas & Alat Olah
            CustomSoftCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2. Komoditas & Kondisi Budidaya',
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
                        child: DropdownButtonFormField<String>(
                          initialValue: _komoditas,
                          decoration: const InputDecoration(
                            labelText: 'Komoditas',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'padi', child: Text('Padi')),
                            DropdownMenuItem(value: 'jagung', child: Text('Jagung')),
                            DropdownMenuItem(value: 'cabai', child: Text('Cabai')),
                            DropdownMenuItem(value: 'tembakau', child: Text('Tembakau')),
                            DropdownMenuItem(value: 'bawang merah', child: Text('Bawang Merah')),
                            DropdownMenuItem(value: 'singkong', child: Text('Singkong')),
                            DropdownMenuItem(value: 'kacang', child: Text('Kacang Tanah')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _komoditas = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _luasCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Luas Lahan',
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
                        child: DropdownButtonFormField<String>(
                          initialValue: _statusLahan,
                          decoration: const InputDecoration(
                            labelText: 'Status Lahan',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'milik sendiri', child: Text('Milik Sendiri')),
                            DropdownMenuItem(value: 'sewa', child: Text('Sewa / Garap')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _statusLahan = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _pembajak,
                          decoration: const InputDecoration(
                            labelText: 'Alat Pembajak',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'traktor', child: Text('Traktor')),
                            DropdownMenuItem(value: 'sapi', child: Text('Sapi')),
                            DropdownMenuItem(value: 'manual', child: Text('Manual / Cangkul')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _pembajak = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Section 3: Pengairan & Infrastruktur Lapangan
            CustomSoftCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3. Pengairan & Infrastruktur Lahan',
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
                        child: DropdownButtonFormField<String>(
                          initialValue: _sumberAir,
                          decoration: const InputDecoration(
                            labelText: 'Sumber Air',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'sumur bor', child: Text('Sumur Bor')),
                            DropdownMenuItem(value: 'irigasi teknis', child: Text('Irigasi Teknis')),
                            DropdownMenuItem(value: 'tadahan hujan', child: Text('Tadahan Hujan')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _sumberAir = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _kondisiAir,
                          decoration: const InputDecoration(
                            labelText: 'Kondisi Air',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'lancar', child: Text('Lancar')),
                            DropdownMenuItem(value: 'tersedia', child: Text('Tersedia')),
                            DropdownMenuItem(value: 'sulit', child: Text('Sulit / Kering')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _kondisiAir = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _sumberEnergiPompa,
                    decoration: const InputDecoration(
                      labelText: 'Sumber Energi Pompa Air',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'BBM', child: Text('BBM (Solar / Bensin)')),
                      DropdownMenuItem(value: 'PLN', child: Text('Listrik PLN')),
                      DropdownMenuItem(value: 'Manual', child: Text('Non-Pompa / Manual')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _sumberEnergiPompa = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  _yesNoToggle('Tersedia Saluran Irigasi?', _irigasi,
                      (val) => setState(() => _irigasi = val)),
                  _yesNoToggle('Tersedia Listrik di Lahan?', _listrik,
                      (val) => setState(() => _listrik = val)),
                  _yesNoToggle('Menggunakan Pompa Air?', _pompaAir,
                      (val) => setState(() => _pompaAir = val)),
                  _yesNoToggle('Lahan Tadah Hujan?', _tadahanHujan,
                      (val) => setState(() => _tadahanHujan = val)),
                  _yesNoToggle('Pernah Mengalami Gagal Panen?', _gagalPanen,
                      (val) => setState(() => _gagalPanen = val)),
                ],
              ),
            ),
            const SizedBox(height: 18),

            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submitForm,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.send, size: 17),
                label: Text(
                  _isSaving
                      ? 'Mengirim ke Server...'
                      : 'Kirim Kondisi Lahan & Sensor 8-in-1',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sensorTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
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

  Widget _yesNoToggle(
    String label,
    String currentValue,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ChoiceChip(
            label: const Text('Ya'),
            selected: currentValue == 'ya',
            onSelected: (_) => onChanged('ya'),
            selectedColor: AppColors.surfaceMint,
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: const Text('Tidak'),
            selected: currentValue == 'tidak',
            onSelected: (_) => onChanged('tidak'),
            selectedColor: AppColors.background,
          ),
        ],
      ),
    );
  }
}
