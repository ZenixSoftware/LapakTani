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
    <section className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-[#0b3b28] via-[#114b35] to-[#134e38] text-white p-6 lg:p-8 shadow-lg shadow-emerald-950/20">
      {/* Subtle graphic background watermark */}
      <div className="absolute -right-12 -top-12 w-64 h-64 rounded-full bg-emerald-400/10 blur-2xl pointer-events-none"></div>
      <div className="absolute right-8 bottom-0 opacity-10 pointer-events-none">
        <span className="material-symbols-outlined text-[180px]">agriculture</span>
      </div>

      <div className="relative z-10 flex flex-col xl:flex-row xl:items-center justify-between gap-6">
        <div className="max-w-2xl space-y-2">
          <div className="flex flex-wrap items-center gap-2">
            <span className="px-2.5 py-1 rounded-lg bg-primary/90 text-white font-extrabold text-[11px] uppercase tracking-wide">
              Modul Penyuluh US-06
            </span>
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 text-emerald-100 text-[12px] font-semibold backdrop-blur-sm border border-white/10">
              <span className="w-2 h-2 rounded-full bg-primary animate-pulse"></span>
              BPP Kabupaten Sumenep
            </span>
          </div>

          <h1 className="text-2xl lg:text-3xl font-extrabold tracking-tight text-white">
            Validasi &amp; Persetujuan Akun Petani
          </h1>

          <p className="text-emerald-100/85 text-[13px] lg:text-[14px] leading-relaxed">
            Verifikasi identitas NIK Dukcapil, Kartu Tani Kementan, pemetaan geofencing GPS batas lahan komoditas, serta mutasi persetujuan petani langsung ke katalog LapakTani.
          </p>
        </div>

        {/* Quick Action Buttons on Hero */}
        <div className="flex flex-wrap items-center gap-3">
          <button
            onClick={onSync}
            disabled={isSyncing}
            className="px-4 py-2.5 rounded-xl bg-white/10 hover:bg-white/20 text-white border border-white/20 font-bold text-[13px] flex items-center gap-2 backdrop-blur-md transition-all active:scale-95 disabled:opacity-50"
          >
            <span
              className={`material-symbols-outlined text-[18px] ${
                isSyncing ? 'animate-spin' : ''
              }`}
            >
              sync
            </span>
            <span>{isSyncing ? 'Menyinkronkan...' : 'Sinkronisasi Simluhtan'}</span>
          </button>
          <button
            onClick={onQuickReview}
            className="px-4 py-2.5 rounded-xl bg-primary hover:bg-primary-dark text-white font-bold text-[13px] flex items-center gap-2 shadow-lg shadow-emerald-950/30 transition-all active:scale-95"
          >
            <span className="material-symbols-outlined text-[18px]">fact_check</span>
            <span>Tinjau Prioritas Cepat</span>
          </button>
        </div>
      </div>

      {/* 4 Stat Badges within Hero */}
      <div className="mt-6 pt-6 border-t border-white/15 grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white/10 backdrop-blur-md rounded-xl p-3.5 border border-white/10">
          <span className="text-emerald-200 text-[11px] font-semibold block">Total Antrean</span>
          <div className="flex items-baseline gap-2 mt-1">
            <span className="text-2xl font-black text-white">{totalQueue}</span>
            <span className="text-[11px] font-bold text-amber-300">
              {totalQueue > 0 ? `${totalQueue} Butuh Cepat` : 'Antrean Bersih'}
            </span>
          </div>
        </div>
        <div className="bg-white/10 backdrop-blur-md rounded-xl p-3.5 border border-white/10">
          <span className="text-emerald-200 text-[11px] font-semibold block">Petani Aktif Binaan</span>
          <div className="flex items-baseline gap-2 mt-1">
            <span className="text-2xl font-black text-white">1.342</span>
            <span className="text-[11px] font-bold text-emerald-300">14 Poktan</span>
          </div>
        </div>
        <div className="bg-white/10 backdrop-blur-md rounded-xl p-3.5 border border-white/10">
          <span className="text-emerald-200 text-[11px] font-semibold block">Lahan Terpetakan</span>
          <div className="flex items-baseline gap-2 mt-1">
            <span className="text-2xl font-black text-white">542,8</span>
            <span className="text-[11px] font-bold text-white/80">Hektar (GPS)</span>
          </div>
        </div>
        <div className="bg-white/10 backdrop-blur-md rounded-xl p-3.5 border border-white/10">
          <span className="text-emerald-200 text-[11px] font-semibold block">Akurasi Dukcapil</span>
          <div className="flex items-baseline gap-2 mt-1">
            <span className="text-2xl font-black text-white">98,4%</span>
            <span className="text-[11px] font-bold text-emerald-300">Biometrik Match</span>
          </div>
        </div>
      </div>
    </section>
  );
};
