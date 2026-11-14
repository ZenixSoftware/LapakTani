import React, { useEffect, useMemo, useState } from 'react';
import {
  fetchMonitoringLahan,
  fetchMonitoringSummary,
  resolveImageUrl,
  submitPplPlotRecommendation,
  type LandPlotRecord,
  type MonitoringSummaryResponse,
} from '../services/api';

interface SumenepLandMonitoringProps {
  onShowToast?: (message: string, type?: 'success' | 'error') => void;
}

const FILTER_CHIPS: { key: string; label: string; icon: string }[] = [
  { key: 'all', label: 'Semua Titik', icon: 'layers' },
  { key: 'padi', label: 'Padi', icon: 'grass' },
  { key: 'jagung', label: 'Jagung', icon: 'agriculture' },
  { key: 'cabai', label: 'Cabai', icon: 'local_fire_department' },
  { key: 'tembakau', label: 'Tembakau', icon: 'eco' },
  { key: 'traktor', label: 'Traktor', icon: 'precision_manufacturing' },
  { key: 'sapi', label: 'Sapi', icon: 'pets' },
  { key: 'poktan', label: 'Poktan', icon: 'groups' },
  { key: 'irigasi', label: 'Irigasi', icon: 'water' },
  { key: 'pompa', label: 'Pompa Air', icon: 'cyclone' },
  { key: 'air_sulit', label: 'Air Sulit', icon: 'water_damage' },
  { key: 'kritis', label: 'Titik Kritis', icon: 'warning' },
];

const isPlotCritical = (plot: LandPlotRecord): boolean => {
  const ph = Number(plot.ph ?? 6.5);
  const moisture = Number(plot.moisture ?? 50);
  const fertility = Number(plot.fertility ?? 60);
  return ph < 5.5 || ph > 7.5 || moisture < 15 || fertility < 20;
};

export const SumenepLandMonitoring: React.FC<SumenepLandMonitoringProps> = ({ onShowToast }) => {
  const [plots, setPlots] = useState<LandPlotRecord[]>([]);
  const [summary, setSummary] = useState<MonitoringSummaryResponse | null>(null);
  const [activeFilter, setActiveFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedPlotId, setSelectedPlotId] = useState<number | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  const [recommendationText, setRecommendationText] = useState<string>('');
  const [verificationStatus, setVerificationStatus] = useState<'verified' | 'needs_action' | 'pending'>('verified');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  const loadData = async (filterKey = activeFilter) => {
    setIsLoading(true);
    setLoadError(null);
    try {
      const [lahanRows, summaryData] = await Promise.all([
        fetchMonitoringLahan(filterKey),
        fetchMonitoringSummary(),
      ]);
      setPlots(lahanRows);
      setSummary(summaryData);
      if (lahanRows.length > 0) {
        const stillExists = lahanRows.some((p) => p.id === selectedPlotId);
        const first = stillExists
          ? lahanRows.find((p) => p.id === selectedPlotId) || lahanRows[0]
          : lahanRows[0];
        setSelectedPlotId(first.id);
        setRecommendationText(first.rekomendasi_ppl || '');
        const st = first.status_verifikasi_ppl;
        setVerificationStatus(
          st === 'needs_action' || st === 'pending' || st === 'verified' ? st : 'verified'
        );
      } else {
        setSelectedPlotId(null);
      }
    } catch (err) {
      setLoadError(err instanceof Error ? err.message : 'Gagal memuat data monitoring Sumenep');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    void loadData(activeFilter);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeFilter]);

  const filteredPlots = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    if (!q) return plots;
    return plots.filter((p) =>
      [p.nama_desa, p.kecamatan, p.komoditas, p.varietas, p.kelompok_tani, p.sumber_air]
        .filter(Boolean)
        .some((v) => String(v).toLowerCase().includes(q))
    );
  }, [plots, searchQuery]);

  const selectedPlot = useMemo(
    () => filteredPlots.find((p) => p.id === selectedPlotId) || filteredPlots[0] || null,
    [filteredPlots, selectedPlotId]
  );

  const handleSelectPlot = (plot: LandPlotRecord) => {
    setSelectedPlotId(plot.id);
    setRecommendationText(plot.rekomendasi_ppl || '');
    const st = plot.status_verifikasi_ppl;
    setVerificationStatus(
      st === 'needs_action' || st === 'pending' || st === 'verified' ? st : 'verified'
    );
  };

  const handleSubmitRecommendation = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedPlot) return;
    setIsSubmitting(true);
    try {
      const updated = await submitPplPlotRecommendation(
        selectedPlot.id,
        recommendationText.trim(),
        verificationStatus
      );
      setPlots((prev) => prev.map((p) => (p.id === updated.id ? updated : p)));
      onShowToast?.(
        `Rekomendasi agronomis untuk ${updated.nama_desa} berhasil disimpan!`,
        'success'
      );
    } catch (err) {
      onShowToast?.(
        err instanceof Error ? err.message : 'Gagal menyimpan rekomendasi PPL',
        'error'
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  // Compute normalized plot positions inside the geospatial preview canvas
  const mapBounds = useMemo(() => {
    const coords = filteredPlots
      .map((p) => ({ lat: Number(p.latitude), lon: Number(p.longitude) }))
      .filter((c) => Number.isFinite(c.lat) && Number.isFinite(c.lon));
    if (coords.length === 0) {
      return { minLat: -7.1, maxLat: -6.88, minLon: 113.65, maxLon: 113.95 };
    }
    const lats = coords.map((c) => c.lat);
    const lons = coords.map((c) => c.lon);
    return {
      minLat: Math.min(...lats) - 0.015,
      maxLat: Math.max(...lats) + 0.015,
      minLon: Math.min(...lons) - 0.015,
      maxLon: Math.max(...lons) + 0.015,
    };
  }, [filteredPlots]);

  const stats = summary?.ringkasan_umum;

  return (
    <div className="space-y-6">
      {/* Header Banner */}
      <section className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-[#0b3b28] via-[#114b35] to-[#134e38] text-white p-6 lg:p-7 shadow-lg shadow-emerald-950/20">
        <div className="absolute -right-10 -top-10 w-56 h-56 rounded-full bg-emerald-400/10 blur-2xl pointer-events-none"></div>
        <div className="relative z-10 flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="space-y-2 max-w-2xl">
            <div className="flex flex-wrap items-center gap-2">
              <span className="px-2.5 py-1 rounded-lg bg-primary/90 text-white font-extrabold text-[11px] uppercase tracking-wide">
                Pertanian Presisi Sumenep
              </span>
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 text-emerald-100 text-[12px] font-semibold border border-white/15">
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
                Probe Tanah 8-in-1 + Geofencing GPS
              </span>
            </div>
            <h1 className="text-2xl lg:text-3xl font-extrabold tracking-tight text-white">
              Peta &amp; Monitoring Lahan Kabupaten Sumenep
            </h1>
            <p className="text-emerald-100/85 text-[13px] lg:text-[14px] leading-relaxed">
              Pantau parameter NPK, pH, EC, kelembapan, infrastruktur irigasi-pompa, serta berikan intervensi agronomis PPL pada titik lahan kritis.
            </p>
          </div>
          <button
            onClick={() => void loadData(activeFilter)}
            disabled={isLoading}
            className="self-start lg:self-center px-4 py-2.5 rounded-xl bg-white/10 hover:bg-white/20 text-white border border-white/20 font-bold text-[13px] flex items-center gap-2 transition-all active:scale-95 disabled:opacity-50"
          >
            <span className="material-symbols-outlined text-[18px]">refresh</span>
            Sinkronkan Data Lahan
          </button>
        </div>
      </section>

      {/* KPI Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <div className="bg-surface-white rounded-2xl border border-gray-100 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-[12px] font-bold text-gray-500 uppercase tracking-wide">Total Titik Pantau</span>
            <span className="material-symbols-outlined text-forest-emerald bg-emerald-50 p-1.5 rounded-lg text-[20px]">pin_drop</span>
          </div>
          <p className="text-2xl font-extrabold text-gray-900 mt-2">{stats?.total_titik ?? plots.length}</p>
          <p className="text-[12px] text-gray-500 mt-1">
            {summary?.distribusi_komoditas?.length || 0} jenis komoditas terdata
          </p>
        </div>

        <div className="bg-surface-white rounded-2xl border border-gray-100 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-[12px] font-bold text-gray-500 uppercase tracking-wide">Rata-rata Kesuburan &amp; pH</span>
            <span className="material-symbols-outlined text-emerald-600 bg-emerald-50 p-1.5 rounded-lg text-[20px]">science</span>
          </div>
          <p className="text-2xl font-extrabold text-gray-900 mt-2">
            {stats?.avg_fertility ?? 0} <span className="text-sm font-bold text-emerald-700">· pH {stats?.avg_ph ?? '—'}</span>
          </p>
          <p className="text-[12px] text-gray-500 mt-1">
            Kelembapan rata-rata {stats?.avg_moisture ?? 0}% · {stats?.avg_temp ?? 0}°C
          </p>
        </div>

        <div className="bg-surface-white rounded-2xl border border-gray-100 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-[12px] font-bold text-gray-500 uppercase tracking-wide">Irigasi &amp; Pompa Air</span>
            <span className="material-symbols-outlined text-blue-600 bg-blue-50 p-1.5 rounded-lg text-[20px]">water_drop</span>
          </div>
          <p className="text-2xl font-extrabold text-gray-900 mt-2">
            {stats?.total_pompa_air ?? 0} Pompa
            <span className="text-sm font-bold text-blue-700"> · {stats?.total_irigasi ?? 0} Irigasi</span>
          </p>
          <p className="text-[12px] text-gray-500 mt-1">Infrastruktur pengairan sumur bor &amp; irigasi teknis</p>
        </div>

        <div className="bg-surface-white rounded-2xl border border-rose-100 p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-[12px] font-bold text-rose-600 uppercase tracking-wide">Titik Kritis PPL</span>
            <span className="material-symbols-outlined text-rose-600 bg-rose-50 p-1.5 rounded-lg text-[20px]">warning</span>
          </div>
          <p className="text-2xl font-extrabold text-rose-700 mt-2">{stats?.total_titik_kritis ?? 0} Lahan</p>
          <p className="text-[12px] text-rose-600/80 mt-1">pH ekstrem / kadar air &lt; 15% / kesuburan &lt; 20</p>
        </div>
      </div>

      {/* Category Filter Chips + Search Bar */}
      <div className="bg-surface-white rounded-2xl border border-gray-100 p-4 shadow-sm space-y-3">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
          <div className="relative flex-1 max-w-md">
            <span className="material-symbols-outlined text-gray-400 text-[18px] absolute left-3 top-1/2 -translate-y-1/2">search</span>
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Cari desa (Mandala, Pakondang, Karangnangka...), Poktan, atau komoditas..."
              className="w-full pl-9 pr-4 py-2 text-[13px] bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-forest-emerald/30 focus:border-forest-emerald"
            />
          </div>
          {summary?.distribusi_komoditas && summary.distribusi_komoditas.length > 0 && (
            <div className="flex flex-wrap items-center gap-1.5">
              {summary.distribusi_komoditas.slice(0, 5).map((item) => (
                <span
                  key={item.komoditas}
                  className="px-2.5 py-1 rounded-lg bg-emerald-50 border border-emerald-100 text-[11px] font-bold text-emerald-800 capitalize"
                >
                  {item.komoditas}: {item.jumlah_titik}
                </span>
              ))}
            </div>
          )}
        </div>

        <div className="flex flex-wrap gap-2">
          {FILTER_CHIPS.map((chip) => {
            const active = activeFilter === chip.key;
            return (
              <button
                key={chip.key}
                onClick={() => setActiveFilter(chip.key)}
                className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-[12px] font-bold transition-all ${
                  active
                    ? 'bg-forest-emerald text-white shadow-sm'
                    : 'bg-gray-50 text-gray-600 border border-gray-200 hover:bg-emerald-50 hover:text-emerald-800'
                }`}
              >
                <span className="material-symbols-outlined text-[15px]">{chip.icon}</span>
                {chip.label}
              </button>
            );
          })}
        </div>
      </div>

      {loadError && (
        <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-[13px] font-semibold">
          {loadError}
        </div>
      )}

      {/* Main Split Workspace */}
      <div className="grid grid-cols-1 xl:grid-cols-12 gap-6 items-start">
        {/* Left/Center: Geospatial Coordinate Preview + Plot List */}
        <div className="xl:col-span-7 space-y-4">
          {/* Interactive Sumenep Geospatial Canvas */}
          <div className="bg-surface-white rounded-2xl border border-gray-100 p-4 shadow-sm">
            <div className="flex items-center justify-between mb-3">
              <div>
                <h2 className="text-[15px] font-extrabold text-gray-900">Sebaran Koordinat Lahan Sumenep</h2>
                <p className="text-[12px] text-gray-500">Klik marker untuk menginspeksi profil 8-in-1 &amp; rekomendasi PPL</p>
              </div>
              <div className="flex items-center gap-3 text-[11px] font-bold">
                <span className="inline-flex items-center gap-1 text-emerald-700">
                  <span className="w-2.5 h-2.5 rounded-full bg-emerald-500"></span> Optimal
                </span>
                <span className="inline-flex items-center gap-1 text-amber-700">
                  <span className="w-2.5 h-2.5 rounded-full bg-amber-500"></span> Sedang
                </span>
                <span className="inline-flex items-center gap-1 text-rose-700">
                  <span className="w-2.5 h-2.5 rounded-full bg-rose-500"></span> Kritis
                </span>
              </div>
            </div>

            <div className="relative h-64 rounded-xl bg-gradient-to-br from-emerald-950 via-[#0e3f2b] to-[#135339] overflow-hidden border border-emerald-900/40">
              {/* Subtle topographic grid */}
              <div
                className="absolute inset-0 opacity-20"
                style={{
                  backgroundImage:
                    'linear-gradient(to right, rgba(255,255,255,0.18) 1px, transparent 1px), linear-gradient(to bottom, rgba(255,255,255,0.18) 1px, transparent 1px)',
                  backgroundSize: '36px 36px',
                }}
              />
              <span className="absolute top-3 left-3 px-2.5 py-1 rounded-lg bg-black/30 text-emerald-100 text-[11px] font-bold backdrop-blur-sm">
                Kab. Sumenep (-6.88°.. -7.08° LS, 113.67°.. 113.93° BT)
              </span>

              {filteredPlots.map((plot) => {
                const lat = Number(plot.latitude);
                const lon = Number(plot.longitude);
                const lonSpan = Math.max(mapBounds.maxLon - mapBounds.minLon, 0.01);
                const latSpan = Math.max(mapBounds.maxLat - mapBounds.minLat, 0.01);
                const xPercent = Math.min(92, Math.max(8, ((lon - mapBounds.minLon) / lonSpan) * 84 + 8));
                const yPercent = Math.min(88, Math.max(16, ((mapBounds.maxLat - lat) / latSpan) * 72 + 14));
                const critical = isPlotCritical(plot);
                const isSelected = selectedPlot?.id === plot.id;
                const dotColor = critical
                  ? 'bg-rose-500 ring-rose-300'
                  : Number(plot.fertility) >= 60
                    ? 'bg-emerald-400 ring-emerald-200'
                    : 'bg-amber-400 ring-amber-200';

                return (
                  <button
                    key={plot.id}
                    type="button"
                    onClick={() => handleSelectPlot(plot)}
                    style={{ left: `${xPercent}%`, top: `${yPercent}%` }}
                    className={`absolute -translate-x-1/2 -translate-y-1/2 group flex flex-col items-center transition-transform ${
                      isSelected ? 'scale-115 z-20' : 'hover:scale-110 z-10'
                    }`}
                  >
                    <span
                      className={`w-4 h-4 rounded-full ${dotColor} ${
                        isSelected ? 'ring-4 shadow-lg' : 'ring-2'
                      }`}
                    />
                    <span
                      className={`mt-1 px-2 py-0.5 rounded-md text-[10px] font-bold whitespace-nowrap shadow ${
                        isSelected
                          ? 'bg-white text-gray-900'
                          : 'bg-black/55 text-white opacity-85 group-hover:opacity-100'
                      }`}
                    >
                      {plot.nama_desa} ({plot.komoditas})
                    </span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Plot List Cards */}
          <div className="bg-surface-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
            <div className="px-4 py-3 border-b border-gray-100 flex items-center justify-between">
              <h3 className="text-[14px] font-extrabold text-gray-900">
                Daftar Titik Monitoring Lahan ({filteredPlots.length})
              </h3>
              {isLoading && <span className="text-[12px] text-emerald-700 font-semibold">Memuat...</span>}
            </div>
            <div className="divide-y divide-gray-100 max-h-[420px] overflow-y-auto">
              {filteredPlots.length === 0 ? (
                <div className="p-8 text-center text-gray-500 text-[13px]">
                  Tidak ada titik monitoring yang cocok dengan filter saat ini.
                </div>
              ) : (
                filteredPlots.map((plot) => {
                  const critical = isPlotCritical(plot);
                  const active = selectedPlot?.id === plot.id;
                  return (
                    <button
                      key={plot.id}
                      type="button"
                      onClick={() => handleSelectPlot(plot)}
                      className={`w-full text-left p-4 transition-colors flex flex-col sm:flex-row sm:items-center justify-between gap-3 ${
                        active ? 'bg-emerald-50/70 border-l-4 border-l-forest-emerald' : 'hover:bg-gray-50'
                      }`}
                    >
                      <div className="space-y-1">
                        <div className="flex flex-wrap items-center gap-2">
                          <span className="text-[14px] font-extrabold text-gray-900">
                            {plot.nama_desa}
                            {plot.kecamatan ? `, Kec. ${plot.kecamatan}` : ''}
                          </span>
                          <span className="px-2 py-0.5 rounded-md bg-emerald-100 text-emerald-900 text-[11px] font-bold capitalize">
                            {plot.komoditas}
                          </span>
                          {critical && (
                            <span className="px-2 py-0.5 rounded-md bg-rose-100 text-rose-700 text-[11px] font-bold">
                              Titik Kritis
                            </span>
                          )}
                        </div>
                        <p className="text-[12px] text-gray-500">
                          {plot.kelompok_tani} · Luas {plot.luas_lahan} · Sumber air: {plot.sumber_air} ({plot.kondisi_air})
                        </p>
                      </div>
                      <div className="flex items-center gap-3 shrink-0">
                        <div className="text-right">
                          <div className="text-[12px] font-extrabold text-gray-800">
                            Kesuburan {plot.fertility}
                          </div>
                          <div className="text-[11px] text-gray-500">
                            pH {plot.ph} · Air {plot.moisture}%
                          </div>
                        </div>
                        <span className="material-symbols-outlined text-gray-400">chevron_right</span>
                      </div>
                    </button>
                  );
                })
              )}
            </div>
          </div>
        </div>

        {/* Right: 8-in-1 Soil Telemetry Inspector & PPL Recommendation Desk */}
        <div className="xl:col-span-5">
          {selectedPlot ? (
            <div className="bg-surface-white rounded-2xl border border-gray-100 shadow-sm p-5 space-y-5 sticky top-20">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <span className="text-[11px] font-bold uppercase tracking-wider text-forest-emerald">
                    Inspektur Plot #{selectedPlot.id}
                  </span>
                  <h2 className="text-xl font-extrabold text-gray-900 mt-0.5">
                    Desa {selectedPlot.nama_desa}
                    {selectedPlot.kecamatan ? `, ${selectedPlot.kecamatan}` : ''}
                  </h2>
                  <p className="text-[12px] text-gray-500 mt-0.5">
                    {selectedPlot.kelompok_tani} · {selectedPlot.komoditas}
                    {selectedPlot.varietas ? ` (${selectedPlot.varietas})` : ''}
                  </p>
                </div>
                <a
                  href={`https://maps.google.com/?q=${selectedPlot.latitude},${selectedPlot.longitude}`}
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex items-center gap-1 px-3 py-1.5 rounded-xl bg-emerald-50 hover:bg-emerald-100 text-forest-emerald text-[12px] font-bold shrink-0"
                >
                  <span className="material-symbols-outlined text-[16px]">map</span>
                  Google Maps
                </a>
              </div>

              {/* 8-in-1 Telemetry Grid */}
              <div>
                <h3 className="text-[12px] font-extrabold text-gray-500 uppercase tracking-wider mb-2.5">
                  Pembacaan Probe Tanah 8-in-1
                </h3>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
                  {[
                    { label: 'pH Tanah', value: `${selectedPlot.ph}`, warn: Number(selectedPlot.ph) < 5.5 || Number(selectedPlot.ph) > 7.5 },
                    { label: 'Kelembapan', value: `${selectedPlot.moisture}%`, warn: Number(selectedPlot.moisture) < 15 },
                    { label: 'Suhu Tanah', value: `${selectedPlot.temp}°C`, warn: false },
                    { label: 'EC Tanah', value: `${selectedPlot.conductivity} uS`, warn: false },
                    { label: 'Nitrogen (N)', value: `${selectedPlot.nitrogen} mg/kg`, warn: false },
                    { label: 'Fosfor (P)', value: `${selectedPlot.phosphorus} mg/kg`, warn: false },
                    { label: 'Kalium (K)', value: `${selectedPlot.potassium} mg/kg`, warn: false },
                    { label: 'Fertilitas', value: `${selectedPlot.fertility}/100`, warn: Number(selectedPlot.fertility) < 20 },
                  ].map((metric) => (
                    <div
                      key={metric.label}
                      className={`p-2.5 rounded-xl border ${
                        metric.warn
                          ? 'bg-rose-50 border-rose-200 text-rose-900'
                          : 'bg-gray-50 border-gray-200 text-gray-900'
                      }`}
                    >
                      <div className="text-[10px] font-bold uppercase opacity-70">{metric.label}</div>
                      <div className="text-[14px] font-extrabold mt-0.5">{metric.value}</div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Infrastructure & Agronomy Conditions */}
              <div>
                <h3 className="text-[12px] font-extrabold text-gray-500 uppercase tracking-wider mb-2">
                  Infrastruktur &amp; Kondisi Lapangan
                </h3>
                <div className="flex flex-wrap gap-1.5 text-[11px] font-bold">
                  <span className="px-2.5 py-1 rounded-lg bg-gray-100 text-gray-700">
                    Irigasi: {selectedPlot.irigasi}
                  </span>
                  <span className="px-2.5 py-1 rounded-lg bg-gray-100 text-gray-700">
                    Pompa Air: {selectedPlot.pompa_air} ({selectedPlot.sumber_energi_pompa})
                  </span>
                  <span className="px-2.5 py-1 rounded-lg bg-gray-100 text-gray-700">
                    Air: {selectedPlot.sumber_air} · {selectedPlot.kondisi_air}
                  </span>
                  <span className="px-2.5 py-1 rounded-lg bg-gray-100 text-gray-700">
                    Pembajak: {selectedPlot.pembajak}
                  </span>
                  <span className="px-2.5 py-1 rounded-lg bg-gray-100 text-gray-700">
                    Luas: {selectedPlot.luas_lahan} ({selectedPlot.status_lahan})
                  </span>
                  {selectedPlot.hasil_panen_lalu && (
                    <span className="px-2.5 py-1 rounded-lg bg-emerald-50 text-emerald-800">
                      Panen Lalu: {selectedPlot.hasil_panen_lalu} {selectedPlot.satuan_panen || 'ton'}
                    </span>
                  )}
                </div>
              </div>

              {/* Evidence Photos if attached */}
              {(selectedPlot.foto_daun || selectedPlot.foto_pohon || selectedPlot.foto_tanah) && (
                <div>
                  <h3 className="text-[12px] font-extrabold text-gray-500 uppercase tracking-wider mb-2">
                    Dokumentasi Foto Lapangan (3 Sudut)
                  </h3>
                  <div className="grid grid-cols-3 gap-2">
                    {[
                      { label: 'Daun', url: selectedPlot.foto_daun },
                      { label: 'Pohon', url: selectedPlot.foto_pohon },
                      { label: 'Tanah', url: selectedPlot.foto_tanah },
                    ].map((photo) => {
                      const resolved = resolveImageUrl(photo.url);
                      return resolved ? (
                        <a
                          key={photo.label}
                          href={resolved}
                          target="_blank"
                          rel="noreferrer"
                          className="group relative rounded-xl overflow-hidden border border-gray-200 aspect-square bg-gray-100"
                        >
                          <img src={resolved} alt={photo.label} className="w-full h-full object-cover" />
                          <span className="absolute bottom-1 left-1 px-1.5 py-0.5 rounded bg-black/60 text-white text-[10px] font-bold">
                            {photo.label}
                          </span>
                        </a>
                      ) : null;
                    })}
                  </div>
                </div>
              )}

              {/* PPL Recommendation Form */}
              <form onSubmit={handleSubmitRecommendation} className="space-y-3 pt-2 border-t border-gray-100">
                <div className="flex items-center justify-between">
                  <label className="text-[12px] font-extrabold text-gray-700 uppercase tracking-wider">
                    Rekomendasi Agronomis PPL
                  </label>
                  <select
                    value={verificationStatus}
                    onChange={(e) =>
                      setVerificationStatus(e.target.value as 'verified' | 'needs_action' | 'pending')
                    }
                    className="px-2.5 py-1 rounded-lg border border-gray-200 text-[12px] font-bold bg-gray-50"
                  >
                    <option value="verified">Terverifikasi PPL</option>
                    <option value="needs_action">Perlu Tindakan</option>
                    <option value="pending">Menunggu Review</option>
                  </select>
                </div>

                <textarea
                  rows={3}
                  value={recommendationText}
                  onChange={(e) => setRecommendationText(e.target.value)}
                  placeholder="Tulis rekomendasi pemupukan berimbang, dosis dolomit/kompos, atau jadwal pengairan..."
                  className="w-full px-3 py-2 text-[13px] rounded-xl border border-gray-200 bg-gray-50 focus:outline-none focus:ring-2 focus:ring-forest-emerald/30 focus:border-forest-emerald"
                />

                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="w-full py-2.5 px-4 rounded-xl bg-forest-emerald hover:bg-[#0e422e] text-white font-bold text-[13px] flex items-center justify-center gap-2 transition-all disabled:opacity-60"
                >
                  <span className="material-symbols-outlined text-[18px]">save</span>
                  {isSubmitting ? 'Menyimpan...' : 'Simpan Rekomendasi PPL'}
                </button>
              </form>
            </div>
          ) : (
            <div className="bg-surface-white rounded-2xl border border-gray-100 p-8 text-center text-gray-500 text-[13px]">
              Pilih salah satu titik lahan di sebelah kiri untuk inspeksi parameter 8-in-1.
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
