import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  fetchPlatformFeeLedger,
  fetchSumenepVillages,
  fetchSuperAdminAuthorities,
  fetchSuperAdminOverview,
  fetchSuperAdminStores,
  provisionAuthorityAccount,
  toggleAuthorityStatus,
  updateSuperAdminStoreStatus,
  type AuthorityAccountRecord,
  type AuthUser,
  type PlatformFeeLedgerEntry,
  type SumenepVillageOption,
  type SuperAdminOverviewResponse,
  type SuperAdminStoreRecord,
} from '../services/api';

interface SuperAdminGovernanceHubProps {
  currentUser: AuthUser | null;
  onShowToast: (message: string, type?: 'success' | 'error' | 'info') => void;
}

type HubSection = 'overview' | 'authorities' | 'stores' | 'ledger';

const ROLE_BADGE_MAP: Record<string, { label: string; cls: string }> = {
  superadmin: { label: 'Super Admin', cls: 'bg-lt-tertiary-tint text-lt-tertiary-text border border-lt-tertiary-border' },
  dinas: { label: 'Dinas Pertanian', cls: 'bg-lt-tertiary-tint text-lt-tertiary-text' },
  penyuluh: { label: 'Penyuluh BPP', cls: 'bg-lt-primary-tint text-lt-primary' },
  admin: { label: 'Admin Toko', cls: 'bg-lt-secondary-tint text-lt-secondary-dark' },
  petani: { label: 'Petani', cls: 'bg-lt-primary-tint text-lt-primary-dark' },
  pembeli: { label: 'Pembeli / B2B', cls: 'bg-lt-surface-canvas text-lt-neutral' },
};

const STORE_STATUS_CLS: Record<string, string> = {
  APPROVED: 'bg-lt-primary-tint text-lt-primary border-lt-primary-border',
  PENDING_PPL: 'bg-lt-tertiary-tint text-lt-tertiary-text border-lt-tertiary-border',
  SUSPENDED: 'bg-lt-error-tint text-lt-error border-lt-error-border',
  REJECTED: 'bg-lt-error-tint text-lt-error border-lt-error-border',
  DRAFT_FROZEN: 'bg-lt-surface-canvas text-lt-neutral border-lt-border',
};

function formatRupiah(value: number | string | undefined | null): string {
  const num = Number(value || 0);
  if (!Number.isFinite(num)) return 'Rp 0';
  return `Rp ${Math.round(num).toLocaleString('id-ID')}`;
}

export const SuperAdminGovernanceHub: React.FC<SuperAdminGovernanceHubProps> = ({
  currentUser,
  onShowToast,
}) => {
  const [section, setSection] = useState<HubSection>('authorities');
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  const [overview, setOverview] = useState<SuperAdminOverviewResponse | null>(null);
  const [authorities, setAuthorities] = useState<AuthorityAccountRecord[]>([]);
  const [stores, setStores] = useState<SuperAdminStoreRecord[]>([]);
  const [ledger, setLedger] = useState<PlatformFeeLedgerEntry[]>([]);
  const [ledgerSummary, setLedgerSummary] = useState<{
    count: number;
    total_fees: number;
    total_refunded: number;
  }>({ count: 0, total_fees: 0, total_refunded: 0 });
  const [villages, setVillages] = useState<SumenepVillageOption[]>([]);

  const [storeTierFilter, setStoreTierFilter] = useState<string>('ALL');
  const [storeStatusFilter, setStoreStatusFilter] = useState<string>('ALL');

  // Authority Provisioning Form State
  const [roleType, setRoleType] = useState<'penyuluh' | 'dinas'>('penyuluh');
  const [fullName, setFullName] = useState<string>('');
  const [email, setEmail] = useState<string>('');
  const [password, setPassword] = useState<string>('LapakTani#2026');
  const [villageId, setVillageId] = useState<number>(109);
  const [bppUnit, setBppUnit] = useState<string>('BPP Kecamatan Gapura');
  const [nip, setNip] = useState<string>('');
  const [phone, setPhone] = useState<string>('');

  const loadGovernanceData = useCallback(async () => {
    setIsLoading(true);
    try {
      const [ov, authList, storeList, ledgerRes, villageList] = await Promise.all([
        fetchSuperAdminOverview(),
        fetchSuperAdminAuthorities(),
        fetchSuperAdminStores(),
        fetchPlatformFeeLedger(),
        fetchSumenepVillages(),
      ]);
      setOverview(ov);
      setAuthorities(authList);
      setStores(storeList);
      setLedger(ledgerRes.data);
      setLedgerSummary(ledgerRes.summary);
      if (villageList.length > 0) {
        setVillages(villageList);
        if (!villageList.some((v) => v.id === villageId)) {
          setVillageId(villageList[0].id);
        }
      }
    } catch (err) {
      onShowToast(
        err instanceof Error ? err.message : 'Gagal memuat pusat tata kelola Super Admin.',
        'error'
      );
    } finally {
      setIsLoading(false);
    }
  }, [onShowToast, villageId]);

  useEffect(() => {
    void loadGovernanceData();
  }, [loadGovernanceData]);

  const handleProvision = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!fullName.trim() || !email.trim() || !password.trim()) {
      onShowToast('Nama lengkap, email resmi, dan kata sandi wajib diisi.', 'error');
      return;
    }
    setIsSubmitting(true);
    try {
      const created = await provisionAuthorityAccount({
        full_name: fullName.trim(),
        email: email.trim().toLowerCase(),
        password: password.trim(),
        role: roleType,
        village_id: villageId,
        bpp_unit: roleType === 'dinas' ? 'Dinas Pertanian Kab. Sumenep' : bppUnit.trim(),
        nip: nip.trim() || undefined,
        phone: phone.trim() || undefined,
      });
      onShowToast(
        `Akun ${created.role.toUpperCase()} '${created.full_name}' berhasil diterbitkan.`,
        'success'
      );
      setFullName('');
      setEmail('');
      setNip('');
      setPhone('');
      await loadGovernanceData();
    } catch (err) {
      onShowToast(err instanceof Error ? err.message : 'Gagal menerbitkan akun otoritas.', 'error');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleToggleAuthority = async (auth: AuthorityAccountRecord) => {
    try {
      await toggleAuthorityStatus(auth.id, !auth.is_active);
      onShowToast(
        `Akun '${auth.full_name}' kini ${!auth.is_active ? 'AKTIF' : 'DINONAKTIFKAN'}.`,
        'info'
      );
      await loadGovernanceData();
    } catch (err) {
      onShowToast(err instanceof Error ? err.message : 'Gagal memperbarui status otoritas.', 'error');
    }
  };

  const handleStoreAction = async (
    store: SuperAdminStoreRecord,
    action: 'APPROVE' | 'SUSPEND' | 'REACTIVATE'
  ) => {
    const reason =
      action === 'SUSPEND'
        ? window.prompt(`Alasan pembekuan toko '${store.nama_toko}':`, 'Audit kepatuhan 2-Tier Super Admin') ||
          'Dibekukan oleh Super Admin'
        : undefined;
    try {
      await updateSuperAdminStoreStatus(store.id, action, reason);
      onShowToast(`Status toko '${store.nama_toko}' diperbarui (${action}).`, 'success');
      await loadGovernanceData();
    } catch (err) {
      onShowToast(err instanceof Error ? err.message : 'Gagal memperbarui status toko.', 'error');
    }
  };

  const totalUsers = useMemo(
    () => (overview?.users_by_role || []).reduce((sum, r) => sum + Number(r.total || 0), 0),
    [overview]
  );

  const b2bCount = useMemo(
    () => stores.filter((s) => (s.admin_tier || 'B2B_OFFTAKER') === 'B2B_OFFTAKER').length,
    [stores]
  );
  const retailCount = useMemo(
    () => stores.filter((s) => s.admin_tier === 'RETAIL_MERCHANT').length,
    [stores]
  );

  const filteredStores = useMemo(() => {
    return stores.filter((s) => {
      const tier = s.admin_tier || 'B2B_OFFTAKER';
      const tierOk = storeTierFilter === 'ALL' || tier === storeTierFilter;
      const statusOk = storeStatusFilter === 'ALL' || s.status === storeStatusFilter;
      return tierOk && statusOk;
    });
  }, [stores, storeTierFilter, storeStatusFilter]);

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="rounded-2xl bg-lt-surface-card border border-lt-border border-l-4 border-l-lt-primary p-6 shadow-sm flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-lt-tertiary-tint text-lt-tertiary-text border border-lt-tertiary-border text-[11px] font-extrabold uppercase tracking-wider mb-2">
            <span className="material-symbols-outlined text-[15px]">admin_panel_settings</span>
            <span>6-Role RBAC · Super Admin Governance</span>
          </div>
          <h1 className="text-xl lg:text-2xl font-extrabold tracking-tight text-lt-neutral">
            Pusat Tata Kelola &amp; Audit LapakTani Sumenep
          </h1>
          <p className="text-[13px] text-lt-neutral-muted mt-1 max-w-2xl">
            Provisioning akun resmi Dinas Pertanian &amp; Penyuluh BPP (registrasi publik terkunci),
            audit toko 2-tier (B2B Offtaker &amp; Retail Auto-KYC), serta pemantauan buku kas Refund Hybrid 2%.
          </p>
        </div>
        <div className="flex items-center gap-3 shrink-0">
          <div className="px-4 py-2.5 rounded-2xl bg-lt-surface-canvas border border-lt-border text-right">
            <div className="text-[10.5px] uppercase tracking-wider text-lt-neutral-muted font-bold">
              Kesehatan 9 Modul MVP
            </div>
            <div className="text-[18px] font-extrabold text-lt-primary">
              {overview?.mvp_9_health?.compliance_score || '9/9 (100%)'}
            </div>
          </div>
          <button
            type="button"
            onClick={() => void loadGovernanceData()}
            disabled={isLoading}
            className="px-4 py-3 rounded-2xl bg-lt-primary hover:bg-lt-primary-dark text-white font-extrabold text-[12.5px] flex items-center gap-1.5 shadow-sm transition-colors disabled:opacity-60"
          >
            <span className={`material-symbols-outlined text-[18px] ${isLoading ? 'animate-spin' : ''}`}>
              refresh
            </span>
            <span>Muat Ulang</span>
          </button>
        </div>
      </div>

      {/* KPI Strip */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <div className="bg-white rounded-2xl p-5 border border-lt-border shadow-sm">
          <div className="text-[11px] font-bold uppercase tracking-wider text-lt-neutral-muted">
            Total Pengguna 6-Role
          </div>
          <div className="text-2xl font-extrabold text-lt-neutral mt-1">{totalUsers} Akun</div>
          <div className="text-[11.5px] text-lt-neutral-muted mt-1">
            Operator aktif: <strong className="text-lt-primary">{currentUser?.full_name || 'Super Admin'}</strong>
          </div>
        </div>
        <div className="bg-white rounded-2xl p-5 border border-lt-border shadow-sm">
          <div className="text-[11px] font-bold uppercase tracking-wider text-lt-neutral-muted">
            Akun Otoritas Resmi
          </div>
          <div className="text-2xl font-extrabold text-lt-primary mt-1">
            {authorities.filter((a) => a.is_active).length} / {authorities.length} Aktif
          </div>
          <div className="text-[11.5px] text-lt-neutral-muted mt-1">
            Dinas Pertanian &amp; Penyuluh BPP terkunci dari daftar mandiri
          </div>
        </div>
        <div className="bg-white rounded-2xl p-5 border border-lt-border shadow-sm">
          <div className="text-[11px] font-bold uppercase tracking-wider text-lt-neutral-muted">
            Toko 2-Tier Terdaftar
          </div>
          <div className="text-2xl font-extrabold text-lt-neutral mt-1">{stores.length} Toko</div>
          <div className="text-[11.5px] text-lt-neutral-muted mt-1">
            <span className="font-bold text-lt-primary">{b2bCount} B2B Offtaker</span> ·{' '}
            <span className="font-bold text-lt-tertiary-text">{retailCount} Retail Auto-KYC</span>
          </div>
        </div>
        <div className="bg-white rounded-2xl p-5 border border-lt-border shadow-sm">
          <div className="text-[11px] font-bold uppercase tracking-wider text-lt-neutral-muted">
            Pendapatan Fee Refund 2%
          </div>
          <div className="text-2xl font-extrabold text-lt-tertiary-text mt-1">
            {formatRupiah(overview?.fee_ledger_summary?.total_fee_collected ?? ledgerSummary.total_fees)}
          </div>
          <div className="text-[11.5px] text-lt-neutral-muted mt-1">
            Total refund bersih: {formatRupiah(overview?.fee_ledger_summary?.total_refunded_to_users ?? ledgerSummary.total_refunded)}
          </div>
        </div>
      </div>

      {/* Sub-navigation Tabs */}
      <div className="flex flex-wrap gap-2 bg-white p-2 rounded-2xl border border-lt-border shadow-sm">
        {(
          [
            { id: 'authorities', label: 'Provisioning Dinas & Penyuluh', icon: 'verified_user' },
            { id: 'stores', label: 'Pengawasan Toko (B2B & Retail Auto-KYC)', icon: 'storefront' },
            { id: 'ledger', label: 'Platform Fee Ledger (Refund 2%)', icon: 'account_balance_wallet' },
            { id: 'overview', label: 'Distribusi 6-Role & Kesehatan MVP', icon: 'monitoring' },
          ] as const
        ).map((tab) => {
          const active = section === tab.id;
          return (
            <button
              key={tab.id}
              type="button"
              onClick={() => setSection(tab.id)}
              className={`px-4 py-2.5 rounded-xl text-[12.5px] font-extrabold flex items-center gap-2 transition-all ${
                active
                  ? 'bg-lt-primary text-white shadow-sm'
                  : 'text-lt-neutral-muted hover:bg-lt-surface-canvas hover:text-lt-neutral'
              }`}
            >
              <span className="material-symbols-outlined text-[18px]">{tab.icon}</span>
              <span>{tab.label}</span>
            </button>
          );
        })}
      </div>

      {/* SECTION 1: AUTHORITIES PROVISIONING & TABLE */}
      {section === 'authorities' && (
        <div className="grid grid-cols-1 xl:grid-cols-12 gap-6 items-start">
          <form
            onSubmit={handleProvision}
            className="xl:col-span-5 bg-white rounded-2xl p-6 border border-lt-border shadow-sm space-y-4"
          >
            <div>
              <h2 className="text-[16px] font-extrabold text-lt-neutral">
                Terbitkan Akun Dinas / Penyuluh BPP
              </h2>
              <p className="text-[12px] text-lt-neutral-muted mt-0.5">
                Hanya Super Admin yang dapat membuat akun otoritas (endpoint `/auth/register` publik diblokir 403).
              </p>
            </div>

            <div className="grid grid-cols-2 gap-2">
              {(['penyuluh', 'dinas'] as const).map((r) => (
                <button
                  key={r}
                  type="button"
                  onClick={() => setRoleType(r)}
                  className={`py-2.5 px-3 rounded-xl border text-[12.5px] font-extrabold transition-all ${
                    roleType === r
                      ? 'bg-lt-primary-tint border-lt-primary text-lt-neutral ring-2 ring-lt-primary/25'
                      : 'bg-lt-surface-canvas border-lt-border text-lt-neutral-muted'
                  }`}
                >
                  {r === 'penyuluh' ? 'Penyuluh BPP (Role 2)' : 'Dinas Pertanian (Role 5)'}
                </button>
              ))}
            </div>

            <div>
              <label className="block text-[11.5px] font-bold text-lt-neutral mb-1">
                Nama Lengkap &amp; Gelar
              </label>
              <input
                type="text"
                required
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                placeholder="Ir. Ahmad Fathoni, M.P."
                className="w-full h-10 px-3 rounded-xl border border-lt-border text-[13px] focus:border-lt-primary outline-none"
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block text-[11.5px] font-bold text-lt-neutral mb-1">
                  Email Resmi
                </label>
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="ppl.gapura@lapaktani.id"
                  className="w-full h-10 px-3 rounded-xl border border-lt-border text-[13px] focus:border-lt-primary outline-none"
                />
              </div>
              <div>
                <label className="block text-[11.5px] font-bold text-lt-neutral mb-1">
                  Kata Sandi Awal
                </label>
                <input
                  type="text"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full h-10 px-3 rounded-xl border border-lt-border text-[13px] focus:border-lt-primary outline-none"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block text-[11.5px] font-bold text-lt-neutral mb-1">
                  Wilayah Desa / Kecamatan
                </label>
                <select
                  value={villageId}
                  onChange={(e) => setVillageId(Number(e.target.value))}
                  className="w-full h-10 px-3 rounded-xl border border-lt-border text-[13px] bg-white focus:border-lt-primary outline-none"
                >
                  {villages.length > 0 ? (
                    villages.map((v) => (
                      <option key={v.id} value={v.id}>
                        {v.name} {v.district_name ? `(${v.district_name})` : ''}
                      </option>
                    ))
                  ) : (
                    <>
                      <option value={109}>Desa Bangselok / Kota Sumenep (#109)</option>
                      <option value={108}>Desa Karangduak (#108)</option>
                      <option value={107}>Kec. Gapura (#107)</option>
                    </>
                  )}
                </select>
              </div>
              <div>
                <label className="block text-[11.5px] font-bold text-lt-neutral mb-1">
                  Unit BPP / Instansi
                </label>
                <input
                  type="text"
                  value={roleType === 'dinas' ? 'Dinas Pertanian Kab. Sumenep' : bppUnit}
                  disabled={roleType === 'dinas'}
                  onChange={(e) => setBppUnit(e.target.value)}
                  className="w-full h-10 px-3 rounded-xl border border-lt-border text-[13px] disabled:bg-lt-surface-canvas focus:border-lt-primary outline-none"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block text-[11.5px] font-bold text-lt-neutral mb-1">
                  NIP (Opsional)
                </label>
                <input
                  type="text"
                  value={nip}
                  onChange={(e) => setNip(e.target.value)}
                  placeholder="198507122015031002"
                  className="w-full h-10 px-3 rounded-xl border border-lt-border text-[13px] focus:border-lt-primary outline-none"
                />
              </div>
              <div>
                <label className="block text-[11.5px] font-bold text-lt-neutral mb-1">
                  No. HP (Opsional)
                </label>
                <input
                  type="text"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="081234567890"
                  className="w-full h-10 px-3 rounded-xl border border-lt-border text-[13px] focus:border-lt-primary outline-none"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full py-3 rounded-xl bg-lt-primary hover:bg-lt-primary-dark text-white font-extrabold text-[13px] shadow-sm transition-colors disabled:opacity-60"
            >
              {isSubmitting ? 'Menerbitkan Akun...' : 'Terbitkan Akun Otoritas'}
            </button>
          </form>

          <div className="xl:col-span-7 bg-white rounded-2xl p-6 border border-lt-border shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-[16px] font-extrabold text-lt-neutral">
                Daftar Akun Dinas &amp; Penyuluh BPP ({authorities.length})
              </h2>
            </div>

            <div className="space-y-3 max-h-[540px] overflow-y-auto pr-1">
              {authorities.map((auth) => (
                <div
                  key={auth.id}
                  className="p-4 rounded-2xl border border-lt-border bg-lt-surface-canvas flex flex-col sm:flex-row sm:items-center justify-between gap-3"
                >
                  <div className="space-y-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="font-extrabold text-[14px] text-lt-neutral">
                        {auth.full_name}
                      </span>
                      <span
                        className={`px-2 py-0.5 rounded-md text-[10px] font-extrabold uppercase ${
                          auth.role === 'dinas'
                            ? 'bg-lt-tertiary-tint text-lt-tertiary-text'
                            : 'bg-lt-primary-tint text-lt-primary'
                        }`}
                      >
                        {auth.role === 'dinas' ? 'DINAS' : 'PENYULUH BPP'}
                      </span>
                      <span
                        className={`px-2 py-0.5 rounded-md text-[10px] font-extrabold ${
                          auth.is_active
                            ? 'bg-lt-primary text-white'
                            : 'bg-lt-error-tint text-lt-error'
                        }`}
                      >
                        {auth.is_active ? 'AKTIF' : 'NONAKTIF'}
                      </span>
                    </div>
                    <div className="text-[12px] text-lt-neutral-muted">
                      {auth.email} {auth.nip ? `· NIP ${auth.nip}` : ''}
                    </div>
                    <div className="text-[11.5px] text-lt-neutral-muted">
                      {auth.bpp_unit || '-'} · {auth.village_name || 'Kab. Sumenep'}{' '}
                      {auth.district_name ? `(${auth.district_name})` : ''}
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => void handleToggleAuthority(auth)}
                    className={`px-3.5 py-2 rounded-xl text-[12px] font-extrabold shrink-0 transition-colors ${
                      auth.is_active
                        ? 'bg-lt-error-tint text-lt-error border border-lt-error-border hover:bg-lt-error-tint'
                        : 'bg-lt-primary-tint text-lt-primary border border-lt-primary-border hover:bg-lt-primary-tint'
                    }`}
                  >
                    {auth.is_active ? 'Nonaktifkan' : 'Aktifkan Kembali'}
                  </button>
                </div>
              ))}
              {authorities.length === 0 && !isLoading && (
                <div className="text-center py-8 text-sm text-lt-neutral-muted">
                  Belum ada akun otoritas Dinas / Penyuluh terdaftar.
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* SECTION 2: 2-TIER STORE OVERSIGHT */}
      {section === 'stores' && (
        <div className="bg-white rounded-2xl p-6 border border-lt-border shadow-sm space-y-4">
          <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3">
            <div>
              <h2 className="text-[16px] font-extrabold text-lt-neutral">
                Pengawasan Toko 2-Tier (B2B Offtaker &amp; Retail Auto-KYC)
              </h2>
              <p className="text-[12px] text-lt-neutral-muted">
                B2B_OFFTAKER wajib verifikasi PPL + kuota desa, sedangkan RETAIL_MERCHANT disetujui otomatis oleh sistem Auto-KYC dan dapat dibekukan jika melanggar.
              </p>
            </div>
            <div className="flex flex-wrap gap-2">
              <select
                value={storeTierFilter}
                onChange={(e) => setStoreTierFilter(e.target.value)}
                className="h-9 px-3 rounded-xl border border-lt-border text-[12px] font-bold bg-lt-surface-canvas"
              >
                <option value="ALL">Semua Tier</option>
                <option value="B2B_OFFTAKER">B2B Offtaker / Koperasi</option>
                <option value="RETAIL_MERCHANT">Retail Merchant (Auto-KYC)</option>
              </select>
              <select
                value={storeStatusFilter}
                onChange={(e) => setStoreStatusFilter(e.target.value)}
                className="h-9 px-3 rounded-xl border border-lt-border text-[12px] font-bold bg-lt-surface-canvas"
              >
                <option value="ALL">Semua Status</option>
                <option value="APPROVED">APPROVED</option>
                <option value="PENDING_PPL">PENDING_PPL</option>
                <option value="SUSPENDED">SUSPENDED</option>
                <option value="REJECTED">REJECTED</option>
              </select>
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-[12.5px]">
              <thead>
                <tr className="border-b border-lt-border text-[11px] uppercase tracking-wider text-lt-neutral-muted">
                  <th className="py-3 pr-3">Nama Toko &amp; Pemilik</th>
                  <th className="py-3 pr-3">Tier 2-Lapis</th>
                  <th className="py-3 pr-3">Wilayah Desa &amp; Gudang</th>
                  <th className="py-3 pr-3">Status</th>
                  <th className="py-3 text-right">Aksi Tata Kelola</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-lt-border">
                {filteredStores.map((store) => {
                  const tier = store.admin_tier || 'B2B_OFFTAKER';
                  const statusCls = STORE_STATUS_CLS[store.status] || 'bg-lt-surface-canvas text-lt-neutral';
                  return (
                    <tr key={store.id} className="hover:bg-lt-surface-canvas">
                      <td className="py-3.5 pr-3">
                        <div className="font-extrabold text-lt-neutral">{store.nama_toko}</div>
                        <div className="text-[11.5px] text-lt-neutral-muted">
                          {store.owner_name || '-'} · {store.owner_email || store.user_id}
                        </div>
                        {store.rejection_reason && (
                          <div className="text-[11px] text-lt-error mt-0.5">
                            Catatan: {store.rejection_reason}
                          </div>
                        )}
                      </td>
                      <td className="py-3.5 pr-3">
                        <span
                          className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10.5px] font-extrabold ${
                            tier === 'RETAIL_MERCHANT'
                              ? 'bg-lt-tertiary-tint text-lt-tertiary-text'
                              : 'bg-lt-secondary-tint text-lt-secondary-dark border border-lt-secondary-border'
                          }`}
                        >
                          {tier === 'RETAIL_MERCHANT' ? 'RETAIL MERCHANT' : 'B2B OFFTAKER'}
                        </span>
                        {store.auto_kyc_passed && (
                          <div className="text-[10.5px] text-lt-primary-dark font-bold mt-1">
                            ✓ Auto-KYC Lolos
                          </div>
                        )}
                      </td>
                      <td className="py-3.5 pr-3">
                        <div className="font-semibold text-lt-neutral">
                          {store.resolved_village_name || store.village_name || 'Kab. Sumenep'}
                        </div>
                        <div className="text-[11px] text-lt-neutral-muted">
                          Gudang: {Number(store.kapasitas_gudang_kg || 0).toLocaleString('id-ID')} kg
                        </div>
                      </td>
                      <td className="py-3.5 pr-3">
                        <span
                          className={`inline-block px-2.5 py-1 rounded-lg border text-[10.5px] font-extrabold ${statusCls}`}
                        >
                          {store.status}
                        </span>
                      </td>
                      <td className="py-3.5 text-right space-x-2 whitespace-nowrap">
                        {store.status !== 'APPROVED' && (
                          <button
                            type="button"
                            onClick={() =>
                              void handleStoreAction(
                                store,
                                store.status === 'SUSPENDED' ? 'REACTIVATE' : 'APPROVE'
                              )
                            }
                            className="px-3 py-1.5 rounded-xl bg-lt-primary hover:bg-lt-primary-dark text-white text-[11.5px] font-bold"
                          >
                            {store.status === 'SUSPENDED' ? 'Aktifkan Ulang' : 'Setujui'}
                          </button>
                        )}
                        {store.status !== 'SUSPENDED' && (
                          <button
                            type="button"
                            onClick={() => void handleStoreAction(store, 'SUSPEND')}
                            className="px-3 py-1.5 rounded-xl bg-lt-error-tint hover:bg-lt-error-tint text-lt-error border border-lt-error-border text-[11.5px] font-bold"
                          >
                            Suspend
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })}
                {filteredStores.length === 0 && !isLoading && (
                  <tr>
                    <td colSpan={5} className="py-8 text-center text-lt-neutral-muted">
                      Tidak ada toko yang cocok dengan filter saat ini.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* SECTION 3: PLATFORM FEE LEDGER */}
      {section === 'ledger' && (
        <div className="bg-white rounded-2xl p-6 border border-lt-border shadow-sm space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
            <div>
              <h2 className="text-[16px] font-extrabold text-lt-neutral">
                Platform Fee Ledger (Refund Hybrid 2% · Floor Rp 10rb / Cap Rp 50rb)
              </h2>
              <p className="text-[12px] text-lt-neutral-muted">
                Pembatalan sepihak oleh Pembeli dikenakan biaya platform 2% (min Rp 10.000, maks Rp 50.000); pembatalan oleh Penjual mengembalikan 100% tanpa potongan.
              </p>
            </div>
            <div className="text-[12px] font-extrabold text-lt-primary bg-lt-primary-tint px-3 py-1.5 rounded-xl border border-lt-primary-border">
              {ledgerSummary.count} Entri · Total Fee {formatRupiah(ledgerSummary.total_fees)}
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-[12.5px]">
              <thead>
                <tr className="border-b border-lt-border text-[11px] uppercase tracking-wider text-lt-neutral-muted">
                  <th className="py-3 pr-3">Tipe &amp; Referensi</th>
                  <th className="py-3 pr-3">Pembatal</th>
                  <th className="py-3 pr-3">Bruto</th>
                  <th className="py-3 pr-3">Fee Platform</th>
                  <th className="py-3 pr-3">Dana Kembali</th>
                  <th className="py-3">Alasan &amp; Waktu</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-lt-border">
                {ledger.map((item) => {
                  const grossVal = Number(item.gross_amount || 0);
                  const feeVal = Number(item.fee_charged || 0);
                  const pctVal =
                    item.fee_percent !== undefined
                      ? Number(item.fee_percent)
                      : grossVal > 0
                        ? Math.round((feeVal / grossVal) * 1000) / 10
                        : 0;
                  return (
                  <tr key={item.id} className="hover:bg-lt-surface-canvas">
                    <td className="py-3 pr-3">
                      <span className="px-2 py-0.5 rounded bg-lt-primary-tint text-lt-neutral text-[10.5px] font-extrabold">
                        {item.ref_type || item.reference_type || 'ORDER'}
                      </span>
                      <div className="text-[11px] font-mono text-lt-neutral-muted mt-0.5">
                        {item.order_or_bid_id || item.reference_id || '-'}
                      </div>
                    </td>
                    <td className="py-3 pr-3">
                      <span
                        className={`px-2 py-0.5 rounded text-[10.5px] font-extrabold ${
                          item.cancelled_by_role === 'SELLER'
                            ? 'bg-lt-secondary-tint text-lt-secondary-dark'
                            : 'bg-lt-tertiary-tint text-lt-tertiary-text'
                        }`}
                      >
                        {item.cancelled_by_role}
                      </span>
                      <div className="text-[11.5px] text-lt-neutral mt-0.5">
                        {item.actor_name || item.actor_email || item.cancelled_by_user_id}
                      </div>
                    </td>
                    <td className="py-3 pr-3 font-semibold text-lt-neutral">
                      {formatRupiah(item.gross_amount)}
                    </td>
                    <td className="py-3 pr-3 font-extrabold text-lt-tertiary-text">
                      {formatRupiah(item.fee_charged)} ({pctVal}%)
                    </td>
                    <td className="py-3 pr-3 font-extrabold text-lt-primary">
                      {formatRupiah(item.refunded_amount)}
                    </td>
                    <td className="py-3 text-[11.5px] text-lt-neutral-muted">
                      <div>{item.reason || '-'}</div>
                      <div className="text-[10.5px] text-lt-neutral-subtle">
                        {item.created_at ? new Date(item.created_at).toLocaleString('id-ID') : ''}
                      </div>
                    </td>
                  </tr>
                  );
                })}
                {ledger.length === 0 && !isLoading && (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-lt-neutral-muted">
                      Belum ada transaksi pembatalan pada Platform Fee Ledger.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* SECTION 4: 6-ROLE DISTRIBUTION & MVP HEALTH */}
      {section === 'overview' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="bg-white rounded-2xl p-6 border border-lt-border shadow-sm space-y-3">
            <h2 className="text-[16px] font-extrabold text-lt-neutral">
              Distribusi Akun Berdasarkan 6-Role RBAC
            </h2>
            <div className="space-y-2.5">
              {(overview?.users_by_role || []).map((row) => {
                const badge = ROLE_BADGE_MAP[row.role] || {
                  label: row.role,
                  cls: 'bg-lt-surface-canvas text-lt-neutral',
                };
                return (
                  <div
                    key={row.role}
                    className="p-3.5 rounded-xl bg-lt-surface-canvas border border-lt-border flex items-center justify-between"
                  >
                    <span className={`px-2.5 py-1 rounded-lg text-[11.5px] font-extrabold ${badge.cls}`}>
                      {badge.label}
                    </span>
                    <div className="text-[13px] font-extrabold text-lt-neutral">
                      {Number(row.active_count || 0)} aktif / {Number(row.total || 0)} total
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="bg-white rounded-2xl p-6 border border-lt-border shadow-sm space-y-3">
            <h2 className="text-[16px] font-extrabold text-lt-neutral">
              Ringkasan 9 Modul Kepatuhan MVP Backend
            </h2>
            <div className="p-4 rounded-xl bg-lt-primary-tint border border-lt-primary-border text-lt-neutral text-[13px] font-bold">
              Skor Kepatuhan: {overview?.mvp_9_health?.compliance_score || '9/9 (100%)'}
            </div>
            <pre className="p-3.5 rounded-xl bg-lt-surface-canvas text-lt-neutral border border-lt-border text-[11.5px] overflow-x-auto max-h-72">
              {JSON.stringify(overview?.mvp_9_health || {}, null, 2)}
            </pre>
          </div>
        </div>
      )}
    </div>
  );
};
