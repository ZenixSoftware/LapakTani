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
      <div className="bg-lt-surface-card rounded-2xl border-2 border-lt-border shadow-sm p-8 text-center text-lt-neutral-muted">
        Pilih petani dari daftar antrean untuk melihat detail verifikasi.
      </div>
    );
  }

  const isPending = farmer.status === 'pending';
  const isVerified = farmer.status === 'verified';
  const isRejected = farmer.status === 'rejected';

  return (
    <div className="bg-lt-surface-card rounded-2xl border-2 border-lt-border shadow-sm overflow-hidden">
      {/* Bento Box Header: Farmer Quick Profile */}
      <div className="p-4 border-b-2 border-lt-border bg-lt-surface-canvas flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="relative">
            {farmer.avatar_url ? (
              <img
                alt={`Foto Petani ${farmer.full_name}`}
                className="w-11 h-11 rounded-xl object-cover border-2 border-lt-border shadow-sm"
                src={farmer.avatar_url}
              />
            ) : (
              <div className="w-11 h-11 rounded-xl bg-lt-primary-tint border-2 border-lt-border shadow-sm flex items-center justify-center text-lt-primary font-extrabold text-sm">
                {farmer.initials}
              </div>
            )}
            <span
              className={`absolute -bottom-1 -right-1 w-3 h-3 rounded-full border border-lt-border ${
                isVerified ? 'bg-lt-primary' : isRejected ? 'bg-lt-error' : 'bg-lt-tertiary'
              }`}
            ></span>
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="font-extrabold text-base text-lt-neutral" id="detailFarmerName">
                {farmer.full_name}
              </span>
              {isPending && (
                <span className="px-2 py-0.5 rounded-full bg-lt-tertiary-tint border border-lt-border text-lt-tertiary-text text-[10px] font-extrabold">
                  Pending
                </span>
              )}
              {isVerified && (
                <span className="px-2 py-0.5 rounded-full bg-lt-primary-tint border border-lt-border text-lt-primary-dark text-[10px] font-extrabold">
                  Disetujui
                </span>
              )}
              {isRejected && (
                <span className="px-2 py-0.5 rounded-full bg-lt-error-tint border border-lt-border text-lt-error text-[10px] font-extrabold">
                  Ditolak
                </span>
              )}
            </div>
            <span className="font-mono text-xs text-lt-neutral-muted">ID: {farmer.id}</span>
          </div>
        </div>
        <div className="flex items-center gap-1.5">
          <button
            className="w-8 h-8 rounded-xl bg-white border border-lt-border flex items-center justify-center hover:bg-lt-surface-canvas shadow-sm cursor-pointer"
            title="Buka Detail"
            type="button"
          >
            <ExternalLink className="w-[17px] h-[17px] text-lt-neutral" />
          </button>
        </div>
      </div>

      {/* Bento Box Body */}
      <div className="p-5 flex flex-col gap-4">
        {/* KTP Photo & OCR Match Tag */}
        <div className="flex flex-col gap-2">
          <div className="flex items-center justify-between">
            <span className="text-xs font-extrabold text-lt-neutral flex items-center gap-1.5">
              <CreditCard className="w-[17px] h-[17px] text-lt-primary" />
              Foto KTP Asli Petani
            </span>
            <span className="px-2 py-0.5 rounded-full bg-lt-primary-tint border border-lt-border text-lt-primary-dark text-[10px] font-extrabold flex items-center gap-1 shadow-sm">
              <Sparkles className="w-[13px] h-[13px]" /> OCR {farmer.ocr_match_percent}% Cocok
            </span>
          </div>

          {/* Document Image Container */}
          <div className="relative w-full h-44 rounded-xl border-2 border-lt-border bg-lt-neutral overflow-hidden group shadow-sm">
            <img
              alt="Scan KTP Petani"
              className={`w-full h-full object-cover opacity-90 transition-transform duration-300 ${
                isZoomed ? 'scale-125' : 'scale-100'
              }`}
              src={farmer.ktp_image_url}
            />
            {/* Validation Watermark Ribbon */}
            <div className="absolute inset-0 bg-lt-primary/10 flex items-center justify-center pointer-events-none select-none">
              <span className="px-3 py-1 bg-white/90 border border-lt-border text-lt-neutral font-extrabold text-xs uppercase tracking-widest rotate-[-12deg] shadow-sm">
                LapakTani Validated
              </span>
            </div>
            {/* Zoom Pill Button */}
            <button
              className="absolute bottom-2.5 right-2.5 px-3 py-1 rounded-xl bg-white border border-lt-border text-lt-neutral text-xs font-bold flex items-center gap-1 shadow-sm hover:bg-lt-surface-canvas transition-all active:scale-95 cursor-pointer"
              type="button"
              onClick={() => setIsZoomed(!isZoomed)}
            >
              <ZoomIn className="w-[15px] h-[15px]" />
              <span>{isZoomed ? 'Perkecil' : 'Perbesar'}</span>
            </button>
          </div>

          {/* Supporting Land Certificate Bento Card */}
          <div className="flex items-center gap-3 p-2.5 rounded-xl bg-white border-2 border-lt-border shadow-sm hover:bg-lt-surface-canvas transition-colors cursor-pointer">
            <div className="w-10 h-10 rounded-lg border border-lt-border overflow-hidden bg-lt-surface-canvas shrink-0">
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
              <span className="text-xs font-bold text-lt-neutral truncate">{farmer.supporting_doc_name}</span>
              <span className="text-[10px] text-lt-neutral-muted font-medium">Ukuran: {farmer.supporting_doc_size}</span>
            </div>
            <Eye className="w-[20px] h-[20px] text-lt-primary" />
          </div>
        </div>

        {/* Information Grid Bento Box */}
        <div className="p-3.5 rounded-xl bg-white border-2 border-lt-border shadow-sm grid grid-cols-2 gap-3 text-xs">
          <div>
            <span className="text-[10px] font-bold uppercase tracking-wider text-lt-neutral-subtle">NIK Terdaftar</span>
            <div className="font-mono font-bold text-lt-neutral">{farmer.nik}</div>
          </div>
          <div>
            <span className="text-[10px] font-bold uppercase tracking-wider text-lt-neutral-subtle">No. WhatsApp</span>
            <div className="font-bold text-lt-primary">{farmer.phone_number}</div>
          </div>
          <div className="col-span-2 pt-1 border-t border-lt-surface-canvas">
            <span className="text-[10px] font-bold uppercase tracking-wider text-lt-neutral-subtle">Kelompok Tani (Poktan)</span>
            <div className="font-bold text-lt-neutral">
              {farmer.poktan} (ID: {farmer.poktan_id})
            </div>
          </div>
          <div className="col-span-2 pt-1 border-t border-lt-surface-canvas">
            <span className="text-[10px] font-bold uppercase tracking-wider text-lt-neutral-subtle">
              Lokasi &amp; Titik Koordinat Lahan
            </span>
            <div className="font-medium text-lt-neutral">{farmer.location_detail}</div>
            <div className="flex items-center gap-1 text-[11px] font-mono text-lt-neutral-muted mt-0.5">
              <Navigation className="w-[13px] h-[13px] text-lt-tertiary-text" />
              <span>{farmer.coordinates}</span>
            </div>
          </div>
          <div className="col-span-2 pt-1 border-t border-lt-surface-canvas">
            <span className="text-[10px] font-bold uppercase tracking-wider text-lt-neutral-subtle">
              Komoditas &amp; Estimasi Panen
            </span>
            <div className="flex flex-wrap gap-1 mt-1">
              {farmer.commodities.map((item, idx) => (
                <span
                  key={idx}
                  className={`px-2 py-0.5 rounded-md border border-lt-border text-[10px] font-bold ${
                    idx === 2 ? 'bg-lt-surface-canvas text-lt-neutral' : 'bg-lt-primary-tint text-lt-primary-dark'
                  }`}
                >
                  {item.name} {item.estimate ? `(${item.estimate})` : ''}
                </span>
              ))}
            </div>
          </div>
        </div>

        {/* SOP Checklist */}
        <div className="p-3.5 rounded-xl bg-white border-2 border-lt-border shadow-sm flex flex-col gap-2">
          <span className="text-xs font-extrabold text-lt-neutral">Daftar Periksa Penyuluh (PPL)</span>
          <div className="space-y-1.5 text-xs text-lt-neutral font-medium">
            <label className="flex items-center gap-2 cursor-pointer select-none">
              <input
                checked={check1}
                onChange={(e) => setCheck1(e.target.checked)}
                className="w-4 h-4 rounded border-2 border-lt-border text-lt-primary focus:ring-0 accent-lt-primary cursor-pointer"
                type="checkbox"
              />
              <span>NIK &amp; Nama cocok dengan database Dukcapil</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer select-none">
              <input
                checked={check2}
                onChange={(e) => setCheck2(e.target.checked)}
                className="w-4 h-4 rounded border-2 border-lt-border text-lt-primary focus:ring-0 accent-lt-primary cursor-pointer"
                type="checkbox"
              />
              <span>Lahan garapan berada dalam wilayah binaan kerja PPL</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer select-none">
              <input
                checked={check3}
                onChange={(e) => setCheck3(e.target.checked)}
                className="w-4 h-4 rounded border-2 border-lt-border text-lt-primary focus:ring-0 accent-lt-primary cursor-pointer"
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
                className="py-2.5 px-4 rounded-xl bg-white border-2 border-lt-border shadow-sm text-lt-neutral font-extrabold text-xs flex items-center justify-center gap-1.5 hover:bg-lt-error-tint hover:text-lt-error transition-all active:translate-x-0.5 active:translate-y-0.5 cursor-pointer"
                onClick={onOpenRejectModal}
                disabled={isProcessing}
                type="button"
              >
                <X className="w-[17px] h-[17px]" />
                <span>Tolak / Revisi</span>
              </button>
              <button
                className="py-2.5 px-4 rounded-xl bg-lt-primary border-2 border-lt-primary shadow-sm text-white font-extrabold text-xs flex items-center justify-center gap-1.5 hover:bg-lt-primary-dark transition-all active:translate-x-0.5 active:translate-y-0.5 cursor-pointer disabled:opacity-70"
                onClick={onApproveFarmer}
                disabled={isProcessing}
                type="button"
              >
                <ShieldCheck className="w-[17px] h-[17px]" />
                <span>{isProcessing ? 'Memproses...' : 'Setujui Akun'}</span>
              </button>
            </div>
            <p className="text-[10px] text-lt-neutral-muted font-medium text-center flex items-center justify-center gap-1">
              <Lock className="w-[13px] h-[13px]" />
              Persetujuan otomatis mengirim SMS/WA OTP &amp; aktivasi di Supabase Auth.
            </p>
          </div>
        ) : isVerified ? (
          <div className="p-3.5 rounded-xl bg-lt-primary-tint border-2 border-lt-border flex items-center gap-3">
            <CheckCircle2 className="w-6 h-6 text-lt-primary-dark shrink-0" />
            <div className="text-xs text-lt-primary-dark">
              <span className="font-bold">Akun ini telah disetujui</span>
              <p className="text-[11px] text-lt-primary-dark mt-0.5">
                Petani dapat langsung mempublikasikan katalog hasil panen dan mengakses layanan subsidi pupuk.
              </p>
            </div>
          </div>
        ) : (
          <div className="p-3.5 rounded-xl bg-lt-error-tint border-2 border-lt-border flex items-center gap-3">
            <XCircle className="w-6 h-6 text-lt-error shrink-0" />
            <div className="text-xs text-lt-error">
              <span className="font-bold">Permohonan Ditolak / Dalam Revisi</span>
              <p className="text-[11px] text-lt-error mt-0.5">
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
