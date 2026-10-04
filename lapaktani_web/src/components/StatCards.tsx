import {
  TrendingUp,
  Users,
  Clock,
  CreditCard,
  CheckCircle2,
  Store,
  Info,
  XCircle
} from 'lucide-react';

interface StatCardsProps {
  totalCount?: number;
  pendingCount?: number;
  verifiedCount?: number;
  rejectedCount?: number;
}

export const StatCards = ({
  totalCount = 24,
  pendingCount = 14,
  verifiedCount = 48,
  rejectedCount = 3
}: StatCardsProps) => {
  return (
    <section className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 md:gap-5">
      {/* Bento Card 1: Total Antrean */}
      <div className="p-5 rounded-2xl bg-cream-50 border-2 border-brutal-border shadow-brutal flex flex-col justify-between hover:-translate-y-0.5 transition-transform">
        <div className="flex items-start justify-between">
          <span className="text-xs font-bold uppercase tracking-wider text-slate-500">Total Antrean</span>
          <span className="px-2.5 py-0.5 rounded-full bg-emerald-100 border border-brutal-border text-emerald-800 text-[11px] font-extrabold flex items-center gap-1">
            <TrendingUp className="w-[13px] h-[13px]" /> +8 hari ini
          </span>
        </div>
        <div className="my-3 flex items-baseline gap-2">
          <span className="text-3xl md:text-4xl font-extrabold text-brutal-dark tracking-tight">{totalCount}</span>
          <span className="text-xs font-semibold text-slate-500">Petani Terdaftar</span>
        </div>
        <div className="pt-2 border-t border-slate-200 flex items-center justify-between text-[11px] text-slate-600 font-medium">
          <span className="flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-brand"></span>
            Kec. Lembang &amp; Ciwidey
          </span>
          <Users className="w-[16px] h-[16px] text-slate-400" />
        </div>
      </div>

      {/* Bento Card 2: Menunggu Verifikasi KTP */}
      <div className="p-5 rounded-2xl bg-amberSoft/60 border-2 border-brutal-border shadow-brutal flex flex-col justify-between hover:-translate-y-0.5 transition-transform relative overflow-hidden">
        <div className="flex items-start justify-between">
          <span className="text-xs font-bold uppercase tracking-wider text-amber-900">Menunggu KTP</span>
          <span className="px-2.5 py-0.5 rounded-full bg-white border border-brutal-border text-amber-800 text-[11px] font-extrabold shadow-brutal-sm">
            Prioritas PPL
          </span>
        </div>
        <div className="my-3 flex items-baseline gap-2">
          <span className="text-3xl md:text-4xl font-extrabold text-amber-900 tracking-tight">{pendingCount}</span>
          <span className="text-xs font-semibold text-amber-800">Berkas Dokumen</span>
        </div>
        <div className="pt-2 border-t border-amber-300/60 flex items-center justify-between text-[11px] text-amber-900 font-medium">
          <span className="flex items-center gap-1">
            <Clock className="w-[15px] h-[15px]" />
            Rata-rata tunggu: 4.2 jam
          </span>
          <CreditCard className="w-[16px] h-[16px] text-amber-800" />
        </div>
      </div>

      {/* Bento Card 3: Terverifikasi Minggu Ini */}
      <div className="p-5 rounded-2xl bg-brand-light/70 border-2 border-brutal-border shadow-brutal flex flex-col justify-between hover:-translate-y-0.5 transition-transform">
        <div className="flex items-start justify-between">
          <span className="text-xs font-bold uppercase tracking-wider text-brand">Terverifikasi</span>
          <span className="px-2.5 py-0.5 rounded-full bg-white border border-brutal-border text-brand text-[11px] font-extrabold shadow-brutal-sm">
            96% Target
          </span>
        </div>
        <div className="my-3 flex items-baseline gap-2">
          <span className="text-3xl md:text-4xl font-extrabold text-emerald-900 tracking-tight">{verifiedCount}</span>
          <span className="text-xs font-semibold text-emerald-700">Akun Sukses</span>
        </div>
        <div className="pt-2 border-t border-emerald-200 flex items-center justify-between text-[11px] text-emerald-800 font-medium">
          <span className="flex items-center gap-1">
            <CheckCircle2 className="w-[15px] h-[15px] text-brand" />
            Siap jual di katalog
          </span>
          <Store className="w-[16px] h-[16px] text-brand" />
        </div>
      </div>

      {/* Bento Card 4: Ditolak / Perlu Revisi */}
      <div className="p-5 rounded-2xl bg-roseSoft/50 border-2 border-brutal-border shadow-brutal flex flex-col justify-between hover:-translate-y-0.5 transition-transform">
        <div className="flex items-start justify-between">
          <span className="text-xs font-bold uppercase tracking-wider text-rose-800">Perlu Revisi</span>
          <span className="px-2.5 py-0.5 rounded-full bg-white border border-brutal-border text-rose-700 text-[11px] font-extrabold shadow-brutal-sm">
            Tinjau Ulang
          </span>
        </div>
        <div className="my-3 flex items-baseline gap-2">
          <span className="text-3xl md:text-4xl font-extrabold text-rose-700 tracking-tight">{rejectedCount}</span>
          <span className="text-xs font-semibold text-rose-800">Petani Perlu Respon</span>
        </div>
        <div className="pt-2 border-t border-rose-200 flex items-center justify-between text-[11px] text-rose-700 font-medium">
          <span className="flex items-center gap-1">
            <Info className="w-[15px] h-[15px]" />
            Foto KTP blur / NIK beda
          </span>
          <XCircle className="w-[16px] h-[16px] text-rose-500" />
        </div>
      </div>
    </section>
  );
};
