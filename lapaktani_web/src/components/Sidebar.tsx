import {
  ShieldCheck,
  Users,
  Sprout,
  Warehouse,
  Bug,
  BarChart3,
  MapPin
} from 'lucide-react';

interface SidebarProps {
  pendingCount?: number;
}

export const Sidebar = ({ pendingCount = 8 }: SidebarProps) => {
  return (
    <aside className="w-full lg:w-72 bg-cream-50 border-b-2 lg:border-b-0 lg:border-r-2 border-brutal-border flex flex-col justify-between p-5 gap-6 shrink-0">
      <div className="flex flex-col gap-6">
        {/* Brand Header */}
        <div className="flex items-center gap-3 pb-4 border-b-2 border-brutal-border/20">
          <div className="w-11 h-11 rounded-2xl bg-white border-2 border-brutal-border shadow-brutal-sm p-1.5 flex items-center justify-center shrink-0">
            <img
              alt="LapakTani Logo"
              className="w-full h-full object-contain"
              src="https://lh3.googleusercontent.com/aida/AEtjO1VQze0EvKA8a8roaI9NmwEyjyCMesMY1G3wmXWDUz1wtxvqQjxvtPxtCPijNJBxFtGW5KZtMfznq0evuUB-TtnmVm-8ywNs24FjlT8DxNxjUQtHQgt5sjsLyGIwDrCnoVCGOS_slHs8Yw-ojX_Jori3qqLiLvqbMEEdT4usKZnebGUJsPCyyQaZTdAe0VemYRa9rnCQlu6RisDSEAdtzyagrsZZr0J3GE9A2JCh8L6MDp9OXDNwvQpmKL21"
            />
          </div>
          <div className="flex flex-col">
            <div className="flex items-center gap-1.5 flex-wrap">
              <span className="font-extrabold text-base tracking-tight text-brutal-dark">LapakTani</span>
              <span className="px-1.5 py-0.5 text-[9px] uppercase font-bold tracking-wide rounded-md bg-brand-light border border-brutal-border text-brand">ADMIN PPL</span>
            </div>
            <span className="text-[11px] text-slate-500 font-medium leading-tight mt-0.5">BPP Wilayah Lembang &amp; Ciwidey</span>
          </div>
        </div>

        {/* Vertical Navigation Menu */}
        <div className="flex flex-col gap-1.5">
          <span className="text-[10px] font-extrabold uppercase tracking-wider text-slate-400 px-3 mb-1">Menu Pengawasan</span>
          
          <a
            className="px-3.5 py-2.5 rounded-xl bg-brand text-white font-bold text-xs border-2 border-brutal-border shadow-brutal-sm flex items-center justify-between transition-all"
            href="#validasi"
          >
            <div className="flex items-center gap-2.5">
              <ShieldCheck className="w-[18px] h-[18px]" />
              <span>Validasi Petani</span>
            </div>
            <span className="px-2 py-0.5 rounded-full bg-white text-brand text-[10px] font-extrabold shadow-brutal-sm">
              {pendingCount}
            </span>
          </a>

          <a
            className="px-3.5 py-2.5 rounded-xl bg-white hover:bg-cream-100 text-slate-700 font-bold text-xs border border-brutal-border flex items-center gap-2.5 transition-colors"
            href="#poktan"
          >
            <Users className="w-[18px] h-[18px] text-slate-500" />
            <span>Data Poktan</span>
          </a>

          <a
            className="px-3.5 py-2.5 rounded-xl bg-white hover:bg-cream-100 text-slate-700 font-bold text-xs border border-brutal-border flex items-center gap-2.5 transition-colors"
            href="#komoditas"
          >
            <Sprout className="w-[18px] h-[18px] text-slate-500" />
            <span>Komoditas &amp; Mutu</span>
          </a>

          <a
            className="px-3.5 py-2.5 rounded-xl bg-white hover:bg-cream-100 text-slate-700 font-bold text-xs border border-brutal-border flex items-center gap-2.5 transition-colors"
            href="#storage"
          >
            <Warehouse className="w-[18px] h-[18px] text-slate-500" />
            <span>Log Storage</span>
          </a>

          <a
            className="px-3.5 py-2.5 rounded-xl bg-white hover:bg-cream-100 text-slate-700 font-bold text-xs border border-brutal-border flex items-center gap-2.5 transition-colors"
            href="#hama"
          >
            <Bug className="w-[18px] h-[18px] text-slate-500" />
            <span>Hama &amp; Cuaca</span>
          </a>

          <a
            className="px-3.5 py-2.5 rounded-xl bg-white hover:bg-cream-100 text-slate-700 font-bold text-xs border border-brutal-border flex items-center gap-2.5 transition-colors"
            href="#laporan"
          >
            <BarChart3 className="w-[18px] h-[18px] text-slate-500" />
            <span>Laporan &amp; Wilayah</span>
          </a>
        </div>
      </div>

      {/* Bottom Sidebar Widget */}
      <div className="flex flex-col gap-3 pt-3 border-t-2 border-brutal-border/20">
        <div className="p-3 rounded-xl bg-white border-2 border-brutal-border shadow-brutal-sm flex flex-col gap-2">
          <div className="flex items-center justify-between text-xs">
            <span className="text-[10px] font-bold uppercase tracking-wider text-slate-500">Wilayah Kerja</span>
            <MapPin className="w-[16px] h-[16px] text-brand" />
          </div>
          <span className="text-xs font-bold text-brutal-dark leading-tight">Kec. Lembang &amp; Ciwidey</span>
          <div className="pt-1.5 border-t border-slate-100 flex items-center justify-between text-[10px] font-mono text-slate-600">
            <span className="flex items-center gap-1">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
              Supabase Online
            </span>
            <span className="font-bold text-brand">v2.4</span>
          </div>
        </div>
      </div>
    </aside>
  );
};
