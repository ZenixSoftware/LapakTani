import React from 'react';
import type { AuthUser } from '../services/api';

export type PortalModuleTab =
  | 'dashboard'
  | 'peta-lahan'
  | 'data-sensor'
  | 'rag-decision'
  | 'policy-brief'
  | 'validasi';

interface SidebarProps {
  pendingCount: number;
  criticalPlotCount?: number;
  activeTab: PortalModuleTab;
  onTabChange: (tab: PortalModuleTab) => void;
  currentUser?: AuthUser | null;
  onLogout?: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  pendingCount,
  criticalPlotCount = 0,
  activeTab,
  onTabChange,
  currentUser,
  onLogout,
}) => {
  const isDinas =
    currentUser?.role?.toLowerCase() === 'dinas' || currentUser?.role_id === 5;

  const menuUtamaItems: {
    id: PortalModuleTab;
    label: string;
    icon: string;
    badge?: string;
  }[] = [
    { id: 'dashboard', label: 'Dashboard', icon: 'space_dashboard' },
    { id: 'peta-lahan', label: 'Peta Lahan', icon: 'map', badge: 'GIS' },
    { id: 'data-sensor', label: 'Data Sensor', icon: 'sensors', badge: '8-in-1' },
    isDinas
      ? { id: 'policy-brief', label: 'AI Policy Brief', icon: 'policy', badge: 'DINAS' }
      : { id: 'rag-decision', label: 'AI Decision Support', icon: 'psychology', badge: 'RAG' },
  ];

  return (
    <aside className="w-64 lg:w-72 bg-[#0D5136] border-r border-emerald-900/70 hidden md:flex flex-col justify-between fixed top-16 bottom-0 left-0 z-30 shadow-xl text-white">
      <div className="p-4 space-y-6 overflow-y-auto custom-scrollbar flex-1">
        {/* Branding Card inside Deep Forest Sidebar */}
        <div className="px-3.5 py-3 rounded-2xl bg-[#166534]/75 border border-emerald-400/20 flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-[#F59E0B] text-white flex items-center justify-center shadow-sm flex-shrink-0">
            <span className="material-symbols-outlined text-[20px]">eco</span>
          </div>
          <div className="min-w-0">
            <div className="text-[12px] font-extrabold tracking-wide text-white truncate">
              LAPAKTANI
            </div>
            <div className="text-[10.5px] text-emerald-200/90 font-semibold truncate">
              {isDinas ? 'Dinas Pertanian Sumenep' : 'Portal Penyuluh Sumenep'}
            </div>
          </div>
        </div>

        {/* MENU UTAMA */}
        <div>
          <span className="text-[10.5px] font-bold tracking-widest text-emerald-200/70 uppercase px-3">
            MENU UTAMA
          </span>
          <nav className="mt-2 space-y-1.5">
            {menuUtamaItems.map((item) => {
              const active = activeTab === item.id;
              return (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => onTabChange(item.id)}
                  className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl text-[13px] transition-all ${
                    active
                      ? 'bg-[#22C55E] text-[#052e16] font-extrabold shadow-md shadow-emerald-950/30'
                      : 'text-emerald-100/85 hover:bg-[#166534] hover:text-white font-semibold'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <span
                      className={`material-symbols-outlined text-[20px] ${
                        active ? 'text-[#052e16]' : 'text-emerald-200/80'
                      }`}
                    >
                      {item.icon}
                    </span>
                    <span>{item.label}</span>
                  </div>
                  {item.badge && (
                    <span
                      className={`px-2 py-0.5 rounded-md text-[10px] font-extrabold ${
                        active
                          ? 'bg-[#0D5136] text-white'
                          : 'bg-white/10 text-emerald-100 border border-white/10'
                      }`}
                    >
                      {item.badge}
                    </span>
                  )}
                </button>
              );
            })}
          </nav>
        </div>

        {/* MANAJEMEN & VALIDASI (Exclusive to Penyuluh BPP) */}
        {!isDinas && (
          <div>
            <span className="text-[10.5px] font-bold tracking-widest text-emerald-200/70 uppercase px-3">
              MANAJEMEN &amp; VALIDASI
            </span>
            <nav className="mt-2 space-y-1.5">
              <button
                type="button"
                onClick={() => onTabChange('validasi')}
                className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl text-[13px] transition-all ${
                  activeTab === 'validasi'
                    ? 'bg-[#22C55E] text-[#052e16] font-extrabold shadow-md shadow-emerald-950/30'
                    : 'text-emerald-100/85 hover:bg-[#166534] hover:text-white font-semibold'
                }`}
              >
                <div className="flex items-center gap-3">
                  <span
                    className={`material-symbols-outlined text-[20px] ${
                      activeTab === 'validasi' ? 'text-[#052e16]' : 'text-emerald-200/80'
                    }`}
                  >
                    verified_user
                  </span>
                  <span>Validasi Petani</span>
                </div>
                <span
                  className={`px-2 py-0.5 rounded-full text-[11px] font-extrabold ${
                    activeTab === 'validasi'
                      ? 'bg-[#0D5136] text-white'
                      : 'bg-[#F59E0B] text-white'
                  }`}
                >
                  {pendingCount}
                </span>
              </button>
            </nav>
          </div>
        )}

        {/* Instansi Card */}
        <div className="p-3.5 rounded-2xl bg-[#166534]/65 border border-emerald-400/20 space-y-2">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-[#F59E0B] text-[18px]">
                domain
              </span>
              <span className="text-[12px] font-extrabold text-white">
                {isDinas ? 'Disperta Sumenep' : 'BPP Sumenep'}
              </span>
            </div>
            {criticalPlotCount > 0 && (
              <span className="px-2 py-0.5 rounded-full bg-rose-500 text-white text-[10px] font-extrabold">
                {criticalPlotCount} Kritis
              </span>
            )}
          </div>
          <p className="text-[11px] text-emerald-100/80 leading-relaxed">
            {isDinas
              ? 'Pemantauan geospasial GIS, AI Policy Brief strategis, dan tinjauan eskalasi RAG dari Penyuluh BPP.'
              : 'Pemetaan presisi 8-in-1 SmartAgri, sintesis AI Decision Support (RAG), dan verifikasi petani binaan.'}
          </p>
        </div>
      </div>

      {/* User Profile Card in Sidebar Footer */}
      <div className="p-3 border-t border-emerald-900/70 bg-[#0a3f2a]">
        <div className="flex items-center justify-between p-2.5 rounded-xl bg-[#166534]/80 border border-emerald-500/25">
          <div className="flex items-center gap-2.5 min-w-0">
            <div className="relative flex-shrink-0">
              <div className="w-9 h-9 rounded-xl bg-[#22C55E] text-[#052e16] flex items-center justify-center font-extrabold text-[13px]">
                {currentUser?.full_name
                  ? currentUser.full_name
                      .split(' ')
                      .map((n) => n[0])
                      .slice(0, 2)
                      .join('')
                      .toUpperCase()
                  : isDinas
                    ? 'DN'
                    : 'PL'}
              </div>
              <span className="absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 bg-[#22C55E] rounded-full border-2 border-[#0a3f2a]"></span>
            </div>
            <div className="min-w-0">
              <p className="text-[12.5px] font-bold text-white truncate">
                {currentUser?.full_name || (isDinas ? 'Dinas Pertanian' : 'Penyuluh Sumenep')}
              </p>
              <span className="text-[10.5px] text-emerald-200/85 font-medium truncate block">
                {currentUser?.email || (isDinas ? 'dinas@lapaktani.id' : 'penyuluh@lapaktani.id')}
              </span>
            </div>
          </div>
          <button
            onClick={onLogout}
            className="p-1.5 rounded-lg text-emerald-200 hover:text-white hover:bg-rose-600/80 transition-colors"
            title="Keluar"
          >
            <span className="material-symbols-outlined text-[19px]">logout</span>
          </button>
        </div>
      </div>
    </aside>
  );
};
