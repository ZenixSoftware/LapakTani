import React, { useMemo, useState } from 'react';
import type { LandPlotRecord } from '../services/api';
import {
  computePlotAverages,
  downloadPlotsCsv,
  getPlotFertilityStatus,
  type FertilityStatus,
} from '../utils/monitoringHelpers';

interface SensorDataTableProps {
  plots: LandPlotRecord[];
  isLoading: boolean;
  onRefresh: () => void;
  onInspectPlot: (plot: LandPlotRecord) => void;
}

export const SensorDataTable: React.FC<SensorDataTableProps> = ({
  plots,
  isLoading,
  onRefresh,
  onInspectPlot,
}) => {
  const [selectedDesa, setSelectedDesa] = useState<string>('');
  const [fertilityFilter, setFertilityFilter] = useState<'all' | FertilityStatus>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');

  const uniqueVillages = useMemo(() => {
    const names = Array.from(
      new Set(plots.map((p) => (p.nama_desa || '').trim()).filter(Boolean))
    ).sort((a, b) => a.localeCompare(b));
    return names;
  }, [plots]);

  const filteredPlots = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    return plots.filter((plot) => {
      if (selectedDesa && plot.nama_desa !== selectedDesa) return false;
      if (fertilityFilter !== 'all' && getPlotFertilityStatus(plot) !== fertilityFilter) {
        return false;
      }
      if (!q) return true;
      return [plot.nama_desa, plot.kecamatan, plot.kelompok_tani, plot.komoditas, plot.varietas]
        .filter(Boolean)
        .some((v) => String(v).toLowerCase().includes(q));
    });
  }, [plots, selectedDesa, fertilityFilter, searchQuery]);

  const averages = useMemo(() => computePlotAverages(filteredPlots), [filteredPlots]);

  const villageRecapRows = useMemo(() => {
    const grouped = new Map<string, LandPlotRecord[]>();
    plots.forEach((p) => {
      const desa = (p.nama_desa || 'Tidak Terdata').trim();
      const existing = grouped.get(desa) || [];
      existing.push(p);
      grouped.set(desa, existing);
    });
    return Array.from(grouped.entries())
      .map(([desa, rows]) => ({
        desa,
        ...computePlotAverages(rows),
      }))
      .sort((a, b) => a.desa.localeCompare(b.desa));
  }, [plots]);

  const metricCards = [
    {
      label: '1. Suhu Tanah',
      value: `${averages.avgTemp.toFixed(1)}`,
      unit: '°C',
      target: 'Target: 25-32 °C',
      badge: averages.avgTemp >= 24 && averages.avgTemp <= 33 ? 'Optimal' : 'Pantau',
      ok: averages.avgTemp >= 24 && averages.avgTemp <= 33,
      icon: 'thermostat',
    },
    {
      label: '2. Kelembaban',
      value: `${averages.avgMoisture.toFixed(1)}`,
      unit: '%',
      target: 'Target: 20-60%',
      badge: averages.avgMoisture >= 20 ? 'Cukup Air' : 'Kering',
      ok: averages.avgMoisture >= 20,
      icon: 'water_drop',
    },
    {
      label: '3. pH Tanah',
      value: `${averages.avgPh.toFixed(2)}`,
      unit: '',
      target: 'Ideal: 6.0-7.5',
      badge: averages.avgPh >= 5.5 && averages.avgPh <= 7.5 ? 'Netral' : 'Koreksi pH',
      ok: averages.avgPh >= 5.5 && averages.avgPh <= 7.5,
      icon: 'science',
    },
    {
      label: '4. EC (Konduktivitas)',
      value: `${averages.avgEc.toFixed(0)}`,
      unit: 'µS/cm',
      target: 'Salinitas Tanah',
      badge: averages.avgEc <= 1200 ? 'Aman' : 'Tinggi',
      ok: averages.avgEc <= 1200,
      icon: 'bolt',
    },
    {
      label: '5. Nitrogen (N)',
      value: `${averages.avgN.toFixed(1)}`,
      unit: 'mg/kg',
      target: 'Pertumbuhan Daun',
      badge: averages.avgN >= 10 ? 'Baik' : 'Perlu Urea/NPK',
      ok: averages.avgN >= 10,
      icon: 'eco',
    },
    {
      label: '6. Fosfor (P)',
      value: `${averages.avgP.toFixed(1)}`,
      unit: 'mg/kg',
      target: 'Akar & Bunga',
      badge: averages.avgP >= 8 ? 'Baik' : 'Perlu SP-36',
      ok: averages.avgP >= 8,
      icon: 'biotech',
    },
    {
      label: '7. Kalium (K)',
      value: `${averages.avgK.toFixed(1)}`,
      unit: 'mg/kg',
      target: 'Ketahanan & Buah',
      badge: averages.avgK >= 15 ? 'Optimal' : 'Perlu KCl',
      ok: averages.avgK >= 15,
      icon: 'grain',
    },
    {
      label: '8. Kesuburan (Fertility)',
      value: `${averages.avgFertility.toFixed(0)}`,
      unit: '/100',
      target: 'Indeks Hara Terpadu',
      badge: averages.avgFertility >= 60 ? 'Subur' : averages.avgFertility >= 20 ? 'Sedang' : 'Kritis',
      ok: averages.avgFertility >= 60,
      icon: 'yard',
    },
  ];

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <div className="inline-flex items-center gap-2 text-[11.5px] font-bold uppercase tracking-wider text-lt-primary">
            <span className="material-symbols-outlined text-[16px]">sensors</span>
            Telemetri Sensor Tanah 8-in-1 &bull; Kabupaten Sumenep
          </div>
          <h1 className="text-2xl font-extrabold text-lt-neutral mt-0.5">
            Data Sensor Lapangan
          </h1>
          <p className="text-[13px] text-lt-neutral-muted">
            Rata-rata 8 parameter unsur hara tanah (Suhu, Kelembaban, EC, pH, N, P, K, Kesuburan) dan tabel inspeksi per titik lahan.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <button
            type="button"
            onClick={() => downloadPlotsCsv(filteredPlots)}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-white hover:bg-lt-surface-canvas border border-lt-border text-lt-neutral text-[12.5px] font-bold shadow-sm transition-colors"
          >
            <span className="material-symbols-outlined text-[17px]">download</span>
            Ekspor CSV ({filteredPlots.length})
          </button>
          <button
            type="button"
            onClick={onRefresh}
            disabled={isLoading}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-lt-primary hover:bg-lt-primary-dark text-white text-[12.5px] font-bold shadow-sm transition-colors disabled:opacity-50"
          >
            <span className={`material-symbols-outlined text-[17px] ${isLoading ? 'animate-spin' : ''}`}>
              refresh
            </span>
            Refresh Data
          </button>
        </div>
      </div>

      {/* Filter Toolbar */}
      <div className="bg-white rounded-2xl border border-lt-border p-4 shadow-sm flex flex-col lg:flex-row lg:items-center justify-between gap-3">
        <div className="flex flex-wrap items-center gap-2.5">
          <label htmlFor="desaSensorFilter" className="text-[12.5px] font-bold text-lt-neutral">
            Wilayah / Desa:
          </label>
          <select
            id="desaSensorFilter"
            value={selectedDesa}
            onChange={(e) => setSelectedDesa(e.target.value)}
            className="px-3 py-2 rounded-xl bg-lt-surface-canvas border border-lt-border text-[12.5px] font-bold text-lt-neutral focus:outline-none focus:border-lt-primary"
          >
            <option value="">Semua Wilayah / Desa ({plots.length} Titik)</option>
            {uniqueVillages.map((desa) => (
              <option key={desa} value={desa}>
                Desa {desa}
              </option>
            ))}
          </select>

          <div className="flex items-center gap-1 bg-lt-surface-canvas p-1 rounded-xl border border-lt-border">
            {(['all', 'optimal', 'sedang', 'kritis'] as const).map((st) => (
              <button
                key={st}
                type="button"
                onClick={() => setFertilityFilter(st)}
                className={`px-2.5 py-1 rounded-lg text-[11.5px] font-bold capitalize transition-all ${
                  fertilityFilter === st
                    ? 'bg-lt-primary text-white'
                    : 'text-lt-neutral-muted hover:text-lt-neutral'
                }`}
              >
                {st === 'all' ? 'Semua' : st}
              </button>
            ))}
          </div>
        </div>

        <div className="flex items-center gap-2">
          <div className="relative flex-1 min-w-[220px]">
            <span className="material-symbols-outlined text-lt-neutral-subtle text-[18px] absolute left-3 top-1/2 -translate-y-1/2">
              search
            </span>
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Filter desa, Poktan, komoditas..."
              className="w-full pl-9 pr-3 py-2 rounded-xl bg-lt-surface-canvas border border-lt-border text-[12.5px] focus:outline-none focus:border-lt-primary"
            />
          </div>
          {(selectedDesa || fertilityFilter !== 'all' || searchQuery) && (
            <button
              type="button"
              onClick={() => {
                setSelectedDesa('');
                setFertilityFilter('all');
                setSearchQuery('');
              }}
              className="px-3 py-2 rounded-xl bg-lt-surface-canvas border border-lt-border text-[12px] font-bold text-lt-neutral hover:bg-lt-surface-canvas"
            >
              Reset
            </button>
          )}
        </div>
      </div>

      {/* 8 Parameter Metric Cards Grid (SmartAgri 8-in-1 Live Aggregations) */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-[13px] font-extrabold text-lt-neutral uppercase tracking-wider">
              Rata-Rata 8 Parameter Unsur Tanah
            </h2>
            <p className="text-[12px] text-lt-neutral-muted">
              Kalkulasi agregat live dari {filteredPlots.length} titik filter aktif
            </p>
          </div>
          <span className="px-2.5 py-1 rounded-lg bg-lt-primary-tint text-lt-primary border border-lt-primary-border text-[11px] font-extrabold">
            8 Sensor Aktif
          </span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
          {metricCards.map((card) => (
            <div
              key={card.label}
              className="bg-white rounded-2xl border border-lt-border p-4 shadow-sm flex flex-col justify-between hover:border-lt-primary transition-colors"
            >
              <div className="flex items-center justify-between">
                <span className="text-[11px] font-bold uppercase tracking-wider text-lt-neutral-muted">
                  {card.label}
                </span>
                <span className="material-symbols-outlined text-[18px] text-lt-primary">
                  {card.icon}
                </span>
              </div>
              <div className="my-2.5">
                <span className="text-2xl font-extrabold text-lt-neutral font-mono">
                  {filteredPlots.length > 0 ? card.value : '--'}
                </span>
                {card.unit && (
                  <span className="text-[12px] font-bold text-lt-neutral-muted ml-1">{card.unit}</span>
                )}
              </div>
              <div className="pt-2 border-t border-lt-surface-canvas flex items-center justify-between text-[11px]">
                <span className="text-lt-neutral-muted">{card.target}</span>
                <span
                  className={`px-2 py-0.5 rounded font-bold ${
                    card.ok
                      ? 'bg-lt-primary-tint text-lt-primary'
                      : 'bg-lt-tertiary-tint text-lt-tertiary-text'
                  }`}
                >
                  {card.badge}
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Village Recapitulation Table */}
      <div className="bg-white rounded-2xl border border-lt-border shadow-sm overflow-hidden">
        <div className="px-5 py-4 border-b border-lt-border flex flex-wrap items-center justify-between gap-2 bg-lt-surface-canvas">
          <div>
            <h2 className="text-[14px] font-extrabold text-lt-neutral uppercase tracking-wide">
              Rekapitulasi Rata-Rata 8 Unsur Tanah per Desa
            </h2>
            <p className="text-[12px] text-lt-neutral-muted">
              Klik baris desa untuk memfilter seluruh log telemetri sensor di bawah
            </p>
          </div>
          <span className="px-2.5 py-1 rounded-lg bg-white border border-lt-border text-[11.5px] font-bold text-lt-neutral font-mono">
            {villageRecapRows.length} Desa
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-[12.5px] text-left">
            <thead className="bg-lt-surface-canvas text-lt-neutral-muted uppercase text-[11px] font-extrabold border-b border-lt-border">
              <tr>
                <th className="px-4 py-3">Desa</th>
                <th className="px-3 py-3 text-center">Sampel</th>
                <th className="px-3 py-3 text-right">Suhu (°C)</th>
                <th className="px-3 py-3 text-right">Lembab (%)</th>
                <th className="px-3 py-3 text-right">pH</th>
                <th className="px-3 py-3 text-right">EC (µS/cm)</th>
                <th className="px-3 py-3 text-right">N (mg/kg)</th>
                <th className="px-3 py-3 text-right">P (mg/kg)</th>
                <th className="px-3 py-3 text-right">K (mg/kg)</th>
                <th className="px-3 py-3 text-right">Fertility</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-lt-surface-canvas">
              {villageRecapRows.map((row) => {
                const isSelected = selectedDesa === row.desa;
                return (
                  <tr
                    key={row.desa}
                    onClick={() => setSelectedDesa(isSelected ? '' : row.desa)}
                    className={`cursor-pointer transition-colors ${
                      isSelected ? 'bg-lt-primary-tint font-bold' : 'hover:bg-lt-surface-canvas'
                    }`}
                  >
                    <td className="px-4 py-3 font-extrabold text-lt-neutral">Desa {row.desa}</td>
                    <td className="px-3 py-3 text-center font-mono">{row.count}</td>
                    <td className="px-3 py-3 text-right font-mono">{row.avgTemp.toFixed(1)}</td>
                    <td className="px-3 py-3 text-right font-mono">{row.avgMoisture.toFixed(1)}</td>
                    <td className="px-3 py-3 text-right font-mono">{row.avgPh.toFixed(2)}</td>
                    <td className="px-3 py-3 text-right font-mono">{row.avgEc.toFixed(0)}</td>
                    <td className="px-3 py-3 text-right font-mono">{row.avgN.toFixed(1)}</td>
                    <td className="px-3 py-3 text-right font-mono">{row.avgP.toFixed(1)}</td>
                    <td className="px-3 py-3 text-right font-mono">{row.avgK.toFixed(1)}</td>
                    <td className="px-3 py-3 text-right font-mono font-extrabold text-lt-primary">
                      {row.avgFertility.toFixed(0)}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Detailed Telemetry Log Table */}
      <div className="bg-white rounded-2xl border border-lt-border shadow-sm overflow-hidden">
        <div className="px-5 py-4 border-b border-lt-border flex flex-wrap items-center justify-between gap-2 bg-lt-surface-canvas">
          <div>
            <h2 className="text-[14px] font-extrabold text-lt-neutral uppercase tracking-wide">
              Log Telemetri Sensor 8-in-1 ({filteredPlots.length})
            </h2>
            <p className="text-[12px] text-lt-neutral-muted">
              Inspeksi lengkap Suhu, Kelembaban, EC, pH, Nitrogen, Fosfor, Kalium, dan Status Kesuburan
            </p>
          </div>
          <span className="text-[11.5px] font-bold text-lt-primary">
            Klik tombol Inspeksi untuk mengisi Rekomendasi PPL
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-[12px] text-left">
            <thead className="bg-lt-surface-canvas text-lt-neutral-muted uppercase text-[10.5px] font-extrabold border-b border-lt-border">
              <tr>
                <th className="px-4 py-3">Desa / Poktan</th>
                <th className="px-3 py-3">Komoditas</th>
                <th className="px-2.5 py-3 text-right">Suhu</th>
                <th className="px-2.5 py-3 text-right">Lembab</th>
                <th className="px-2.5 py-3 text-right">EC</th>
                <th className="px-2.5 py-3 text-right">pH</th>
                <th className="px-2.5 py-3 text-right">N</th>
                <th className="px-2.5 py-3 text-right">P</th>
                <th className="px-2.5 py-3 text-right">K</th>
                <th className="px-3 py-3 text-center">Status Kesuburan</th>
                <th className="px-4 py-3 text-right">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-lt-surface-canvas">
              {filteredPlots.length === 0 ? (
                <tr>
                  <td colSpan={11} className="px-4 py-8 text-center text-lt-neutral-muted">
                    Tidak ada log sensor yang sesuai dengan filter.
                  </td>
                </tr>
              ) : (
                filteredPlots.map((plot) => {
                  const status = getPlotFertilityStatus(plot);
                  return (
                    <tr key={plot.id} className="hover:bg-lt-surface-canvas transition-colors">
                      <td className="px-4 py-3">
                        <div className="font-extrabold text-lt-neutral">Desa {plot.nama_desa}</div>
                        <div className="text-[11px] text-lt-neutral-muted">
                          {plot.kelompok_tani || 'Mandiri'} · {plot.luas_lahan}
                        </div>
                      </td>
                      <td className="px-3 py-3">
                        <span className="px-2 py-0.5 rounded bg-lt-primary-tint text-lt-primary font-bold capitalize">
                          {plot.komoditas}
                        </span>
                      </td>
                      <td className="px-2.5 py-3 text-right font-mono">{plot.temp}°C</td>
                      <td className="px-2.5 py-3 text-right font-mono">{plot.moisture}%</td>
                      <td className="px-2.5 py-3 text-right font-mono">{plot.conductivity}</td>
                      <td className="px-2.5 py-3 text-right font-mono font-bold">{plot.ph}</td>
                      <td className="px-2.5 py-3 text-right font-mono text-lt-primary font-bold">
                        {plot.nitrogen}
                      </td>
                      <td className="px-2.5 py-3 text-right font-mono text-lt-tertiary-text font-bold">
                        {plot.phosphorus}
                      </td>
                      <td className="px-2.5 py-3 text-right font-mono text-lt-secondary-dark font-bold">
                        {plot.potassium}
                      </td>
                      <td className="px-3 py-3 text-center">
                        <span
                          className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10.5px] font-extrabold uppercase ${
                            status === 'kritis'
                              ? 'bg-lt-error-tint text-lt-error'
                              : status === 'optimal'
                                ? 'bg-lt-primary-tint text-lt-primary'
                                : 'bg-lt-tertiary-tint text-lt-tertiary-text'
                          }`}
                        >
                          {status} ({plot.fertility})
                        </span>
                      </td>
                      <td className="px-4 py-3 text-right">
                        <button
                          type="button"
                          onClick={() => onInspectPlot(plot)}
                          className="px-3 py-1.5 rounded-lg bg-lt-primary hover:bg-lt-primary-dark text-white text-[11.5px] font-bold transition-colors"
                        >
                          Inspeksi
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

