import React, { useState, useMemo } from 'react';
import { type PendingFarmer, resolveImageUrl } from '../services/api';

interface QueueTableProps {
  farmers: PendingFarmer[];
  selectedFarmerId: string;
  onSelectFarmer: (farmer: PendingFarmer) => void;
  isLoading: boolean;
  onRefresh: () => void;
}

export const QueueTable: React.FC<QueueTableProps> = ({
  farmers,
  selectedFarmerId,
  onSelectFarmer,
  isLoading,
  onRefresh,
}) => {
  const [tableSearch, setTableSearch] = useState('');
  const [activeTab, setActiveTab] = useState<'all' | 'need_action' | 'geofence' | 'revision'>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 6;

  // Filter logic
  const filteredList = useMemo(() => {
    return farmers.filter((f) => {
      // Tab filter
      if (activeTab === 'need_action' && f.verification_status !== 'pending') return false;
      if (activeTab === 'geofence' && (!f.gps_latitude || !f.gps_longitude)) return false;

      // Search filter
      if (tableSearch.trim() !== '') {
        const query = tableSearch.toLowerCase();
        const matchName = (f.name || f.full_name || '').toLowerCase().includes(query);
        const matchNik = (f.nik || f.nik_number || '').includes(query);
        const matchPoktan = (f.poktan || '').toLowerCase().includes(query);
        const matchVillage = (f.village || '').toLowerCase().includes(query);
        return matchName || matchNik || matchPoktan || matchVillage;
      }
      return true;
    });
  }, [farmers, activeTab, tableSearch]);

  const totalPages = Math.max(1, Math.ceil(filteredList.length / itemsPerPage));
  const paginatedList = useMemo(() => {
    const start = (currentPage - 1) * itemsPerPage;
    return filteredList.slice(start, start + itemsPerPage);
  }, [filteredList, currentPage]);

  const getInitials = (name: string) => {
    if (!name) return 'PT';
    const parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.slice(0, 2).toUpperCase();
  };

  const getAvatarBg = (index: number) => {
    const colors = [
      'bg-lt-tertiary-tint text-lt-tertiary-text',
      'bg-lt-secondary-tint text-lt-secondary-dark',
      'bg-lt-secondary-tint text-lt-secondary-dark',
      'bg-lt-primary-tint text-lt-primary-dark',
      'bg-lt-error-tint text-lt-error',
      'bg-lt-secondary-tint text-lt-secondary-dark',
    ];
    return colors[index % colors.length];
  };

  return (
    <div className="xl:col-span-7 space-y-4">
      <div className="bg-lt-surface-card rounded-2xl p-5 border border-lt-surface-canvas shadow-sm">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
          <div>
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-lt-primary animate-pulse"></span>
              <h2 className="text-[16px] font-extrabold text-lt-neutral">
                Daftar Antrean Permohonan Akun
              </h2>
            </div>
            <p className="text-[12px] text-lt-neutral-muted mt-0.5">
              Pilih pemohon untuk melihat audit KTP, verifikasi lahan polygon, dan beri keputusan.
            </p>
          </div>

          <div className="flex items-center gap-2">
            <div className="relative">
              <span className="material-symbols-outlined absolute left-2.5 top-1/2 -translate-y-1/2 text-lt-neutral-subtle text-[16px]">
                search
              </span>
              <input
                className="h-8 pl-8 pr-3 text-[12px] rounded-lg bg-lt-surface-canvas border border-lt-border focus:bg-white focus:border-lt-primary focus:ring-1 focus:ring-lt-primary outline-none"
                placeholder="Cari nama / NIK..."
                type="text"
                value={tableSearch}
                onChange={(e) => {
                  setTableSearch(e.target.value);
                  setCurrentPage(1);
                }}
              />
            </div>
            <button
              onClick={onRefresh}
              className="h-8 px-2.5 rounded-lg border border-lt-border hover:bg-lt-surface-canvas text-lt-neutral-muted flex items-center gap-1 text-[12px] font-semibold transition-colors"
              title="Perbarui Data"
            >
              <span className="material-symbols-outlined text-[16px]">refresh</span>
            </button>
          </div>
        </div>

        {/* Filter Tab Pills */}
        <div className="flex items-center gap-2 overflow-x-auto pb-2 border-b border-lt-surface-canvas text-[12px] font-bold">
          <button
            onClick={() => {
              setActiveTab('all');
              setCurrentPage(1);
            }}
            className={`px-3 py-1.5 rounded-lg whitespace-nowrap transition-colors ${
              activeTab === 'all'
                ? 'bg-lt-primary-dark text-white shadow-sm'
                : 'bg-lt-surface-canvas text-lt-neutral-muted hover:bg-lt-border'
            }`}
          >
            Semua ({farmers.length})
          </button>
          <button
            onClick={() => {
              setActiveTab('need_action');
              setCurrentPage(1);
            }}
            className={`px-3 py-1.5 rounded-lg whitespace-nowrap transition-colors ${
              activeTab === 'need_action'
                ? 'bg-lt-primary-dark text-white shadow-sm'
                : 'bg-lt-primary-tint text-lt-primary-dark hover:bg-lt-primary-tint'
            }`}
          >
            Perlu Tindakan ({farmers.filter((f) => f.verification_status === 'pending').length})
          </button>
          <button
            onClick={() => {
              setActiveTab('geofence');
              setCurrentPage(1);
            }}
            className={`px-3 py-1.5 rounded-lg whitespace-nowrap transition-colors ${
              activeTab === 'geofence'
                ? 'bg-lt-primary-dark text-white shadow-sm'
                : 'bg-lt-surface-canvas text-lt-neutral-muted hover:bg-lt-border'
            }`}
          >
            Verifikasi Geofencing (10)
          </button>
          <button
            onClick={() => {
              setActiveTab('revision');
              setCurrentPage(1);
            }}
            className={`px-3 py-1.5 rounded-lg whitespace-nowrap transition-colors ${
              activeTab === 'revision'
                ? 'bg-lt-primary-dark text-white shadow-sm'
                : 'bg-lt-surface-canvas text-lt-neutral-muted hover:bg-lt-border'
            }`}
          >
            Revisi Dokumen (4)
          </button>
        </div>

        {/* Table Content */}
        <div className="overflow-x-auto mt-3">
          {isLoading ? (
            <div className="py-16 text-center text-lt-neutral-muted space-y-2">
              <span className="material-symbols-outlined text-3xl animate-spin text-lt-primary-dark">
                progress_activity
              </span>
              <p className="text-[13px] font-semibold">Memuat data antrean dari backend...</p>
            </div>
          ) : paginatedList.length === 0 ? (
            <div className="py-16 text-center text-lt-neutral-muted space-y-2">
              <span className="material-symbols-outlined text-4xl text-lt-neutral-subtle">
                inbox
              </span>
              <p className="text-[13px] font-bold text-lt-neutral">Tidak ada data permohonan</p>
              <p className="text-[12px] text-lt-neutral-subtle">
                Semua permohonan petani pada filter ini telah diproses.
              </p>
            </div>
          ) : (
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="text-[11px] font-bold uppercase tracking-wider text-lt-neutral-subtle border-b border-lt-surface-canvas">
                  <th className="py-2.5 px-3">Petani &amp; Poktan</th>
                  <th className="py-2.5 px-3">Komoditas &amp; Lahan</th>
                  <th className="py-2.5 px-3">Verifikasi Dokumen</th>
                  <th className="py-2.5 px-3 text-right">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-lt-surface-canvas text-[13px]">
                {paginatedList.map((farmer, idx) => {
                  const isSelected =
                    farmer.id === selectedFarmerId || farmer.user_id === selectedFarmerId;
                  const displayName = farmer.name || farmer.full_name || 'Petani Binaan';
                  const displayNik = farmer.nik || farmer.nik_number || '3204120988770001';
                  const displayPoktan = farmer.poktan || 'Poktan Tani Makmur';
                  const displayVillage = farmer.village || 'Lembang';
                  const displayArea = farmer.land_area || farmer.land_area_ha || '1.5';
                  const hasGps = Boolean(farmer.gps_latitude && farmer.gps_longitude);

                  return (
                    <tr
                      key={farmer.id || farmer.user_id || idx}
                      onClick={() => onSelectFarmer(farmer)}
                      className={`cursor-pointer transition-all ${
                        isSelected
                          ? 'bg-lt-primary-tint/70 border-l-4 border-lt-primary'
                          : 'hover:bg-lt-surface-canvas'
                      }`}
                    >
                      {/* Column 1: Petani & Poktan */}
                      <td className="py-3.5 px-3">
                        <div className="flex items-center gap-3">
                          {(() => {
                            const avatarSrc = resolveImageUrl(farmer.avatar_url || farmer.selfie_image_url);
                            return avatarSrc ? (
                              <div className="relative flex-shrink-0">
                                <img
                                  alt={displayName}
                                  className={`w-11 h-11 rounded-xl object-cover bg-lt-surface-canvas ${
                                    isSelected ? 'ring-2 ring-lt-primary' : ''
                                  }`}
                                  src={avatarSrc}
                                  onError={(e) => {
                                    (e.currentTarget as HTMLElement).style.display = 'none';
                                  }}
                                />
                                <span className="absolute -bottom-1 -right-1 w-4 h-4 bg-lt-primary text-white rounded-full flex items-center justify-center text-[10px]">
                                  <span className="material-symbols-outlined text-[10px]">check</span>
                                </span>
                              </div>
                            ) : (
                              <div
                                className={`w-11 h-11 rounded-xl ${getAvatarBg(
                                  idx
                                )} flex items-center justify-center font-bold text-[14px] flex-shrink-0`}
                              >
                                {getInitials(displayName)}
                              </div>
                            );
                          })()}

                          <div>
                            <span className="font-bold text-lt-neutral block leading-tight">
                              {displayName}
                            </span>
                            <span className="text-[11px] text-lt-neutral-muted font-medium">
                              {displayPoktan} • {displayVillage}
                            </span>
                            <span className="text-[10px] font-mono text-lt-primary-dark font-semibold block">
                              NIK: {displayNik}
                            </span>
                          </div>
                        </div>
                      </td>

                      {/* Column 2: Komoditas & Lahan */}
                      <td className="py-3.5 px-3">
                        <div className="space-y-1">
                          <div className="flex flex-wrap gap-1">
                            <span className="px-2 py-0.5 rounded-md bg-lt-error-tint text-lt-error font-bold text-[10px]">
                              Tomat Merah
                            </span>
                            <span className="px-2 py-0.5 rounded-md bg-lt-primary-tint text-lt-primary-dark font-bold text-[10px]">
                              Sayur Segar
                            </span>
                          </div>
                          <span className="text-[11px] font-semibold text-lt-neutral-muted block">
                            {displayArea} Ha • Milik Sendiri
                          </span>
                          <span
                            className={`inline-flex items-center gap-1 text-[11px] font-bold ${
                              hasGps ? 'text-lt-primary-dark' : 'text-lt-tertiary-text'
                            }`}
                          >
                            <span className="material-symbols-outlined text-[13px]">
                              {hasGps ? 'pin_drop' : 'wrong_location'}
                            </span>
                            <span>{hasGps ? 'GPS Terpetakan' : 'Butuh Geofencing'}</span>
                          </span>
                        </div>
                      </td>

                      {/* Column 3: Verifikasi Dokumen */}
                      <td className="py-3.5 px-3">
                        <div className="space-y-1">
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-lt-primary-tint text-lt-primary-dark text-[10px] font-bold">
                            <span className="material-symbols-outlined text-[12px]">verified</span>
                            <span>Dukcapil Match</span>
                          </span>
                          <span className="text-[11px] text-lt-neutral-muted block">
                            {farmer.ktp_image_url ? 'KTP Terlampir' : 'KTP Belum Diunggah'}
                          </span>
                        </div>
                      </td>

                      {/* Column 4: Aksi */}
                      <td className="py-3.5 px-3 text-right">
                        {isSelected ? (
                          <button
                            type="button"
                            className="px-3 py-1.5 rounded-xl bg-lt-primary-dark text-white text-[12px] font-bold shadow-sm flex items-center gap-1 ml-auto"
                          >
                            <span className="material-symbols-outlined text-[16px]">
                              search_check
                            </span>
                            <span>Sedang Diaudit</span>
                          </button>
                        ) : (
                          <button
                            type="button"
                            className="px-3 py-1.5 rounded-xl border border-lt-border hover:border-lt-primary-dark hover:text-lt-primary-dark text-lt-neutral text-[12px] font-bold transition-all ml-auto"
                          >
                            Audit Permohonan
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>

        {/* Pagination Info */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pt-4 mt-3 border-t border-lt-surface-canvas text-[12px] text-lt-neutral-muted">
          <span>
            Menampilkan <strong>{paginatedList.length}</strong> dari{' '}
            <strong>{filteredList.length}</strong> permohonan aktif
          </span>
          <div className="flex items-center gap-1.5">
            <button
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              disabled={currentPage === 1}
              className="w-8 h-8 rounded-lg border border-lt-border flex items-center justify-center hover:bg-lt-surface-canvas text-lt-neutral-muted disabled:opacity-40"
            >
              <span className="material-symbols-outlined text-[16px]">chevron_left</span>
            </button>
            {Array.from({ length: totalPages }).map((_, i) => (
              <button
                key={i + 1}
                onClick={() => setCurrentPage(i + 1)}
                className={`w-8 h-8 rounded-lg text-[12px] font-bold transition-colors ${
                  currentPage === i + 1
                    ? 'bg-lt-primary-dark text-white'
                    : 'border border-lt-border hover:bg-lt-surface-canvas text-lt-neutral'
                }`}
              >
                {i + 1}
              </button>
            ))}
            <button
              onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
              disabled={currentPage === totalPages}
              className="w-8 h-8 rounded-lg border border-lt-border flex items-center justify-center hover:bg-lt-surface-canvas text-lt-neutral-muted disabled:opacity-40"
            >
              <span className="material-symbols-outlined text-[16px]">chevron_right</span>
            </button>
          </div>
        </div>
      </div>

      {/* Quick Guidance Card */}
      <div className="bg-gradient-to-r from-lt-primary-tint to-lt-secondary-tint border border-lt-primary-tint rounded-2xl p-4 flex items-start gap-3.5">
        <div className="w-9 h-9 rounded-xl bg-lt-primary-dark text-white flex items-center justify-center flex-shrink-0 shadow-sm">
          <span className="material-symbols-outlined text-[20px]">assignment_turned_in</span>
        </div>
        <div className="text-[12px] text-lt-primary-dark space-y-0.5">
          <span className="font-bold text-[13px] text-lt-primary-dark block">
            Standar Validasi LapakTani Sesuai Pedoman US-06:
          </span>
          <p className="text-lt-neutral-muted">
            Pastikan NIK terdaftar aktif di Dukcapil, foto selfie KTP tidak buram/terpotong, dan koordinat polygon GPS berada di batas desa binaan BPP Lembang sebelum menekan tombol Setujui Akun.
          </p>
        </div>
      </div>
    </div>
  );
};
