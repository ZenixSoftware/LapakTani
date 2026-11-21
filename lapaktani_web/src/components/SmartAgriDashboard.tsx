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
      ? { label: 'Netral · Optimal', cls: 'bg-lt-primary-tint text-lt-primary border-lt-primary-border' }
      : avgPh < 6.0
        ? { label: 'Asam · Butuh Dolomit', cls: 'bg-lt-error-tint text-lt-error border-lt-error-border' }
        : { label: 'Alkali · Basa', cls: 'bg-lt-tertiary-tint text-lt-tertiary-text border-lt-tertiary-border' };

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
      <section className="rounded-2xl bg-lt-surface-card border border-lt-border border-l-4 border-l-lt-primary p-6 lg:p-7 shadow-sm">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="space-y-2 max-w-2xl">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-lt-primary-tint border border-lt-primary-border text-[11.5px] font-bold text-lt-primary">
              <span className="w-2 h-2 rounded-full bg-lt-primary animate-pulse" />
              Kabupaten Sumenep · Sensor 8-in-1 &amp; Precision Farming
            </div>
            <h1 className="text-2xl lg:text-3xl font-extrabold tracking-tight text-lt-neutral">
              Dashboard Ringkasan Lahan Presisi
            </h1>
            <p className="text-lt-neutral-muted text-[13px] lg:text-[14px] leading-relaxed">
              Agregasi real-time parameter hara NPK, pH, EC, infrastruktur irigasi Poktan, AI Policy Brief, serta antrean validasi petani LapakTani.
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2.5">
            <button
              type="button"
              onClick={() => onNavigateTab(isDinas ? 'policy-brief' : 'rag-decision')}
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-lt-tertiary hover:bg-lt-tertiary-tint text-lt-neutral border border-lt-tertiary-border font-extrabold text-[13px] shadow-sm transition-all"
            >
              <span className="material-symbols-outlined text-[18px]">psychology</span>
              {isDinas ? 'AI Policy Brief & Eskalasi' : 'AI Decision Support (RAG)'}
            </button>
            <button
              type="button"
              onClick={onRefresh}
              disabled={isLoading}
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-lt-primary hover:bg-lt-primary-dark text-white font-bold text-[13px] transition-all disabled:opacity-50"
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
          className="text-left bg-white rounded-2xl border border-lt-border hover:border-lt-primary p-5 shadow-sm transition-all group"
        >
          <div className="flex items-start justify-between">
            <span className="text-[11.5px] font-bold uppercase tracking-wider text-lt-neutral-muted">
              Total Titik Lahan
            </span>
            <span className="p-2 rounded-xl bg-lt-primary-tint text-lt-primary group-hover:bg-lt-primary group-hover:text-white transition-colors">
              <span className="material-symbols-outlined text-[20px]">location_on</span>
            </span>
          </div>
          <div className="text-3xl font-extrabold text-lt-neutral mt-3 font-mono">{totalPlots}</div>
          <div className="mt-2 inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-lt-primary-tint text-lt-primary border border-lt-primary-border">
            <span className="material-symbols-outlined text-[13px]">check_circle</span>
            Terpetakan Sumenep · Buka Peta
          </div>
        </button>

        <button
          type="button"
          onClick={() => onNavigateTab('data-sensor')}
          className="text-left bg-white rounded-2xl border border-lt-border hover:border-lt-primary p-5 shadow-sm transition-all group"
        >
          <div className="flex items-start justify-between">
            <span className="text-[11.5px] font-bold uppercase tracking-wider text-lt-neutral-muted">
              Rata-Rata pH &amp; Fertilitas
            </span>
            <span className="p-2 rounded-xl bg-lt-tertiary-tint text-lt-tertiary-text group-hover:bg-lt-tertiary group-hover:text-lt-neutral transition-colors">
              <span className="material-symbols-outlined text-[20px]">science</span>
            </span>
          </div>
          <div className="text-3xl font-extrabold text-lt-neutral mt-3 font-mono">
            {avgPh.toFixed(2)}{' '}
            <span className="text-[14px] font-bold text-lt-primary">
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
          className="text-left bg-white rounded-2xl border border-lt-border hover:border-lt-primary p-5 shadow-sm transition-all group"
        >
          <div className="flex items-start justify-between">
            <span className="text-[11.5px] font-bold uppercase tracking-wider text-lt-neutral-muted">
              Nitrogen (N) &amp; Kelembaban
            </span>
            <span className="p-2 rounded-xl bg-lt-secondary-tint text-lt-secondary-dark group-hover:bg-lt-secondary group-hover:text-white transition-colors">
              <span className="material-symbols-outlined text-[20px]">water_drop</span>
            </span>
          </div>
          <div className="text-3xl font-extrabold text-lt-neutral mt-3 font-mono">
            {avgNitrogen.toFixed(1)}{' '}
            <span className="text-[13px] font-semibold text-lt-neutral-muted">mg/kg</span>
            <span className="text-[14px] font-bold text-lt-secondary-dark ml-2">
              · {avgMoisture.toFixed(1)}%
            </span>
          </div>
          <div className="mt-2 inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-lt-secondary-tint text-lt-secondary-dark border border-lt-secondary-border">
            {stats?.total_pompa_air ?? 0} Pompa · {stats?.total_irigasi ?? 0} Irigasi Aktif
          </div>
        </button>

        <button
          type="button"
          onClick={() =>
            onNavigateTab(!isDinas && pendingFarmerCount > 0 ? 'validasi' : 'peta-lahan')
          }
          className="text-left bg-white rounded-2xl border border-lt-border hover:border-lt-tertiary p-5 shadow-sm transition-all group"
        >
          <div className="flex items-start justify-between">
            <span className="text-[11.5px] font-bold uppercase tracking-wider text-lt-neutral-muted">
              {isDinas ? 'Zona Kritis Prioritas' : 'Titik Kritis & Antrean KTP'}
            </span>
            <span className="p-2 rounded-xl bg-lt-error-tint text-lt-error group-hover:bg-lt-error group-hover:text-white transition-colors">
              <span className="material-symbols-outlined text-[20px]">warning</span>
            </span>
          </div>
          <div className="text-3xl font-extrabold text-lt-error mt-3 font-mono">
            {stats?.total_titik_kritis ?? criticalPlots.length}{' '}
            <span className="text-[14px] font-bold text-lt-neutral-muted">Lahan Kritis</span>
          </div>
          <div className="mt-2 inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-lt-tertiary-tint text-lt-tertiary-text border border-lt-tertiary-border">
            {isDinas
              ? 'Lihat Peta Geospasial GIS'
              : `${pendingFarmerCount} Petani Menunggu Verifikasi`}
          </div>
        </button>
      </div>

      {/* Row 2: Commodity Distribution + Soil Fertility Breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div className="lg:col-span-7 bg-white rounded-2xl border border-lt-border p-6 shadow-sm flex flex-col justify-between">
          <div>
            <div className="flex flex-wrap items-center justify-between gap-2 mb-5">
              <div>
                <h2 className="text-[16px] font-extrabold text-lt-neutral">
                  Distribusi Komoditas &amp; Rata-Rata Kesuburan Sumenep
                </h2>
                <p className="text-[12.5px] text-lt-neutral-muted">
                  Proporsi komoditas pertanian strategis beserta indeks pH dan kesuburan hara
                </p>
              </div>
              <button
                type="button"
                onClick={() => onNavigateTab('peta-lahan')}
                className="text-[12px] font-bold text-lt-primary hover:underline flex items-center gap-1"
              >
                Lihat di Peta GIS
                <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
              </button>
            </div>

            {commodityRows.length === 0 ? (
              <div className="py-10 text-center text-[13px] text-lt-neutral-muted">
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
                          <span className="font-extrabold text-lt-neutral capitalize">
                            {row.komoditas}
                          </span>
                          <span className="px-2 py-0.5 rounded bg-lt-primary-tint text-lt-primary text-[11px] font-bold">
                            {row.jumlah_titik} titik ({totalShare}%)
                          </span>
                        </div>
                        <span className="text-[12px] font-mono font-bold text-lt-neutral-muted">
                          pH {Number(row.avg_ph || 0).toFixed(2)} · Subur{' '}
                          {Number(row.avg_fertility || 0).toFixed(0)}
                        </span>
                      </div>
                      <div className="h-3 rounded-full bg-lt-surface-canvas border border-lt-border overflow-hidden">
                        <div
                          className="h-full rounded-full bg-gradient-to-r from-lt-primary to-lt-primary"
                          style={{ width: `${Math.max(8, pct)}%` }}
                        />
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          <div className="pt-4 mt-5 border-t border-lt-border flex flex-wrap items-center justify-between gap-2 text-[12px] text-lt-neutral-muted">
            <span>
              Suhu Tanah Rata-Rata:{' '}
              <strong className="text-lt-neutral font-mono">{avgTemp.toFixed(1)}°C</strong> · Konduktivitas
              Listrik: <strong className="text-lt-neutral font-mono">{avgEc.toFixed(0)} µS/cm</strong>
            </span>
            <span className="px-2.5 py-1 rounded-lg bg-lt-primary-tint text-lt-primary font-bold">
              {totalPlots} Sampel Teruji 8-in-1
            </span>
          </div>
        </div>

        {/* Fertility Status Breakdown + Quick Access */}
        <div className="lg:col-span-5 bg-white rounded-2xl border border-lt-border p-6 shadow-sm flex flex-col justify-between space-y-5">
          <div>
            <div className="flex items-center justify-between mb-4">
              <div>
                <h2 className="text-[16px] font-extrabold text-lt-neutral">
                  Status Kesuburan Tanah
                </h2>
                <p className="text-[12.5px] text-lt-neutral-muted">
                  Klasifikasi kesehatan lahan berdasarkan ambang pH, lengas &amp; fertilitas
                </p>
              </div>
              <span className="px-2.5 py-1 rounded-full bg-lt-surface-canvas border border-lt-border text-[11px] font-bold text-lt-neutral-muted">
                3 Tier
              </span>
            </div>

            <div className="space-y-3">
              {[
                {
                  label: 'Optimal (Subur ≥ 60 & pH Ideal)',
                  count: fertilityCounts.optimal,
                  barCls: 'bg-lt-primary',
                  pillCls: 'bg-lt-primary-tint text-lt-primary border-lt-primary-border',
                },
                {
                  label: 'Sedang (Perlu Pemupukan Terarah)',
                  count: fertilityCounts.sedang,
                  barCls: 'bg-lt-tertiary',
                  pillCls: 'bg-lt-tertiary-tint text-lt-tertiary-text border-lt-tertiary-border',
                },
                {
                  label: 'Kritis (pH Ekstrem / Kering < 15%)',
                  count: fertilityCounts.kritis,
                  barCls: 'bg-lt-error',
                  pillCls: 'bg-lt-error-tint text-lt-error border-lt-error-border',
                },
              ].map((tier) => {
                const share =
                  plots.length > 0 ? Math.round((tier.count / plots.length) * 100) : 0;
                return (
                  <div
                    key={tier.label}
                    className="p-3 rounded-xl bg-lt-surface-canvas border border-lt-border"
                  >
                    <div className="flex items-center justify-between gap-2 text-[12.5px]">
                      <span className="font-bold text-lt-neutral">{tier.label}</span>
                      <span
                        className={`px-2 py-0.5 rounded-md border text-[11px] font-extrabold font-mono ${tier.pillCls}`}
                      >
                        {tier.count} ({share}%)
                      </span>
                    </div>
                    <div className="h-2 rounded-full bg-white border border-lt-border mt-2 overflow-hidden">
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

          <div className="grid grid-cols-2 gap-2.5 pt-2 border-t border-lt-border">
            <button
              type="button"
              onClick={() => onNavigateTab('data-sensor')}
              className="py-2.5 px-3 rounded-xl bg-lt-primary-tint hover:bg-lt-primary-tint text-lt-primary font-bold text-[12px] flex items-center justify-center gap-1.5 transition-colors"
            >
              <span className="material-symbols-outlined text-[17px]">sensors</span>
              Tabel Data 8-in-1
            </button>
            <button
              type="button"
              onClick={() => onNavigateTab(isDinas ? 'policy-brief' : 'validasi')}
              className="py-2.5 px-3 rounded-xl bg-lt-primary hover:bg-lt-primary-dark text-white font-bold text-[12px] flex items-center justify-center gap-1.5 transition-colors"
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
        <div className="lg:col-span-6 bg-white rounded-2xl border border-lt-border p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between gap-2">
            <div>
              <h2 className="text-[16px] font-extrabold text-lt-neutral">
                Catatan &amp; Rekomendasi Agronomi
              </h2>
              <p className="text-[12px] text-lt-neutral-muted">
                Sintesis kondisi hara tanah Sumenep dan prioritas intervensi PPL
              </p>
            </div>
            <button
              type="button"
              onClick={() => onNavigateTab(isDinas ? 'policy-brief' : 'rag-decision')}
              className="px-3 py-1.5 rounded-xl bg-lt-primary text-white text-[12px] font-bold hover:bg-lt-primary-dark"
            >
              {isDinas ? 'Buka Policy Brief' : 'Buka Decision RAG'}
            </button>
          </div>

          <div className="grid grid-cols-2 gap-1.5 p-1 rounded-xl bg-lt-surface-canvas border border-lt-border">
            <button
              type="button"
              onClick={() => setAiNoteTab('rekom')}
              className={`py-2 px-3 rounded-lg text-[12px] font-bold transition-all ${
                aiNoteTab === 'rekom'
                  ? 'bg-lt-primary text-white shadow-sm'
                  : 'text-lt-neutral-muted hover:text-lt-neutral'
              }`}
            >
              Rekomendasi Pemupukan
            </button>
            <button
              type="button"
              onClick={() => setAiNoteTab('lapangan')}
              className={`py-2 px-3 rounded-lg text-[12px] font-bold transition-all ${
                aiNoteTab === 'lapangan'
                  ? 'bg-lt-primary text-white shadow-sm'
                  : 'text-lt-neutral-muted hover:text-lt-neutral'
              }`}
            >
              Catatan Sensor &amp; Air
            </button>
          </div>

          {aiNoteTab === 'rekom' ? (
            <div className="space-y-3">
              <div className="p-4 rounded-xl bg-lt-surface-canvas border border-lt-border">
                <div className="flex items-center justify-between gap-2 mb-1">
                  <span className="font-extrabold text-[13.5px] text-lt-neutral">
                    {avgPh < 6.0
                      ? 'Pengapuran Dolomit & Penyeimbangan pH Masam'
                      : 'Pemupukan Berimbang NPK Fase Generatif'}
                  </span>
                  <span className="px-2 py-0.5 rounded bg-lt-primary-tint text-lt-primary text-[10.5px] font-bold">
                    Prioritas Tinggi
                  </span>
                </div>
                <p className="text-[12.5px] text-lt-neutral-muted leading-relaxed">
                  Dari {totalPlots} titik lahan di Sumenep (rata-rata pH {avgPh.toFixed(2)}, Nitrogen{' '}
                  {avgNitrogen.toFixed(1)} mg/kg), prioritaskan suplementasi NPK terukur dan bahan organik pada blok dengan fertilitas rendah.
                </p>
              </div>
              <div className="p-4 rounded-xl bg-lt-surface-canvas border border-lt-border">
                <div className="flex items-center justify-between gap-2 mb-1">
                  <span className="font-extrabold text-[13.5px] text-lt-neutral">
                    Konservasi Lengas &amp; Mulsa Sentra Hortikultura
                  </span>
                  <span className="px-2 py-0.5 rounded bg-lt-tertiary-tint text-lt-tertiary-text text-[10.5px] font-bold">
                    Efisiensi Air
                  </span>
                </div>
                <p className="text-[12.5px] text-lt-neutral-muted leading-relaxed">
                  Dengan kelembaban rata-rata {avgMoisture.toFixed(1)}% dan suhu tanah {avgTemp.toFixed(1)}°C, jadwalkan pompa air pagi/sore pada sentra cabai dan tembakau.
                </p>
              </div>
            </div>
          ) : (
            <div className="space-y-3">
              <div className="p-4 rounded-xl bg-lt-surface-canvas border border-lt-border">
                <div className="flex items-center justify-between gap-2 mb-1">
                  <span className="font-extrabold text-[13.5px] text-lt-neutral">
                    Konduktivitas Listrik (EC) &amp; Salinitas
                  </span>
                  <span className="px-2 py-0.5 rounded bg-lt-primary-tint text-lt-primary text-[10.5px] font-bold">
                    EC {avgEc.toFixed(0)} µS/cm
                  </span>
                </div>
                <p className="text-[12.5px] text-lt-neutral-muted leading-relaxed">
                  Pantauan salinitas rata-rata berada pada ambang aman untuk serapan akar komoditas Padi, Jagung, Cabai, dan Tembakau Madura.
                </p>
              </div>
              <div className="p-4 rounded-xl bg-lt-surface-canvas border border-lt-border">
                <div className="flex items-center justify-between gap-2 mb-1">
                  <span className="font-extrabold text-[13.5px] text-lt-neutral">
                    Kesiapan Infrastruktur Pompa &amp; Listrik
                  </span>
                  <span className="px-2 py-0.5 rounded bg-lt-secondary-tint text-lt-secondary-dark text-[10.5px] font-bold">
                    {stats?.total_pompa_air ?? 0} Pompa
                  </span>
                </div>
                <p className="text-[12.5px] text-lt-neutral-muted leading-relaxed">
                  Sebanyak {stats?.total_irigasi ?? 0} titik terhubung saluran irigasi dan{' '}
                  {plots.filter((p) => p.listrik?.toLowerCase() === 'ya').length} titik memiliki akses listrik untuk pompa bor.
                </p>
              </div>
            </div>
          )}
        </div>

        <div className="lg:col-span-6 bg-white rounded-2xl border border-lt-border p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between gap-2">
            <div>
              <h2 className="text-[16px] font-extrabold text-lt-neutral">
                Kelembagaan Poktan &amp; Titik Prioritas
              </h2>
              <p className="text-[12px] text-lt-neutral-muted">
                Klik salah satu plot untuk membuka inspektor 8-in-1 &amp; menulis arahan PPL
              </p>
            </div>
            <button
              type="button"
              onClick={() => onNavigateTab('peta-lahan')}
              className="px-3 py-1.5 rounded-xl bg-lt-primary-tint text-lt-primary text-[12px] font-bold hover:bg-lt-primary-tint"
            >
              Peta Lahan
            </button>
          </div>

          <div className="grid grid-cols-2 gap-1.5 p-1 rounded-xl bg-lt-surface-canvas border border-lt-border">
            <button
              type="button"
              onClick={() => setPoktanTab('binaan')}
              className={`py-2 px-3 rounded-lg text-[12px] font-bold transition-all ${
                poktanTab === 'binaan'
                  ? 'bg-lt-primary text-white shadow-sm'
                  : 'text-lt-neutral-muted hover:text-lt-neutral'
              }`}
            >
              Plot Poktan ({poktanPlots.length})
            </button>
            <button
              type="button"
              onClick={() => setPoktanTab('kritis')}
              className={`py-2 px-3 rounded-lg text-[12px] font-bold transition-all ${
                poktanTab === 'kritis'
                  ? 'bg-lt-error text-white shadow-sm'
                  : 'text-lt-neutral-muted hover:text-lt-neutral'
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
                  className="w-full text-left p-3.5 rounded-xl bg-lt-surface-canvas hover:bg-lt-primary-tint/70 border border-lt-border hover:border-lt-primary transition-all flex items-center justify-between gap-3"
                >
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-extrabold text-[13px] text-lt-neutral truncate">
                        Desa {plot.nama_desa}
                      </span>
                      <span className="px-2 py-0.5 rounded bg-lt-primary-tint text-lt-primary text-[10.5px] font-bold capitalize">
                        {plot.komoditas}
                      </span>
                      {critical && (
                        <span className="px-2 py-0.5 rounded bg-lt-error-tint text-lt-error text-[10.5px] font-bold">
                          Kritis
                        </span>
                      )}
                    </div>
                    <p className="text-[11.5px] text-lt-neutral-muted truncate mt-0.5">
                      {plot.kelompok_tani} · pH {plot.ph} · Lembab {plot.moisture}% · NPK{' '}
                      {plot.nitrogen}/{plot.phosphorus}/{plot.potassium}
                    </p>
                  </div>
                  <span className="material-symbols-outlined text-lt-neutral-subtle text-[20px]">
                    chevron_right
                  </span>
                </button>
              );
            })}
            {(poktanTab === 'kritis' ? criticalPlots : poktanPlots).length === 0 && (
              <div className="py-8 text-center text-[12.5px] text-lt-neutral-muted">
                Tidak ada plot pada kategori ini.
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

