import React, { useState } from 'react';
import type { LandPlotRecord, MonitoringSummaryResponse } from '../services/api';
import { getPlotFertilityStatus, isPlotCritical } from '../utils/monitoringHelpers';
import type { PortalModuleTab } from './Sidebar';

interface SmartAgriDashboardProps {
  plots: LandPlotRecord[];
  summary: MonitoringSummaryResponse | null;
  pendingFarmerCount: number;
  userRole?: string | null;
  isLoading: boolean;
  onRefresh: () => void;
  onNavigateTab: (tab: PortalModuleTab) => void;
  onInspectPlot: (plot: LandPlotRecord) => void;
}

export const SmartAgriDashboard: React.FC<SmartAgriDashboardProps> = ({
  plots,
  summary,
  pendingFarmerCount,
  userRole,
  isLoading,
  onRefresh,
  onNavigateTab,
  onInspectPlot,
}) => {
  const isDinas = String(userRole || '').toLowerCase() === 'dinas';
  const [aiNoteTab, setAiNoteTab] = useState<'rekom' | 'lapangan'>('rekom');
  const [poktanTab, setPoktanTab] = useState<'binaan' | 'kritis'>('binaan');

  const stats = summary?.ringkasan_umum;
  const totalPlots = Number(stats?.total_titik ?? plots.length);
  const avgPh = Number(stats?.avg_ph ?? 0);
  const avgNitrogen = Number(stats?.avg_nitrogen ?? 0);
  const avgMoisture = Number(stats?.avg_moisture ?? 0);
  const avgFertility = Number(stats?.avg_fertility ?? 0);
  const avgTemp = Number(stats?.avg_temp ?? 0);
  const avgEc = Number(stats?.avg_conductivity ?? 0);

  const phStatus =
    avgPh >= 6.0 && avgPh <= 7.5
      ? { label: 'Netral · Optimal', cls: 'bg-emerald-50 text-[#166534] border-emerald-200' }
      : avgPh < 6.0
        ? { label: 'Asam · Butuh Dolomit', cls: 'bg-rose-50 text-rose-700 border-rose-200' }
        : { label: 'Alkali · Basa', cls: 'bg-amber-50 text-[#F59E0B] border-amber-200' };

  const fertilityCounts = plots.reduce(
    (acc, plot) => {
      const st = getPlotFertilityStatus(plot);
      acc[st] += 1;
      return acc;
    },
    { optimal: 0, sedang: 0, kritis: 0 }
  );

  const criticalPlots = plots.filter(isPlotCritical);
  const poktanPlots = plots.filter(
    (p) =>
      p.kelompok_tani &&
      !['tidak', 'mandiri', '-', ''].includes(p.kelompok_tani.toLowerCase().trim())
  );

  const commodityRows =
    summary?.distribusi_komoditas && summary.distribusi_komoditas.length > 0
      ? summary.distribusi_komoditas
      : Object.entries(
          plots.reduce<Record<string, { count: number; fertSum: number; phSum: number }>>(
            (acc, p) => {
              const key = (p.komoditas || 'lainnya').toLowerCase();
              if (!acc[key]) acc[key] = { count: 0, fertSum: 0, phSum: 0 };
              acc[key].count += 1;
              acc[key].fertSum += Number(p.fertility) || 0;
              acc[key].phSum += Number(p.ph) || 0;
              return acc;
            },
            {}
          )
        ).map(([komoditas, val]) => ({
          komoditas,
          jumlah_titik: val.count,
          avg_fertility: (val.fertSum / val.count).toFixed(1),
          avg_ph: (val.phSum / val.count).toFixed(2),
        }));

  const maxCommodityCount = Math.max(1, ...commodityRows.map((c) => Number(c.jumlah_titik) || 0));

  return (
    <div className="space-y-6">
      {/* Header Banner */}
      <section className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-[#0D5136] via-[#166534] to-[#15803d] text-white p-6 lg:p-7 shadow-lg shadow-emerald-950/15">
        <div className="absolute -right-12 -top-12 w-60 h-60 rounded-full bg-[#22C55E]/20 blur-3xl pointer-events-none" />
        <div className="relative z-10 flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="space-y-2 max-w-2xl">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 border border-white/15 text-[11.5px] font-bold text-emerald-100">
              <span className="w-2 h-2 rounded-full bg-[#22C55E] animate-pulse" />
              Kabupaten Sumenep · Sensor 8-in-1 &amp; Precision Farming
            </div>
            <h1 className="text-2xl lg:text-3xl font-extrabold tracking-tight text-white">
              Dashboard Ringkasan Lahan Presisi
            </h1>
            <p className="text-emerald-100/90 text-[13px] lg:text-[14px] leading-relaxed">
              Agregasi real-time parameter hara NPK, pH, EC, infrastruktur irigasi Poktan, AI Policy Brief, serta antrean validasi petani LapakTani.
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2.5">
            <button
              type="button"
              onClick={() => onNavigateTab(isDinas ? 'policy-brief' : 'rag-decision')}
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#F59E0B] hover:bg-amber-500 text-white font-extrabold text-[13px] shadow-sm transition-all"
            >
              <span className="material-symbols-outlined text-[18px]">psychology</span>
              {isDinas ? 'AI Policy Brief & Eskalasi' : 'AI Decision Support (RAG)'}
            </button>
            <button
              type="button"
              onClick={onRefresh}
              disabled={isLoading}
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-white/15 hover:bg-white/25 text-white border border-white/20 font-bold text-[13px] transition-all disabled:opacity-50"
            >
              <span
                className={`material-symbols-outlined text-[18px] ${
                  isLoading ? 'animate-spin' : ''
                }`}
              >
                refresh
              </span>
              Refresh Data
            </button>
          </div>
        </div>
      </section>

      {/* 4 KPI Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <button
          type="button"
          onClick={() => onNavigateTab('peta-lahan')}
          className="text-left bg-white rounded-2xl border border-[#E2E8F0] hover:border-[#22C55E] p-5 shadow-sm transition-all group"
        >
          <div className="flex items-start justify-between">
            <span className="text-[11.5px] font-bold uppercase tracking-wider text-gray-500">
              Total Titik Lahan
            </span>
            <span className="p-2 rounded-xl bg-emerald-50 text-[#166534] group-hover:bg-[#166534] group-hover:text-white transition-colors">
              <span className="material-symbols-outlined text-[20px]">location_on</span>
            </span>
          </div>
          <div className="text-3xl font-extrabold text-gray-900 mt-3 font-mono">{totalPlots}</div>
          <div className="mt-2 inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-emerald-50 text-[#166534] border border-emerald-200">
            <span className="material-symbols-outlined text-[13px]">check_circle</span>
            Terpetakan Sumenep · Buka Peta
          </div>
        </button>

        <button
          type="button"
          onClick={() => onNavigateTab('data-sensor')}
          className="text-left bg-white rounded-2xl border border-[#E2E8F0] hover:border-[#22C55E] p-5 shadow-sm transition-all group"
        >
          <div className="flex items-start justify-between">
            <span className="text-[11.5px] font-bold uppercase tracking-wider text-gray-500">
              Rata-Rata pH &amp; Fertilitas
            </span>
            <span className="p-2 rounded-xl bg-amber-50 text-[#F59E0B] group-hover:bg-[#F59E0B] group-hover:text-white transition-colors">
              <span className="material-symbols-outlined text-[20px]">science</span>
            </span>
          </div>
          <div className="text-3xl font-extrabold text-gray-900 mt-3 font-mono">
            {avgPh.toFixed(2)}{' '}
            <span className="text-[14px] font-bold text-[#166534]">
              · Skor {avgFertility.toFixed(0)}/100
            </span>
          </div>
          <div
            className={`mt-2 inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold border ${phStatus.cls}`}
          >
            {phStatus.label}
          </div>
        </button>

        <button
          type="button"
          onClick={() => onNavigateTab('data-sensor')}
          className="text-left bg-white rounded-2xl border border-[#E2E8F0] hover:border-[#22C55E] p-5 shadow-sm transition-all group"
        >
          <div className="flex items-start justify-between">
            <span className="text-[11.5px] font-bold uppercase tracking-wider text-gray-500">
              Nitrogen (N) &amp; Kelembaban
            </span>
            <span className="p-2 rounded-xl bg-sky-50 text-sky-700 group-hover:bg-sky-600 group-hover:text-white transition-colors">
              <span className="material-symbols-outlined text-[20px]">water_drop</span>
            </span>
          </div>
          <div className="text-3xl font-extrabold text-gray-900 mt-3 font-mono">
            {avgNitrogen.toFixed(1)}{' '}
            <span className="text-[13px] font-semibold text-gray-500">mg/kg</span>
            <span className="text-[14px] font-bold text-sky-700 ml-2">
              · {avgMoisture.toFixed(1)}%
            </span>
          </div>
          <div className="mt-2 inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-sky-50 text-sky-800 border border-sky-200">
            {stats?.total_pompa_air ?? 0} Pompa · {stats?.total_irigasi ?? 0} Irigasi Aktif
          </div>
        </button>

        <button
          type="button"
          onClick={() =>
            onNavigateTab(!isDinas && pendingFarmerCount > 0 ? 'validasi' : 'peta-lahan')
          }
          className="text-left bg-white rounded-2xl border border-[#E2E8F0] hover:border-[#F59E0B] p-5 shadow-sm transition-all group"
        >
          <div className="flex items-start justify-between">
            <span className="text-[11.5px] font-bold uppercase tracking-wider text-gray-500">
              {isDinas ? 'Zona Kritis Prioritas' : 'Titik Kritis & Antrean KTP'}
            </span>
            <span className="p-2 rounded-xl bg-rose-50 text-rose-600 group-hover:bg-rose-600 group-hover:text-white transition-colors">
              <span className="material-symbols-outlined text-[20px]">warning</span>
            </span>
          </div>
          <div className="text-3xl font-extrabold text-rose-700 mt-3 font-mono">
            {stats?.total_titik_kritis ?? criticalPlots.length}{' '}
            <span className="text-[14px] font-bold text-gray-600">Lahan Kritis</span>
          </div>
          <div className="mt-2 inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-amber-50 text-amber-800 border border-amber-200">
            {isDinas
              ? 'Lihat Peta Geospasial GIS'
              : `${pendingFarmerCount} Petani Menunggu Verifikasi`}
          </div>
        </button>
      </div>

      {/* Row 2: Commodity Distribution + Soil Fertility Breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div className="lg:col-span-7 bg-white rounded-2xl border border-[#E2E8F0] p-6 shadow-sm flex flex-col justify-between">
          <div>
            <div className="flex flex-wrap items-center justify-between gap-2 mb-5">
              <div>
                <h2 className="text-[16px] font-extrabold text-gray-900">
                  Distribusi Komoditas &amp; Rata-Rata Kesuburan Sumenep
                </h2>
                <p className="text-[12.5px] text-gray-500">
                  Proporsi komoditas pertanian strategis beserta indeks pH dan kesuburan hara
                </p>
              </div>
              <button
                type="button"
                onClick={() => onNavigateTab('peta-lahan')}
                className="text-[12px] font-bold text-[#166534] hover:underline flex items-center gap-1"
              >
                Lihat di Peta GIS
                <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
              </button>
            </div>

            {commodityRows.length === 0 ? (
              <div className="py-10 text-center text-[13px] text-gray-500">
                Belum ada data distribusi komoditas yang termuat.
              </div>
            ) : (
              <div className="space-y-4">
                {commodityRows.map((row) => {
                  const pct = Math.round(((Number(row.jumlah_titik) || 0) / maxCommodityCount) * 100);
                  const totalShare =
                    totalPlots > 0 ? Math.round(((Number(row.jumlah_titik) || 0) / totalPlots) * 100) : 0;
                  return (
                    <div key={row.komoditas} className="space-y-1.5">
                      <div className="flex items-center justify-between text-[13px]">
                        <div className="flex items-center gap-2">
                          <span className="font-extrabold text-gray-900 capitalize">
                            {row.komoditas}
                          </span>
                          <span className="px-2 py-0.5 rounded bg-emerald-50 text-[#166534] text-[11px] font-bold">
                            {row.jumlah_titik} titik ({totalShare}%)
                          </span>
                        </div>
                        <span className="text-[12px] font-mono font-bold text-gray-600">
                          pH {Number(row.avg_ph || 0).toFixed(2)} · Subur{' '}
                          {Number(row.avg_fertility || 0).toFixed(0)}
                        </span>
                      </div>
                      <div className="h-3 rounded-full bg-[#F8FAF9] border border-[#E2E8F0] overflow-hidden">
                        <div
                          className="h-full rounded-full bg-gradient-to-r from-[#166534] to-[#22C55E]"
                          style={{ width: `${Math.max(8, pct)}%` }}
                        />
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          <div className="pt-4 mt-5 border-t border-[#E2E8F0] flex flex-wrap items-center justify-between gap-2 text-[12px] text-gray-600">
            <span>
              Suhu Tanah Rata-Rata:{' '}
              <strong className="text-gray-900 font-mono">{avgTemp.toFixed(1)}°C</strong> · Konduktivitas
              Listrik: <strong className="text-gray-900 font-mono">{avgEc.toFixed(0)} µS/cm</strong>
            </span>
            <span className="px-2.5 py-1 rounded-lg bg-emerald-50 text-[#166534] font-bold">
              {totalPlots} Sampel Teruji 8-in-1
            </span>
          </div>
        </div>

        {/* Fertility Status Breakdown + Quick Access */}
        <div className="lg:col-span-5 bg-white rounded-2xl border border-[#E2E8F0] p-6 shadow-sm flex flex-col justify-between space-y-5">
          <div>
            <div className="flex items-center justify-between mb-4">
              <div>
                <h2 className="text-[16px] font-extrabold text-gray-900">
                  Status Kesuburan Tanah
                </h2>
                <p className="text-[12.5px] text-gray-500">
                  Klasifikasi kesehatan lahan berdasarkan ambang pH, lengas &amp; fertilitas
                </p>
              </div>
              <span className="px-2.5 py-1 rounded-full bg-[#F8FAF9] border border-[#E2E8F0] text-[11px] font-bold text-gray-600">
                3 Tier
              </span>
            </div>

            <div className="space-y-3">
              {[
                {
                  label: 'Optimal (Subur ≥ 60 & pH Ideal)',
                  count: fertilityCounts.optimal,
                  barCls: 'bg-[#22C55E]',
                  pillCls: 'bg-emerald-50 text-[#166534] border-emerald-200',
                },
                {
                  label: 'Sedang (Perlu Pemupukan Terarah)',
                  count: fertilityCounts.sedang,
                  barCls: 'bg-[#F59E0B]',
                  pillCls: 'bg-amber-50 text-amber-800 border-amber-200',
                },
                {
                  label: 'Kritis (pH Ekstrem / Kering < 15%)',
                  count: fertilityCounts.kritis,
                  barCls: 'bg-rose-500',
                  pillCls: 'bg-rose-50 text-rose-700 border-rose-200',
                },
              ].map((tier) => {
                const share =
                  plots.length > 0 ? Math.round((tier.count / plots.length) * 100) : 0;
                return (
                  <div
                    key={tier.label}
                    className="p-3 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0]"
                  >
                    <div className="flex items-center justify-between gap-2 text-[12.5px]">
                      <span className="font-bold text-gray-800">{tier.label}</span>
                      <span
                        className={`px-2 py-0.5 rounded-md border text-[11px] font-extrabold font-mono ${tier.pillCls}`}
                      >
                        {tier.count} ({share}%)
                      </span>
                    </div>
                    <div className="h-2 rounded-full bg-white border border-gray-200 mt-2 overflow-hidden">
                      <div
                        className={`h-full rounded-full ${tier.barCls}`}
                        style={{ width: `${share}%` }}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-2.5 pt-2 border-t border-[#E2E8F0]">
            <button
              type="button"
              onClick={() => onNavigateTab('data-sensor')}
              className="py-2.5 px-3 rounded-xl bg-emerald-50 hover:bg-emerald-100 text-[#166534] font-bold text-[12px] flex items-center justify-center gap-1.5 transition-colors"
            >
              <span className="material-symbols-outlined text-[17px]">sensors</span>
              Tabel Data 8-in-1
            </button>
            <button
              type="button"
              onClick={() => onNavigateTab(isDinas ? 'policy-brief' : 'validasi')}
              className="py-2.5 px-3 rounded-xl bg-[#0D5136] hover:bg-[#166534] text-white font-bold text-[12px] flex items-center justify-center gap-1.5 transition-colors"
            >
              <span className="material-symbols-outlined text-[17px]">
                {isDinas ? 'policy' : 'verified_user'}
              </span>
              {isDinas ? 'Policy Brief' : `Validasi (${pendingFarmerCount})`}
            </button>
          </div>
        </div>
      </div>

      {/* Row 3: Agronomic Notes + Critical & Poktan List */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div className="lg:col-span-6 bg-white rounded-2xl border border-[#E2E8F0] p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between gap-2">
            <div>
              <h2 className="text-[16px] font-extrabold text-gray-900">
                Catatan &amp; Rekomendasi Agronomi
              </h2>
              <p className="text-[12px] text-gray-500">
                Sintesis kondisi hara tanah Sumenep dan prioritas intervensi PPL
              </p>
            </div>
            <button
              type="button"
              onClick={() => onNavigateTab(isDinas ? 'policy-brief' : 'rag-decision')}
              className="px-3 py-1.5 rounded-xl bg-[#166534] text-white text-[12px] font-bold hover:bg-[#0D5136]"
            >
              {isDinas ? 'Buka Policy Brief' : 'Buka Decision RAG'}
            </button>
          </div>

          <div className="grid grid-cols-2 gap-1.5 p-1 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0]">
            <button
              type="button"
              onClick={() => setAiNoteTab('rekom')}
              className={`py-2 px-3 rounded-lg text-[12px] font-bold transition-all ${
                aiNoteTab === 'rekom'
                  ? 'bg-[#0D5136] text-white shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              Rekomendasi Pemupukan
            </button>
            <button
              type="button"
              onClick={() => setAiNoteTab('lapangan')}
              className={`py-2 px-3 rounded-lg text-[12px] font-bold transition-all ${
                aiNoteTab === 'lapangan'
                  ? 'bg-[#0D5136] text-white shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              Catatan Sensor &amp; Air
            </button>
          </div>

          {aiNoteTab === 'rekom' ? (
            <div className="space-y-3">
              <div className="p-4 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0]">
                <div className="flex items-center justify-between gap-2 mb-1">
                  <span className="font-extrabold text-[13.5px] text-gray-900">
                    {avgPh < 6.0
                      ? 'Pengapuran Dolomit & Penyeimbangan pH Masam'
                      : 'Pemupukan Berimbang NPK Fase Generatif'}
                  </span>
                  <span className="px-2 py-0.5 rounded bg-emerald-100 text-[#166534] text-[10.5px] font-bold">
                    Prioritas Tinggi
                  </span>
                </div>
                <p className="text-[12.5px] text-gray-600 leading-relaxed">
                  Dari {totalPlots} titik lahan di Sumenep (rata-rata pH {avgPh.toFixed(2)}, Nitrogen{' '}
                  {avgNitrogen.toFixed(1)} mg/kg), prioritaskan suplementasi NPK terukur dan bahan organik pada blok dengan fertilitas rendah.
                </p>
              </div>
              <div className="p-4 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0]">
                <div className="flex items-center justify-between gap-2 mb-1">
                  <span className="font-extrabold text-[13.5px] text-gray-900">
                    Konservasi Lengas &amp; Mulsa Sentra Hortikultura
                  </span>
                  <span className="px-2 py-0.5 rounded bg-amber-100 text-amber-800 text-[10.5px] font-bold">
                    Efisiensi Air
                  </span>
                </div>
                <p className="text-[12.5px] text-gray-600 leading-relaxed">
                  Dengan kelembaban rata-rata {avgMoisture.toFixed(1)}% dan suhu tanah {avgTemp.toFixed(1)}°C, jadwalkan pompa air pagi/sore pada sentra cabai dan tembakau.
                </p>
              </div>
            </div>
          ) : (
            <div className="space-y-3">
              <div className="p-4 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0]">
                <div className="flex items-center justify-between gap-2 mb-1">
                  <span className="font-extrabold text-[13.5px] text-gray-900">
                    Konduktivitas Listrik (EC) &amp; Salinitas
                  </span>
                  <span className="px-2 py-0.5 rounded bg-emerald-100 text-[#166534] text-[10.5px] font-bold">
                    EC {avgEc.toFixed(0)} µS/cm
                  </span>
                </div>
                <p className="text-[12.5px] text-gray-600 leading-relaxed">
                  Pantauan salinitas rata-rata berada pada ambang aman untuk serapan akar komoditas Padi, Jagung, Cabai, dan Tembakau Madura.
                </p>
              </div>
              <div className="p-4 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0]">
                <div className="flex items-center justify-between gap-2 mb-1">
                  <span className="font-extrabold text-[13.5px] text-gray-900">
                    Kesiapan Infrastruktur Pompa &amp; Listrik
                  </span>
                  <span className="px-2 py-0.5 rounded bg-sky-100 text-sky-800 text-[10.5px] font-bold">
                    {stats?.total_pompa_air ?? 0} Pompa
                  </span>
                </div>
                <p className="text-[12.5px] text-gray-600 leading-relaxed">
                  Sebanyak {stats?.total_irigasi ?? 0} titik terhubung saluran irigasi dan{' '}
                  {plots.filter((p) => p.listrik?.toLowerCase() === 'ya').length} titik memiliki akses listrik untuk pompa bor.
                </p>
              </div>
            </div>
          )}
        </div>

        <div className="lg:col-span-6 bg-white rounded-2xl border border-[#E2E8F0] p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between gap-2">
            <div>
              <h2 className="text-[16px] font-extrabold text-gray-900">
                Kelembagaan Poktan &amp; Titik Prioritas
              </h2>
              <p className="text-[12px] text-gray-500">
                Klik salah satu plot untuk membuka inspektor 8-in-1 &amp; menulis arahan PPL
              </p>
            </div>
            <button
              type="button"
              onClick={() => onNavigateTab('peta-lahan')}
              className="px-3 py-1.5 rounded-xl bg-emerald-50 text-[#166534] text-[12px] font-bold hover:bg-emerald-100"
            >
              Peta Lahan
            </button>
          </div>

          <div className="grid grid-cols-2 gap-1.5 p-1 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0]">
            <button
              type="button"
              onClick={() => setPoktanTab('binaan')}
              className={`py-2 px-3 rounded-lg text-[12px] font-bold transition-all ${
                poktanTab === 'binaan'
                  ? 'bg-[#0D5136] text-white shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              Plot Poktan ({poktanPlots.length})
            </button>
            <button
              type="button"
              onClick={() => setPoktanTab('kritis')}
              className={`py-2 px-3 rounded-lg text-[12px] font-bold transition-all ${
                poktanTab === 'kritis'
                  ? 'bg-rose-600 text-white shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              Titik Kritis ({criticalPlots.length})
            </button>
          </div>

          <div className="space-y-2.5 max-h-60 overflow-y-auto custom-scrollbar pr-1">
            {(poktanTab === 'kritis' ? criticalPlots : poktanPlots).slice(0, 6).map((plot) => {
              const critical = isPlotCritical(plot);
              return (
                <button
                  key={plot.id}
                  type="button"
                  onClick={() => onInspectPlot(plot)}
                  className="w-full text-left p-3.5 rounded-xl bg-[#F8FAF9] hover:bg-emerald-50/70 border border-[#E2E8F0] hover:border-[#22C55E] transition-all flex items-center justify-between gap-3"
                >
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-extrabold text-[13px] text-gray-900 truncate">
                        Desa {plot.nama_desa}
                      </span>
                      <span className="px-2 py-0.5 rounded bg-emerald-100 text-[#166534] text-[10.5px] font-bold capitalize">
                        {plot.komoditas}
                      </span>
                      {critical && (
                        <span className="px-2 py-0.5 rounded bg-rose-100 text-rose-700 text-[10.5px] font-bold">
                          Kritis
                        </span>
                      )}
                    </div>
                    <p className="text-[11.5px] text-gray-500 truncate mt-0.5">
                      {plot.kelompok_tani} · pH {plot.ph} · Lembab {plot.moisture}% · NPK{' '}
                      {plot.nitrogen}/{plot.phosphorus}/{plot.potassium}
                    </p>
                  </div>
                  <span className="material-symbols-outlined text-gray-400 text-[20px]">
                    chevron_right
                  </span>
                </button>
              );
            })}
            {(poktanTab === 'kritis' ? criticalPlots : poktanPlots).length === 0 && (
              <div className="py-8 text-center text-[12.5px] text-gray-500">
                Tidak ada plot pada kategori ini.
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

