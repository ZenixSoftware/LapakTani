import React, { useCallback, useEffect, useState } from 'react';
import {
  createInterPplForumPost,
  createVillageForumPost,
  fetchFertilizerSubsidies,
  fetchInterPplForum,
  fetchStoreApplications,
  fetchVillageForum,
  markFertilizerReceivedByPpl,
  proposeFertilizerSubsidy,
  updateVillageStoreQuota,
  verifyB2BUpgrade,
  type FertilizerAllocationRecord,
  type PplForumPost,
  type StoreApplicationRecord,
  type VillageForumPost,
  type VillageQuotaRecord,
} from '../services/api';

interface PenyuluhStoreAndForumHubProps {
  onShowToast?: (message: string, type?: 'success' | 'error' | 'info') => void;
}

export const PenyuluhStoreAndForumHub: React.FC<PenyuluhStoreAndForumHubProps> = ({
  onShowToast,
}) => {
  const [activeSubTab, setActiveSubTab] = useState<'toko' | 'forum-desa' | 'antar-ppl'>('toko');
  const [applications, setApplications] = useState<StoreApplicationRecord[]>([]);
  const [villages, setVillages] = useState<VillageQuotaRecord[]>([]);
  const [fertilizers, setFertilizers] = useState<FertilizerAllocationRecord[]>([]);
  const [selectedVillageId, setSelectedVillageId] = useState<number>(109);
  const [villagePosts, setVillagePosts] = useState<VillageForumPost[]>([]);
  const [pplPosts, setPplPosts] = useState<PplForumPost[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [busyId, setBusyId] = useState<string | null>(null);

  // Store quota controls
  const [quotaEnabled, setQuotaEnabled] = useState<boolean>(true);
  const [maxQuotaInput, setMaxQuotaInput] = useState<number>(3);

  // New Village Forum post form
  const [vfCategory, setVfCategory] = useState<
    'INFO_PUPUK' | 'TANYA_JAWAB' | 'PERINGATAN_HAMA' | 'ARAHAN_TANAM'
  >('INFO_PUPUK');
  const [vfTitle, setVfTitle] = useState<string>('');
  const [vfBody, setVfBody] = useState<string>('');
  const [vfPickupPoint, setVfPickupPoint] = useState<string>(
    'Balai Poktan Harapan Dungkek (Depan Embung Desa)'
  );

  // New Fertilizer Proposal
  const [fertKind, setFertKind] = useState<string>('NPK Phonska & Dolomit');
  const [fertTon, setFertTon] = useState<string>('2.5');
  const [fertReason, setFertReason] = useState<string>('');

  // Inter-PPL post form
  const [pplTopic, setPplTopic] = useState<string>('');
  const [pplCommodity, setPplCommodity] = useState<string>('Bawang Merah');
  const [pplDiscussion, setPplDiscussion] = useState<string>('');
  const [pplRemedy, setPplRemedy] = useState<string>('');

  const loadAll = useCallback(async () => {
    setIsLoading(true);
    try {
      const [storeData, fertData, vPosts, pPosts] = await Promise.all([
        fetchStoreApplications(),
        fetchFertilizerSubsidies(),
        fetchVillageForum(selectedVillageId),
        fetchInterPplForum(),
      ]);
      setApplications(storeData.applications);
      setVillages(storeData.villages);
      setFertilizers(fertData);
      setVillagePosts(vPosts);
      setPplPosts(pPosts);

      const currentV = storeData.villages.find((v) => v.id === selectedVillageId);
      if (currentV) {
        setQuotaEnabled(currentV.is_store_quota_enabled);
        setMaxQuotaInput(currentV.max_stores_quota);
      }
    } catch (err) {
      onShowToast?.(
        err instanceof Error ? err.message : 'Gagal memuat data toko & forum desa.',
        'error'
      );
    } finally {
      setIsLoading(false);
    }
  }, [onShowToast, selectedVillageId]);

  useEffect(() => {
    void loadAll();
  }, [loadAll]);

  const handleSelectVillage = (vid: number) => {
    setSelectedVillageId(vid);
    const v = villages.find((item) => item.id === vid);
    if (v) {
      setQuotaEnabled(v.is_store_quota_enabled);
      setMaxQuotaInput(v.max_stores_quota);
    }
  };

  const handleSaveQuota = async () => {
    setBusyId('quota');
    try {
      const res = await updateVillageStoreQuota({
        village_id: selectedVillageId,
        is_store_quota_enabled: quotaEnabled,
        max_stores_quota: maxQuotaInput,
      });
      setVillages(res.villages);
      onShowToast?.('Pengaturan batas kuota toko desa berhasil diperbarui.', 'success');
    } catch (err) {
      onShowToast?.(err instanceof Error ? err.message : 'Gagal menyimpan kuota toko.', 'error');
    } finally {
      setBusyId(null);
    }
  };

  const handleVerifyStore = async (id: string, status: 'APPROVED' | 'REJECTED') => {
    setBusyId(id);
    try {
      const updated = await verifyB2BUpgrade(
        id,
        status,
        status === 'REJECTED' ? 'Perlu kelengkapan berkas verifikasi Penjual B2B.' : undefined
      );
      setApplications((prev) =>
        prev.map((a) =>
          a.id === id
            ? {
                ...a,
                status: updated.status,
                b2b_status: updated.b2b_status,
                is_b2b_verified: updated.is_b2b_verified,
                admin_tier: updated.admin_tier,
              }
            : a
        )
      );
      onShowToast?.(
        status === 'APPROVED'
          ? 'Upgrade disetujui! Akun kini berstatus Penjual B2B Terverifikasi.'
          : 'Pengajuan upgrade Penjual B2B ditolak (Penjual tetap aktif di etalase Retail).',
        'success'
      );
      void loadAll();
    } catch (err) {
      onShowToast?.(err instanceof Error ? err.message : 'Gagal memverifikasi upgrade B2B.', 'error');
    } finally {
      setBusyId(null);
    }
  };

  const handleMarkReceived = async (fert: FertilizerAllocationRecord) => {
    setBusyId(fert.id);
    try {
      await markFertilizerReceivedByPpl(
        fert.id,
        fert.titik_ambil_desa || `Balai Poktan Desa ${fert.village_name}`
      );
      onShowToast?.(
        `Pupuk Desa ${fert.village_name} ditandai tiba & diumumkan ke Forum Privat Desa.`,
        'success'
      );
      void loadAll();
    } catch (err) {
      onShowToast?.(err instanceof Error ? err.message : 'Gagal menandai penerimaan.', 'error');
    } finally {
      setBusyId(null);
    }
  };

  const handleProposeFertilizer = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusyId('propose-fert');
    try {
      const created = await proposeFertilizerSubsidy({
        village_id: selectedVillageId,
        jenis_pupuk: fertKind,
        jumlah_ton: Number(fertTon) || 2.0,
        alasan_kebutuhan: fertReason || 'Kebutuhan kelompok tani sesuai laporan sensor tanah.',
        titik_ambil_desa: vfPickupPoint,
      });
      setFertilizers((prev) => [created, ...prev]);
      setFertReason('');
      onShowToast?.('Usulan pupuk subsidi dikirim ke Dinas Pertanian.', 'success');
    } catch (err) {
      onShowToast?.(err instanceof Error ? err.message : 'Gagal mengusulkan pupuk.', 'error');
    } finally {
      setBusyId(null);
    }
  };

  const handlePublishVillagePost = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!vfTitle.trim() || !vfBody.trim()) return;
    setBusyId('vf-post');
    try {
      const created = await createVillageForumPost({
        village_id: selectedVillageId,
        kategori: vfCategory,
        judul: vfTitle.trim(),
        isi_pesan: vfBody.trim(),
        titik_ambil_pupuk: vfCategory === 'INFO_PUPUK' ? vfPickupPoint : undefined,
      });
      setVillagePosts((prev) => [created, ...prev]);
      setVfTitle('');
      setVfBody('');
      onShowToast?.('Pengumuman berhasil dikirim ke petani desa.', 'success');
    } catch (err) {
      onShowToast?.(err instanceof Error ? err.message : 'Gagal mengirim pengumuman.', 'error');
    } finally {
      setBusyId(null);
    }
  };

  const handlePublishPplPost = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!pplTopic.trim() || !pplDiscussion.trim()) return;
    setBusyId('ppl-post');
    try {
      const created = await createInterPplForumPost({
        topik: pplTopic.trim(),
        komoditas: pplCommodity,
        isi_diskusi: pplDiscussion.trim(),
        rekomendasi_teknis: pplRemedy.trim() || undefined,
      });
      setPplPosts((prev) => [created, ...prev]);
      setPplTopic('');
      setPplDiscussion('');
      setPplRemedy('');
      onShowToast?.('Diskusi dibagikan ke Forum Khusus Antar-Penyuluh.', 'success');
    } catch (err) {
      onShowToast?.(err instanceof Error ? err.message : 'Gagal mempublikasikan topik.', 'error');
    } finally {
      setBusyId(null);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header & Sub-tab Switcher */}
      <div className="bg-lt-surface-card border border-lt-border border-l-4 border-l-lt-primary rounded-2xl p-6 shadow-sm flex flex-wrap items-center justify-between gap-4">
        <div>
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-lt-primary-tint text-lt-primary border border-lt-primary-border text-[11px] font-bold tracking-wide uppercase mb-2">
            BPP Kabupaten Sumenep · Verifikasi B2B &amp; Forum
          </span>
          <h1 className="text-[20px] font-extrabold tracking-tight text-lt-neutral">
            Verifikasi Upgrade Penjual B2B, Pupuk &amp; Forum Penyuluh
          </h1>
          <p className="text-[12.5px] text-lt-neutral-muted mt-1">
            Tinjau pengajuan upgrade Penjual B2B Terverifikasi (SK Poktan &amp; kapasitas gudang), umumkan titik ambil pupuk, dan koordinasi antar-PPL.
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => setActiveSubTab('toko')}
            className={`px-3.5 py-2 rounded-xl text-[12px] font-extrabold transition-all ${
              activeSubTab === 'toko'
                ? 'bg-lt-primary text-white shadow-sm'
                : 'bg-lt-surface-canvas text-lt-neutral-muted border border-lt-border hover:text-lt-neutral'
            }`}
          >
            Verifikasi Upgrade Penjual B2B (
            {
              applications.filter(
                (a) => a.b2b_status === 'PENDING_PPL' || a.status === 'PENDING_PPL'
              ).length
            }
            )
          </button>
          <button
            type="button"
            onClick={() => setActiveSubTab('forum-desa')}
            className={`px-3.5 py-2 rounded-xl text-[12px] font-extrabold transition-all ${
              activeSubTab === 'forum-desa'
                ? 'bg-lt-primary text-white shadow-sm'
                : 'bg-lt-surface-canvas text-lt-neutral-muted border border-lt-border hover:text-lt-neutral'
            }`}
          >
            Pupuk &amp; Forum Desa
          </button>
          <button
            type="button"
            onClick={() => setActiveSubTab('antar-ppl')}
            className={`px-3.5 py-2 rounded-xl text-[12px] font-extrabold transition-all ${
              activeSubTab === 'antar-ppl'
                ? 'bg-lt-primary text-white shadow-sm'
                : 'bg-lt-surface-canvas text-lt-neutral-muted border border-lt-border hover:text-lt-neutral'
            }`}
          >
            Forum Antar-Penyuluh
          </button>
        </div>
      </div>

      {isLoading && (
        <div className="bg-white rounded-2xl border border-lt-border p-8 text-center text-[13px] text-lt-neutral-muted">
          Memuat data pembukaan toko, kuota desa, pupuk subsidi, dan forum...
        </div>
      )}

      {/* TAB 1: Verifikasi Upgrade Penjual B2B */}
      {!isLoading && activeSubTab === 'toko' && (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          <div className="lg:col-span-8 bg-white rounded-2xl border border-lt-border shadow-sm overflow-hidden">
            <div className="px-5 py-4 border-b border-lt-border bg-lt-surface-canvas flex items-center justify-between">
              <div>
                <h2 className="text-[14.5px] font-extrabold text-lt-neutral">
                  Verifikasi Upgrade Penjual B2B
                </h2>
                <p className="text-[11.5px] text-lt-neutral-muted">
                  Penjual Retail aktif instan; persetujuan B2B membuka akses serapan panen petani &amp; lelang lot partai.
                </p>
              </div>
              <span className="px-2.5 py-1 rounded-full bg-lt-primary-tint text-lt-primary text-[11px] font-bold">
                {
                  applications.filter(
                    (a) => a.b2b_status === 'PENDING_PPL' || a.status === 'PENDING_PPL'
                  ).length
                }{' '}
                Menunggu
              </span>
            </div>
            <div className="divide-y divide-lt-surface-canvas">
              {applications.length === 0 ? (
                <div className="p-8 text-center text-[12.5px] text-lt-neutral-muted">
                  Belum ada pengajuan upgrade Penjual B2B saat ini.
                </div>
              ) : (
                applications.map((app) => {
                  const isPending =
                    app.b2b_status === 'PENDING_PPL' || app.status === 'PENDING_PPL';
                  const displayB2bStatus =
                    app.b2b_status && app.b2b_status !== 'NONE'
                      ? app.b2b_status
                      : app.admin_tier === 'B2B_OFFTAKER' && app.status === 'APPROVED'
                        ? 'APPROVED'
                        : 'RETAIL_ONLY';

                  return (
                    <div
                      key={app.id}
                      className="p-4 flex flex-wrap items-center justify-between gap-4 hover:bg-lt-surface-canvas/50 transition-colors"
                    >
                      <div className="space-y-1 flex-1 min-w-[240px]">
                        <div className="flex items-center gap-2 flex-wrap">
                          <span className="font-extrabold text-[14px] text-lt-neutral">
                            {app.nama_toko}
                          </span>
                          <span className="px-2 py-0.5 rounded-md bg-lt-primary-tint text-lt-primary text-[10px] font-extrabold">
                            {app.tipe_pengelola}
                          </span>
                          <span
                            className={`px-2 py-0.5 rounded-full text-[10px] font-extrabold ${
                              displayB2bStatus === 'APPROVED'
                                ? 'bg-lt-primary-tint text-lt-primary-dark'
                                : displayB2bStatus === 'REJECTED'
                                  ? 'bg-lt-error-tint text-lt-error'
                                  : isPending
                                    ? 'bg-lt-tertiary-tint text-lt-tertiary-text'
                                    : 'bg-lt-surface-canvas text-lt-neutral-muted border border-lt-border'
                            }`}
                          >
                            {displayB2bStatus === 'APPROVED'
                              ? 'PENJUAL B2B TERVERIFIKASI'
                              : displayB2bStatus === 'REJECTED'
                                ? 'B2B DITOLAK (TETAP RETAIL)'
                                : isPending
                                  ? 'PENDING VERIFIKASI B2B'
                                  : 'PENJUAL RETAIL'}
                          </span>
                        </div>
                        <p className="text-[12px] text-lt-neutral-muted">
                          Pemilik: {app.applicant_name || app.user_id} · Desa{' '}
                          {app.resolved_village_name || app.village_name} ({app.postal_code || '69471'}) · Gudang:{' '}
                          {Number(app.kapasitas_gudang_kg || 0).toLocaleString('id-ID')} kg
                        </p>
                        <p className="text-[11px] text-lt-neutral-muted">
                          NIK: {app.nik || '-'} · HP: {app.no_hp || '-'} · Berkas:{' '}
                          {app.dokumen_syarat_url || '-'}
                        </p>
                      </div>
                      {isPending && (
                        <div className="flex items-center gap-2">
                          <button
                            type="button"
                            disabled={busyId === app.id}
                            onClick={() => void handleVerifyStore(app.id, 'REJECTED')}
                            className="px-3 py-1.5 rounded-xl border border-lt-error-border text-lt-error text-[12px] font-bold hover:bg-lt-error-tint"
                          >
                            Tolak B2B
                          </button>
                          <button
                            type="button"
                            disabled={busyId === app.id}
                            onClick={() => void handleVerifyStore(app.id, 'APPROVED')}
                            className="px-3.5 py-1.5 rounded-xl bg-lt-primary-dark hover:bg-lt-primary text-white text-[12px] font-extrabold"
                          >
                            ACC Penjual B2B
                          </button>
                        </div>
                      )}
                    </div>
                  );
                })
              )}
            </div>
          </div>

          <div className="lg:col-span-4 bg-white rounded-2xl border border-lt-border p-5 space-y-4 shadow-sm self-start">
            <h2 className="text-[14.5px] font-extrabold text-lt-neutral">
              Konfigurasi Wilayah Desa (Opsional)
            </h2>
            <p className="text-[12px] text-lt-neutral-muted">
              Penjual Retail bebas membuka toko tanpa batas kuota. Atur parameter desa binaan di bawah ini bila diperlukan.
            </p>
            <div>
              <label className="block text-[11px] font-bold text-lt-neutral-muted mb-1">Pilih Desa Binaan</label>
              <select
                value={selectedVillageId}
                onChange={(e) => handleSelectVillage(Number(e.target.value))}
                className="w-full px-3 py-2 rounded-xl border border-lt-neutral-border text-[12.5px]"
              >
                {villages.map((v) => (
                  <option key={v.id} value={v.id}>
                    Desa {v.name} (Kec. {v.district_name}) — {v.approved_stores_count} Penjual
                  </option>
                ))}
              </select>
            </div>
            <label className="flex items-center justify-between p-3 rounded-xl bg-lt-surface-canvas border border-lt-border cursor-pointer">
              <div>
                <div className="text-[12.5px] font-bold text-lt-neutral">
                  Catatan Batas Kuota B2B
                </div>
                <div className="text-[11px] text-lt-neutral-muted">
                  Tampilkan referensi kuota B2B desa
                </div>
              </div>
              <input
                type="checkbox"
                checked={quotaEnabled}
                onChange={(e) => setQuotaEnabled(e.target.checked)}
                className="w-4 h-4 accent-lt-primary"
              />
            </label>
            <div>
              <label className="block text-[11px] font-bold text-lt-neutral-muted mb-1">
                Target Kuota B2B Referensi
              </label>
              <input
                type="number"
                min={1}
                max={50}
                value={maxQuotaInput}
                onChange={(e) => setMaxQuotaInput(Number(e.target.value) || 1)}
                className="w-full px-3 py-2 rounded-xl border border-lt-neutral-border text-[12.5px]"
              />
            </div>
            <button
              type="button"
              disabled={busyId === 'quota'}
              onClick={() => void handleSaveQuota()}
              className="w-full py-2.5 rounded-xl bg-lt-primary-dark hover:bg-lt-primary text-white text-[12.5px] font-extrabold"
            >
              {busyId === 'quota' ? 'Menyimpan...' : 'Simpan Konfigurasi Desa'}
            </button>
          </div>
        </div>
      )}

      {/* TAB 2: Info Pupuk & Forum Privat Desa */}
      {!isLoading && activeSubTab === 'forum-desa' && (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          <div className="lg:col-span-5 space-y-5">
            <div className="bg-white rounded-2xl border border-lt-border p-5 space-y-3 shadow-sm">
              <div className="flex items-center justify-between">
                <h2 className="text-[14.5px] font-extrabold text-lt-neutral">
                  Konfirmasi Pupuk Dari Dinas Pertanian
                </h2>
                <select
                  value={selectedVillageId}
                  onChange={(e) => handleSelectVillage(Number(e.target.value))}
                  className="px-2.5 py-1 rounded-lg border border-lt-neutral-border text-[11.5px] font-bold"
                >
                  {villages.map((v) => (
                    <option key={v.id} value={v.id}>
                      Desa {v.name}
                    </option>
                  ))}
                </select>
              </div>
              <div className="space-y-2.5">
                {fertilizers.map((f) => (
                  <div key={f.id} className="p-3 rounded-xl bg-lt-surface-canvas border border-lt-border space-y-1.5">
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-bold text-[12.5px] text-lt-neutral">
                        Desa {f.village_name} · {f.jenis_pupuk} ({f.jumlah_ton} Ton)
                      </span>
                      <span className="px-2 py-0.5 rounded-full bg-white border text-[10px] font-extrabold">
                        {f.status}
                      </span>
                    </div>
                    <p className="text-[11px] text-lt-neutral-muted">
                      Titik Ambil: {f.titik_ambil_desa || 'Balai Poktan'}
                    </p>
                    {f.status === 'DIKIRIM_DINAS' && (
                      <button
                        type="button"
                        disabled={busyId === f.id}
                        onClick={() => void handleMarkReceived(f)}
                        className="mt-1 px-3 py-1.5 rounded-lg bg-lt-primary-dark text-white text-[11px] font-bold"
                      >
                        Tandai Diterima Desa &amp; Umumkan ke Petani
                      </button>
                    )}
                  </div>
                ))}
              </div>
              <form onSubmit={handleProposeFertilizer} className="pt-3 border-t space-y-2">
                <div className="text-[12px] font-extrabold text-lt-neutral">
                  Ajukan Kebutuhan Pupuk Baru ke Dinas
                </div>
                <div className="grid grid-cols-3 gap-2">
                  <input
                    type="text"
                    value={fertKind}
                    onChange={(e) => setFertKind(e.target.value)}
                    placeholder="Jenis pupuk"
                    className="col-span-2 px-2.5 py-1.5 rounded-lg border border-lt-neutral-border text-[12px]"
                  />
                  <input
                    type="number"
                    step="0.5"
                    value={fertTon}
                    onChange={(e) => setFertTon(e.target.value)}
                    placeholder="Ton"
                    className="px-2.5 py-1.5 rounded-lg border border-lt-neutral-border text-[12px]"
                  />
                </div>
                <input
                  type="text"
                  value={fertReason}
                  onChange={(e) => setFertReason(e.target.value)}
                  placeholder="Alasan kebutuhan lapangan..."
                  className="w-full px-2.5 py-1.5 rounded-lg border border-lt-neutral-border text-[12px]"
                />
                <button
                  type="submit"
                  disabled={busyId === 'propose-fert'}
                  className="w-full py-2 rounded-xl bg-lt-tertiary hover:bg-lt-tertiary-tint text-lt-neutral border border-lt-tertiary-border text-[12px] font-extrabold transition-colors"
                >
                  Kirim Usulan ke Dinas
                </button>
              </form>
            </div>
          </div>

          <div className="lg:col-span-7 bg-white rounded-2xl border border-lt-border p-5 space-y-4 shadow-sm">
            <div>
              <h2 className="text-[15px] font-extrabold text-lt-neutral">
                Forum Privat Petani &amp; PPL (Khusus Desa Terpilih)
              </h2>
              <p className="text-[11.5px] text-lt-neutral-muted">
                Hanya petani di `village_id` terkait yang menerima siaran lokasi ambil pupuk &amp; diskusi ini.
              </p>
            </div>
            <form onSubmit={handlePublishVillagePost} className="p-4 rounded-xl bg-lt-primary-tint border border-lt-primary-border space-y-2.5">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                <select
                  value={vfCategory}
                  onChange={(e) => setVfCategory(e.target.value as typeof vfCategory)}
                  className="px-3 py-2 rounded-lg border border-lt-primary-border text-[12px] bg-white font-bold"
                >
                  <option value="INFO_PUPUK">Pengumuman Titik Ambil Pupuk</option>
                  <option value="ARAHAN_TANAM">Arahan Tanam &amp; Dosis</option>
                  <option value="PERINGATAN_HAMA">Peringatan Hama Desa</option>
                  <option value="TANYA_JAWAB">Respon Tanya Jawab Petani</option>
                </select>
                {vfCategory === 'INFO_PUPUK' && (
                  <input
                    type="text"
                    value={vfPickupPoint}
                    onChange={(e) => setVfPickupPoint(e.target.value)}
                    placeholder="Lokasi titik ambil pupuk di desa"
                    className="px-3 py-2 rounded-lg border border-lt-primary-border text-[12px] bg-white"
                  />
                )}
              </div>
              <input
                type="text"
                value={vfTitle}
                onChange={(e) => setVfTitle(e.target.value)}
                placeholder="Judul pengumuman / arahan desa..."
                className="w-full px-3 py-2 rounded-lg border border-lt-primary-border text-[12.5px] bg-white"
              />
              <textarea
                rows={2}
                value={vfBody}
                onChange={(e) => setVfBody(e.target.value)}
                placeholder="Tulis instruksi jadwal ambil pupuk, syarat Poktan, atau solusi hama..."
                className="w-full px-3 py-2 rounded-lg border border-lt-primary-border text-[12.5px] bg-white"
              />
              <button
                type="submit"
                disabled={busyId === 'vf-post'}
                className="px-4 py-2 rounded-xl bg-lt-primary-dark text-white text-[12px] font-extrabold"
              >
                Kirim ke Forum Privat Desa
              </button>
            </form>

            <div className="space-y-2.5 max-h-[360px] overflow-y-auto">
              {villagePosts.map((post) => (
                <div key={post.id} className="p-3.5 rounded-xl border border-lt-border space-y-1">
                  <div className="flex items-center justify-between gap-2">
                    <span className="px-2 py-0.5 rounded-md bg-lt-primary-tint text-lt-primary text-[10px] font-extrabold">
                      {post.kategori} · Desa {post.village_name}
                    </span>
                    <span className="text-[10.5px] text-lt-neutral-muted">
                      {post.author_name} ({post.author_role})
                    </span>
                  </div>
                  <h4 className="font-extrabold text-[13px] text-lt-neutral">{post.judul}</h4>
                  <p className="text-[12px] text-lt-neutral">{post.isi_pesan}</p>
                  {post.titik_ambil_pupuk && (
                    <div className="text-[11px] font-bold text-lt-neutral pt-1">
                      Lokasi Ambil Pupuk: {post.titik_ambil_pupuk}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* TAB 3: Forum Khusus Antar-Penyuluh */}
      {!isLoading && activeSubTab === 'antar-ppl' && (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          <form onSubmit={handlePublishPplPost} className="lg:col-span-5 bg-white rounded-2xl border border-lt-border p-5 space-y-3 shadow-sm">
            <h2 className="text-[15px] font-extrabold text-lt-neutral">
              Forum Khusus Antar-Penyuluh Lintas Desa
            </h2>
            <p className="text-[12px] text-lt-neutral-muted">
              Eksklusif PPL untuk berbagi penanganan kasus pH asam, salinitas pesisir, &amp; OPT antar kecamatan.
            </p>
            <input
              type="text"
              value={pplTopic}
              onChange={(e) => setPplTopic(e.target.value)}
              placeholder="Topik diskusi lapangan..."
              className="w-full px-3 py-2 rounded-xl border border-lt-neutral-border text-[12.5px]"
              required
            />
            <input
              type="text"
              value={pplCommodity}
              onChange={(e) => setPplCommodity(e.target.value)}
              placeholder="Komoditas terkait"
              className="w-full px-3 py-2 rounded-xl border border-lt-neutral-border text-[12.5px]"
            />
            <textarea
              rows={3}
              value={pplDiscussion}
              onChange={(e) => setPplDiscussion(e.target.value)}
              placeholder="Deskripsi kondisi lahan atau serangan hama..."
              className="w-full px-3 py-2 rounded-xl border border-lt-neutral-border text-[12.5px]"
              required
            />
            <textarea
              rows={2}
              value={pplRemedy}
              onChange={(e) => setPplRemedy(e.target.value)}
              placeholder="Rekomendasi teknis yang berhasil diterapkan (opsional)..."
              className="w-full px-3 py-2 rounded-xl border border-lt-neutral-border text-[12.5px]"
            />
            <button
              type="submit"
              disabled={busyId === 'ppl-post'}
              className="w-full py-2.5 rounded-xl bg-lt-primary-dark hover:bg-lt-primary text-white text-[12.5px] font-extrabold"
            >
              Bagikan ke Forum Antar-Penyuluh
            </button>
          </form>

          <div className="lg:col-span-7 space-y-3">
            {pplPosts.map((post) => (
              <div key={post.id} className="bg-white rounded-2xl border border-lt-border p-4 space-y-2 shadow-sm">
                <div className="flex items-center justify-between gap-2 flex-wrap">
                  <span className="px-2.5 py-0.5 rounded-full bg-lt-primary-tint text-lt-primary text-[10.5px] font-extrabold">
                    {post.komoditas} · {post.bpp_kecamatan}
                  </span>
                  <span className="text-[11px] font-semibold text-lt-neutral-muted">
                    {post.penyuluh_name}
                  </span>
                </div>
                <h3 className="font-extrabold text-[14px] text-lt-neutral">{post.topik}</h3>
                <p className="text-[12.5px] text-lt-neutral leading-relaxed">{post.isi_diskusi}</p>
                {post.rekomendasi_teknis && (
                  <div className="p-2.5 rounded-xl bg-lt-primary-tint border border-lt-primary-border text-[11.5px] text-lt-neutral">
                    <span className="font-extrabold">Rekomendasi Teknis:</span> {post.rekomendasi_teknis}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
