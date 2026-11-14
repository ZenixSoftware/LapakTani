import React, { useMemo, useState } from 'react';
import type { LandPlotRecord, MonitoringSummaryResponse } from '../services/api';
import {
  computePlotAverages,
  escapeHtml,
  getPlotFertilityStatus,
  isPlotCritical,
} from '../utils/monitoringHelpers';

interface AiPolicyBriefProps {
  plots: LandPlotRecord[];
  summary: MonitoringSummaryResponse | null;
  onRefresh: () => void;
  onInspectPlot: (plot: LandPlotRecord) => void;
}

type PolicyFocus = 'semua' | 'pemupukan' | 'irigasi' | 'zonasi';

export const AiPolicyBrief: React.FC<AiPolicyBriefProps> = ({
  plots,
  summary,
  onRefresh,
  onInspectPlot,
}) => {
  const [focus, setFocus] = useState<PolicyFocus>('semua');
  const [generatedAt, setGeneratedAt] = useState<string>(() =>
    new Date().toLocaleString('id-ID', { dateStyle: 'medium', timeStyle: 'short' })
  );

  const stats = summary?.ringkasan_umum;
  const averages = useMemo(() => computePlotAverages(plots), [plots]);

  const totalPlots = Number(stats?.total_titik ?? plots.length);
  const avgPh = Number(stats?.avg_ph ?? averages.avgPh);
  const avgMoisture = Number(stats?.avg_moisture ?? averages.avgMoisture);
  const avgN = Number(stats?.avg_nitrogen ?? averages.avgN);
  const avgP = Number(stats?.avg_phosphorus ?? averages.avgP);
  const avgK = Number(stats?.avg_potassium ?? averages.avgK);
  const avgFertility = Number(stats?.avg_fertility ?? averages.avgFertility);

  const criticalPlots = useMemo(() => plots.filter(isPlotCritical), [plots]);
  const dryPlots = useMemo(() => plots.filter((p) => Number(p.moisture) < 25), [plots]);
  const acidPlots = useMemo(() => plots.filter((p) => Number(p.ph) < 6.0), [plots]);
  const nonIrrigatedCount = useMemo(
    () => plots.filter((p) => (p.irigasi || '').toLowerCase() !== 'ya').length,
    [plots]
  );

  // Commodity zoning matrix derived live from Sumenep plot data
  const zoningMatrix = useMemo(() => {
    const groups = new Map<string, LandPlotRecord[]>();
    plots.forEach((p) => {
      const kom = (p.komoditas || 'lainnya').trim().toLowerCase();
      const arr = groups.get(kom) || [];
      arr.push(p);
      groups.set(kom, arr);
    });

    return Array.from(groups.entries()).map(([komoditas, rows]) => {
      const avg = computePlotAverages(rows);
      const villages = Array.from(new Set(rows.map((r) => r.nama_desa))).slice(0, 3).join(', ');
      const needDolomit = avg.avgPh < 6.0;
      const needUrea = avg.avgN < 15;
      const needWater = avg.avgMoisture < 25;

      const fertilizerDirective = [
        needDolomit ? 'Dolomit 1.5–2 ton/Ha (koreksi pH asam)' : 'Pertahankan kapur pemeliharaan 0.5 ton/Ha',
        needUrea ? 'NPK Phonska 250 kg/Ha + Urea 100 kg/Ha' : 'NPK berimbang 200 kg/Ha + kompos matang 2 ton/Ha',
      ].join(' · ');

      const infraDirective = needWater
        ? 'Prioritas pompa air bertenaga listrik & mulsa organik'
        : 'Optimasi jadwal irigasi tersier & pemeliharaan drainase';

      return {
        komoditas,
        count: rows.length,
        villages,
        avgPh: avg.avgPh,
        avgFertility: avg.avgFertility,
        fertilizerDirective,
        infraDirective,
      };
    });
  }, [plots]);

  const handlePrintBrief = () => {
    const htmlRows = zoningMatrix
      .map(
        (z) => `
      <tr>
        <td style="text-transform:capitalize;font-weight:700;">${escapeHtml(z.komoditas)}</td>
        <td>${escapeHtml(z.villages)} (${z.count} titik)</td>
        <td>pH ${z.avgPh.toFixed(2)} · Subur ${z.avgFertility.toFixed(0)}</td>
        <td>${escapeHtml(z.fertilizerDirective)}</td>
        <td>${escapeHtml(z.infraDirective)}</td>
      </tr>`
      )
      .join('');

    const win = window.open('', '_blank', 'width=960,height=800');
    if (!win) return;
    win.document.write(`<!DOCTYPE html>
      <html lang="id">
      <head>
        <title>AI Policy Brief - LapakTani &amp; BPP Kab. Sumenep</title>
        <style>
          body { font-family: Arial, sans-serif; color: #131f18; padding: 36px; line-height: 1.6; }
          h1 { color: #0D5136; border-bottom: 3px solid #166534; padding-bottom: 8px; margin-bottom: 6px; }
          h2 { color: #166534; margin-top: 24px; font-size: 16px; }
          .meta { color: #475569; font-size: 12px; margin-bottom: 20px; }
          table { width: 100%; border-collapse: collapse; margin-top: 12px; font-size: 12px; }
          th, td { border: 1px solid #cbd5e1; padding: 8px 10px; text-align: left; vertical-align: top; }
          th { background: #0D5136; color: #ffffff; }
        </style>
      </head>
      <body>
        <h1>AI Policy Brief: Rekomendasi Pemupukan &amp; Zonasi Komoditas Sumenep</h1>
        <div class="meta">LAPAKTANI Portal Penyuluh Pertanian &bull; Digenerasi pada ${escapeHtml(generatedAt)}</div>
        <h2>1. Ringkasan Eksekutif Agregasi Data Tanah 8-in-1</h2>
        <ul>
          <li>Total Titik Pantau Lahan: <strong>${totalPlots}</strong> plot di Kabupaten Sumenep.</li>
          <li>Rata-rata pH Tanah: <strong>${avgPh.toFixed(2)}</strong> (${acidPlots.length} plot membutuhkan pengapuran dolomit).</li>
          <li>Rata-rata Hara NPK: <strong>N ${avgN.toFixed(1)} / P ${avgP.toFixed(1)} / K ${avgK.toFixed(1)} mg/kg</strong> dengan Indeks Fertilitas rata-rata <strong>${avgFertility.toFixed(0)}/100</strong>.</li>
          <li>Status Lengas &amp; Irigasi: Kelembaban rata-rata <strong>${avgMoisture.toFixed(1)}%</strong> (${dryPlots.length} lahan kering &lt; 25%, ${nonIrrigatedCount} plot belum terhubung irigasi teknis).</li>
        </ul>
        <h2>2. Matriks Zonasi Komoditas &amp; Alokasi Pupuk Bersubsidi</h2>
        <table>
          <thead>
            <tr>
              <th>Komoditas</th>
              <th>Desa Klaster</th>
              <th>Profil Tanah</th>
              <th>Rekomendasi Pemupukan Berimbang</th>
              <th>Prioritas Infrastruktur</th>
            </tr>
          </thead>
          <tbody>${htmlRows}</tbody>
        </table>
      </body>
      </html>`);
    win.document.close();
    win.focus();
    window.setTimeout(() => win.print(), 250);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-2 text-[11.5px] font-bold uppercase tracking-wider text-[#166534]">
            <span className="material-symbols-outlined text-[16px]">psychology</span>
            Decision Support System &bull; BPP Kabupaten Sumenep
          </div>
          <h1 className="text-2xl font-extrabold text-gray-900 mt-0.5">
            AI Policy Brief &amp; Zonasi Komoditas
          </h1>
          <p className="text-[13px] text-gray-500">
            Ringkasan rekomendasi kebijakan pemupukan berimbang, alokasi subsidi NPK/Dolomit, dan prioritas irigasi berdasarkan agregasi data sensor 8-in-1 Sumenep.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <select
            value={focus}
            onChange={(e) => setFocus(e.target.value as PolicyFocus)}
            className="px-3 py-2 rounded-xl bg-white border border-[#E2E8F0] text-[12.5px] font-bold text-gray-800"
          >
            <option value="semua">Semua Pilar Kebijakan</option>
            <option value="pemupukan">Fokus Pemupukan &amp; pH</option>
            <option value="irigasi">Fokus Irigasi &amp; Pompa</option>
            <option value="zonasi">Fokus Zonasi Komoditas</option>
          </select>
          <button
            type="button"
            onClick={() => {
              onRefresh();
              setGeneratedAt(
                new Date().toLocaleString('id-ID', { dateStyle: 'medium', timeStyle: 'short' })
              );
            }}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-[#166534] hover:bg-[#0D5136] text-white text-[12.5px] font-bold shadow-sm transition-colors"
          >
            <span className="material-symbols-outlined text-[17px]">auto_awesome</span>
            Sintesis Ulang Brief
          </button>
          <button
            type="button"
            onClick={handlePrintBrief}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-[#F59E0B] hover:bg-amber-500 text-white text-[12.5px] font-bold shadow-sm transition-colors"
          >
            <span className="material-symbols-outlined text-[17px]">print</span>
            Cetak Policy Brief
          </button>
        </div>
      </div>

      {/* 3 Strategic Pillar Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white rounded-2xl border border-[#E2E8F0] p-5 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <span className="px-2.5 py-0.5 rounded-full bg-emerald-50 text-[#166534] text-[11px] font-extrabold">
              Pilar 1 · Kesehatan Tanah
            </span>
            <span className="material-symbols-outlined text-[#166534]">science</span>
          </div>
          <div className="text-xl font-extrabold text-gray-900">
            pH {avgPh.toFixed(2)} · Subur {avgFertility.toFixed(0)}/100
          </div>
          <p className="text-[12.5px] text-gray-600 mt-1.5 leading-relaxed">
            {acidPlots.length} dari {totalPlots} plot terdeteksi memiliki pH masam (&lt; 6.0) dan memerlukan program subsidi dolomit &amp; bahan organik Poktan.
          </p>
        </div>

        <div className="bg-white rounded-2xl border border-[#E2E8F0] p-5 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <span className="px-2.5 py-0.5 rounded-full bg-sky-50 text-sky-700 text-[11px] font-extrabold">
              Pilar 2 · Infrastruktur Air
            </span>
            <span className="material-symbols-outlined text-sky-600">water_drop</span>
          </div>
          <div className="text-xl font-extrabold text-gray-900">
            Lembab {avgMoisture.toFixed(1)}% · {nonIrrigatedCount} Non-Irigasi
          </div>
          <p className="text-[12.5px] text-gray-600 mt-1.5 leading-relaxed">
            {dryPlots.length} plot berada di bawah ambang kelembaban 25%. Prioritaskan elektrifikasi pompa sumur bor pada lahan tadah hujan.
          </p>
        </div>

        <div className="bg-white rounded-2xl border border-[#E2E8F0] p-5 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <span className="px-2.5 py-0.5 rounded-full bg-amber-50 text-amber-800 text-[11px] font-extrabold">
              Pilar 3 · Intervensi Kritis
            </span>
            <span className="material-symbols-outlined text-[#F59E0B]">verified</span>
          </div>
          <div className="text-xl font-extrabold text-gray-900">
            {criticalPlots.length} Plot Prioritas Tinggi
          </div>
          <p className="text-[12.5px] text-gray-600 mt-1.5 leading-relaxed">
            Diperlukan kunjungan pendampingan BPP dan penyaluran pupuk NPK tepat dosis agar produktivitas pra-panen tidak turun.
          </p>
        </div>
      </div>

      {/* Executive Policy Brief Document Card */}
      <div className="bg-white rounded-2xl border border-[#E2E8F0] shadow-sm overflow-hidden">
        <div className="bg-[#0D5136] text-white px-6 py-4 flex flex-wrap items-center justify-between gap-2">
          <div>
            <h2 className="text-[16px] font-extrabold">
              Naskah Ringkas Kebijakan Agronomi Kabupaten Sumenep
            </h2>
            <p className="text-[11.5px] text-emerald-100/85">
              Diperbarui otomatis dari {totalPlots} catatan monitoring 8-in-1 &bull; {generatedAt}
            </p>
          </div>
          <span className="px-2.5 py-1 rounded-lg bg-[#22C55E] text-[#052e16] text-[11px] font-extrabold">
            Siap Tindak Lanjut BPP
          </span>
        </div>

        <div className="p-6 space-y-5 text-[13.5px] text-gray-700 leading-relaxed">
          {(focus === 'semua' || focus === 'pemupukan') && (
            <div className="p-4 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0] space-y-1.5">
              <h3 className="font-extrabold text-[#0D5136] text-[14px]">
                1. Rekomendasi Pemupukan Berimbang &amp; Remediasi pH Tanah
              </h3>
              <p>
                Agregasi telemetri menunjukkan rata-rata unsur hara <strong>Nitrogen {avgN.toFixed(1)} mg/kg</strong>,{' '}
                <strong>Fosfor {avgP.toFixed(1)} mg/kg</strong>, dan <strong>Kalium {avgK.toFixed(1)} mg/kg</strong> dengan
                pH rata-rata <strong>{avgPh.toFixed(2)}</strong>. Alokasi pupuk bersubsidi disarankan beralih dari dosis seragam ke paket presisi: aplikasi{' '}
                <strong>Dolomit 1,5–2 ton/Ha</strong> pada {acidPlots.length} lahan pH masam sebelum pemupukan dasar NPK Phonska + pupuk kandang terfermentasi.
              </p>
            </div>
          )}

          {(focus === 'semua' || focus === 'irigasi') && (
            <div className="p-4 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0] space-y-1.5">
              <h3 className="font-extrabold text-[#0D5136] text-[14px]">
                2. Penguatan Irigasi Tadah Hujan &amp; Elektrifikasi Pompa Air
              </h3>
              <p>
                Terdapat <strong>{nonIrrigatedCount} titik</strong> yang belum memiliki saluran irigasi teknis permanen dan{' '}
                <strong>{dryPlots.length} titik</strong> dengan kadar lengas di bawah 25%. BPP kecamatan bersama Poktan direkomendasikan mengonsolidasikan pompa air listrik efisiensi tinggi dan penggunaan mulsa jerami pada sentra cabai dan tembakau.
              </p>
            </div>
          )}

          {(focus === 'semua' || focus === 'zonasi') && (
            <div className="p-4 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0] space-y-1.5">
              <h3 className="font-extrabold text-[#0D5136] text-[14px]">
                3. Zonasi Komoditas &amp; Bursa Pra-Panen LapakTani
              </h3>
              <p>
                Lahan dengan fertilitas di atas 60 dan akses pompa aktif diprioritaskan menjadi klaster kontrak B2B pra-panen di ekosistem LapakTani guna menjamin serapan hasil petani dengan harga transparan.
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Regional Zoning & Fertilizer Matrix */}
      <div className="bg-white rounded-2xl border border-[#E2E8F0] shadow-sm overflow-hidden">
        <div className="px-5 py-4 border-b border-[#E2E8F0] bg-[#F8FAF9] flex flex-wrap items-center justify-between gap-2">
          <div>
            <h2 className="text-[14px] font-extrabold text-gray-900 uppercase tracking-wide">
              Matriks Zonasi Komoditas &amp; Rekomendasi Pupuk Daerah
            </h2>
            <p className="text-[12px] text-gray-500">
              Dihitung langsung dari rata-rata parameter N-P-K, pH, dan lengas masing-masing komoditas
            </p>
          </div>
          <span className="px-2.5 py-1 rounded-lg bg-emerald-50 text-[#166534] text-[11px] font-extrabold">
            {zoningMatrix.length} Zona Komoditas
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-[12.5px] text-left">
            <thead className="bg-[#F8FAF9] text-gray-600 uppercase text-[11px] font-extrabold border-b border-[#E2E8F0]">
              <tr>
                <th className="px-4 py-3">Komoditas</th>
                <th className="px-3 py-3">Sebaran Desa</th>
                <th className="px-3 py-3">Profil pH &amp; Subur</th>
                <th className="px-4 py-3">Rekomendasi Pemupukan</th>
                <th className="px-4 py-3">Prioritas Infrastruktur</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#F1F5F9]">
              {zoningMatrix.map((z) => (
                <tr key={z.komoditas} className="hover:bg-[#F8FAF9]">
                  <td className="px-4 py-3 font-extrabold text-[#0D5136] capitalize">
                    {z.komoditas} ({z.count})
                  </td>
                  <td className="px-3 py-3 text-gray-600">{z.villages || 'Kab. Sumenep'}</td>
                  <td className="px-3 py-3 font-mono font-bold text-gray-800">
                    pH {z.avgPh.toFixed(2)} · Subur {z.avgFertility.toFixed(0)}
                  </td>
                  <td className="px-4 py-3 text-gray-800">{z.fertilizerDirective}</td>
                  <td className="px-4 py-3 text-gray-700">{z.infraDirective}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Critical Action Plots Strip */}
      {criticalPlots.length > 0 && (
        <div className="bg-white rounded-2xl border border-rose-200 shadow-sm overflow-hidden">
          <div className="px-5 py-3.5 bg-rose-50 border-b border-rose-200 flex items-center justify-between">
            <div className="flex items-center gap-2 text-rose-800 font-extrabold text-[13.5px]">
              <span className="material-symbols-outlined text-[19px]">warning</span>
              Lahan Titik Kritis Memerlukan Tindak Lanjut Kebijakan ({criticalPlots.length})
            </div>
          </div>
          <div className="divide-y divide-rose-100">
            {criticalPlots.map((plot) => (
              <div
                key={plot.id}
                className="p-4 flex flex-wrap items-center justify-between gap-3 hover:bg-rose-50/40"
              >
                <div>
                  <div className="font-extrabold text-[13.5px] text-gray-900">
                    Desa {plot.nama_desa}
                    {plot.kecamatan ? `, Kec. ${plot.kecamatan}` : ''} ·{' '}
                    <span className="capitalize text-rose-700">{plot.komoditas}</span>
                  </div>
                  <p className="text-[12px] text-gray-600">
                    Status: {getPlotFertilityStatus(plot).toUpperCase()} · pH {plot.ph} · Lengas{' '}
                    {plot.moisture}% · Fertilitas {plot.fertility}/100 · Rekomendasi PPL:{' '}
                    {plot.rekomendasi_ppl || 'Belum diisi'}
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => onInspectPlot(plot)}
                  className="px-3.5 py-1.5 rounded-xl bg-[#0D5136] hover:bg-[#166534] text-white text-[12px] font-bold"
                >
                  Tulis Arahan PPL
                </button>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

