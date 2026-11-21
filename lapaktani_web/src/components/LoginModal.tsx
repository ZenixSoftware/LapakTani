import React, { useState } from 'react';
import { loginPenyuluh, type AuthUser } from '../services/api';

interface LoginModalProps {
  isOpen: boolean;
  onClose?: () => void;
  onSuccess: (user: AuthUser) => void;
}

const DEMO_ACCOUNTS = [
  {
    key: 'penyuluh',
    label: 'Penyuluh BPP',
    sub: 'GIS + Validasi Petani + RAG Dispatch',
    email: 'penyuluh@lapaktani.id',
    password: 'penyuluh123',
  },
  {
    key: 'dinas',
    label: 'Dinas Pertanian',
    sub: 'Monitoring GIS + AI Policy Brief & Inbox',
    email: 'dinas@lapaktani.id',
    password: 'dinas123',
  },
  {
    key: 'superadmin',
    label: 'Super Admin',
    sub: 'Tata Kelola 6-Role, Otoritas & Ledger',
    email: 'superadmin@lapaktani.id',
    password: 'superadmin123',
  },
] as const;

export const LoginModal: React.FC<LoginModalProps> = ({
  isOpen,
  onClose,
  onSuccess,
}) => {
  const [email, setEmail] = useState('penyuluh@lapaktani.id');
  const [password, setPassword] = useState('penyuluh123');
  const [selectedRoleKey, setSelectedRoleKey] = useState<'penyuluh' | 'dinas' | 'superadmin'>('penyuluh');
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  if (!isOpen) return null;

  const selectDemoRole = (acc: (typeof DEMO_ACCOUNTS)[number]) => {
    setSelectedRoleKey(acc.key);
    setEmail(acc.email);
    setPassword(acc.password);
    setErrorMessage(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setErrorMessage(null);

    try {
      const res = await loginPenyuluh(email.trim(), password);
      onSuccess(res.user);
    } catch (err: unknown) {
      setErrorMessage(
        err instanceof Error ? err.message : 'Gagal masuk. Periksa kembali email dan kata sandi.'
      );
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full border border-lt-surface-canvas overflow-hidden">
        {/* Header */}
        <div className="bg-lt-surface-card border-b border-lt-border border-l-4 border-l-lt-primary p-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2.5">
              <div className="w-9 h-9 rounded-xl bg-lt-primary-tint text-lt-primary flex items-center justify-center">
                <span className="material-symbols-outlined text-[22px]">
                  verified_user
                </span>
              </div>
              <div>
                <h3 className="font-extrabold text-[17px] tracking-tight text-lt-neutral leading-tight">
                  Portal Web Sumenep
                </h3>
                <p className="text-[12px] text-lt-neutral-muted">
                  Penyuluh BPP, Dinas Pertanian &amp; Super Admin
                </p>
              </div>
            </div>
            {onClose && (
              <button
                onClick={onClose}
                className="text-lt-neutral-muted hover:text-lt-neutral p-1 rounded-lg transition-colors"
              >
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            )}
          </div>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {/* Quick Role Switcher */}
          <div>
            <span className="block text-[11px] font-bold text-lt-neutral-muted uppercase tracking-wider mb-1.5">
              Pilih Peran Demo Web Portal (6-Role Governance)
            </span>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
              {DEMO_ACCOUNTS.map((acc) => {
                const active = selectedRoleKey === acc.key;
                return (
                  <button
                    key={acc.key}
                    type="button"
                    onClick={() => selectDemoRole(acc)}
                    className={`p-2.5 rounded-xl border text-left transition-all ${
                      active
                        ? 'bg-lt-primary-tint border-lt-primary ring-2 ring-lt-primary/25'
                        : 'bg-lt-surface-canvas border-lt-border hover:border-lt-neutral-border'
                    }`}
                  >
                    <div className="text-[12px] font-extrabold text-lt-neutral">{acc.label}</div>
                    <div className="text-[10px] text-lt-neutral-muted leading-tight mt-0.5">{acc.sub}</div>
                  </button>
                );
              })}
            </div>
          </div>

          {errorMessage && (
            <div className="p-3 rounded-xl bg-lt-error-tint border border-lt-error-border text-lt-error text-[12px] font-semibold flex items-center gap-2">
              <span className="material-symbols-outlined text-[18px]">error</span>
              <span>{errorMessage}</span>
            </div>
          )}

          <div>
            <label className="block text-[12px] font-bold text-lt-neutral uppercase tracking-wider mb-1">
              Email Petugas / Instansi
            </label>
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-lt-neutral-subtle text-[18px]">
                mail
              </span>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="nama@lapaktani.id"
                className="w-full pl-10 pr-3 py-2.5 bg-lt-surface-canvas border border-lt-border rounded-xl text-[13px] text-lt-neutral focus:bg-white focus:border-lt-primary focus:ring-2 focus:ring-lt-primary/20 outline-none transition-all"
              />
            </div>
          </div>

          <div>
            <label className="block text-[12px] font-bold text-lt-neutral uppercase tracking-wider mb-1">
              Kata Sandi
            </label>
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-lt-neutral-subtle text-[18px]">
                lock
              </span>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-10 pr-3 py-2.5 bg-lt-surface-canvas border border-lt-border rounded-xl text-[13px] text-lt-neutral focus:bg-white focus:border-lt-primary focus:ring-2 focus:ring-lt-primary/20 outline-none transition-all"
              />
            </div>
          </div>

          <div className="p-3 rounded-xl bg-lt-primary-tint/60 border border-lt-primary-tint text-[11px] text-lt-primary-dark leading-relaxed space-y-1">
            <div className="flex items-center justify-between font-mono">
              <span><strong>Penyuluh:</strong> penyuluh@lapaktani.id</span>
              <span>penyuluh123</span>
            </div>
            <div className="flex items-center justify-between font-mono">
              <span><strong>Dinas:</strong> dinas@lapaktani.id</span>
              <span>dinas123</span>
            </div>
          </div>

          <div className="pt-1">
            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-2.5 px-4 bg-lt-primary hover:bg-lt-primary-dark text-white font-bold text-[13px] rounded-xl shadow-md transition-all flex items-center justify-center gap-2 disabled:opacity-50"
            >
              {isLoading ? (
                <>
                  <span className="material-symbols-outlined animate-spin text-[18px]">
                    progress_activity
                  </span>
                  <span>Memverifikasi...</span>
                </>
              ) : (
                <>
                  <span className="material-symbols-outlined text-[18px]">login</span>
                  <span>
                    {selectedRoleKey === 'dinas'
                      ? 'Masuk Dashboard Dinas Pertanian'
                      : 'Masuk Dashboard Penyuluh BPP'}
                  </span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
