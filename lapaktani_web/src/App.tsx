import { useState, useEffect, useMemo } from 'react';
import { MapPin, ChevronDown, FolderArchive, CheckCircle2, AlertCircle } from 'lucide-react';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { StatCards } from './components/StatCards';
import { QueueTable } from './components/QueueTable';
import { FarmerDetailPanel } from './components/FarmerDetailPanel';
import { RejectionModal } from './components/RejectionModal';
import { mockApi, type FarmerProfile, INITIAL_FARMERS } from './services/mockApi';

export function App() {
  const [farmers, setFarmers] = useState<FarmerProfile[]>(INITIAL_FARMERS);
  const [selectedFarmerId, setSelectedFarmerId] = useState<string>(INITIAL_FARMERS[0].id);
  const [statusFilter, setStatusFilter] = useState<'all' | 'pending' | 'verified' | 'rejected'>('all');
  const [selectedPoktan, setSelectedPoktan] = useState<string>('all');
  const [selectedCommodity, setSelectedCommodity] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [isRejectModalOpen, setIsRejectModalOpen] = useState<boolean>(false);
  const [isProcessing, setIsProcessing] = useState<boolean>(false);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);
  const [toastMessage, setToastMessage] = useState<{ type: 'success' | 'info'; message: string } | null>(null);

  // Load initial data
  useEffect(() => {
    mockApi.fetchAllFarmers().then((data) => {
      setFarmers(data);
      if (data.length > 0 && !selectedFarmerId) {
        setSelectedFarmerId(data[0].id);
      }
    });
  }, []);

  const showToast = (message: string, type: 'success' | 'info' = 'success') => {
    setToastMessage({ message, type });
    setTimeout(() => {
      setToastMessage(null);
    }, 4500);
  };

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      const data = await mockApi.fetchAllFarmers();
      setFarmers(data);
      showToast('Data antrean berhasil disinkronkan.', 'info');
    } finally {
      setIsRefreshing(false);
    }
  };

  const handleExportCsv = () => {
    const csvContent =
      'data:text/csv;charset=utf-8,' +
      ['ID,Nama,NIK,Poktan,Desa,Lahan,Status']
        .concat(
          farmers.map(
            (f) =>
              `"${f.id}","${f.full_name}","${f.nik}","${f.poktan}","${f.village}","${f.land_area}","${f.status}"`
          )
        )
        .join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `lapaktani_permohonan_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    showToast('File CSV berhasil diunduh.', 'success');
  };

  // Filter farmers based on status, poktan, commodity, and search query
  const filteredFarmers = useMemo(() => {
    return farmers.filter((farmer) => {
      // Status filter
      if (statusFilter !== 'all' && farmer.status !== statusFilter) {
        return false;
      }

      // Poktan filter
      if (selectedPoktan !== 'all' && farmer.poktan !== selectedPoktan) {
        return false;
      }

      // Commodity filter
      if (selectedCommodity !== 'all') {
        const hasCommodity = farmer.commodities.some((c) => {
          const name = c.name.toLowerCase();
          if (selectedCommodity === 'sayuran') return name.includes('brokoli') || name.includes('kubis') || name.includes('wortel') || name.includes('selada') || name.includes('bawang');
          if (selectedCommodity === 'buah') return name.includes('stroberi') || name.includes('alpukat') || name.includes('tomat') || name.includes('paprika');
          if (selectedCommodity === 'kopi') return name.includes('kopi');
          return true;
        });
        if (!hasCommodity) return false;
      }

      // Search query filter
      if (searchQuery.trim() !== '') {
        const q = searchQuery.toLowerCase();
        const matchName = farmer.full_name.toLowerCase().includes(q);
        const matchNik = farmer.nik.replace(/\s+/g, '').includes(q.replace(/\s+/g, ''));
        const matchPoktan = farmer.poktan.toLowerCase().includes(q);
        const matchVillage = farmer.village.toLowerCase().includes(q);
        if (!matchName && !matchNik && !matchPoktan && !matchVillage) {
          return false;
        }
      }

      return true;
    });
  }, [farmers, statusFilter, selectedPoktan, selectedCommodity, searchQuery]);

  const selectedFarmer = useMemo(() => {
    return farmers.find((f) => f.id === selectedFarmerId) || filteredFarmers[0] || farmers[0] || null;
  }, [farmers, selectedFarmerId, filteredFarmers]);

  const pendingCount = useMemo(() => {
    return farmers.filter((f) => f.status === 'pending').length;
  }, [farmers]);

  const verifiedCount = useMemo(() => {
    return farmers.filter((f) => f.status === 'verified').length;
  }, [farmers]);

  const rejectedCount = useMemo(() => {
    return farmers.filter((f) => f.status === 'rejected').length;
  }, [farmers]);

  const handleApproveFarmer = async () => {
    if (!selectedFarmer) return;
    setIsProcessing(true);
    try {
      const res = await mockApi.approveFarmer(selectedFarmer.id);
      setFarmers((prev) => prev.map((f) => (f.id === res.farmer.id ? res.farmer : f)));
      showToast(
        `Akun petani "${selectedFarmer.full_name}" berhasil divalidasi dan diaktifkan di LapakTani. Kredensial telah disinkronkan ke Supabase Auth.`,
        'success'
      );
    } catch (err: any) {
      alert(err?.message || 'Gagal menyetujui akun');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleRejectConfirm = async (reason: string, note?: string) => {
    if (!selectedFarmer) return;
    setIsProcessing(true);
    try {
      const res = await mockApi.rejectFarmer(selectedFarmer.id, reason, note);
      setFarmers((prev) => prev.map((f) => (f.id === res.farmer.id ? res.farmer : f)));
      setIsRejectModalOpen(false);
      showToast(
        `Permohonan petani "${selectedFarmer.full_name}" telah dialihkan ke status "Revisi Dokumen". Notifikasi WhatsApp berhasil dikirim ke nomor petani binaan.`,
        'info'
      );
    } catch (err: any) {
      alert(err?.message || 'Gagal menolak akun');
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <div className="max-w-[1560px] mx-auto border-2 border-brutal-border rounded-3xl bg-canvas shadow-brutal-lg overflow-hidden flex flex-col min-h-[92vh]">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed top-6 right-6 z-50 animate-in slide-in-from-top duration-300">
          <div
            className={`px-4 py-3 rounded-2xl border-2 border-brutal-border shadow-brutal flex items-center gap-3 text-xs font-bold ${
              toastMessage.type === 'success'
                ? 'bg-emerald-50 text-emerald-950 border-emerald-900'
                : 'bg-amberSoft text-amberText border-amber-900'
            }`}
          >
            {toastMessage.type === 'success' ? (
              <CheckCircle2 className="w-5 h-5 text-brand shrink-0" />
            ) : (
              <AlertCircle className="w-5 h-5 text-amber-700 shrink-0" />
            )}
            <span>{toastMessage.message}</span>
          </div>
        </div>
      )}

      {/* Top Window / Browser Bar style header */}
      <div className="px-5 py-3 border-b-2 border-brutal-border bg-cream-100 flex items-center justify-between text-xs font-bold tracking-wider text-slate-600">
        <div className="flex items-center gap-2">
          <span className="inline-block w-3 h-3 rounded-full bg-rose-400 border border-brutal-border"></span>
          <span className="inline-block w-3 h-3 rounded-full bg-amber-300 border border-brutal-border"></span>
          <span className="inline-block w-3 h-3 rounded-full bg-emerald-400 border border-brutal-border"></span>
          <span className="ml-2 font-mono uppercase text-[11px] text-slate-500">
            LAPAKTANI // PPL BINAAN PORTAL • VERIFIKASI AKUN PETANI [US-06]
          </span>
        </div>
        <div className="flex items-center gap-3 font-mono text-[11px]">
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-cream-50 border border-brutal-border font-semibold">
            <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse"></span>
            Supabase Sync: Active
          </span>
          <span className="hidden sm:inline text-slate-400">v2.4-soft-brutal</span>
        </div>
      </div>

      <div className="flex flex-col lg:flex-row flex-1 min-h-0">
        {/* PERSISTENT LEFT SIDEBAR */}
        <Sidebar pendingCount={pendingCount} />

        {/* RIGHT WORKSPACE WITH DEDICATED TOP HEADER */}
        <div className="flex-1 flex flex-col min-w-0 bg-canvas">
          {/* Dedicated Top Header Bar */}
          <Header
            searchQuery={searchQuery}
            onSearchChange={setSearchQuery}
            onRefresh={handleRefresh}
            onExportCsv={handleExportCsv}
            isRefreshing={isRefreshing}
          />

          {/* Main Content Canvas */}
          <main className="flex-1 p-5 md:p-8 flex flex-col gap-6 bg-canvas overflow-y-auto">
            {/* Hero Header & Section Title */}
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 pb-2">
              <div>
                <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-cream-200/80 border border-brutal-border text-xs font-bold text-slate-700 mb-2 shadow-brutal-sm">
                  <span>Dashboard</span>
                  <span className="text-slate-400">/</span>
                  <span>Validasi &amp; Persetujuan</span>
                  <span className="text-slate-400">/</span>
                  <span className="text-brand font-extrabold">[US-06] Permohonan Akun Petani</span>
                </div>
                <h1 className="text-2xl md:text-3xl lg:text-4xl font-extrabold tracking-tight text-brutal-dark">
                  Validasi &amp; Persetujuan Akun Petani
                </h1>
                <p className="text-sm text-slate-600 font-medium max-w-3xl mt-1">
                  Validasi keabsahan berkas permohonan petani binaan wilayah Lembang &amp; Ciwidey untuk akses penjualan
                  komoditas langsung dan kepemilikan lahan sah.
                </p>
              </div>
              <div className="flex items-center gap-2.5 flex-wrap">
                <div className="px-4 py-2 rounded-xl bg-brand-light border-2 border-brutal-border shadow-brutal text-xs font-bold text-brutal-dark flex items-center gap-2">
                  <MapPin className="w-[17px] h-[17px] text-brand" />
                  <span>
                    Wilayah: <strong>Lembang Raya</strong>
                  </span>
                  <ChevronDown className="w-[16px] h-[16px] text-slate-400" />
                </div>
              </div>
            </div>

            {/* KPI BENTO METRIC TILES */}
            <StatCards
              totalCount={24}
              pendingCount={pendingCount + 11}
              verifiedCount={verifiedCount + 47}
              rejectedCount={rejectedCount + 2}
            />

            {/* TWO-COLUMN WORKSPACE */}
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
              {/* LEFT COLUMN: Applications Queue Bento (7 Cols) */}
              <div className="lg:col-span-7">
                <QueueTable
                  farmers={filteredFarmers}
                  selectedFarmerId={selectedFarmer?.id || ''}
                  onSelectFarmer={(f) => setSelectedFarmerId(f.id)}
                  statusFilter={statusFilter}
                  onStatusFilterChange={setStatusFilter}
                  selectedPoktan={selectedPoktan}
                  onPoktanChange={setSelectedPoktan}
                  selectedCommodity={selectedCommodity}
                  onCommodityChange={setSelectedCommodity}
                  pendingCount={pendingCount}
                />
              </div>

              {/* RIGHT COLUMN: Farmer Inspection & Validation Dock Bento (5 Cols) */}
              <div className="lg:col-span-5">
                <FarmerDetailPanel
                  farmer={selectedFarmer}
                  onOpenRejectModal={() => setIsRejectModalOpen(true)}
                  onApproveFarmer={handleApproveFarmer}
                  isProcessing={isProcessing}
                />
              </div>
            </div>

            {/* Realtime Supabase Footer Ribbon */}
            <div className="mt-2 p-3 rounded-2xl bg-cream-100 border-2 border-brutal-border shadow-brutal-sm flex items-center justify-between flex-wrap gap-2 text-xs font-semibold text-slate-700">
              <div className="flex items-center gap-2.5">
                <span className="flex h-2.5 w-2.5 relative">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-brand opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-brand"></span>
                </span>
                <span>
                  <strong>Supabase Realtime:</strong> Terkoneksi ke 24 tabel skema LapakTani
                </span>
              </div>
              <div className="flex items-center gap-2">
                <span className="px-2.5 py-0.5 rounded-full bg-white border border-brutal-border font-mono text-[11px] text-slate-600 flex items-center gap-1">
                  <FolderArchive className="w-[14px] h-[14px] text-brand" />
                  bucket: lapaktani-ktp-docs
                </span>
                <span className="text-slate-400">|</span>
                <span className="text-slate-500 text-[11px]">Sistem Penyuluh Pertanian Lapangan (PPL) RI</span>
              </div>
            </div>
          </main>
        </div>
      </div>

      {/* Rejection Modal */}
      <RejectionModal
        isOpen={isRejectModalOpen}
        farmerName={selectedFarmer ? selectedFarmer.full_name.replace(/^(Pak|Bpk\.|Bu)\s+/, '') : ''}
        onClose={() => setIsRejectModalOpen(false)}
        onConfirm={handleRejectConfirm}
        isProcessing={isProcessing}
      />
    </div>
  );
}

export default App;
