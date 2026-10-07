import { useState, useEffect, useCallback } from 'react';
import { Header } from './components/Header';
import { Sidebar } from './components/Sidebar';
import { HeroBanner } from './components/HeroBanner';
import { QueueTable } from './components/QueueTable';
import { AuditDesk } from './components/AuditDesk';
import { LoginModal } from './components/LoginModal';
import {
  fetchPendingFarmers,
  verifyFarmer,
  getAuthToken,
  getStoredUser,
  removeAuthToken,
  type PendingFarmer,
  type AuthUser,
} from './services/api';

export function App() {
  const [farmers, setFarmers] = useState<PendingFarmer[]>([]);
  const [selectedFarmerId, setSelectedFarmerId] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isProcessing, setIsProcessing] = useState<boolean>(false);
  const [isSyncing, setIsSyncing] = useState<boolean>(false);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'info' } | null>(null);
  const [currentUser, setCurrentUser] = useState<AuthUser | null>(() => getStoredUser());
  const [isLoginModalOpen, setIsLoginModalOpen] = useState<boolean>(() => !getAuthToken());

  const showToast = useCallback((message: string, type: 'success' | 'error' | 'info' = 'success') => {
    setToast({ message, type });
    setTimeout(() => {
      setToast(null);
    }, 4500);
  }, []);

  const loadData = useCallback(async (quiet = false) => {
    if (!quiet) setIsLoading(true);
    try {
      const data = await fetchPendingFarmers();
      setFarmers(data);
      if (data.length > 0) {
        setSelectedFarmerId((prevId) => {
          const exists = data.some((f) => f.id === prevId || f.user_id === prevId);
          return exists ? prevId : (data[0].id || data[0].user_id);
        });
      } else {
        setSelectedFarmerId('');
      }
    } catch (err: any) {
      console.error('[WEB] Error fetching pending farmers:', err);
      if (err.message && err.message.includes('401')) {
        setIsLoginModalOpen(true);
        showToast('Sesi autentikasi belum tersedia atau kedaluwarsa. Silakan masuk.', 'error');
      } else {
        showToast(err.message || 'Gagal memuat data antrean dari backend.', 'error');
      }
    } finally {
      if (!quiet) setIsLoading(false);
    }
  }, [showToast]);

  useEffect(() => {
    if (getAuthToken()) {
      loadData();
    } else {
      setIsLoading(false);
      setIsLoginModalOpen(true);
    }
  }, [loadData]);

  const handleLoginSuccess = (user: AuthUser) => {
    setCurrentUser(user);
    setIsLoginModalOpen(false);
    showToast(`Berhasil masuk sebagai ${user.full_name || 'Penyuluh Pertanian'}.`, 'success');
    loadData();
  };

  const handleLogout = () => {
    removeAuthToken();
    setCurrentUser(null);
    setFarmers([]);
    setSelectedFarmerId('');
    setIsLoginModalOpen(true);
    showToast('Sesi keluar berhasil.', 'info');
  };

  const handleVerify = async (id: string, status: 'verified' | 'rejected', notes: string) => {
    setIsProcessing(true);
    try {
      const res = await verifyFarmer(id, status, notes);
      const actionText = status === 'verified' ? 'disetujui' : 'ditolak';
      showToast(res.message || `Akun petani berhasil ${actionText}.`, 'success');
      await loadData(true);
    } catch (err: any) {
      console.error('[WEB] Verification failed:', err);
      if (err.message && err.message.includes('401')) {
        setIsLoginModalOpen(true);
      }
      showToast(err.message || 'Terjadi kesalahan saat memproses permohonan.', 'error');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleSyncSimluhtan = async () => {
    setIsSyncing(true);
    try {
      await loadData(true);
      showToast('Sinkronisasi data Simluhtan dan Dukcapil berhasil diperbarui.', 'info');
    } finally {
      setIsSyncing(false);
    }
  };

  const handleQuickReview = () => {
    if (farmers.length > 0) {
      const firstPending = farmers[0];
      setSelectedFarmerId(firstPending.id || firstPending.user_id);
      showToast(`Membuka audit prioritas: ${firstPending.name || firstPending.full_name}`, 'info');
    }
  };

  const selectedFarmer =
    farmers.find((f) => f.id === selectedFarmerId || f.user_id === selectedFarmerId) ||
    (farmers.length > 0 ? farmers[0] : null);

  const displayedFarmers = searchQuery.trim()
    ? farmers.filter((f) => {
        const q = searchQuery.toLowerCase();
        return (
          (f.name || f.full_name || '').toLowerCase().includes(q) ||
          (f.nik || f.nik_number || '').includes(q) ||
          (f.poktan || '').toLowerCase().includes(q) ||
          (f.village || '').toLowerCase().includes(q)
        );
      })
    : farmers;

  return (
    <div className="text-neutral-dark antialiased bg-[#f6f8f6] min-h-screen flex flex-col">
      {/* Toast Notification */}
      {toast && (
        <div
          className={`fixed bottom-5 right-5 z-50 px-4 py-3 rounded-xl shadow-lg border text-[13px] font-semibold flex items-center gap-2.5 transition-all transform animate-in fade-in slide-in-from-bottom-2 ${
            toast.type === 'success'
              ? 'bg-emerald-900 text-white border-emerald-700 shadow-emerald-950/20'
              : toast.type === 'error'
              ? 'bg-red-900 text-white border-red-700 shadow-red-950/20'
              : 'bg-forest-card text-white border-emerald-700 shadow-emerald-950/20'
          }`}
        >
          <span className="material-symbols-outlined text-[18px]">
            {toast.type === 'success' ? 'check_circle' : toast.type === 'error' ? 'error' : 'info'}
          </span>
          <span>{toast.message}</span>
        </div>
      )}

      {/* TOP APP BAR */}
      <Header
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
        onSync={handleSyncSimluhtan}
        isSyncing={isSyncing}
        currentUser={currentUser}
        onOpenLogin={() => setIsLoginModalOpen(true)}
      />

      <div className="flex pt-16 min-h-screen">
        {/* SIDEBAR NAVIGATION */}
        <Sidebar
          pendingCount={farmers.length}
          currentUser={currentUser}
          onLogout={handleLogout}
        />

        {/* MAIN WORKSPACE */}
        <main className="flex-1 md:pl-64 lg:pl-72 p-4 lg:p-8 overflow-x-hidden">
          <div className="max-w-[1440px] mx-auto space-y-6">
            {/* HERO BANNER */}
            <HeroBanner
              totalQueue={farmers.length}
              onSync={handleSyncSimluhtan}
              onQuickReview={handleQuickReview}
              isSyncing={isSyncing}
            />

            {/* MAIN DUAL-PANE WORKSPACE */}
            <div className="grid grid-cols-1 xl:grid-cols-12 gap-6 items-start">
              {/* LEFT QUEUE TABLE */}
              <QueueTable
                farmers={displayedFarmers}
                selectedFarmerId={selectedFarmerId}
                onSelectFarmer={(farmer) =>
                  setSelectedFarmerId(farmer.id || farmer.user_id)
                }
                isLoading={isLoading}
                onRefresh={() => loadData(false)}
              />

              {/* RIGHT AUDIT DESK */}
              <AuditDesk
                farmer={selectedFarmer}
                onVerify={handleVerify}
                isProcessing={isProcessing}
              />
            </div>
          </div>
        </main>
      </div>

      {/* Penyuluh Authentication Modal */}
      <LoginModal
        isOpen={isLoginModalOpen}
        onClose={getAuthToken() ? () => setIsLoginModalOpen(false) : undefined}
        onSuccess={handleLoginSuccess}
      />
    </div>
  );
}

export default App;
