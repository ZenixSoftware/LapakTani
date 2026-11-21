import React from 'react';
import type { AuthUser } from '../services/api';

export type PortalModuleTab =
  | 'dashboard'
  | 'peta-lahan'
  | 'data-sensor'
  | 'rag-decision'
  | 'toko-forum'
  | 'policy-brief'
  | 'validasi'
  | 'superadmin-governance';

interface SidebarProps {
  pendingCount: number;
  criticalPlotCount?: number;
  activeTab: PortalModuleTab;
  onTabChange: (tab: PortalModuleTab) => void;
  currentUser?: AuthUser | null;
  onLogout?: () => void;
  onOpenDm?: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  pendingCount,
  criticalPlotCount = 0,
  activeTab,
  onTabChange,
  currentUser,
  onLogout,
  onOpenDm,
}) => {
  const isDinas =
    currentUser?.role?.toLowerCase() === 'dinas' || currentUser?.role_id === 5;
  const isSuperAdmin =
    currentUser?.role?.toLowerCase() === 'superadmin' || currentUser?.role_id === 6;

  const menuUtamaItems: {
    id: PortalModuleTab;
    label: string;
    icon: string;
    badge?: string;
  }[] = isSuperAdmin
    ? [
        { id: 'superadmin-governance', label: 'Tata Kelola Pusat', icon: 'admin_panel_settings', badge: '6-ROLE' },
        { id: 'dashboard', label: 'Ringkasan GIS', icon: 'space_dashboard' },
        { id: 'peta-lahan', label: 'Peta Lahan', icon: 'map', badge: 'GIS' },
        { id: 'data-sensor', label: 'Data Sensor', icon: 'sensors', badge: '8-in-1' },
      ]
    : [
        { id: 'dashboard', label: 'Dashboard', icon: 'space_dashboard' },
        { id: 'peta-lahan', label: 'Peta Lahan', icon: 'map', badge: 'GIS' },
        { id: 'data-sensor', label: 'Data Sensor', icon: 'sensors', badge: '8-in-1' },
        isDinas
          ? { id: 'policy-brief', label: 'AI Policy Brief', icon: 'policy', badge: 'DINAS' }
          : { id: 'rag-decision', label: 'AI Decision Support', icon: 'psychology', badge: 'RAG' },
      ];

  return (
    <aside className="w-64 lg:w-72 bg-lt-surface-card border-r border-lt-border hidden md:flex flex-col justify-between fixed top-16 bottom-0 left-0 z-30 text-lt-neutral">
      <div className="p-4 space-y-6 overflow-y-auto custom-scrollbar flex-1">
        {/* Branding Card inside White-Dominant Sidebar */}
        <div className="px-3.5 py-3 rounded-2xl bg-lt-surface-canvas border border-lt-border flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-lt-primary text-white flex items-center justify-center shadow-sm flex-shrink-0">
            <span className="material-symbols-outlined text-[20px]">eco</span>
          </div>
          <div className="min-w-0">
            <div className="text-[12px] font-extrabold tracking-wide text-lt-neutral truncate">
              LAPAKTANI
            </div>
            <div className="text-[10.5px] text-lt-neutral-muted font-semibold truncate">
              {isSuperAdmin
                ? 'Pusat Tata Kelola Super Admin'
                : isDinas
                  ? 'Dinas Pertanian Sumenep'
                  : 'Portal Penyuluh Sumenep'}
            </div>
          </div>
        </div>

        {/* MENU UTAMA */}
        <div>
          <span className="text-[10.5px] font-bold tracking-widest text-lt-neutral-subtle uppercase px-3">
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
                      ? 'bg-lt-primary-tint text-lt-primary font-bold border border-lt-primary-border'
                      : 'text-lt-neutral-muted hover:bg-lt-surface-canvas hover:text-lt-neutral font-semibold'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <span
                      className={`material-symbols-outlined text-[20px] ${
                        active ? 'text-lt-primary' : 'text-lt-neutral-muted'
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
                          ? 'bg-lt-primary text-white'
                          : 'bg-lt-surface-canvas text-lt-neutral-muted border border-lt-border'
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
        {!isDinas && !isSuperAdmin && (
          <div>
            <span className="text-[10.5px] font-bold tracking-widest text-lt-neutral-subtle uppercase px-3">
              MANAJEMEN &amp; VALIDASI
            </span>
            <nav className="mt-2 space-y-1.5">
              <button
                type="button"
                onClick={() => onTabChange('validasi')}
                className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl text-[13px] transition-all ${
                  activeTab === 'validasi'
                    ? 'bg-lt-primary-tint text-lt-primary font-bold border border-lt-primary-border'
                    : 'text-lt-neutral-muted hover:bg-lt-surface-canvas hover:text-lt-neutral font-semibold'
                }`}
              >
                <div className="flex items-center gap-3">
                  <span
                    className={`material-symbols-outlined text-[20px] ${
                      activeTab === 'validasi' ? 'text-lt-primary' : 'text-lt-neutral-muted'
                    }`}
                  >
                    verified_user
                  </span>
                  <span>Validasi Petani</span>
                </div>
                <span
                  className={`px-2 py-0.5 rounded-full text-[11px] font-extrabold ${
                    activeTab === 'validasi'
                      ? 'bg-lt-primary text-white'
                      : 'bg-lt-tertiary-tint text-lt-tertiary-text border border-lt-tertiary-border'
                  }`}
                >
                  {pendingCount}
                </span>
              </button>
              <button
                type="button"
                onClick={() => onTabChange('toko-forum')}
                className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl text-[13px] transition-all ${
                  activeTab === 'toko-forum'
                    ? 'bg-lt-primary-tint text-lt-primary font-bold border border-lt-primary-border'
                    : 'text-lt-neutral-muted hover:bg-lt-surface-canvas hover:text-lt-neutral font-semibold'
                }`}
              >
                <div className="flex items-center gap-3">
                  <span
                    className={`material-symbols-outlined text-[20px] ${
                      activeTab === 'toko-forum' ? 'text-lt-primary' : 'text-lt-neutral-muted'
                    }`}
                  >
                    storefront
                  </span>
                  <span>Toko &amp; Forum</span>
                </div>
                <span
                  className={`px-2 py-0.5 rounded-md text-[10px] font-extrabold ${
                    activeTab === 'toko-forum'
                      ? 'bg-lt-primary text-white'
                      : 'bg-lt-surface-canvas text-lt-neutral-muted border border-lt-border'
                  }`}
                >
                  DESA
                </span>
              </button>
            </nav>
          </div>
        )}

        {/* Direct Message Shortcut */}
        {currentUser && onOpenDm && (
          <div>
            <button
              type="button"
              onClick={onOpenDm}
              className="w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl text-[13px] font-bold bg-lt-tertiary-tint hover:bg-lt-tertiary-border/40 text-lt-tertiary-text border border-lt-tertiary-border transition-all"
            >
              <div className="flex items-center gap-2.5">
                <span className="material-symbols-outlined text-[19px]">forum</span>
                <span>Pesan DM (6 Role)</span>
              </div>
              <span className="px-2 py-0.5 rounded-md bg-lt-tertiary text-lt-neutral text-[10px] font-extrabold">
                LIVE
              </span>
            </button>
          </div>
        )}

        {/* Instansi Card */}
        <div className="p-3.5 rounded-2xl bg-lt-surface-canvas border border-lt-border space-y-2">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-lt-secondary text-[18px]">
                domain
              </span>
              <span className="text-[12px] font-extrabold text-lt-neutral">
                {isSuperAdmin
                  ? 'Super Admin Pusat'
                  : isDinas
                    ? 'Disperta Sumenep'
                    : 'BPP Sumenep'}
              </span>
            </div>
            {criticalPlotCount > 0 && (
              <span className="px-2 py-0.5 rounded-full bg-lt-error text-white text-[10px] font-extrabold">
                {criticalPlotCount} Kritis
              </span>
            )}
          </div>
          <p className="text-[11px] text-lt-neutral-muted leading-relaxed">
            {isSuperAdmin
              ? 'Kendali 6-Role RBAC, provisioning akun Dinas & Penyuluh BPP, pengawasan B2B/Retail Auto-KYC, & Fee Ledger.'
              : isDinas
                ? 'Pemantauan geospasial GIS, AI Policy Brief strategis, dan tinjauan eskalasi RAG dari Penyuluh BPP.'
                : 'Pemetaan presisi 8-in-1 SmartAgri, sintesis AI Decision Support (RAG), dan verifikasi petani binaan.'}
          </p>
        </div>
      </div>

      {/* User Profile Card in Sidebar Footer */}
      <div className="p-3 border-t border-lt-border bg-lt-surface-card">
        <div className="flex items-center justify-between p-2.5 rounded-xl bg-lt-surface-canvas border border-lt-border">
          <div className="flex items-center gap-2.5 min-w-0">
            <div className="relative flex-shrink-0">
              <div className="w-9 h-9 rounded-xl bg-lt-primary-tint text-lt-primary flex items-center justify-center font-extrabold text-[13px] border border-lt-primary-border">
                {currentUser?.full_name
                  ? currentUser.full_name
                      .split(' ')
                      .map((n) => n[0])
                      .slice(0, 2)
                      .join('')
                      .toUpperCase()
                  : isSuperAdmin
                    ? 'SA'
                    : isDinas
                      ? 'DN'
                      : 'PL'}
              </div>
              <span className="absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 bg-lt-primary rounded-full border-2 border-lt-surface-card"></span>
            </div>
            <div className="min-w-0">
              <p className="text-[12.5px] font-bold text-lt-neutral truncate">
                {currentUser?.full_name ||
                  (isSuperAdmin
                    ? 'Super Admin Pusat'
                    : isDinas
                      ? 'Dinas Pertanian'
                      : 'Penyuluh Sumenep')}
              </p>
              <span className="text-[10.5px] text-lt-neutral-muted font-medium truncate block">
                {currentUser?.email ||
                  (isSuperAdmin
                    ? 'superadmin@lapaktani.id'
                    : isDinas
                      ? 'dinas@lapaktani.id'
                      : 'penyuluh@lapaktani.id')}
              </span>
            </div>
          </div>
          <button
            onClick={onLogout}
            className="p-1.5 rounded-lg text-lt-neutral-muted hover:text-lt-error hover:bg-lt-error-tint transition-colors"
            title="Keluar"
          >
            <span className="material-symbols-outlined text-[19px]">logout</span>
          </button>
        </div>
      </div>
    </aside>
  );
};
