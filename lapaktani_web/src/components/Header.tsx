import React from 'react';

interface HeaderProps {
  searchQuery: string;
  onSearchChange: (query: string) => void;
  onSync: () => void;
  isSyncing: boolean;
  currentUser?: { full_name?: string; email?: string } | null;
  onOpenLogin?: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  searchQuery,
  onSearchChange,
  onSync,
  isSyncing,
  currentUser,
  onOpenLogin,
}) => {
  return (
    <header className="fixed top-0 left-0 right-0 h-16 bg-surface-white/95 backdrop-blur-md z-40 border-b border-gray-100 flex items-center justify-between px-4 lg:px-8">
      <div className="flex items-center gap-3 w-64 lg:w-72 flex-shrink-0">
        <div className="w-10 h-10 rounded-xl bg-forest-emerald flex items-center justify-center text-white shadow-sm shadow-emerald-900/20">
          <span className="material-symbols-outlined text-[24px]">eco</span>
        </div>
        <div>
          <div className="flex items-center gap-1.5">
            <span className="font-extrabold text-[18px] tracking-tight text-forest-emerald leading-tight">
              LapakTani
            </span>
            <span className="text-[10px] font-bold uppercase tracking-wider px-1.5 py-0.5 rounded bg-emerald-100 text-forest-emerald">
              Penyuluh
            </span>
          </div>
          <p className="text-[11px] text-gray-500 font-medium">BPP Wilayah Jawa Barat</p>
        </div>
      </div>

      {/* Search Bar */}
      <div className="hidden md:flex items-center flex-1 max-w-xl mx-4">
        <div className="relative w-full">
          <span className="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400 text-[20px]">
            search
          </span>
          <input
            className="w-full h-10 pl-11 pr-4 rounded-xl bg-[#eef2ef] border-transparent text-[13px] text-neutral-dark placeholder-gray-400 focus:bg-white focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all outline-none"
            placeholder="Cari NIK, nama petani, Poktan binaan, atau komoditas..."
            type="text"
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
          />
          <div className="absolute right-2.5 top-1/2 -translate-y-1/2 flex items-center gap-1 text-[11px] bg-white px-2 py-0.5 rounded-md border border-gray-200 text-gray-400">
            <span>Ctrl</span>
            <span>K</span>
          </div>
        </div>
      </div>

      {/* Header Actions */}
      <div className="flex items-center gap-2 sm:gap-3">
        <button
          onClick={onSync}
          disabled={isSyncing}
          className="hidden sm:inline-flex items-center gap-1.5 px-3 py-2 rounded-xl bg-emerald-50 text-forest-emerald hover:bg-emerald-100 font-bold text-[12px] transition-colors disabled:opacity-50"
        >
          <span
            className={`material-symbols-outlined text-[18px] ${
              isSyncing ? 'animate-spin' : ''
            }`}
          >
            sync
          </span>
          <span>{isSyncing ? 'Sinkronisasi...' : 'Simluhtan Terhubung'}</span>
        </button>

        <button
          className="relative w-9 h-9 rounded-xl bg-gray-100 hover:bg-gray-200 flex items-center justify-center text-gray-600 transition-colors"
          title="Notifikasi"
        >
          <span className="material-symbols-outlined text-[20px]">notifications</span>
          <span className="absolute top-2 right-2 w-2 h-2 rounded-full bg-red-500 ring-2 ring-white"></span>
        </button>

        <div className="h-6 w-px bg-gray-200 mx-1 hidden sm:block"></div>

        {currentUser ? (
          <div className="flex items-center gap-2.5 pl-1">
            <div className="w-9 h-9 rounded-xl bg-forest-emerald text-white flex items-center justify-center font-bold text-[13px] shadow-sm">
              {currentUser.full_name
                ? currentUser.full_name
                    .split(' ')
                    .map((n) => n[0])
                    .slice(0, 2)
                    .join('')
                    .toUpperCase()
                : 'AH'}
            </div>
            <div className="hidden xl:flex flex-col text-left">
              <span className="text-[13px] font-bold text-gray-800 leading-tight">
                {currentUser.full_name || 'Ir. Ahmad Hidayat'}
              </span>
              <span className="text-[11px] text-gray-500">Penyuluh Ahli Muda</span>
            </div>
          </div>
        ) : (
          <button
            onClick={onOpenLogin}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-700 hover:bg-emerald-800 text-white font-bold text-[12px] shadow-sm transition-colors"
          >
            <span className="material-symbols-outlined text-[16px]">login</span>
            <span>Masuk</span>
          </button>
        )}
      </div>
    </header>
  );
};
