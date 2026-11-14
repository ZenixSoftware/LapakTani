import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  dispatchRagDecision,
  fetchDecisionReports,
  generateRagDecision,
  type DecisionReportRecord,
  type LandPlotRecord,
  type RagSynthesisResult,
} from '../services/api';
import { isPlotCritical } from '../utils/monitoringHelpers';

interface AiDecisionSupportProps {
  plots: LandPlotRecord[];
  onRefresh: () => void;
  onInspectPlot: (plot: LandPlotRecord) => void;
  onShowToast?: (message: string, type?: 'success' | 'error' | 'info') => void;
}

const SCOPE_LABELS: Record<DecisionReportRecord['target_scope'], { text: string; cls: string }> = {
  BOTH: {
    text: 'DINAS + PETANI',
    cls: 'bg-emerald-50 text-[#166534] border-emerald-200',
  },
  DINAS_ONLY: {
    text: 'DINAS SAJA',
    cls: 'bg-amber-50 text-amber-800 border-amber-200',
  },
  FARMERS_ONLY: {
    text: 'PETANI SAJA',
    cls: 'bg-sky-50 text-sky-800 border-sky-200',
  },
};

export const AiDecisionSupport: React.FC<AiDecisionSupportProps> = ({
  plots,
  onRefresh,
  onInspectPlot,
  onShowToast,
}) => {
  const sortedPlots = useMemo(() => {
    return [...plots].sort((a, b) => {
      const aDungkek = a.nama_desa.toLowerCase().includes('dungkek') ? 0 : 1;
      const bDungkek = b.nama_desa.toLowerCase().includes('dungkek') ? 0 : 1;
      if (aDungkek !== bDungkek) return aDungkek - bDungkek;
      const aCrit = isPlotCritical(a) ? 0 : 1;
      const bCrit = isPlotCritical(b) ? 0 : 1;
      return aCrit - bCrit;
    });
  }, [plots]);

  const [selectedPlotId, setSelectedPlotId] = useState<string>('');
  const [queryPrompt, setQueryPrompt] = useState<string>(
    'Susun keputusan pemulihan pH asam, mitigasi kekeringan, serta alokasi pupuk & pompa darurat.'
  );
  const [synthesis, setSynthesis] = useState<RagSynthesisResult | null>(null);
  const [decisionSummary, setDecisionSummary] = useState<string>('');
  const [actionPlan, setActionPlan] = useState<string>('');
  const [sendToDinas, setSendToDinas] = useState<boolean>(true);
  const [sendToFarmers, setSendToFarmers] = useState<boolean>(true);
  const [isSynthesizing, setIsSynthesizing] = useState<boolean>(false);
  const [isDispatching, setIsDispatching] = useState<boolean>(false);
  const [reports, setReports] = useState<DecisionReportRecord[]>([]);
  const [isLoadingReports, setIsLoadingReports] = useState<boolean>(true);

  useEffect(() => {
    if (!selectedPlotId && sortedPlots.length > 0) {
      setSelectedPlotId(String(sortedPlots[0].id));
    }
  }, [selectedPlotId, sortedPlots]);

  const selectedPlot = useMemo(
    () => sortedPlots.find((p) => String(p.id) === String(selectedPlotId)) || sortedPlots[0] || null,
    [sortedPlots, selectedPlotId]
  );

  const loadReports = useCallback(async () => {
    setIsLoadingReports(true);
    try {
      const list = await fetchDecisionReports({ role: 'penyuluh' });
      setReports(list);
    } catch (err) {
      console.error('[RAG_UI] Failed to load decision history:', err);
    } finally {
      setIsLoadingReports(false);
    }
  }, []);

  useEffect(() => {
    void loadReports();
  }, [loadReports]);

  const handleSynthesize = async () => {
    setIsSynthesizing(true);
    try {
      const res = await generateRagDecision({
        plot_id: selectedPlot ? selectedPlot.id : undefined,
        desa: selectedPlot?.nama_desa || 'Dungkek',
        kecamatan: selectedPlot?.kecamatan || 'Dungkek',
        komoditas: selectedPlot?.komoditas || 'Bawang Merah',
        query_prompt: queryPrompt.trim(),
      });
      setSynthesis(res);
      setDecisionSummary(res.decision_summary);
      setActionPlan(res.action_plan);
      onShowToast?.(
        `Sintesis RAG untuk Desa ${res.desa} berhasil digenerasi dari data telemetri langsung.`,
        'info'
      );
    } catch (err) {
      onShowToast?.(
        err instanceof Error ? err.message : 'Gagal menghasilkan sintesis RAG.',
        'error'
      );
    } finally {
      setIsSynthesizing(false);
    }
  };

  const handleDispatch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!sendToDinas && !sendToFarmers) {
      onShowToast?.('Pilih minimal satu tujuan pengiriman (Dinas Pertanian atau Petani).', 'error');
      return;
    }
    if (!decisionSummary.trim() || !actionPlan.trim()) {
      onShowToast?.('Ringkasan keputusan dan rencana aksi tidak boleh kosong.', 'error');
      return;
    }

    const target_scope: 'BOTH' | 'DINAS_ONLY' | 'FARMERS_ONLY' =
      sendToDinas && sendToFarmers
        ? 'BOTH'
        : sendToDinas
          ? 'DINAS_ONLY'
          : 'FARMERS_ONLY';

    setIsDispatching(true);
    try {
      await dispatchRagDecision({
        plot_id: selectedPlot ? selectedPlot.id : synthesis?.plot_id,
        desa: selectedPlot?.nama_desa || synthesis?.desa || 'Dungkek',
        kecamatan: selectedPlot?.kecamatan || synthesis?.kecamatan || 'Sumenep',
        komoditas: selectedPlot?.komoditas || synthesis?.komoditas || 'Hortikultura',
        rag_context: (synthesis?.rag_context as unknown as Record<string, unknown>) || {
          desa: selectedPlot?.nama_desa,
          ph: selectedPlot?.ph,
          moisture: selectedPlot?.moisture,
          fertility: selectedPlot?.fertility,
        },
        decision_summary: decisionSummary.trim(),
        action_plan: actionPlan.trim(),
        target_scope,
      });

      onShowToast?.(
        `Keputusan RAG Desa ${selectedPlot?.nama_desa || 'Sumenep'} berhasil dikirim (${SCOPE_LABELS[target_scope].text})!`,
        'success'
      );
      await loadReports();
      onRefresh();
    } catch (err) {
      onShowToast?.(
        err instanceof Error ? err.message : 'Gagal mengirim keputusan RAG.',
        'error'
      );
    } finally {
      setIsDispatching(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header Banner */}
      <section className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-[#0D5136] via-[#166534] to-[#14532d] text-white p-6 shadow-lg shadow-emerald-950/15">
        <div className="relative z-10 flex flex-wrap items-start justify-between gap-4">
          <div className="max-w-2xl space-y-1.5">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 border border-white/15 text-[11px] font-bold text-emerald-100">
              <span className="material-symbols-outlined text-[15px] text-[#22C55E]">psychology</span>
              Eksklusif Penyuluh BPP · Kabupaten Sumenep
            </div>
            <h1 className="text-2xl font-extrabold tracking-tight">
              AI Decision Support (RAG) &amp; Pengiriman Arahan Ganda
            </h1>
            <p className="text-emerald-100/90 text-[13px] leading-relaxed">
              Ambil konteks langsung dari sensor 8-in-1, laporan hama OPT, dan catatan harian petani, lalu kirimkan keputusan agronomis ke Dinas Pertanian maupun Petani/Poktan di aplikasi mobile.
            </p>
          </div>
          {selectedPlot && (
            <button
              type="button"
              onClick={() => onInspectPlot(selectedPlot)}
              className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-white/15 hover:bg-white/25 text-white border border-white/20 text-[12.5px] font-bold"
            >
              <span className="material-symbols-outlined text-[17px]">visibility</span>
              Inspeksi Lahan Desa {selectedPlot.nama_desa}
            </button>
          )}
        </div>
      </section>

      {/* Main Split Workbench */}
      <div className="grid grid-cols-1 xl:grid-cols-12 gap-6 items-start">
        {/* Left: Retrieval Context & Synthesizer */}
        <div className="xl:col-span-5 bg-white rounded-2xl border border-[#E2E8F0] p-5 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-[14px] font-extrabold text-gray-900 uppercase tracking-wide">
              1. Konteks Telemetri Lahan (Retrieval)
            </h2>
            <span className="px-2.5 py-0.5 rounded-full bg-emerald-50 text-[#166534] text-[11px] font-extrabold">
              {sortedPlots.length} Plot Terpantau
            </span>
          </div>

          <div>
            <label className="block text-[11.5px] font-bold text-gray-600 uppercase mb-1.5">
              Pilih Plot Lahan / Desa Target
            </label>
            <select
              value={selectedPlotId}
              onChange={(e) => setSelectedPlotId(e.target.value)}
              className="w-full px-3 py-2.5 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0] text-[13px] font-bold text-gray-800 focus:border-[#166534] outline-none"
            >
              {sortedPlots.map((p) => (
                <option key={p.id} value={String(p.id)}>
                  {isPlotCritical(p) ? '⚠️ KRITIS · ' : ''}Desa {p.nama_desa} (Kec. {p.kecamatan || 'Sumenep'}) — {p.komoditas} [pH {p.ph}, Lengas {p.moisture}%]
                </option>
              ))}
            </select>
          </div>

          {selectedPlot && (
            <div className="p-4 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0] space-y-2.5">
              <div className="flex items-center justify-between">
                <span className="text-[13px] font-extrabold text-[#0D5136]">
                  Desa {selectedPlot.nama_desa}, Kec. {selectedPlot.kecamatan || 'Sumenep'}
                </span>
                <span
                  className={`px-2 py-0.5 rounded-full text-[10.5px] font-extrabold ${
                    isPlotCritical(selectedPlot)
                      ? 'bg-rose-100 text-rose-800'
                      : 'bg-emerald-100 text-[#166534]'
                  }`}
                >
                  {isPlotCritical(selectedPlot) ? 'BUTUH INTERVENSI SEGERA' : 'TERPANTAU'}
                </span>
              </div>
              <div className="grid grid-cols-3 gap-2 text-[11.5px]">
                <div className="p-2 rounded-lg bg-white border border-[#E2E8F0]">
                  <span className="text-gray-500 block text-[10px] font-bold">pH Tanah</span>
                  <span className="font-mono font-extrabold text-gray-900">{selectedPlot.ph}</span>
                </div>
                <div className="p-2 rounded-lg bg-white border border-[#E2E8F0]">
                  <span className="text-gray-500 block text-[10px] font-bold">Kelembapan</span>
                  <span className="font-mono font-extrabold text-gray-900">{selectedPlot.moisture}%</span>
                </div>
                <div className="p-2 rounded-lg bg-white border border-[#E2E8F0]">
                  <span className="text-gray-500 block text-[10px] font-bold">Fertilitas</span>
                  <span className="font-mono font-extrabold text-gray-900">{selectedPlot.fertility}/100</span>
                </div>
                <div className="p-2 rounded-lg bg-white border border-[#E2E8F0]">
                  <span className="text-gray-500 block text-[10px] font-bold">NPK (mg/kg)</span>
                  <span className="font-mono font-bold text-gray-800">
                    {selectedPlot.nitrogen}/{selectedPlot.phosphorus}/{selectedPlot.potassium}
                  </span>
                </div>
                <div className="p-2 rounded-lg bg-white border border-[#E2E8F0]">
                  <span className="text-gray-500 block text-[10px] font-bold">EC / Konduktivitas</span>
                  <span className="font-mono font-bold text-gray-800">{selectedPlot.conductivity} uS</span>
                </div>
                <div className="p-2 rounded-lg bg-white border border-[#E2E8F0]">
                  <span className="text-gray-500 block text-[10px] font-bold">Kondisi Air</span>
                  <span className="font-bold text-gray-800 capitalize">{selectedPlot.kondisi_air}</span>
                </div>
              </div>
              <div className="text-[11.5px] text-gray-600">
                <strong>Poktan:</strong> {selectedPlot.kelompok_tani || 'Mandiri'} ·{' '}
                <strong>Penginput:</strong> {selectedPlot.tipe_penginput || 'petani'}
              </div>
            </div>
          )}

          <div>
            <label className="block text-[11.5px] font-bold text-gray-600 uppercase mb-1.5">
              Fokus Pertanyaan Agronomi PPL (Opsional)
            </label>
            <textarea
              rows={2}
              value={queryPrompt}
              onChange={(e) => setQueryPrompt(e.target.value)}
              className="w-full px-3 py-2 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0] text-[12.5px] text-gray-800 focus:border-[#166534] outline-none"
            />
          </div>

          <button
            type="button"
            onClick={handleSynthesize}
            disabled={isSynthesizing}
            className="w-full py-2.5 px-4 rounded-xl bg-[#F59E0B] hover:bg-amber-500 text-white font-extrabold text-[13px] flex items-center justify-center gap-2 shadow-sm transition-all disabled:opacity-60"
          >
            <span className={`material-symbols-outlined text-[18px] ${isSynthesizing ? 'animate-spin' : ''}`}>
              {isSynthesizing ? 'progress_activity' : 'auto_awesome'}
            </span>
            <span>{isSynthesizing ? 'Mengambil & Menyintesis RAG...' : 'Sintesis Keputusan Agronomi (RAG)'}</span>
          </button>

          {synthesis && (
            <div className="p-3 rounded-xl bg-emerald-50 border border-emerald-200 text-[11.5px] text-[#0D5136] space-y-1">
              <div className="font-extrabold flex items-center gap-1.5">
                <span className="material-symbols-outlined text-[16px]">verified</span>
                Sumber RAG Terhubung ({synthesis.synthesizer_engine})
              </div>
              <div>
                • {synthesis.rag_context.related_plots_count} plot desa ·{' '}
                {synthesis.rag_context.pest_alerts.length} peringatan OPT ·{' '}
                {synthesis.rag_context.farmer_daily_logs.length} log harian petani
              </div>
            </div>
          )}
        </div>

        {/* Right: Dual-Target Composer & Dispatch */}
        <form
          onSubmit={handleDispatch}
          className="xl:col-span-7 bg-white rounded-2xl border border-[#E2E8F0] p-5 shadow-sm space-y-4"
        >
          <div className="flex items-center justify-between">
            <h2 className="text-[14px] font-extrabold text-gray-900 uppercase tracking-wide">
              2. Finalisasi &amp; Distribusi Tujuan Ganda
            </h2>
            <span className="text-[11px] font-bold text-gray-500">
              Terverifikasi oleh Role: Penyuluh
            </span>
          </div>

          <div>
            <label className="block text-[11.5px] font-bold text-gray-700 uppercase mb-1.5">
              Ringkasan Keputusan Masalah (Problem-Solving Summary)
            </label>
            <textarea
              rows={3}
              required
              value={decisionSummary}
              onChange={(e) => setDecisionSummary(e.target.value)}
              placeholder="Klik 'Sintesis Keputusan Agronomi (RAG)' di sebelah kiri atau tulis keputusan agronomis..."
              className="w-full px-3.5 py-2.5 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0] text-[13px] text-gray-900 focus:bg-white focus:border-[#166534] outline-none"
            />
          </div>

          <div>
            <label className="block text-[11.5px] font-bold text-gray-700 uppercase mb-1.5">
              Rencana Aksi Teknis &amp; Kebutuhan Sarpras (Dinas / Petani)
            </label>
            <textarea
              rows={6}
              required
              value={actionPlan}
              onChange={(e) => setActionPlan(e.target.value)}
              placeholder="Rincian langkah teknis untuk petani (dosis Dolomit/NPK/mulsa) serta pengajuan dukungan ke Dinas Pertanian..."
              className="w-full px-3.5 py-2.5 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0] text-[13px] text-gray-900 focus:bg-white focus:border-[#166534] outline-none"
            />
          </div>

          {/* Dual-Target Checkboxes */}
          <div className="p-4 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0] space-y-2.5">
            <div className="text-[11.5px] font-extrabold text-[#0D5136] uppercase tracking-wider">
              Target Penerima Keputusan (Bisa Pilih Keduanya)
            </div>
            <label className="flex items-start gap-3 p-2.5 rounded-xl bg-white border border-[#E2E8F0] cursor-pointer hover:border-[#166534]">
              <input
                type="checkbox"
                checked={sendToDinas}
                onChange={(e) => setSendToDinas(e.target.checked)}
                className="mt-0.5 w-4 h-4 accent-[#166534]"
              />
              <div>
                <div className="text-[13px] font-bold text-gray-900">
                  Kirim ke Dinas Pertanian Kab. Sumenep
                </div>
                <div className="text-[11.5px] text-gray-500">
                  Masuk ke Kotak Masuk Eskalasi Kebijakan Pemerintah untuk persetujuan subsidi pupuk, pompa, dan irigasi.
                </div>
              </div>
            </label>

            <label className="flex items-start gap-3 p-2.5 rounded-xl bg-white border border-[#E2E8F0] cursor-pointer hover:border-[#166534]">
              <input
                type="checkbox"
                checked={sendToFarmers}
                onChange={(e) => setSendToFarmers(e.target.checked)}
                className="mt-0.5 w-4 h-4 accent-[#166534]"
              />
              <div>
                <div className="text-[13px] font-bold text-gray-900">
                  Kirim ke Petani / Poktan Desa Terkait
                </div>
                <div className="text-[11.5px] text-gray-500">
                  Tampil langsung di dashboard HP Petani (&ldquo;Arahan &amp; Keputusan Penyuluh&rdquo;) dan terkirim sebagai Kartu Arahan DM.
                </div>
              </div>
            </label>
          </div>

          <button
            type="submit"
            disabled={isDispatching}
            className="w-full py-3 px-4 rounded-xl bg-[#166534] hover:bg-[#0D5136] text-white font-extrabold text-[13.5px] flex items-center justify-center gap-2 shadow-md transition-all disabled:opacity-60"
          >
            <span className="material-symbols-outlined text-[19px]">send</span>
            <span>{isDispatching ? 'Mengirim Keputusan...' : 'Kirim Keputusan RAG Sekarang'}</span>
          </button>
        </form>
      </div>

      {/* Dispatched History Table */}
      <div className="bg-white rounded-2xl border border-[#E2E8F0] shadow-sm overflow-hidden">
        <div className="px-5 py-4 border-b border-[#E2E8F0] bg-[#F8FAF9] flex flex-wrap items-center justify-between gap-2">
          <div>
            <h2 className="text-[14px] font-extrabold text-gray-900 uppercase tracking-wide">
              Riwayat Keputusan RAG Terkirim
            </h2>
            <p className="text-[12px] text-gray-500">
              Pantau status pembacaan oleh Dinas Pertanian dan penerapan oleh Petani Desa
            </p>
          </div>
          <button
            type="button"
            onClick={() => void loadReports()}
            className="px-3 py-1.5 rounded-xl bg-white border border-[#E2E8F0] hover:border-[#166534] text-[12px] font-bold text-gray-700"
          >
            Muat Ulang
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-[12.5px] text-left">
            <thead className="bg-[#F8FAF9] text-gray-600 uppercase text-[11px] font-extrabold border-b border-[#E2E8F0]">
              <tr>
                <th className="px-4 py-3">Desa / Komoditas</th>
                <th className="px-4 py-3">Ringkasan Keputusan</th>
                <th className="px-3 py-3">Target Distribusi</th>
                <th className="px-3 py-3">Status Dinas / Petani</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#F1F5F9]">
              {isLoadingReports ? (
                <tr>
                  <td colSpan={4} className="px-4 py-6 text-center text-gray-500">
                    Memuat riwayat keputusan RAG...
                  </td>
                </tr>
              ) : reports.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-4 py-6 text-center text-gray-500">
                    Belum ada keputusan RAG yang dikirimkan.
                  </td>
                </tr>
              ) : (
                reports.map((rep) => {
                  const scopeMeta = SCOPE_LABELS[rep.target_scope] || SCOPE_LABELS.BOTH;
                  return (
                    <tr key={rep.id} className="hover:bg-[#F8FAF9] align-top">
                      <td className="px-4 py-3 font-extrabold text-[#0D5136] whitespace-nowrap">
                        Desa {rep.desa}
                        <span className="block text-[11px] font-normal text-gray-500">
                          Kec. {rep.kecamatan} · {rep.komoditas}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-gray-800 max-w-md">
                        <div className="font-bold">{rep.decision_summary}</div>
                        <pre className="mt-1 whitespace-pre-wrap font-sans text-[11.5px] text-gray-600">
                          {rep.action_plan}
                        </pre>
                        {rep.dinas_notes && (
                          <div className="mt-1.5 px-2.5 py-1 rounded-lg bg-amber-50 border border-amber-200 text-[11px] text-amber-900">
                            <strong>Catatan Dinas:</strong> {rep.dinas_notes}
                          </div>
                        )}
                      </td>
                      <td className="px-3 py-3 whitespace-nowrap">
                        <span className={`px-2.5 py-1 rounded-full text-[10.5px] font-extrabold border ${scopeMeta.cls}`}>
                          {scopeMeta.text}
                        </span>
                      </td>
                      <td className="px-3 py-3 whitespace-nowrap">
                        <span
                          className={`px-2.5 py-1 rounded-full text-[10.5px] font-extrabold ${
                            rep.status === 'REVIEWED'
                              ? 'bg-emerald-100 text-[#166534]'
                              : rep.status === 'ACKNOWLEDGED'
                                ? 'bg-sky-100 text-sky-800'
                                : 'bg-gray-100 text-gray-700'
                          }`}
                        >
                          {rep.status}
                        </span>
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
