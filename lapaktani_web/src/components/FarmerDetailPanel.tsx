import { useState } from 'react';
import {
  ExternalLink,
  CreditCard,
  Sparkles,
  ZoomIn,
  Eye,
  Navigation,
  X,
  ShieldCheck,
  Lock,
  CheckCircle2,
  XCircle
} from 'lucide-react';
import type { FarmerProfile } from '../services/mockApi';

interface FarmerDetailPanelProps {
  farmer: FarmerProfile | null;
  onOpenRejectModal: () => void;
  onApproveFarmer: () => void;
  isProcessing?: boolean;
}

export const FarmerDetailPanel = ({
  farmer,
  onOpenRejectModal,
  onApproveFarmer,
  isProcessing = false
}: FarmerDetailPanelProps) => {
  const [check1, setCheck1] = useState(true);
  const [check2, setCheck2] = useState(true);
  const [check3, setCheck3] = useState(true);
  const [isZoomed, setIsZoomed] = useState(false);

  if (!farmer) {
    return (
      <div className="bg-cream-50 rounded-2xl border-2 border-brutal-border shadow-brutal p-8 text-center text-slate-500">
        Pilih petani dari daftar antrean untuk melihat detail verifikasi.
      </div>
    );
  }

  const isPending = farmer.status === 'pending';
  const isVerified = farmer.status === 'verified';
  const isRejected = farmer.status === 'rejected';

  return (
    <div className="bg-cream-50 rounded-2xl border-2 border-brutal-border shadow-brutal overflow-hidden">
      {/* Bento Box Header: Farmer Quick Profile */}
      <div className="p-4 border-b-2 border-brutal-border bg-cream-100 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="relative">
            {farmer.avatar_url ? (
              <img
                alt={`Foto Petani ${farmer.full_name}`}
                className="w-11 h-11 rounded-xl object-cover border-2 border-brutal-border shadow-brutal-sm"
                src={farmer.avatar_url}
              />
            ) : (
              <div className="w-11 h-11 rounded-xl bg-brand-light border-2 border-brutal-border shadow-brutal-sm flex items-center justify-center text-brand font-extrabold text-sm">
                {farmer.initials}
              </div>
            )}
            <span
              className={`absolute -bottom-1 -right-1 w-3 h-3 rounded-full border border-brutal-border ${
                isVerified ? 'bg-emerald-500' : isRejected ? 'bg-rose-500' : 'bg-amber-400'
              }`}
            ></span>
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="font-extrabold text-base text-brutal-dark" id="detailFarmerName">
                {farmer.full_name}
              </span>
              {isPending && (
                <span className="px-2 py-0.5 rounded-full bg-amber-100 border border-brutal-border text-amber-900 text-[10px] font-extrabold">
                  Pending
                </span>
              )}
              {isVerified && (
                <span className="px-2 py-0.5 rounded-full bg-emerald-100 border border-brutal-border text-emerald-900 text-[10px] font-extrabold">
                  Disetujui
                </span>
              )}
              {isRejected && (
                <span className="px-2 py-0.5 rounded-full bg-rose-100 border border-brutal-border text-rose-900 text-[10px] font-extrabold">
                  Ditolak
                </span>
              )}
            </div>
            <span className="font-mono text-xs text-slate-500">ID: {farmer.id}</span>
          </div>
        </div>
        <div className="flex items-center gap-1.5">
          <button
            className="w-8 h-8 rounded-xl bg-white border border-brutal-border flex items-center justify-center hover:bg-cream-200 shadow-brutal-sm cursor-pointer"
            title="Buka Detail"
            type="button"
          >
            <ExternalLink className="w-[17px] h-[17px] text-slate-700" />
          </button>
        </div>
      </div>

      {/* Bento Box Body */}
      <div className="p-5 flex flex-col gap-4">
        {/* KTP Photo & OCR Match Tag */}
        <div className="flex flex-col gap-2">
          <div className="flex items-center justify-between">
            <span className="text-xs font-extrabold text-brutal-dark flex items-center gap-1.5">
              <CreditCard className="w-[17px] h-[17px] text-brand" />
              Foto KTP Asli Petani
            </span>
            <span className="px-2 py-0.5 rounded-full bg-emerald-100 border border-brutal-border text-emerald-900 text-[10px] font-extrabold flex items-center gap-1 shadow-brutal-sm">
              <Sparkles className="w-[13px] h-[13px]" /> OCR {farmer.ocr_match_percent}% Cocok
            </span>
          </div>

          {/* Document Image Container */}
          <div className="relative w-full h-44 rounded-xl border-2 border-brutal-border bg-slate-900 overflow-hidden group shadow-brutal-sm">
            <img
              alt="Scan KTP Petani"
              className={`w-full h-full object-cover opacity-90 transition-transform duration-300 ${
                isZoomed ? 'scale-125' : 'scale-100'
              }`}
              src={farmer.ktp_image_url}
            />
            {/* Brutalist Watermark Ribbon */}
            <div className="absolute inset-0 bg-brand/10 flex items-center justify-center pointer-events-none select-none">
              <span className="px-3 py-1 bg-white/90 border border-brutal-border text-slate-800 font-extrabold text-xs uppercase tracking-widest rotate-[-12deg] shadow-brutal-sm">
                LapakTani Validated
              </span>
            </div>
            {/* Zoom Pill Button */}
            <button
              className="absolute bottom-2.5 right-2.5 px-3 py-1 rounded-xl bg-white border border-brutal-border text-brutal-dark text-xs font-bold flex items-center gap-1 shadow-brutal-sm hover:bg-cream-100 transition-all active:scale-95 cursor-pointer"
              type="button"
              onClick={() => setIsZoomed(!isZoomed)}
            >
              <ZoomIn className="w-[15px] h-[15px]" />
              <span>{isZoomed ? 'Perkecil' : 'Perbesar'}</span>
            </button>
          </div>

          {/* Supporting Land Certificate Bento Card */}
          <div className="flex items-center gap-3 p-2.5 rounded-xl bg-white border-2 border-brutal-border shadow-brutal-sm hover:bg-cream-100 transition-colors cursor-pointer">
            <div className="w-10 h-10 rounded-lg border border-brutal-border overflow-hidden bg-slate-100 shrink-0">
              <img
                alt={farmer.supporting_doc_name}
                className="w-full h-full object-cover"
                src={
                  farmer.supporting_doc_image ||
                  "https://lh3.googleusercontent.com/aida-public/AB6AXuBgJQ83OqQaystjBwW4XIZiKT46BapDUxnY6f8x-48XhbS1c7xbWZZg-joTuKNtc0Q67w2F3Cj8twV1YW_-0Nf2sCeCbG17OaSmnc8k32QvColQQV9nD6RV0ipCgb-TvEr-WDvI8_XDRQA1urHTYAaDFJfYFloconU-5okJ54fVLMVo4zFokgWbPoT8He9gZAwLNKMuudgC6MLVwweWnYca3rcW9aUF-ahAZzs9O-5-r-w1RtRd0w8-cQ"
                }
              />
            </div>
            <div className="flex flex-col min-w-0 flex-1">
              <span className="text-xs font-bold text-brutal-dark truncate">{farmer.supporting_doc_name}</span>
              <span className="text-[10px] text-slate-500 font-medium">Ukuran: {farmer.supporting_doc_size}</span>
            </div>
            <Eye className="w-[20px] h-[20px] text-brand" />
          </div>
        </div>

        {/* Information Grid Bento Box */}
        <div className="p-3.5 rounded-xl bg-white border-2 border-brutal-border shadow-brutal-sm grid grid-cols-2 gap-3 text-xs">
          <div>
            <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400">NIK Terdaftar</span>
            <div className="font-mono font-bold text-slate-800">{farmer.nik}</div>
          </div>
          <div>
            <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400">No. WhatsApp</span>
            <div className="font-bold text-brand">{farmer.phone_number}</div>
          </div>
          <div className="col-span-2 pt-1 border-t border-slate-100">
            <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Kelompok Tani (Poktan)</span>
            <div className="font-bold text-slate-800">
              {farmer.poktan} (ID: {farmer.poktan_id})
            </div>
          </div>
          <div className="col-span-2 pt-1 border-t border-slate-100">
            <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
              Lokasi &amp; Titik Koordinat Lahan
            </span>
            <div className="font-medium text-slate-700">{farmer.location_detail}</div>
            <div className="flex items-center gap-1 text-[11px] font-mono text-slate-500 mt-0.5">
              <Navigation className="w-[13px] h-[13px] text-amber-700" />
              <span>{farmer.coordinates}</span>
            </div>
          </div>
          <div className="col-span-2 pt-1 border-t border-slate-100">
            <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
              Komoditas &amp; Estimasi Panen
            </span>
            <div className="flex flex-wrap gap-1 mt-1">
              {farmer.commodities.map((item, idx) => (
                <span
                  key={idx}
                  className={`px-2 py-0.5 rounded-md border border-brutal-border text-[10px] font-bold ${
                    idx === 2 ? 'bg-cream-200 text-slate-700' : 'bg-emerald-50 text-emerald-800'
                  }`}
                >
                  {item.name} {item.estimate ? `(${item.estimate})` : ''}
                </span>
              ))}
            </div>
          </div>
        </div>

        {/* SOP Checklist */}
        <div className="p-3.5 rounded-xl bg-white border-2 border-brutal-border shadow-brutal-sm flex flex-col gap-2">
          <span className="text-xs font-extrabold text-brutal-dark">Daftar Periksa Penyuluh (PPL)</span>
          <div className="space-y-1.5 text-xs text-slate-700 font-medium">
            <label className="flex items-center gap-2 cursor-pointer select-none">
              <input
                checked={check1}
                onChange={(e) => setCheck1(e.target.checked)}
                className="w-4 h-4 rounded border-2 border-brutal-border text-brand focus:ring-0 accent-brand cursor-pointer"
                type="checkbox"
              />
              <span>NIK &amp; Nama cocok dengan database Dukcapil</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer select-none">
              <input
                checked={check2}
                onChange={(e) => setCheck2(e.target.checked)}
                className="w-4 h-4 rounded border-2 border-brutal-border text-brand focus:ring-0 accent-brand cursor-pointer"
                type="checkbox"
              />
              <span>Lahan garapan berada dalam wilayah binaan kerja PPL</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer select-none">
              <input
                checked={check3}
                onChange={(e) => setCheck3(e.target.checked)}
                className="w-4 h-4 rounded border-2 border-brutal-border text-brand focus:ring-0 accent-brand cursor-pointer"
                type="checkbox"
              />
              <span>Petani aktif terdaftar pada SIMLUHTAN resmi</span>
            </label>
          </div>
        </div>

        {/* Action Buttons or Status Notice */}
        {isPending ? (
          <div className="flex flex-col gap-2.5 pt-1">
            <div className="grid grid-cols-2 gap-3">
              <button
                className="py-2.5 px-4 rounded-xl bg-white border-2 border-brutal-border shadow-brutal text-slate-800 font-extrabold text-xs flex items-center justify-center gap-1.5 hover:bg-rose-50 hover:text-rose-700 transition-all active:translate-x-0.5 active:translate-y-0.5 cursor-pointer"
                onClick={onOpenRejectModal}
                disabled={isProcessing}
                type="button"
              >
                <X className="w-[17px] h-[17px]" />
                <span>Tolak / Revisi</span>
              </button>
              <button
                className="py-2.5 px-4 rounded-xl bg-brand border-2 border-brutal-border shadow-brutal text-white font-extrabold text-xs flex items-center justify-center gap-1.5 hover:bg-brand-hover transition-all active:translate-x-0.5 active:translate-y-0.5 cursor-pointer disabled:opacity-70"
                onClick={onApproveFarmer}
                disabled={isProcessing}
                type="button"
              >
                <ShieldCheck className="w-[17px] h-[17px]" />
                <span>{isProcessing ? 'Memproses...' : 'Setujui Akun'}</span>
              </button>
            </div>
            <p className="text-[10px] text-slate-500 font-medium text-center flex items-center justify-center gap-1">
              <Lock className="w-[13px] h-[13px]" />
              Persetujuan otomatis mengirim SMS/WA OTP &amp; aktivasi di Supabase Auth.
            </p>
          </div>
        ) : isVerified ? (
          <div className="p-3.5 rounded-xl bg-emerald-50 border-2 border-brutal-border flex items-center gap-3">
            <CheckCircle2 className="w-6 h-6 text-emerald-700 shrink-0" />
            <div className="text-xs text-emerald-900">
              <span className="font-bold">Akun ini telah disetujui</span>
              <p className="text-[11px] text-emerald-700 mt-0.5">
                Petani dapat langsung mempublikasikan katalog hasil panen dan mengakses layanan subsidi pupuk.
              </p>
            </div>
          </div>
        ) : (
          <div className="p-3.5 rounded-xl bg-rose-50 border-2 border-brutal-border flex items-center gap-3">
            <XCircle className="w-6 h-6 text-rose-700 shrink-0" />
            <div className="text-xs text-rose-900">
              <span className="font-bold">Permohonan Ditolak / Dalam Revisi</span>
              <p className="text-[11px] text-rose-700 mt-0.5">
                Alasan: {farmer.rejection_reason || 'KTP buram / tidak sesuai data'}
                {farmer.rejection_note && ` • Catatan: ${farmer.rejection_note}`}
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
