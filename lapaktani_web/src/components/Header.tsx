import React from 'react';
import type { AuthUser } from '../services/api';

interface HeaderProps {
  searchQuery: string;
  onSearchChange: (query: string) => void;
  onSync: () => void;
  isSyncing: boolean;
  currentUser?: AuthUser | null;
  onOpenLogin?: () => void;
  onOpenDm?: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  searchQuery,
  onSearchChange,
  onSync,
  isSyncing,
  currentUser,
  onOpenLogin,
  onOpenDm,
}) => {
  const isDinas =
    currentUser?.role?.toLowerCase() === 'dinas' || currentUser?.role_id === 5;
  const isSuperAdmin =
    currentUser?.role?.toLowerCase() === 'superadmin' || currentUser?.role_id === 6;

  return (
    <header className="fixed top-0 left-0 right-0 h-16 bg-white/95 backdrop-blur-md z-40 border-b border-lt-border flex items-center justify-between px-4 lg:px-8">
      <div className="flex items-center gap-3 w-64 lg:w-72 flex-shrink-0">
        <div className="w-10 h-10 rounded-xl bg-lt-primary flex items-center justify-center text-white shadow-sm ">
          <span className="material-symbols-outlined text-[24px]">eco</span>
        </div>
        <div>
          <div className="flex items-center gap-1.5">
            <span className="font-extrabold text-[17px] tracking-tight text-lt-neutral leading-tight">
              LAPAKTANI
            </span>
            <span
              className={`text-[10px] font-bold uppercase tracking-wider px-1.5 py-0.5 rounded ${
                isSuperAdmin
                  ? 'bg-lt-tertiary-tint text-lt-tertiary-text border border-lt-tertiary-border'
                  : isDinas
                    ? 'bg-lt-secondary-tint text-lt-secondary-dark'
                    : 'bg-lt-primary-tint text-lt-primary'
              }`}
            >
              {isSuperAdmin ? 'SUPERADMIN' : isDinas ? 'DINAS' : 'PPL'}
            </span>
          </div>
          <p className="text-[11px] text-lt-neutral-muted font-medium">
            {isSuperAdmin
              ? 'Pusat Tata Kelola 6-Role · Sumenep'
              : isDinas
                ? 'Portal Dinas Pertanian · Kab. Sumenep'
                : 'Portal Penyuluh · Kab. Sumenep'}
          </p>
        </div>
      </div>

      {/* Global Search Bar */}
      <div className="hidden md:flex items-center flex-1 max-w-xl mx-4">
        <div className="relative w-full">
          <span className="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-lt-neutral-subtle text-[20px]">
            search
          </span>
          <input
            className="w-full h-10 pl-11 pr-4 rounded-xl bg-lt-surface-canvas border border-lt-border text-[13px] text-lt-neutral placeholder-lt-neutral-subtle focus:bg-white focus:border-lt-primary focus:ring-2 focus:ring-lt-primary/20 transition-all outline-none"
            placeholder="Cari desa Sumenep, Poktan, komoditas, atau NIK petani..."
            type="text"
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
          />
          <div className="hidden lg:flex absolute right-2.5 top-1/2 -translate-y-1/2 items-center gap-1 text-[10.5px] font-bold bg-white px-2 py-0.5 rounded-md border border-lt-border text-lt-primary-dark">
            <span className="w-1.5 h-1.5 rounded-full bg-lt-primary animate-pulse"></span>
            Live API
          </div>
        </div>
      </div>

      {/* Header Actions */}
      <div className="flex items-center gap-2 sm:gap-3">
        {currentUser && onOpenDm && (
          <button
            type="button"
            onClick={onOpenDm}
            className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl bg-lt-tertiary-tint text-lt-tertiary-text hover:bg-lt-tertiary-tint border border-lt-tertiary-border font-bold text-[12px] transition-colors"
          >
            <span className="material-symbols-outlined text-[18px]">forum</span>
            <span>Pesan DM</span>
          </button>
        )}

        <button
          onClick={onSync}
          disabled={isSyncing}
          className="hidden sm:inline-flex items-center gap-1.5 px-3 py-2 rounded-xl bg-lt-primary-tint text-lt-primary hover:bg-lt-primary-tint border border-lt-primary-border/70 font-bold text-[12px] transition-colors disabled:opacity-50"
        >
          <span
            className={`material-symbols-outlined text-[18px] ${
              isSyncing ? 'animate-spin' : ''
            }`}
          >
            sync
          </span>
          <span>{isSyncing ? 'Sinkronisasi...' : 'Sinkronkan Portal'}</span>
        </button>

        <div className="h-6 w-px bg-lt-border mx-1 hidden sm:block"></div>

        {currentUser ? (
          <div className="flex items-center gap-2.5 pl-1">
            <div className="w-9 h-9 rounded-xl bg-lt-primary-tint text-lt-primary border border-lt-primary-border flex items-center justify-center font-bold text-[13px]">
              {currentUser.full_name
                ? currentUser.full_name
                    .split(' ')
                    .map((n) => n[0])
                    .slice(0, 2)
                    .join('')
                    .toUpperCase()
                : 'PL'}
            </div>
            <div className="hidden xl:flex flex-col text-left">
              <span className="text-[13px] font-bold text-lt-neutral leading-tight">
                {currentUser.full_name || 'Penyuluh Pertanian'}
              </span>
              <span className="text-[11px] text-lt-neutral-muted">
                {isSuperAdmin
                  ? 'Super Admin Pusat'
                  : isDinas
                    ? 'Dinas Pertanian Sumenep'
                    : 'BPP Kab. Sumenep'}
              </span>
            </div>
          </div>
        ) : (
          <button
            onClick={onOpenLogin}
            className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-lt-primary hover:bg-lt-primary-dark text-white font-bold text-[12px] shadow-sm transition-colors"
          >
            <span className="material-symbols-outlined text-[16px]">login</span>
            <span>Masuk Portal</span>
          </button>
        )}
      </div>
    </header>
  );
};
