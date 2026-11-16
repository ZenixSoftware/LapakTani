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
  verifyStoreApplication,
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
      const updated = await verifyStoreApplication(
        id,
        status,
        status === 'REJECTED' ? 'Perlu kelengkapan berkas pengelola toko desa.' : undefined
      );
      setApplications((prev) => prev.map((a) => (a.id === id ? { ...a, status: updated.status } : a)));
      onShowToast?.(
        status === 'APPROVED'
          ? 'Pembukaan toko disetujui! Pemilik kini menjadi Admin Toko.'
          : 'Pengajuan pembukaan toko ditolak.',
        'success'
      );
      void loadAll();
    } catch (err) {
      onShowToast?.(err instanceof Error ? err.message : 'Gagal memverifikasi toko.', 'error');
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
      <div className="bg-gradient-to-r from-[#0D5136] to-[#166534] rounded-2xl p-6 text-white shadow-lg flex flex-wrap items-center justify-between gap-4">
        <div>
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-white/15 text-[11px] font-bold tracking-wide uppercase mb-2">
            BPP Kabupaten Sumenep · Tata Kelola Toko &amp; Forum
          </span>
          <h1 className="text-[20px] font-extrabold tracking-tight">
            ACC Pembukaan Toko, Kuota Desa, Info Pupuk &amp; Forum Penyuluh
          </h1>
          <p className="text-[12.5px] text-emerald-100/90 mt-1">
            Kelola kuota toko per desa, verifikasi calon Admin Toko, umumkan titik ambil pupuk di forum privat desa, dan koordinasi antar-PPL.
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => setActiveSubTab('toko')}
            className={`px-3.5 py-2 rounded-xl text-[12px] font-extrabold transition-all ${
              activeSubTab === 'toko'
                ? 'bg-[#22C55E] text-[#052e16]'
                : 'bg-white/15 text-white hover:bg-white/25'
            }`}
          >
            ACC Toko &amp; Kuota ({applications.filter((a) => a.status === 'PENDING_PPL').length})
          </button>
          <button
            type="button"
            onClick={() => setActiveSubTab('forum-desa')}
            className={`px-3.5 py-2 rounded-xl text-[12px] font-extrabold transition-all ${
              activeSubTab === 'forum-desa'
                ? 'bg-[#22C55E] text-[#052e16]'
                : 'bg-white/15 text-white hover:bg-white/25'
            }`}
          >
            Pupuk &amp; Forum Desa
          </button>
          <button
            type="button"
            onClick={() => setActiveSubTab('antar-ppl')}
            className={`px-3.5 py-2 rounded-xl text-[12px] font-extrabold transition-all ${
              activeSubTab === 'antar-ppl'
                ? 'bg-[#22C55E] text-[#052e16]'
                : 'bg-white/15 text-white hover:bg-white/25'
            }`}
          >
            Forum Antar-Penyuluh
          </button>
        </div>
      </div>

      {isLoading && (
        <div className="bg-white rounded-2xl border border-[#E2E8F0] p-8 text-center text-[13px] text-gray-500">
          Memuat data pembukaan toko, kuota desa, pupuk subsidi, dan forum...
        </div>
      )}

      {/* TAB 1: ACC Toko & Batas Kuota Toko Desa */}
      {!isLoading && activeSubTab === 'toko' && (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          <div className="lg:col-span-4 bg-white rounded-2xl border border-[#E2E8F0] p-5 space-y-4 shadow-sm">
            <h2 className="text-[15px] font-extrabold text-gray-900">
              Pengaturan Kuota Toko Per Desa
            </h2>
            <p className="text-[12px] text-gray-500">
              Aktifkan pembatasan jumlah toko per desa agar persaingan sehat &amp; logistik tertata.
            </p>
            <div>
              <label className="block text-[11px] font-bold text-gray-600 mb-1">Pilih Desa Binaan</label>
              <select
                value={selectedVillageId}
                onChange={(e) => handleSelectVillage(Number(e.target.value))}
                className="w-full px-3 py-2 rounded-xl border border-gray-300 text-[12.5px]"
              >
                {villages.map((v) => (
                  <option key={v.id} value={v.id}>
                    Desa {v.name} (Kec. {v.district_name}) — {v.approved_stores_count}/
                    {v.is_store_quota_enabled ? v.max_stores_quota : '∞'} Toko
                  </option>
                ))}
              </select>
            </div>
            <label className="flex items-center justify-between p-3 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0] cursor-pointer">
              <div>
                <div className="text-[12.5px] font-bold text-gray-900">
                  Aktifkan Batas Kuota Toko
                </div>
                <div className="text-[11px] text-gray-500">
                  Blokir pengajuan jika toko aktif mencapai batas
                </div>
              </div>
              <input
                type="checkbox"
                checked={quotaEnabled}
                onChange={(e) => setQuotaEnabled(e.target.checked)}
                className="w-4 h-4 accent-[#166534]"
              />
            </label>
            <div>
              <label className="block text-[11px] font-bold text-gray-600 mb-1">
                Maksimal Toko Aktif di Desa
              </label>
              <input
                type="number"
                min={1}
                max={50}
                value={maxQuotaInput}
                onChange={(e) => setMaxQuotaInput(Number(e.target.value) || 1)}
                className="w-full px-3 py-2 rounded-xl border border-gray-300 text-[12.5px]"
              />
            </div>
            <button
              type="button"
              disabled={busyId === 'quota'}
              onClick={() => void handleSaveQuota()}
              className="w-full py-2.5 rounded-xl bg-[#0D5136] hover:bg-[#166534] text-white text-[12.5px] font-extrabold"
            >
              {busyId === 'quota' ? 'Menyimpan...' : 'Simpan Pengaturan Kuota'}
            </button>
          </div>

          <div className="lg:col-span-8 bg-white rounded-2xl border border-[#E2E8F0] shadow-sm overflow-hidden">
            <div className="px-5 py-4 border-b border-[#E2E8F0] bg-[#F8FAF9] flex items-center justify-between">
              <h2 className="text-[14.5px] font-extrabold text-gray-900">
                Antrean Pengajuan Pembukaan Toko (2 Tahap)
              </h2>
              <span className="text-[11px] font-bold text-[#166534]">
                {applications.length} Pengajuan
              </span>
            </div>
            <div className="divide-y divide-[#F1F5F9]">
              {applications.map((app) => (
                <div key={app.id} className="p-4 flex flex-wrap items-center justify-between gap-4">
                  <div className="space-y-1 flex-1 min-w-[240px]">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-extrabold text-[14px] text-gray-900">
                        {app.nama_toko}
                      </span>
                      <span className="px-2 py-0.5 rounded-md bg-emerald-50 text-[#166534] text-[10px] font-extrabold">
                        {app.tipe_pengelola}
                      </span>
                      <span
                        className={`px-2 py-0.5 rounded-full text-[10px] font-extrabold ${
                          app.status === 'APPROVED'
                            ? 'bg-emerald-100 text-emerald-800'
                            : app.status === 'REJECTED'
                              ? 'bg-rose-100 text-rose-700'
                              : 'bg-amber-100 text-amber-800'
                        }`}
                      >
                        {app.status}
                      </span>
                    </div>
                    <p className="text-[12px] text-gray-600">
                      Pemohon: {app.applicant_name || app.user_id} · Desa{' '}
                      {app.resolved_village_name || app.village_name} ({app.postal_code || '69471'}) · Min. Partai Default: {app.default_min_wholesale_kg} kg
                    </p>
                    <p className="text-[11px] text-gray-500">
                      NIK: {app.nik || '-'} · HP: {app.no_hp || '-'} · {app.alamat_lengkap || ''}
                    </p>
                  </div>
                  {app.status === 'PENDING_PPL' && (
                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        disabled={busyId === app.id}
                        onClick={() => void handleVerifyStore(app.id, 'REJECTED')}
                        className="px-3 py-1.5 rounded-xl border border-rose-200 text-rose-700 text-[12px] font-bold hover:bg-rose-50"
                      >
                        Tolak
                      </button>
                      <button
                        type="button"
                        disabled={busyId === app.id}
                        onClick={() => void handleVerifyStore(app.id, 'APPROVED')}
                        className="px-3.5 py-1.5 rounded-xl bg-[#0D5136] hover:bg-[#166534] text-white text-[12px] font-extrabold"
                      >
                        ACC Buka Toko
                      </button>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: Info Pupuk & Forum Privat Desa */}
      {!isLoading && activeSubTab === 'forum-desa' && (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          <div className="lg:col-span-5 space-y-5">
            <div className="bg-white rounded-2xl border border-[#E2E8F0] p-5 space-y-3 shadow-sm">
              <div className="flex items-center justify-between">
                <h2 className="text-[14.5px] font-extrabold text-gray-900">
                  Konfirmasi Pupuk Dari Dinas Pertanian
                </h2>
                <select
                  value={selectedVillageId}
                  onChange={(e) => handleSelectVillage(Number(e.target.value))}
                  className="px-2.5 py-1 rounded-lg border border-gray-300 text-[11.5px] font-bold"
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
                  <div key={f.id} className="p-3 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0] space-y-1.5">
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-bold text-[12.5px] text-[#0D5136]">
                        Desa {f.village_name} · {f.jenis_pupuk} ({f.jumlah_ton} Ton)
                      </span>
                      <span className="px-2 py-0.5 rounded-full bg-white border text-[10px] font-extrabold">
                        {f.status}
                      </span>
                    </div>
                    <p className="text-[11px] text-gray-600">
                      Titik Ambil: {f.titik_ambil_desa || 'Balai Poktan'}
                    </p>
                    {f.status === 'DIKIRIM_DINAS' && (
                      <button
                        type="button"
                        disabled={busyId === f.id}
                        onClick={() => void handleMarkReceived(f)}
                        className="mt-1 px-3 py-1.5 rounded-lg bg-[#0D5136] text-white text-[11px] font-bold"
                      >
                        Tandai Diterima Desa &amp; Umumkan ke Petani
                      </button>
                    )}
                  </div>
                ))}
              </div>
              <form onSubmit={handleProposeFertilizer} className="pt-3 border-t space-y-2">
                <div className="text-[12px] font-extrabold text-gray-800">
                  Ajukan Kebutuhan Pupuk Baru ke Dinas
                </div>
                <div className="grid grid-cols-3 gap-2">
                  <input
                    type="text"
                    value={fertKind}
                    onChange={(e) => setFertKind(e.target.value)}
                    placeholder="Jenis pupuk"
                    className="col-span-2 px-2.5 py-1.5 rounded-lg border border-gray-300 text-[12px]"
                  />
                  <input
                    type="number"
                    step="0.5"
                    value={fertTon}
                    onChange={(e) => setFertTon(e.target.value)}
                    placeholder="Ton"
                    className="px-2.5 py-1.5 rounded-lg border border-gray-300 text-[12px]"
                  />
                </div>
                <input
                  type="text"
                  value={fertReason}
                  onChange={(e) => setFertReason(e.target.value)}
                  placeholder="Alasan kebutuhan lapangan..."
                  className="w-full px-2.5 py-1.5 rounded-lg border border-gray-300 text-[12px]"
                />
                <button
                  type="submit"
                  disabled={busyId === 'propose-fert'}
                  className="w-full py-2 rounded-xl bg-[#F59E0B] hover:bg-[#D97706] text-white text-[12px] font-extrabold"
                >
                  Kirim Usulan ke Dinas
                </button>
              </form>
            </div>
          </div>

          <div className="lg:col-span-7 bg-white rounded-2xl border border-[#E2E8F0] p-5 space-y-4 shadow-sm">
            <div>
              <h2 className="text-[15px] font-extrabold text-gray-900">
                Forum Privat Petani &amp; PPL (Khusus Desa Terpilih)
              </h2>
              <p className="text-[11.5px] text-gray-500">
                Hanya petani di `village_id` terkait yang menerima siaran lokasi ambil pupuk &amp; diskusi ini.
              </p>
            </div>
            <form onSubmit={handlePublishVillagePost} className="p-4 rounded-xl bg-[#F0FDF4] border border-emerald-200 space-y-2.5">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                <select
                  value={vfCategory}
                  onChange={(e) => setVfCategory(e.target.value as typeof vfCategory)}
                  className="px-3 py-2 rounded-lg border border-emerald-200 text-[12px] bg-white font-bold"
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
                    className="px-3 py-2 rounded-lg border border-emerald-200 text-[12px] bg-white"
                  />
                )}
              </div>
              <input
                type="text"
                value={vfTitle}
                onChange={(e) => setVfTitle(e.target.value)}
                placeholder="Judul pengumuman / arahan desa..."
                className="w-full px-3 py-2 rounded-lg border border-emerald-200 text-[12.5px] bg-white"
              />
              <textarea
                rows={2}
                value={vfBody}
                onChange={(e) => setVfBody(e.target.value)}
                placeholder="Tulis instruksi jadwal ambil pupuk, syarat Poktan, atau solusi hama..."
                className="w-full px-3 py-2 rounded-lg border border-emerald-200 text-[12.5px] bg-white"
              />
              <button
                type="submit"
                disabled={busyId === 'vf-post'}
                className="px-4 py-2 rounded-xl bg-[#0D5136] text-white text-[12px] font-extrabold"
              >
                Kirim ke Forum Privat Desa
              </button>
            </form>

            <div className="space-y-2.5 max-h-[360px] overflow-y-auto">
              {villagePosts.map((post) => (
                <div key={post.id} className="p-3.5 rounded-xl border border-[#E2E8F0] space-y-1">
                  <div className="flex items-center justify-between gap-2">
                    <span className="px-2 py-0.5 rounded-md bg-emerald-50 text-[#166534] text-[10px] font-extrabold">
                      {post.kategori} · Desa {post.village_name}
                    </span>
                    <span className="text-[10.5px] text-gray-500">
                      {post.author_name} ({post.author_role})
                    </span>
                  </div>
                  <h4 className="font-extrabold text-[13px] text-gray-900">{post.judul}</h4>
                  <p className="text-[12px] text-gray-700">{post.isi_pesan}</p>
                  {post.titik_ambil_pupuk && (
                    <div className="text-[11px] font-bold text-[#0D5136] pt-1">
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
          <form onSubmit={handlePublishPplPost} className="lg:col-span-5 bg-white rounded-2xl border border-[#E2E8F0] p-5 space-y-3 shadow-sm">
            <h2 className="text-[15px] font-extrabold text-gray-900">
              Forum Khusus Antar-Penyuluh Lintas Desa
            </h2>
            <p className="text-[12px] text-gray-500">
              Eksklusif PPL untuk berbagi penanganan kasus pH asam, salinitas pesisir, &amp; OPT antar kecamatan.
            </p>
            <input
              type="text"
              value={pplTopic}
              onChange={(e) => setPplTopic(e.target.value)}
              placeholder="Topik diskusi lapangan..."
              className="w-full px-3 py-2 rounded-xl border border-gray-300 text-[12.5px]"
              required
            />
            <input
              type="text"
              value={pplCommodity}
              onChange={(e) => setPplCommodity(e.target.value)}
              placeholder="Komoditas terkait"
              className="w-full px-3 py-2 rounded-xl border border-gray-300 text-[12.5px]"
            />
            <textarea
              rows={3}
              value={pplDiscussion}
              onChange={(e) => setPplDiscussion(e.target.value)}
              placeholder="Deskripsi kondisi lahan atau serangan hama..."
              className="w-full px-3 py-2 rounded-xl border border-gray-300 text-[12.5px]"
              required
            />
            <textarea
              rows={2}
              value={pplRemedy}
              onChange={(e) => setPplRemedy(e.target.value)}
              placeholder="Rekomendasi teknis yang berhasil diterapkan (opsional)..."
              className="w-full px-3 py-2 rounded-xl border border-gray-300 text-[12.5px]"
            />
            <button
              type="submit"
              disabled={busyId === 'ppl-post'}
              className="w-full py-2.5 rounded-xl bg-[#0D5136] hover:bg-[#166534] text-white text-[12.5px] font-extrabold"
            >
              Bagikan ke Forum Antar-Penyuluh
            </button>
          </form>

          <div className="lg:col-span-7 space-y-3">
            {pplPosts.map((post) => (
              <div key={post.id} className="bg-white rounded-2xl border border-[#E2E8F0] p-4 space-y-2 shadow-sm">
                <div className="flex items-center justify-between gap-2 flex-wrap">
                  <span className="px-2.5 py-0.5 rounded-full bg-emerald-50 text-[#166534] text-[10.5px] font-extrabold">
                    {post.komoditas} · {post.bpp_kecamatan}
                  </span>
                  <span className="text-[11px] font-semibold text-gray-500">
                    {post.penyuluh_name}
                  </span>
                </div>
                <h3 className="font-extrabold text-[14px] text-gray-900">{post.topik}</h3>
                <p className="text-[12.5px] text-gray-700 leading-relaxed">{post.isi_diskusi}</p>
                {post.rekomendasi_teknis && (
                  <div className="p-2.5 rounded-xl bg-[#F0FDF4] border border-emerald-200 text-[11.5px] text-[#0D5136]">
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
