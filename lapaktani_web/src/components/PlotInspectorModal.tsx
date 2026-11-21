import React, { useEffect, useState } from 'react';
import {
  resolveImageUrl,
  submitPplPlotRecommendation,
  type LandPlotRecord,
} from '../services/api';
import { getPlotFertilityStatus } from '../utils/monitoringHelpers';

interface PlotInspectorModalProps {
  plot: LandPlotRecord | null;
  readOnly?: boolean;
  onClose: () => void;
  onPlotUpdated?: (updated: LandPlotRecord) => void;
  onShowToast?: (message: string, type?: 'success' | 'error' | 'info') => void;
}

export const PlotInspectorModal: React.FC<PlotInspectorModalProps> = ({
  plot,
  readOnly = false,
  onClose,
  onPlotUpdated,
  onShowToast,
}) => {
  const [recommendationText, setRecommendationText] = useState('');
  const [verificationStatus, setVerificationStatus] = useState<'verified' | 'needs_action' | 'pending'>('verified');
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (!plot) return;
    setRecommendationText(plot.rekomendasi_ppl || '');
    const st = plot.status_verifikasi_ppl;
    setVerificationStatus(
      st === 'needs_action' || st === 'pending' || st === 'verified' ? st : 'verified'
    );
  }, [plot]);

  if (!plot) return null;

  const fertilityStatus = getPlotFertilityStatus(plot);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      const updated = await submitPplPlotRecommendation(
        plot.id,
        recommendationText.trim(),
        verificationStatus
      );
      onPlotUpdated?.(updated);
      onShowToast?.(
        `Rekomendasi agronomis PPL untuk Desa ${updated.nama_desa} berhasil disimpan!`,
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

  return (
    <div
      className="fixed inset-0 z-50 flex justify-end bg-black/45 backdrop-blur-[2px]"
      onClick={onClose}
    >
      <div
        className="w-full max-w-xl bg-white h-full shadow-2xl border-l border-lt-border flex flex-col overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Top Drawer Header */}
        <div className="bg-lt-surface-card border-b border-lt-border border-l-4 border-l-lt-primary px-6 py-4 flex items-start justify-between gap-4">
          <div>
            <div className="flex items-center gap-2">
              <span className="px-2 py-0.5 rounded bg-lt-primary-tint text-lt-primary text-[10px] font-bold uppercase tracking-wider border border-lt-primary-border">
                Inspektor Lahan #{plot.id}
              </span>
              <span
                className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider ${
                  fertilityStatus === 'kritis'
                    ? 'bg-lt-error text-white'
                    : fertilityStatus === 'optimal'
                      ? 'bg-lt-primary text-white'
                      : 'bg-lt-tertiary text-lt-neutral'
                }`}
              >
                {fertilityStatus === 'kritis'
                  ? 'Titik Kritis'
                  : fertilityStatus === 'optimal'
                    ? 'Kesuburan Optimal'
                    : 'Kesuburan Sedang'}
              </span>
            </div>
            <h2 className="text-xl font-extrabold text-lt-neutral mt-1.5">
              Desa {plot.nama_desa}
              {plot.kecamatan ? `, Kec. ${plot.kecamatan}` : ''}
            </h2>
            <p className="text-[12px] text-lt-neutral-muted mt-0.5">
              {plot.kelompok_tani || 'Mandiri'} · Komoditas {plot.komoditas}
              {plot.varietas ? ` (${plot.varietas})` : ''}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="p-1.5 rounded-lg bg-lt-surface-canvas hover:bg-lt-border text-lt-neutral border border-lt-border transition-colors"
            aria-label="Tutup inspektor"
          >
            <span className="material-symbols-outlined text-[20px]">close</span>
          </button>
        </div>

        {/* Drawer Body */}
        <div className="flex-1 overflow-y-auto p-6 space-y-5 custom-scrollbar bg-lt-surface-canvas">
          {/* Location & Maps Action Bar */}
          <div className="bg-white rounded-2xl border border-lt-border p-4 flex flex-wrap items-center justify-between gap-3">
            <div>
              <div className="text-[11px] font-bold uppercase tracking-wider text-lt-neutral-subtle">
                Koordinat Spasial GPS
              </div>
              <div className="font-mono text-[13px] font-bold text-lt-neutral mt-0.5">
                {plot.latitude}, {plot.longitude}
              </div>
            </div>
            <a
              href={`https://www.google.com/maps?q=${plot.latitude},${plot.longitude}`}
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-lt-primary hover:bg-lt-primary-dark text-white text-[12px] font-bold transition-colors"
            >
              <span className="material-symbols-outlined text-[16px]">map</span>
              Buka Google Maps
            </a>
          </div>

          {/* 8-in-1 Telemetry Grid */}
          <div className="bg-white rounded-2xl border border-lt-border p-4">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-[12px] font-extrabold text-lt-neutral-muted uppercase tracking-wider">
                Pembacaan Sensor Tanah 8-in-1
              </h3>
              <span className="text-[11px] font-bold text-lt-primary bg-lt-primary-tint px-2 py-0.5 rounded-md border border-lt-primary-border">
                Telemetry Live
              </span>
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
              {[
                { label: 'Suhu Tanah', value: `${plot.temp}°C`, warn: Number(plot.temp) > 35 },
                { label: 'Kelembaban', value: `${plot.moisture}%`, warn: Number(plot.moisture) < 15 },
                { label: 'EC Tanah', value: `${plot.conductivity} uS`, warn: false },
                {
                  label: 'pH Tanah',
                  value: `${plot.ph}`,
                  warn: Number(plot.ph) < 5.5 || Number(plot.ph) > 7.5,
                },
                { label: 'Nitrogen (N)', value: `${plot.nitrogen} mg/kg`, warn: Number(plot.nitrogen) < 5 },
                { label: 'Fosfor (P)', value: `${plot.phosphorus} mg/kg`, warn: false },
                { label: 'Kalium (K)', value: `${plot.potassium} mg/kg`, warn: false },
                { label: 'Fertilitas', value: `${plot.fertility}/100`, warn: Number(plot.fertility) < 20 },
              ].map((m) => (
                <div
                  key={m.label}
                  className={`p-3 rounded-xl border ${
                    m.warn
                      ? 'bg-lt-error-tint border-lt-error-border text-lt-error'
                      : 'bg-lt-surface-canvas border-lt-border text-lt-neutral'
                  }`}
                >
                  <div className="text-[10px] font-bold uppercase tracking-wide opacity-70">
                    {m.label}
                  </div>
                  <div className="text-[14px] font-extrabold mt-0.5 font-mono">{m.value}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Infrastructure & Agronomy Conditions */}
          <div className="bg-white rounded-2xl border border-lt-border p-4 space-y-3">
            <h3 className="text-[12px] font-extrabold text-lt-neutral-muted uppercase tracking-wider">
              Infrastruktur Air, Listrik &amp; Budidaya
            </h3>
            <div className="grid grid-cols-2 gap-2.5 text-[12px]">
              <div className="p-2.5 rounded-xl bg-lt-surface-canvas border border-lt-border">
                <span className="text-lt-neutral-muted block text-[10px] font-bold uppercase">Irigasi &amp; Tadahan</span>
                <span className="font-bold text-lt-neutral">
                  Irigasi: {plot.irigasi} · Tadahan: {plot.tadahan_hujan || '-'}
                </span>
              </div>
              <div className="p-2.5 rounded-xl bg-lt-surface-canvas border border-lt-border">
                <span className="text-lt-neutral-muted block text-[10px] font-bold uppercase">Pompa &amp; Energi</span>
                <span className="font-bold text-lt-neutral">
                  Pompa: {plot.pompa_air} ({plot.sumber_energi_pompa || '-'})
                </span>
              </div>
              <div className="p-2.5 rounded-xl bg-lt-surface-canvas border border-lt-border">
                <span className="text-lt-neutral-muted block text-[10px] font-bold uppercase">Listrik &amp; Kondisi Air</span>
                <span className="font-bold text-lt-neutral">
                  Listrik: {plot.listrik} · Air: {plot.sumber_air} ({plot.kondisi_air})
                </span>
              </div>
              <div className="p-2.5 rounded-xl bg-lt-surface-canvas border border-lt-border">
                <span className="text-lt-neutral-muted block text-[10px] font-bold uppercase">Pembajak &amp; Luas Lahan</span>
                <span className="font-bold text-lt-neutral">
                  {plot.pembajak} · {plot.luas_lahan} ({plot.status_lahan})
                </span>
              </div>
            </div>
          </div>

          {/* Field Evidence Photos */}
          {(plot.foto_daun || plot.foto_pohon || plot.foto_tanah) && (
            <div className="bg-white rounded-2xl border border-lt-border p-4">
              <h3 className="text-[12px] font-extrabold text-lt-neutral-muted uppercase tracking-wider mb-2.5">
                Dokumentasi Foto Lapangan (3 Sudut)
              </h3>
              <div className="grid grid-cols-3 gap-2.5">
                {[
                  { label: 'Daun', url: plot.foto_daun },
                  { label: 'Pohon', url: plot.foto_pohon },
                  { label: 'Tanah', url: plot.foto_tanah },
                ].map((photo) => {
                  const resolved = resolveImageUrl(photo.url);
                  return resolved ? (
                    <a
                      key={photo.label}
                      href={resolved}
                      target="_blank"
                      rel="noreferrer"
                      className="group relative rounded-xl overflow-hidden border border-lt-border aspect-square bg-lt-surface-canvas"
                    >
                      <img src={resolved} alt={photo.label} className="w-full h-full object-cover" />
                      <span className="absolute bottom-1.5 left-1.5 px-2 py-0.5 rounded bg-black/65 text-white text-[10px] font-bold">
                        {photo.label}
                      </span>
                    </a>
                  ) : null;
                })}
              </div>
            </div>
          )}

          {/* PPL Agronomic Recommendation Form (editable by Penyuluh, read-only for Dinas) */}
          {readOnly ? (
            <div className="bg-white rounded-2xl border border-lt-border p-4 space-y-2">
              <div className="flex items-center justify-between gap-2">
                <span className="text-[12px] font-extrabold text-lt-neutral uppercase tracking-wider">
                  Catatan Agronomis Penyuluh BPP
                </span>
                <span className="px-2.5 py-0.5 rounded-full bg-lt-primary-tint text-lt-primary text-[11px] font-bold">
                  Mode Pantau Dinas (Read-Only)
                </span>
              </div>
              <p className="text-[13px] text-lt-neutral bg-lt-surface-canvas p-3 rounded-xl border border-lt-border">
                {plot.rekomendasi_ppl || 'Belum ada catatan rekomendasi dari Penyuluh BPP.'}
              </p>
            </div>
          ) : (
            <form
              onSubmit={handleSubmit}
              className="bg-white rounded-2xl border border-lt-border p-4 space-y-3"
            >
              <div className="flex items-center justify-between gap-2">
                <label className="text-[12px] font-extrabold text-lt-neutral uppercase tracking-wider">
                  Rekomendasi Agronomis PPL
                </label>
                <select
                  value={verificationStatus}
                  onChange={(e) =>
                    setVerificationStatus(e.target.value as 'verified' | 'needs_action' | 'pending')
                  }
                  className="px-2.5 py-1.5 rounded-lg border border-lt-border text-[12px] font-bold bg-lt-surface-canvas"
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
                placeholder="Tulis rekomendasi dosis pupuk berimbang (NPK/Urea/Dolomit), pengairan pompa, atau tindak lanjut lapangan..."
                className="w-full px-3 py-2.5 text-[13px] rounded-xl border border-lt-border bg-lt-surface-canvas focus:outline-none focus:ring-2 focus:ring-lt-primary/35 focus:border-lt-primary"
              />

              <button
                type="submit"
                disabled={isSubmitting}
                className="w-full py-2.5 px-4 rounded-xl bg-lt-primary hover:bg-lt-primary-dark text-white font-bold text-[13px] flex items-center justify-center gap-2 transition-all disabled:opacity-60 shadow-sm"
              >
                <span className="material-symbols-outlined text-[18px]">save</span>
                {isSubmitting ? 'Menyimpan...' : 'Simpan Rekomendasi PPL'}
              </button>
            </form>
          )}
        </div>
      </div>
    </div>
  );
};

