import {
  RefreshCw,
  CreditCard,
  CheckCircle2,
  XCircle,
  ChevronLeft,
  ChevronRight,
  ShieldCheck
} from 'lucide-react';
import type { FarmerProfile } from '../services/mockApi';

interface QueueTableProps {
  farmers: FarmerProfile[];
  selectedFarmerId: string;
  onSelectFarmer: (farmer: FarmerProfile) => void;
  statusFilter: 'all' | 'pending' | 'verified' | 'rejected';
  onStatusFilterChange: (status: 'all' | 'pending' | 'verified' | 'rejected') => void;
  selectedPoktan: string;
  onPoktanChange: (poktan: string) => void;
  selectedCommodity: string;
  onCommodityChange: (commodity: string) => void;
  pendingCount: number;
}

export const QueueTable = ({
  farmers,
  selectedFarmerId,
  onSelectFarmer,
  statusFilter,
  onStatusFilterChange,
  selectedPoktan,
  onPoktanChange,
  selectedCommodity,
  onCommodityChange,
  pendingCount
}: QueueTableProps) => {
  return (
    <div className="flex flex-col gap-4">
      {/* Search, Filter & Quick Pills Toolbar Bento */}
      <section className="p-4 rounded-2xl bg-cream-50 border-2 border-brutal-border shadow-brutal flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-4">
        <div className="flex items-center gap-2 overflow-x-auto pb-1 lg:pb-0" id="statusFilterTabs">
          <button
            className={`tab-btn px-4 py-1.5 rounded-full font-bold text-xs border border-brutal-border whitespace-nowrap transition-all cursor-pointer ${
              statusFilter === 'all'
                ? 'bg-brutal-dark text-white shadow-brutal-sm'
                : 'bg-white text-slate-700 hover:bg-cream-200'
            }`}
            type="button"
            onClick={() => onStatusFilterChange('all')}
          >
            Semua (24)
          </button>
          <button
            className={`tab-btn px-4 py-1.5 rounded-full font-bold text-xs border border-brutal-border whitespace-nowrap transition-all cursor-pointer ${
              statusFilter === 'pending'
                ? 'bg-brutal-dark text-white shadow-brutal-sm'
                : 'bg-white text-slate-700 hover:bg-cream-200'
            }`}
            type="button"
            onClick={() => onStatusFilterChange('pending')}
          >
            Menunggu Validasi ({pendingCount})
          </button>
          <button
            className={`tab-btn px-4 py-1.5 rounded-full font-bold text-xs border border-brutal-border whitespace-nowrap transition-all cursor-pointer ${
              statusFilter === 'verified'
                ? 'bg-brutal-dark text-white shadow-brutal-sm'
                : 'bg-white text-slate-700 hover:bg-cream-200'
            }`}
            type="button"
            onClick={() => onStatusFilterChange('verified')}
          >
            Terverifikasi (48)
          </button>
          <button
            className={`tab-btn px-4 py-1.5 rounded-full font-bold text-xs border border-brutal-border whitespace-nowrap transition-all cursor-pointer ${
              statusFilter === 'rejected'
                ? 'bg-brutal-dark text-white shadow-brutal-sm'
                : 'bg-white text-slate-700 hover:bg-cream-200'
            }`}
            type="button"
            onClick={() => onStatusFilterChange('rejected')}
          >
            Ditolak / Revisi (3)
          </button>
        </div>
        <div className="flex flex-wrap items-center gap-2.5">
          <select
            className="h-9 px-3 rounded-xl bg-white border-2 border-brutal-border text-xs font-bold text-slate-700 focus:outline-none cursor-pointer"
            value={selectedPoktan}
            onChange={(e) => onPoktanChange(e.target.value)}
          >
            <option value="all">Semua Poktan</option>
            <option value="Tani Makmur Sejahtera">Poktan Tani Makmur Sejahtera</option>
            <option value="Harapan Mandiri">Poktan Harapan Mandiri</option>
            <option value="Subur Barokah">Poktan Subur Barokah</option>
          </select>
          <select
            className="h-9 px-3 rounded-xl bg-white border-2 border-brutal-border text-xs font-bold text-slate-700 focus:outline-none cursor-pointer"
            value={selectedCommodity}
            onChange={(e) => onCommodityChange(e.target.value)}
          >
            <option value="all">Semua Komoditas</option>
            <option value="sayuran">Sayuran Dataran Tinggi</option>
            <option value="buah">Hortikultura / Buah</option>
            <option value="kopi">Kopi &amp; Palawija</option>
          </select>
        </div>
      </section>

      {/* Main Table Bento Container */}
      <div className="bg-cream-50 rounded-2xl border-2 border-brutal-border shadow-brutal overflow-hidden">
        {/* Table Header Bar */}
        <div className="px-5 py-3.5 border-b-2 border-brutal-border bg-cream-100 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <span className="font-extrabold text-sm text-brutal-dark">Daftar Antrean Permohonan Petani</span>
            <span className="px-2 py-0.5 rounded-full bg-white border border-brutal-border text-slate-700 font-extrabold text-[11px]">
              {pendingCount} Menunggu
            </span>
          </div>
          <div className="flex items-center gap-1 text-[11px] font-semibold text-slate-500">
            <RefreshCw className="w-[15px] h-[15px] text-brand" />
            <span>Update 1 menit lalu</span>
          </div>
        </div>

        {/* Queue Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="border-b-2 border-brutal-border bg-cream-50 font-extrabold text-slate-500 text-[11px] uppercase tracking-wider">
                <th className="py-3 px-4">Petani &amp; NIK</th>
                <th className="py-3 px-3">Poktan &amp; Desa</th>
                <th className="py-3 px-3">Lahan</th>
                <th className="py-3 px-3">Status</th>
                <th className="py-3 px-4 text-right">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y border-brutal-border/20 font-medium" id="queueTableBody">
              {farmers.map((farmer) => {
                const isSelected = farmer.id === selectedFarmerId;
                const isPending = farmer.status === 'pending';
                const isVerified = farmer.status === 'verified';
                const isRejected = farmer.status === 'rejected';

                let rowBgClass = 'bg-cream-50/70';
                if (isSelected) {
                  rowBgClass = 'bg-white border-l-4 border-l-brand';
                } else if (isVerified || isRejected) {
                  rowBgClass = 'bg-cream-50/40 opacity-80';
                }

                let badgeColorClass = 'bg-cream-200 text-slate-700';
                if (farmer.id === 'PTN-2024-00412') {
                  badgeColorClass = 'bg-brand-light text-brand shadow-brutal-sm';
                } else if (isVerified) {
                  badgeColorClass = 'bg-emerald-100 text-emerald-800';
                } else if (isRejected) {
                  badgeColorClass = 'bg-rose-100 text-rose-700';
                }

                return (
                  <tr
                    key={farmer.id}
                    className={`table-row-item cursor-pointer transition-all hover:bg-cream-100 ${rowBgClass}`}
                    onClick={() => onSelectFarmer(farmer)}
                  >
                    <td className="py-3.5 px-4">
                      <div className="flex items-center gap-2.5">
                        <div
                          className={`w-9 h-9 rounded-xl border border-brutal-border flex items-center justify-center font-extrabold text-xs shrink-0 ${badgeColorClass}`}
                        >
                          {farmer.initials}
                        </div>
                        <div className="flex flex-col">
                          <span
                            className={`font-bold flex items-center gap-1 ${
                              isVerified || isRejected ? 'text-slate-700' : 'text-brutal-dark'
                            }`}
                          >
                            {farmer.full_name}
                            <span title="KTP Terunggah" className="inline-flex items-center">
                              <CreditCard className="w-[14px] h-[14px] text-brand" />
                            </span>
                          </span>
                          <span
                            className={`font-mono text-[10px] ${
                              isVerified || isRejected ? 'text-slate-400' : 'text-slate-500'
                            }`}
                          >
                            {farmer.nik}
                          </span>
                        </div>
                      </div>
                    </td>
                    <td className="py-3.5 px-3">
                      <div className="flex flex-col leading-tight">
                        <span className={`font-bold ${isVerified || isRejected ? 'text-slate-700' : 'text-slate-800'}`}>
                          {farmer.poktan}
                        </span>
                        <span className="text-[11px] text-slate-500">{farmer.village}</span>
                      </div>
                    </td>
                    <td className="py-3.5 px-3">
                      <div className="flex flex-col leading-tight">
                        <span className={`font-bold ${isVerified || isRejected ? 'text-slate-700' : 'text-slate-800'}`}>
                          {farmer.land_area}
                        </span>
                        <span className="text-[11px] text-slate-500">
                          {farmer.commodities.map((c) => c.name.split(' ')[0]).join(' & ')}
                        </span>
                      </div>
                    </td>
                    <td className="py-3.5 px-3">
                      {isPending && (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-amber-100 border border-brutal-border text-amber-900 font-bold text-[10px]">
                          <span className="w-1.5 h-1.5 rounded-full bg-amber-600"></span> Menunggu
                        </span>
                      )}
                      {isVerified && (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-emerald-100 border border-brutal-border text-emerald-800 font-bold text-[10px]">
                          <CheckCircle2 className="w-[13px] h-[13px]" /> Disetujui
                        </span>
                      )}
                      {isRejected && (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-rose-100 border border-brutal-border text-rose-800 font-bold text-[10px]">
                          <XCircle className="w-[13px] h-[13px]" /> Ditolak
                        </span>
                      )}
                    </td>
                    <td className="py-3.5 px-4 text-right">
                      {isPending && (
                        <button
                          className={`px-3 py-1 rounded-xl font-bold text-xs border border-brutal-border shadow-brutal-sm transition-all active:translate-x-0.5 active:translate-y-0.5 cursor-pointer ${
                            isSelected
                              ? 'bg-brand text-white hover:bg-brand-hover'
                              : 'bg-white text-slate-800 hover:bg-cream-200'
                          }`}
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            onSelectFarmer(farmer);
                          }}
                        >
                          Periksa
                        </button>
                      )}
                      {isVerified && (
                        <span className="text-[11px] text-slate-500 font-mono">
                          {farmer.verified_by || 'Oleh: Andi P.'}
                        </span>
                      )}
                      {isRejected && (
                        <span className="text-[10px] text-rose-700 font-semibold">
                          {farmer.rejection_reason || 'KTP non-wilayah'}
                        </span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {/* Table Pagination Bar */}
        <div className="p-4 border-t-2 border-brutal-border bg-cream-100 flex items-center justify-between text-xs font-semibold text-slate-600">
          <span>
            Menampilkan <strong>1 - {farmers.length}</strong> dari <strong>24</strong> permohonan
          </span>
          <div className="flex items-center gap-1">
            <button
              className="w-8 h-8 rounded-lg bg-white border border-brutal-border flex items-center justify-center hover:bg-cream-200 cursor-pointer"
              type="button"
            >
              <ChevronLeft className="w-[16px] h-[16px]" />
            </button>
            <button
              className="w-8 h-8 rounded-lg bg-brutal-dark text-white font-bold border border-brutal-border shadow-brutal-sm cursor-pointer"
              type="button"
            >
              1
            </button>
            <button
              className="w-8 h-8 rounded-lg bg-white border border-brutal-border flex items-center justify-center hover:bg-cream-200 cursor-pointer"
              type="button"
            >
              2
            </button>
            <button
              className="w-8 h-8 rounded-lg bg-white border border-brutal-border flex items-center justify-center hover:bg-cream-200 cursor-pointer"
              type="button"
            >
              3
            </button>
            <button
              className="w-8 h-8 rounded-lg bg-white border border-brutal-border flex items-center justify-center hover:bg-cream-200 cursor-pointer"
              type="button"
            >
              <ChevronRight className="w-[16px] h-[16px]" />
            </button>
          </div>
        </div>
      </div>

      {/* SOP Guide Bento Banner */}
      <div className="p-4 rounded-2xl bg-white border-2 border-brutal-border shadow-brutal flex items-start gap-3.5">
        <div className="w-10 h-10 rounded-xl bg-brand-light border-2 border-brutal-border flex items-center justify-center text-brand shrink-0 shadow-brutal-sm">
          <ShieldCheck className="w-[22px] h-[22px]" />
        </div>
        <div>
          <span className="font-extrabold text-sm text-brutal-dark">Panduan SOP Verifikasi Lapangan PPL</span>
          <p className="text-xs text-slate-600 font-medium mt-0.5 leading-relaxed">
            Pastikan NIK terdaftar di Disdukcapil Jawa Barat dan koordinat lahan garapan tidak bersinggungan dengan kawasan
            hutan lindung Perhutani. Sertakan catatan bila petani menggarap lahan sewa/bengkok desa.
          </p>
        </div>
      </div>
    </div>
  );
};
