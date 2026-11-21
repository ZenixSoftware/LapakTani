import React from 'react';

interface HeroBannerProps {
  totalQueue: number;
  onSync: () => void;
  onQuickReview: () => void;
  isSyncing: boolean;
}

export const HeroBanner: React.FC<HeroBannerProps> = ({
  totalQueue,
  onSync,
  onQuickReview,
  isSyncing,
}) => {
  return (
    <section className="relative overflow-hidden rounded-2xl bg-lt-surface-card border border-lt-border border-l-4 border-l-lt-primary p-6 lg:p-8 shadow-sm">
      <div className="flex flex-col xl:flex-row xl:items-center justify-between gap-6">
        <div className="max-w-2xl space-y-2">
          <div className="flex flex-wrap items-center gap-2">
            <span className="px-2.5 py-1 rounded-lg bg-lt-primary-tint text-lt-primary border border-lt-primary-border font-extrabold text-[11px] uppercase tracking-wide">
              Modul Penyuluh US-06
            </span>
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-lt-surface-canvas text-lt-neutral-muted text-[12px] font-semibold border border-lt-border">
              <span className="w-2 h-2 rounded-full bg-lt-primary animate-pulse"></span>
              BPP Kabupaten Sumenep
            </span>
          </div>

          <h1 className="text-2xl lg:text-3xl font-extrabold tracking-tight text-lt-neutral">
            Validasi &amp; Persetujuan Akun Petani
          </h1>

          <p className="text-lt-neutral-muted text-[13px] lg:text-[14px] leading-relaxed">
            Verifikasi identitas NIK Dukcapil, Kartu Tani Kementan, pemetaan geofencing GPS batas lahan komoditas, serta mutasi persetujuan petani langsung ke katalog LapakTani.
          </p>
        </div>

        {/* Quick Action Buttons on Hero */}
        <div className="flex flex-wrap items-center gap-3">
          <button
            onClick={onSync}
            disabled={isSyncing}
            className="px-4 py-2.5 rounded-xl bg-lt-surface-card hover:bg-lt-surface-canvas text-lt-neutral border border-lt-border font-bold text-[13px] flex items-center gap-2 transition-all active:scale-95 disabled:opacity-50"
          >
            <span
              className={`material-symbols-outlined text-[18px] text-lt-primary ${
                isSyncing ? 'animate-spin' : ''
              }`}
            >
              sync
            </span>
            <span>{isSyncing ? 'Menyinkronkan...' : 'Sinkronisasi Simluhtan'}</span>
          </button>
          <button
            onClick={onQuickReview}
            className="px-4 py-2.5 rounded-xl bg-lt-primary hover:bg-lt-primary-dark text-white font-bold text-[13px] flex items-center gap-2 shadow-sm transition-all active:scale-95"
          >
            <span className="material-symbols-outlined text-[18px]">fact_check</span>
            <span>Tinjau Prioritas Cepat</span>
          </button>
        </div>
      </div>

      {/* 4 Stat Badges within Hero */}
      <div className="mt-6 pt-6 border-t border-lt-border grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-lt-surface-canvas rounded-xl p-3.5 border border-lt-border">
          <span className="text-lt-neutral-muted text-[11px] font-semibold block">Total Antrean</span>
          <div className="flex items-baseline gap-2 mt-1">
            <span className="text-2xl font-black text-lt-neutral">{totalQueue}</span>
            <span className="text-[11px] font-bold text-lt-tertiary-text">
              {totalQueue > 0 ? `${totalQueue} Butuh Cepat` : 'Antrean Bersih'}
            </span>
          </div>
        </div>
        <div className="bg-lt-surface-canvas rounded-xl p-3.5 border border-lt-border">
          <span className="text-lt-neutral-muted text-[11px] font-semibold block">Petani Aktif Binaan</span>
          <div className="flex items-baseline gap-2 mt-1">
            <span className="text-2xl font-black text-lt-neutral">1.342</span>
            <span className="text-[11px] font-bold text-lt-primary">14 Poktan</span>
          </div>
        </div>
        <div className="bg-lt-surface-canvas rounded-xl p-3.5 border border-lt-border">
          <span className="text-lt-neutral-muted text-[11px] font-semibold block">Lahan Terpetakan</span>
          <div className="flex items-baseline gap-2 mt-1">
            <span className="text-2xl font-black text-lt-neutral">542,8</span>
            <span className="text-[11px] font-bold text-lt-neutral-muted">Hektar (GPS)</span>
          </div>
        </div>
        <div className="bg-lt-surface-canvas rounded-xl p-3.5 border border-lt-border">
          <span className="text-lt-neutral-muted text-[11px] font-semibold block">Akurasi Dukcapil</span>
          <div className="flex items-baseline gap-2 mt-1">
            <span className="text-2xl font-black text-lt-neutral">98,4%</span>
            <span className="text-[11px] font-bold text-lt-secondary">Biometrik Match</span>
          </div>
        </div>
      </div>
    </section>
  );
};
