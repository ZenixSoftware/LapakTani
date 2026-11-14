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
] as const;

export const LoginModal: React.FC<LoginModalProps> = ({
  isOpen,
  onClose,
  onSuccess,
}) => {
  const [email, setEmail] = useState('penyuluh@lapaktani.id');
  const [password, setPassword] = useState('penyuluh123');
  const [selectedRoleKey, setSelectedRoleKey] = useState<'penyuluh' | 'dinas'>('penyuluh');
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
      <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full border border-gray-100 overflow-hidden">
        {/* Header */}
        <div className="bg-gradient-to-r from-[#0D5136] to-[#166534] p-6 text-white">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2.5">
              <div className="w-9 h-9 rounded-xl bg-white/10 flex items-center justify-center">
                <span className="material-symbols-outlined text-[22px] text-emerald-300">
                  verified_user
                </span>
              </div>
              <div>
                <h3 className="font-extrabold text-[17px] tracking-tight text-white leading-tight">
                  Portal Web Sumenep
                </h3>
                <p className="text-[12px] text-emerald-200">
                  Penyuluh Pertanian BPP &amp; Dinas Pertanian
                </p>
              </div>
            </div>
            {onClose && (
              <button
                onClick={onClose}
                className="text-white/70 hover:text-white p-1 rounded-lg transition-colors"
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
            <span className="block text-[11px] font-bold text-gray-500 uppercase tracking-wider mb-1.5">
              Pilih Peran Demo Web Portal
            </span>
            <div className="grid grid-cols-2 gap-2">
              {DEMO_ACCOUNTS.map((acc) => {
                const active = selectedRoleKey === acc.key;
                return (
                  <button
                    key={acc.key}
                    type="button"
                    onClick={() => selectDemoRole(acc)}
                    className={`p-2.5 rounded-xl border text-left transition-all ${
                      active
                        ? 'bg-emerald-50 border-[#166534] ring-2 ring-[#22C55E]/25'
                        : 'bg-[#F8FAF9] border-[#E2E8F0] hover:border-gray-300'
                    }`}
                  >
                    <div className="text-[12px] font-extrabold text-[#0D5136]">{acc.label}</div>
                    <div className="text-[10px] text-gray-500 leading-tight mt-0.5">{acc.sub}</div>
                  </button>
                );
              })}
            </div>
          </div>

          {errorMessage && (
            <div className="p-3 rounded-xl bg-red-50 border border-red-200 text-red-700 text-[12px] font-semibold flex items-center gap-2">
              <span className="material-symbols-outlined text-[18px]">error</span>
              <span>{errorMessage}</span>
            </div>
          )}

          <div>
            <label className="block text-[12px] font-bold text-gray-700 uppercase tracking-wider mb-1">
              Email Petugas / Instansi
            </label>
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-[18px]">
                mail
              </span>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="nama@lapaktani.id"
                className="w-full pl-10 pr-3 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-[13px] text-gray-800 focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20 outline-none transition-all"
              />
            </div>
          </div>

          <div>
            <label className="block text-[12px] font-bold text-gray-700 uppercase tracking-wider mb-1">
              Kata Sandi
            </label>
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-[18px]">
                lock
              </span>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-10 pr-3 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-[13px] text-gray-800 focus:bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20 outline-none transition-all"
              />
            </div>
          </div>

          <div className="p-3 rounded-xl bg-emerald-50/60 border border-emerald-100 text-[11px] text-emerald-900 leading-relaxed space-y-1">
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
              className="w-full py-2.5 px-4 bg-[#166534] hover:bg-[#0D5136] text-white font-bold text-[13px] rounded-xl shadow-md shadow-emerald-900/20 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
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
