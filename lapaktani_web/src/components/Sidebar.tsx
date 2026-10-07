import React from 'react';

interface SidebarProps {
  pendingCount: number;
  currentUser?: { full_name?: string; email?: string } | null;
  onLogout?: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  pendingCount,
  currentUser,
  onLogout,
}) => {
  return (
    <aside className="w-64 lg:w-72 bg-surface-white border-r border-gray-100 hidden md:flex flex-col justify-between fixed top-16 bottom-0 left-0 z-30 shadow-sm">
      <div className="p-4 space-y-6 overflow-y-auto custom-scrollbar flex-1">
        {/* Navigation Section */}
        <div>
          <span className="text-[11px] font-bold tracking-wider text-gray-400 uppercase px-3">
            Menu Utama
          </span>
          <nav className="mt-2 space-y-1">
            <a
              className="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-gray-600 hover:bg-gray-50 hover:text-gray-900 font-semibold text-[13px] transition-all"
              href="#dashboard"
            >
              <span className="material-symbols-outlined text-[20px] text-gray-400">
                space_dashboard
              </span>
              <span>Dashboard Ringkasan</span>
            </a>
            <a
              className="flex items-center justify-between px-3.5 py-2.5 rounded-xl bg-forest-emerald text-white font-bold text-[13px] shadow-md shadow-emerald-950/15"
              href="#validasi"
            >
              <div className="flex items-center gap-3">
                <span className="material-symbols-outlined text-[20px]">
                  verified_user
                </span>
                <span>Validasi Petani</span>
              </div>
              <span className="px-2 py-0.5 rounded-full bg-primary text-white text-[11px] font-bold">
                {pendingCount}
              </span>
            </a>
            <a
              className="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-gray-600 hover:bg-gray-50 hover:text-gray-900 font-semibold text-[13px] transition-all"
              href="#lahan"
            >
              <span className="material-symbols-outlined text-[20px] text-gray-400">
                potted_plant
              </span>
              <span>Pemantauan Lahan</span>
            </a>
            <a
              className="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-gray-600 hover:bg-gray-50 hover:text-gray-900 font-semibold text-[13px] transition-all"
              href="#poktan"
            >
              <span className="material-symbols-outlined text-[20px] text-gray-400">
                groups
              </span>
              <span>Kelompok Tani Binaan</span>
            </a>
          </nav>
        </div>

        <div>
          <span className="text-[11px] font-bold tracking-wider text-gray-400 uppercase px-3">
            Verifikasi &amp; Mutu
          </span>
          <nav className="mt-2 space-y-1">
            <a
              className="flex items-center justify-between px-3.5 py-2.5 rounded-xl text-gray-600 hover:bg-gray-50 font-semibold text-[13px] transition-all"
              href="#geofencing"
            >
              <div className="flex items-center gap-3">
                <span className="material-symbols-outlined text-[20px] text-gray-400">
                  share_location
                </span>
                <span>Audit Geofencing GPS</span>
              </div>
              <span className="text-[11px] font-bold text-amber-warm bg-amber-50 px-2 py-0.5 rounded-md">
                10 Titik
              </span>
            </a>
            <a
              className="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-gray-600 hover:bg-gray-50 font-semibold text-[13px] transition-all"
              href="#organik"
            >
              <span className="material-symbols-outlined text-[20px] text-gray-400">
                workspace_premium
              </span>
              <span>Sertifikasi Organik</span>
            </a>
            <a
              className="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-gray-600 hover:bg-gray-50 font-semibold text-[13px] transition-all"
              href="#riwayat"
            >
              <span className="material-symbols-outlined text-[20px] text-gray-400">
                history_edu
              </span>
              <span>Riwayat Keputusan</span>
            </a>
          </nav>
        </div>

        {/* BPP Info Box */}
        <div className="p-3.5 rounded-2xl bg-gradient-to-br from-emerald-50 to-[#eaf5ef] border border-emerald-100/70">
          <div className="flex items-center gap-2 mb-1.5">
            <span className="material-symbols-outlined text-forest-emerald text-[18px]">
              domain
            </span>
            <span className="text-[12px] font-bold text-forest-emerald">
              Pos Penyuluhan (BPP)
            </span>
          </div>
          <p className="text-[11px] text-gray-600 leading-snug">
            Wilayah Kerja: <strong>Lembang &amp; Parongpong</strong>. Mengawasi 14 Kelompok Tani aktif dan 542 Ha lahan.
          </p>
        </div>
      </div>

      {/* User Profile Card in Sidebar Footer */}
      <div className="p-3 border-t border-gray-100 bg-[#fbfdfb]">
        <div className="flex items-center justify-between p-2 rounded-xl bg-white border border-gray-100 shadow-sm">
          <div className="flex items-center gap-2.5 min-w-0">
            <div className="relative flex-shrink-0">
              <div className="w-10 h-10 rounded-xl bg-forest-emerald text-white flex items-center justify-center font-bold text-[14px]">
                {currentUser?.full_name
                  ? currentUser.full_name
                      .split(' ')
                      .map((n) => n[0])
                      .slice(0, 2)
                      .join('')
                      .toUpperCase()
                  : 'AH'}
              </div>
              <span className="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-primary rounded-full border-2 border-white"></span>
            </div>
            <div className="min-w-0">
              <p className="text-[13px] font-bold text-gray-900 truncate">
                {currentUser?.full_name || 'Ir. Ahmad Hidayat'}
              </p>
              <div className="flex items-center gap-1">
                <span className="inline-block w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                <span className="text-[11px] text-gray-500 font-medium truncate">
                  {currentUser?.email || 'BPP Lembang'}
                </span>
              </div>
            </div>
          </div>
          <button
            onClick={onLogout}
            className="p-1.5 rounded-lg text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors"
            title="Keluar"
          >
            <span className="material-symbols-outlined text-[20px]">logout</span>
          </button>
        </div>
      </div>
    </aside>
  );
};
