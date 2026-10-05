import { Search, Download, RefreshCw, Bell } from 'lucide-react';

interface HeaderProps {
  searchQuery: string;
  onSearchChange: (val: string) => void;
  onRefresh: () => void;
  onExportCsv: () => void;
  isRefreshing?: boolean;
}

export const Header = ({
  searchQuery,
  onSearchChange,
  onRefresh,
  onExportCsv,
  isRefreshing = false
}: HeaderProps) => {
  return (
    <header className="px-6 py-3.5 border-b-2 border-brutal-border bg-cream-50 flex items-center justify-between gap-4 flex-wrap sticky top-0 z-50 shadow-brutal-sm">
      {/* Search input bar */}
      <div className="relative flex-1 min-w-[240px] max-w-xl">
        <Search className="absolute left-3 top-2.5 text-slate-400 w-[18px] h-[18px]" />
        <input
          className="w-full h-10 pl-9 pr-3 rounded-xl bg-white border-2 border-brutal-border text-xs font-semibold placeholder:text-slate-400 focus:outline-none focus:shadow-brutal-sm transition-all"
          placeholder="Cari NIK, nama petani, kelompok tani, atau desa..."
          type="text"
          value={searchQuery}
          onChange={(e) => onSearchChange(e.target.value)}
        />
      </div>

      {/* Right Header Actions & Profile */}
      <div className="flex items-center gap-3 flex-wrap">
        {/* Action button: Export CSV */}
        <button
          className="px-3.5 py-2 rounded-xl bg-white border-2 border-brutal-border shadow-brutal-sm text-xs font-bold text-brutal-dark flex items-center gap-1.5 hover:bg-cream-100 transition-all active:translate-x-0.5 active:translate-y-0.5 cursor-pointer"
          type="button"
          onClick={onExportCsv}
        >
          <Download className="w-[17px] h-[17px] text-brand" />
          <span className="hidden sm:inline">Unduh CSV</span>
        </button>

        {/* Action button: Segarkan / Refresh */}
        <button
          className="px-3.5 py-2 rounded-xl bg-white border-2 border-brutal-border shadow-brutal-sm text-xs font-bold text-slate-700 flex items-center gap-1.5 hover:bg-cream-100 transition-all active:translate-x-0.5 active:translate-y-0.5 cursor-pointer"
          title="Segarkan Data"
          type="button"
          onClick={onRefresh}
          disabled={isRefreshing}
        >
          <RefreshCw className={`w-[17px] h-[17px] text-brand ${isRefreshing ? 'animate-spin' : ''}`} />
          <span className="hidden sm:inline">Segarkan</span>
        </button>

        {/* Notification Bell */}
        <button
          className="relative w-10 h-10 rounded-xl bg-white border-2 border-brutal-border shadow-brutal-sm flex items-center justify-center hover:bg-cream-100 transition-all active:translate-x-0.5 active:translate-y-0.5 cursor-pointer"
          title="Notifikasi"
          type="button"
        >
          <Bell className="w-[20px] h-[20px] text-brutal-dark" />
          <span className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-rose-500 text-white font-bold text-[9px] flex items-center justify-center border border-brutal-border">
            12
          </span>
        </button>

        {/* Officer Profile Bento Capsule */}
        <div className="flex items-center gap-2.5 px-3 py-1.5 rounded-2xl bg-white border-2 border-brutal-border shadow-brutal-sm">
          <div className="relative">
            <img
              alt="Bpk. Andi Pratama, S.P."
              className="w-9 h-9 rounded-xl object-cover border border-brutal-border"
              src="https://lh3.googleusercontent.com/aida/AEtjO1UNfK26KJdbT_DohKppIpXeaJGOvGULCmW80KzAfR5f9tchkdqHaaY5pSV_kPOj1x_6_wPiCuY-txPOodLlZKInZycXVthb2N-ZtqXCzgllp_qaDgWnXQNRbd-ySCksoeSGbzDJf04RYmW84LJsE7Fuu1eMbhS6oIQgqH4lhtEGJwPiXVBKCNYhItHIKdjnB4W1cqfseQrehGk_CMwXdGjw990Tf2MDomlt5BHDegWzznpMk9KcCu0DDeJL"
            />
            <span className="absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 rounded-full bg-emerald-500 border border-white"></span>
          </div>
          <div className="flex flex-col text-left leading-none">
            <span className="text-xs font-bold text-brutal-dark truncate max-w-[130px]">Bpk. Andi Pratama, S.P.</span>
            <span className="text-[10px] text-slate-500 font-medium mt-0.5">Penyuluh Ahli Pertama</span>
          </div>
        </div>
      </div>
    </header>
  );
};
