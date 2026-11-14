import { useState, useEffect, useCallback, useMemo } from 'react';
import { Header } from './components/Header';
import { Sidebar, type PortalModuleTab } from './components/Sidebar';
import { HeroBanner } from './components/HeroBanner';
import { QueueTable } from './components/QueueTable';
import { AuditDesk } from './components/AuditDesk';
import { LoginModal } from './components/LoginModal';
import { SmartAgriDashboard } from './components/SmartAgriDashboard';
import { SumenepLandMonitoring } from './components/SumenepLandMonitoring';
import { SensorDataTable } from './components/SensorDataTable';
import { AiPolicyBrief } from './components/AiPolicyBrief';
import { PlotInspectorModal } from './components/PlotInspectorModal';
import { isPlotCritical } from './utils/monitoringHelpers';
import {
  fetchPendingFarmers,
  fetchMonitoringLahan,
  fetchMonitoringSummary,
  verifyFarmer,
  getAuthToken,
  getStoredUser,
  removeAuthToken,
  type PendingFarmer,
  type AuthUser,
  type LandPlotRecord,
  type MonitoringSummaryResponse,
} from './services/api';

const MOBILE_TABS: { id: PortalModuleTab; label: string }[] = [
  { id: 'dashboard', label: 'Dashboard' },
  { id: 'peta-lahan', label: 'Peta Lahan' },
  { id: 'data-sensor', label: 'Data Sensor' },
  { id: 'policy-brief', label: 'Policy Brief' },
  { id: 'validasi', label: 'Validasi' },
];

export function App() {
  const [activeTab, setActiveTab] = useState<PortalModuleTab>('dashboard');
  const [farmers, setFarmers] = useState<PendingFarmer[]>([]);
  const [selectedFarmerId, setSelectedFarmerId] = useState<string>('');
  const [plots, setPlots] = useState<LandPlotRecord[]>([]);
  const [summary, setSummary] = useState<MonitoringSummaryResponse | null>(null);
  const [inspectedPlot, setInspectedPlot] = useState<LandPlotRecord | null>(null);

  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isLoadingMonitoring, setIsLoadingMonitoring] = useState<boolean>(true);
  const [isProcessing, setIsProcessing] = useState<boolean>(false);
  const [isSyncing, setIsSyncing] = useState<boolean>(false);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [toast, setToast] = useState<{
    message: string;
    type: 'success' | 'error' | 'info';
  } | null>(null);
  const [currentUser, setCurrentUser] = useState<AuthUser | null>(() => getStoredUser());
  const [isLoginModalOpen, setIsLoginModalOpen] = useState<boolean>(() => !getAuthToken());

  const showToast = useCallback(
    (message: string, type: 'success' | 'error' | 'info' = 'success') => {
      setToast({ message, type });
      window.setTimeout(() => {
        setToast(null);
      }, 4500);
    },
    []
  );

  const loadMonitoringData = useCallback(
    async (quiet = false) => {
      if (!quiet) setIsLoadingMonitoring(true);
      try {
        const [lahanRows, summaryData] = await Promise.all([
          fetchMonitoringLahan('all'),
          fetchMonitoringSummary(),
        ]);
        setPlots(lahanRows);
        setSummary(summaryData);
      } catch (err) {
        console.error('[WEB] Error fetching Sumenep monitoring data:', err);
        if (!quiet) {
          showToast(
            err instanceof Error ? err.message : 'Gagal memuat data monitoring Sumenep.',
            'error'
          );
        }
      } finally {
        if (!quiet) setIsLoadingMonitoring(false);
      }
    },
    [showToast]
  );

  const loadData = useCallback(
    async (quiet = false) => {
      if (!quiet) setIsLoading(true);
      try {
        const data = await fetchPendingFarmers();
        setFarmers(data);
        if (data.length > 0) {
          setSelectedFarmerId((prevId) => {
            const exists = data.some((f) => f.id === prevId || f.user_id === prevId);
            return exists ? prevId : data[0].id || data[0].user_id;
          });
        } else {
          setSelectedFarmerId('');
        }
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Gagal memuat antrean petani.';
        console.error('[WEB] Error fetching pending farmers:', err);
        if (message.includes('401')) {
          setIsLoginModalOpen(true);
          showToast('Sesi autentikasi belum tersedia atau kedaluwarsa. Silakan masuk.', 'error');
        } else {
          showToast(message, 'error');
        }
      } finally {
        if (!quiet) setIsLoading(false);
      }
    },
    [showToast]
  );

  useEffect(() => {
    void loadMonitoringData();
    if (getAuthToken()) {
      void loadData();
    } else {
      setIsLoading(false);
      setIsLoginModalOpen(true);
    }
  }, [loadData, loadMonitoringData]);

  const handleLoginSuccess = (user: AuthUser) => {
    setCurrentUser(user);
    setIsLoginModalOpen(false);
    showToast(`Berhasil masuk sebagai ${user.full_name || 'Penyuluh Pertanian'}.`, 'success');
    void loadData();
    void loadMonitoringData(true);
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
    } catch (err: unknown) {
      const message =
        err instanceof Error ? err.message : 'Terjadi kesalahan saat memproses permohonan.';
      console.error('[WEB] Verification failed:', err);
      if (message.includes('401')) {
        setIsLoginModalOpen(true);
      }
      showToast(message, 'error');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleSyncAll = async () => {
    setIsSyncing(true);
    try {
      await Promise.all([loadMonitoringData(true), getAuthToken() ? loadData(true) : Promise.resolve()]);
      showToast('Sinkronisasi Portal Penyuluh Sumenep berhasil diperbarui.', 'info');
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

  const handlePlotUpdated = (updated: LandPlotRecord) => {
    setPlots((prev) => prev.map((p) => (p.id === updated.id ? updated : p)));
    setInspectedPlot((prev) => (prev && prev.id === updated.id ? updated : prev));
    void loadMonitoringData(true);
  };

  const selectedFarmer =
    farmers.find((f) => f.id === selectedFarmerId || f.user_id === selectedFarmerId) ||
    (farmers.length > 0 ? farmers[0] : null);

  const displayedFarmers = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    if (!q) return farmers;
    return farmers.filter(
      (f) =>
        (f.name || f.full_name || '').toLowerCase().includes(q) ||
        (f.nik || f.nik_number || '').includes(q) ||
        (f.poktan || '').toLowerCase().includes(q) ||
        (f.village || '').toLowerCase().includes(q)
    );
  }, [farmers, searchQuery]);

  const displayedPlots = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    if (!q) return plots;
    return plots.filter((p) =>
      [p.nama_desa, p.kecamatan, p.kelompok_tani, p.komoditas, p.varietas]
        .filter(Boolean)
        .some((v) => String(v).toLowerCase().includes(q))
    );
  }, [plots, searchQuery]);

  const criticalPlotCount = useMemo(() => plots.filter(isPlotCritical).length, [plots]);

  return (
    <div className="text-neutral-dark antialiased bg-[#F8FAF9] min-h-screen flex flex-col">
      {/* Toast Notification */}
      {toast && (
        <div
          className={`fixed bottom-5 right-5 z-[60] px-4 py-3 rounded-xl shadow-lg border text-[13px] font-semibold flex items-center gap-2.5 transition-all ${
            toast.type === 'success'
              ? 'bg-[#0D5136] text-white border-emerald-700'
              : toast.type === 'error'
                ? 'bg-rose-800 text-white border-rose-600'
                : 'bg-[#166534] text-white border-emerald-600'
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
        onSync={handleSyncAll}
        isSyncing={isSyncing}
        currentUser={currentUser}
        onOpenLogin={() => setIsLoginModalOpen(true)}
      />

      <div className="flex pt-16 min-h-screen">
        {/* LEFT SIDEBAR (Deep Forest Green SmartAgri x LapakTani) */}
        <Sidebar
          pendingCount={farmers.length}
          criticalPlotCount={criticalPlotCount}
          activeTab={activeTab}
          onTabChange={setActiveTab}
          currentUser={currentUser}
          onLogout={handleLogout}
        />

        {/* MAIN WORKSPACE */}
        <main className="flex-1 md:pl-64 lg:pl-72 p-4 lg:p-8 overflow-x-hidden">
          <div className="max-w-[1440px] mx-auto space-y-6">
            {/* Compact Mobile View Switcher */}
            <div className="flex md:hidden gap-1.5 overflow-x-auto pb-1">
              {MOBILE_TABS.map((tab) => {
                const active = activeTab === tab.id;
                return (
                  <button
                    key={tab.id}
                    type="button"
                    onClick={() => setActiveTab(tab.id)}
                    className={`shrink-0 py-2 px-3 rounded-xl text-[12px] font-bold transition-all ${
                      active
                        ? 'bg-[#0D5136] text-white shadow-sm'
                        : 'bg-white text-gray-700 border border-[#E2E8F0]'
                    }`}
                  >
                    {tab.label}
                    {tab.id === 'validasi' ? ` (${farmers.length})` : ''}
                  </button>
                );
              })}
            </div>

            {activeTab === 'dashboard' && (
              <SmartAgriDashboard
                plots={displayedPlots}
                summary={summary}
                pendingFarmerCount={farmers.length}
                isLoading={isLoadingMonitoring}
                onRefresh={() => void loadMonitoringData(false)}
                onNavigateTab={setActiveTab}
                onInspectPlot={setInspectedPlot}
              />
            )}

            {activeTab === 'peta-lahan' && (
              <SumenepLandMonitoring
                plots={displayedPlots}
                isLoading={isLoadingMonitoring}
                onRefresh={() => void loadMonitoringData(false)}
                onInspectPlot={setInspectedPlot}
              />
            )}

            {activeTab === 'data-sensor' && (
              <SensorDataTable
                plots={displayedPlots}
                isLoading={isLoadingMonitoring}
                onRefresh={() => void loadMonitoringData(false)}
                onInspectPlot={setInspectedPlot}
              />
            )}

            {activeTab === 'policy-brief' && (
              <AiPolicyBrief
                plots={displayedPlots}
                summary={summary}
                onRefresh={() => void loadMonitoringData(false)}
                onInspectPlot={setInspectedPlot}
              />
            )}

            {activeTab === 'validasi' && (
              <>
                <HeroBanner
                  totalQueue={farmers.length}
                  onSync={handleSyncAll}
                  onQuickReview={handleQuickReview}
                  isSyncing={isSyncing}
                />

                <div className="grid grid-cols-1 xl:grid-cols-12 gap-6 items-start">
                  <QueueTable
                    farmers={displayedFarmers}
                    selectedFarmerId={selectedFarmerId}
                    onSelectFarmer={(farmer) =>
                      setSelectedFarmerId(farmer.id || farmer.user_id)
                    }
                    isLoading={isLoading}
                    onRefresh={() => void loadData(false)}
                  />

                  <AuditDesk
                    farmer={selectedFarmer}
                    onVerify={handleVerify}
                    isProcessing={isProcessing}
                  />
                </div>
              </>
            )}
          </div>
        </main>
      </div>

      {/* Click-to-Inspect 8-in-1 Drawer Modal */}
      <PlotInspectorModal
        plot={inspectedPlot}
        onClose={() => setInspectedPlot(null)}
        onPlotUpdated={handlePlotUpdated}
        onShowToast={showToast}
      />

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
