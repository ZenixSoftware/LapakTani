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
      <div className="p-5 rounded-2xl bg-lt-surface-card border-2 border-lt-border shadow-sm flex flex-col justify-between hover:-translate-y-0.5 transition-transform">
        <div className="flex items-start justify-between">
          <span className="text-xs font-bold uppercase tracking-wider text-lt-neutral-muted">Total Antrean</span>
          <span className="px-2.5 py-0.5 rounded-full bg-lt-primary-tint border border-lt-border text-lt-primary-dark text-[11px] font-extrabold flex items-center gap-1">
            <TrendingUp className="w-[13px] h-[13px]" /> +8 hari ini
          </span>
        </div>
        <div className="my-3 flex items-baseline gap-2">
          <span className="text-3xl md:text-4xl font-extrabold text-lt-neutral tracking-tight">{totalCount}</span>
          <span className="text-xs font-semibold text-lt-neutral-muted">Petani Terdaftar</span>
        </div>
        <div className="pt-2 border-t border-lt-border flex items-center justify-between text-[11px] text-lt-neutral-muted font-medium">
          <span className="flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-lt-primary"></span>
            Kec. Lembang &amp; Ciwidey
          </span>
          <Users className="w-[16px] h-[16px] text-lt-neutral-subtle" />
        </div>
      </div>

      {/* Bento Card 2: Menunggu Verifikasi KTP */}
      <div className="p-5 rounded-2xl bg-lt-tertiary-tint border-2 border-lt-border shadow-sm flex flex-col justify-between hover:-translate-y-0.5 transition-transform relative overflow-hidden">
        <div className="flex items-start justify-between">
          <span className="text-xs font-bold uppercase tracking-wider text-lt-tertiary-text">Menunggu KTP</span>
          <span className="px-2.5 py-0.5 rounded-full bg-white border border-lt-border text-lt-tertiary-text text-[11px] font-extrabold shadow-sm">
            Prioritas PPL
          </span>
        </div>
        <div className="my-3 flex items-baseline gap-2">
          <span className="text-3xl md:text-4xl font-extrabold text-lt-tertiary-text tracking-tight">{pendingCount}</span>
          <span className="text-xs font-semibold text-lt-tertiary-text">Berkas Dokumen</span>
        </div>
        <div className="pt-2 border-t border-lt-tertiary-border/60 flex items-center justify-between text-[11px] text-lt-tertiary-text font-medium">
          <span className="flex items-center gap-1">
            <Clock className="w-[15px] h-[15px]" />
            Rata-rata tunggu: 4.2 jam
          </span>
          <CreditCard className="w-[16px] h-[16px] text-lt-tertiary-text" />
        </div>
      </div>

      {/* Bento Card 3: Terverifikasi Minggu Ini */}
      <div className="p-5 rounded-2xl bg-lt-primary-tint border-2 border-lt-border shadow-sm flex flex-col justify-between hover:-translate-y-0.5 transition-transform">
        <div className="flex items-start justify-between">
          <span className="text-xs font-bold uppercase tracking-wider text-lt-primary">Terverifikasi</span>
          <span className="px-2.5 py-0.5 rounded-full bg-white border border-lt-border text-lt-primary text-[11px] font-extrabold shadow-sm">
            96% Target
          </span>
        </div>
        <div className="my-3 flex items-baseline gap-2">
          <span className="text-3xl md:text-4xl font-extrabold text-lt-primary-dark tracking-tight">{verifiedCount}</span>
          <span className="text-xs font-semibold text-lt-primary-dark">Akun Sukses</span>
        </div>
        <div className="pt-2 border-t border-lt-primary-border flex items-center justify-between text-[11px] text-lt-primary-dark font-medium">
          <span className="flex items-center gap-1">
            <CheckCircle2 className="w-[15px] h-[15px] text-lt-primary" />
            Siap jual di katalog
          </span>
          <Store className="w-[16px] h-[16px] text-lt-primary" />
        </div>
      </div>

      {/* Bento Card 4: Ditolak / Perlu Revisi */}
      <div className="p-5 rounded-2xl bg-lt-error-tint border-2 border-lt-border shadow-sm flex flex-col justify-between hover:-translate-y-0.5 transition-transform">
        <div className="flex items-start justify-between">
          <span className="text-xs font-bold uppercase tracking-wider text-lt-error">Perlu Revisi</span>
          <span className="px-2.5 py-0.5 rounded-full bg-white border border-lt-border text-lt-error text-[11px] font-extrabold shadow-sm">
            Tinjau Ulang
          </span>
        </div>
        <div className="my-3 flex items-baseline gap-2">
          <span className="text-3xl md:text-4xl font-extrabold text-lt-error tracking-tight">{rejectedCount}</span>
          <span className="text-xs font-semibold text-lt-error">Petani Perlu Respon</span>
        </div>
        <div className="pt-2 border-t border-lt-error-border flex items-center justify-between text-[11px] text-lt-error font-medium">
          <span className="flex items-center gap-1">
            <Info className="w-[15px] h-[15px]" />
            Foto KTP blur / NIK beda
          </span>
          <XCircle className="w-[16px] h-[16px] text-lt-error" />
        </div>
      </div>
    </section>
  );
};
