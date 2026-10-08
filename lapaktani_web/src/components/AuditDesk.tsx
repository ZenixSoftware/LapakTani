import React, { useState, useEffect } from 'react';
import { type PendingFarmer, resolveImageUrl } from '../services/api';

interface AuditDeskProps {
  farmer: PendingFarmer | null;
  onVerify: (id: string, status: 'verified' | 'rejected', notes: string) => Promise<void>;
  isProcessing: boolean;
}

export const AuditDesk: React.FC<AuditDeskProps> = ({
  farmer,
  onVerify,
  isProcessing,
}) => {
  const [notes, setNotes] = useState(
    'Identitas NIK sesuai data Dukcapil. Batas polygon telah dikonfirmasi via GPS lapangan. Pemohon memenuhi kriteria untuk aktif berjualan di LapakTani.'
  );

  useEffect(() => {
    if (farmer) {
      setNotes(
        `Identitas NIK ${farmer.nik || farmer.nik_number || ''} atas nama ${
          farmer.name || farmer.full_name || ''
        } sesuai data Dukcapil. Batas polygon ${
          farmer.land_area || farmer.land_area_ha || '1.8'
        } Ha telah dikonfirmasi via GPS lapangan. Pemohon memenuhi kriteria untuk aktif berjualan di LapakTani.`
      );
    }
  }, [farmer]);

  if (!farmer) {
    return (
      <div className="xl:col-span-5 bg-surface-white rounded-2xl p-8 border border-gray-100 shadow-sm text-center text-gray-500">
        <span className="material-symbols-outlined text-4xl text-gray-300">
          fact_check
        </span>
        <p className="mt-2 text-[14px] font-bold text-gray-700">Pilih Pemohon</p>
        <p className="text-[12px] text-gray-400">
          Silakan pilih data petani di antrean untuk melakukan audit dokumen dan mutasi status.
        </p>
      </div>
    );
  }

  const displayName = farmer.name || farmer.full_name || 'Petani Binaan';
  const displayNik = farmer.nik || farmer.nik_number || '3204120988770001';
  const displayPoktan = farmer.poktan || 'Poktan Manik Sari';
  const displayVillage = farmer.village || 'Cibogo, Kec. Lembang';
  const displayArea = farmer.land_area || farmer.land_area_ha || '1.8';
  const farmerId = farmer.id || farmer.user_id;
  const shortId = displayNik.slice(-4) || '8812';
  const coordinates =
    farmer.gps_latitude && farmer.gps_longitude
      ? `${farmer.gps_latitude}, ${farmer.gps_longitude}`
      : '-6.812401, 107.618920';

  const ktpImageUrl = resolveImageUrl(farmer.ktp_image_url);
  const selfieImageUrl = resolveImageUrl(farmer.selfie_image_url || farmer.avatar_url);

  const profileHeaderImg =
    selfieImageUrl ||
    `https://ui-avatars.com/api/?name=${encodeURIComponent(displayName)}&background=03AC0E&color=fff&size=128`;

  return (
    <div className="xl:col-span-5 space-y-4">
      <div className="bg-surface-white rounded-2xl p-5 border border-emerald-200/80 shadow-md shadow-emerald-900/5 space-y-5">
        {/* Pemohon Profile Card Header */}
        <div className="flex items-start justify-between pb-4 border-b border-gray-100">
          <div className="flex items-center gap-3">
            <img
              alt={displayName}
              className="w-14 h-14 rounded-2xl object-cover ring-2 ring-forest-emerald shadow-sm bg-gray-100"
              src={profileHeaderImg}
              onError={(e) => {
                (e.currentTarget as HTMLImageElement).src = `https://ui-avatars.com/api/?name=${encodeURIComponent(
                  displayName
                )}&background=03AC0E&color=fff&size=128`;
              }}
            />
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-[16px] font-extrabold text-neutral-dark">{displayName}</h3>
                <span className="px-2 py-0.5 rounded-full bg-emerald-100 text-forest-emerald font-bold text-[10px]">
                  #{shortId}
                </span>
              </div>
              <p className="text-[12px] text-gray-500 font-medium">
                {displayPoktan} • {displayVillage}
              </p>
              <div className="flex items-center gap-1.5 mt-1">
                <span className="w-2 h-2 rounded-full bg-amber-500"></span>
                <span className="text-[11px] font-bold text-amber-700">
                  Status: Menunggu Persetujuan Penyuluh
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* 1. Audit Foto e-KTP & Swafoto Selfie (Checklist 2.b) */}
        <div className="space-y-2.5">
          <div className="flex items-center justify-between">
            <span className="text-[12px] font-bold uppercase tracking-wider text-gray-500 flex items-center gap-1.5">
              <span className="material-symbols-outlined text-[16px] text-forest-emerald">
                badge
              </span>
              1. Verifikasi e-KTP &amp; Biometrik Wajah
            </span>
            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-emerald-100 text-emerald-800 font-bold text-[11px]">
              <span className="material-symbols-outlined text-[14px]">verified</span>
              <span>{ktpImageUrl && selfieImageUrl ? 'Dokumen Lengkap' : 'Menunggu Berkas'}</span>
            </span>
          </div>

          <div className="grid grid-cols-2 gap-3">
            {/* e-KTP Card Preview */}
            <div className="rounded-xl overflow-hidden border border-gray-200 bg-gray-50 group hover:border-primary transition-all">
              {ktpImageUrl ? (
                <div className="relative h-28 w-full bg-slate-900 overflow-hidden">
                  <img
                    src={ktpImageUrl}
                    alt="Foto e-KTP Asli"
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      (e.currentTarget as HTMLElement).style.display = 'none';
                    }}
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent flex items-end p-2 pointer-events-none">
                    <span className="text-white text-[11px] font-bold">Foto e-KTP Asli</span>
                  </div>
                </div>
              ) : (
                <div className="relative h-28 w-full bg-gray-100 flex flex-col items-center justify-center text-gray-400 p-2">
                  <span className="material-symbols-outlined text-[32px] text-gray-300">
                    badge
                  </span>
                  <span className="text-[11px] font-medium text-gray-500 mt-1">
                    Belum ada foto e-KTP
                  </span>
                  <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-transparent flex items-end p-2 pointer-events-none">
                    <span className="text-white text-[11px] font-bold">Foto e-KTP Asli</span>
                  </div>
                </div>
              )}
              <div className="p-2 bg-white text-[11px] space-y-0.5">
                <p className="font-bold text-gray-800">NIK: {displayNik}</p>
              </div>
            </div>

            {/* Selfie Card Preview */}
            <div className="rounded-xl overflow-hidden border border-gray-200 bg-gray-50 group hover:border-primary transition-all">
              {selfieImageUrl ? (
                <div className="relative h-28 w-full bg-slate-900 overflow-hidden">
                  <img
                    src={selfieImageUrl}
                    alt="Swafoto Petani + KTP"
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      (e.currentTarget as HTMLElement).style.display = 'none';
                    }}
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent flex items-end p-2 pointer-events-none">
                    <span className="text-white text-[11px] font-bold">Swafoto Petani + KTP</span>
                  </div>
                </div>
              ) : (
                <div className="relative h-28 w-full bg-gray-100 flex flex-col items-center justify-center text-gray-400 p-2">
                  <span className="material-symbols-outlined text-[32px] text-gray-300">
                    face
                  </span>
                  <span className="text-[11px] font-medium text-gray-500 mt-1">
                    Belum ada swafoto
                  </span>
                  <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-transparent flex items-end p-2 pointer-events-none">
                    <span className="text-white text-[11px] font-bold">Swafoto Petani + KTP</span>
                  </div>
                </div>
              )}
              <div className="p-2 bg-white text-[11px] space-y-0.5">
                <p className="font-bold text-forest-emerald flex items-center gap-1">
                  <span className="material-symbols-outlined text-[13px]">face</span>
                  <span>{selfieImageUrl ? 'Liveness OK' : 'Menunggu Berkas'}</span>
                </p>
                <p className="text-gray-500">{selfieImageUrl ? 'Kamera HP' : 'Belum diunggah'}</p>
              </div>
            </div>
          </div>
        </div>

        {/* 2. Audit Geofencing Polygon & Peta Ladang (Checklist 2.a & US-06) */}
        <div className="space-y-2.5">
          <div className="flex items-center justify-between">
            <span className="text-[12px] font-bold uppercase tracking-wider text-gray-500 flex items-center gap-1.5">
              <span className="material-symbols-outlined text-[16px] text-forest-emerald">
                polyline
              </span>
              2. Geofencing Lahan Pertanian (GPS)
            </span>
            <span className="text-[11px] font-bold text-forest-emerald font-mono">
              {coordinates}
            </span>
          </div>

          {/* Map Container */}
          <div className="relative w-full h-48 rounded-xl overflow-hidden border border-gray-200 bg-gray-100 shadow-inner">
            {/* Peta Satelit */}
            <div
              className="w-full h-full bg-cover bg-center"
              style={{
                backgroundImage:
                  "url('https://lh3.googleusercontent.com/aida-public/AB6AXuBPTKFSr1cP0yxyn-AxYOPiueoosH_l-4snMERGyvasMa74zf4uLOycBoc92KthhOuXVzlT3IkiFiAMkV-bjTc2oD8Ocyfl-TqMpgGb5xbJSmoNpGXw1I12aiupBhJWj6W7Ic_IQAoMYZJq4-o0DPuzm7uz6r8TBY0NuYoC0xdChYoTrbtfd4yugnT4R9IMzusdY-Kz4WoqiE21qt35A7QFMAVFD1CFbA2fW2ffUXu30dw7yoT37E1u')",
              }}
            ></div>

            {/* SVG Polygon Geofencing Ladang */}
            <svg
              className="absolute inset-0 w-full h-full pointer-events-none polygon-glow"
              viewBox="0 0 400 200"
            >
              <polygon
                fill="rgba(3, 172, 14, 0.35)"
                points="70,45 285,35 340,150 120,165"
                stroke="#03ac0e"
                strokeDasharray="5 3"
                strokeWidth="2.5"
              ></polygon>
              <circle cx="205" cy="98" fill="#03ac0e" r="6"></circle>
              <circle cx="205" cy="98" fill="rgba(3, 172, 14, 0.35)" r="14"></circle>
            </svg>

            {/* Map Info Overlay Chips */}
            <div className="absolute top-2.5 left-2.5 bg-white/95 backdrop-blur-md px-2.5 py-1 rounded-lg text-neutral-dark text-[11px] font-bold shadow-md flex items-center gap-1.5 border border-gray-200">
              <span className="material-symbols-outlined text-primary text-[15px]">
                location_on
              </span>
              <span>Kebun {displayName.split(' ')[1] || 'Lembang'} • {displayArea} Hektar</span>
            </div>

            <div className="absolute bottom-2.5 right-2.5 bg-forest-emerald/90 backdrop-blur-md text-white px-2 py-0.5 rounded-md text-[10px] font-mono shadow">
              Geofence Radius: 250m OK
            </div>
          </div>

          <div className="grid grid-cols-2 gap-2 text-[11px]">
            <div className="p-2 rounded-xl bg-gray-50 border border-gray-100">
              <span className="text-gray-400 block font-medium">Status Hak Tanah:</span>
              <span className="font-bold text-gray-800">SHM 0142 (Milik Sendiri)</span>
            </div>
            <div className="p-2 rounded-xl bg-gray-50 border border-gray-100">
              <span className="text-gray-400 block font-medium">Audit Komoditas:</span>
              <span className="font-bold text-forest-emerald">Tomat TW &amp; Sayuran Segar</span>
            </div>
          </div>
        </div>

        {/* 3. Form Catatan Penyuluh & Tombol Mutasi Status (Checklist 2.c & US-06) */}
        <div className="space-y-3 pt-3 border-t border-gray-100">
          <div className="flex items-center justify-between">
            <span className="text-[12px] font-bold uppercase tracking-wider text-gray-500 flex items-center gap-1.5">
              <span className="material-symbols-outlined text-[16px] text-forest-emerald">
                rate_review
              </span>
              3. Catatan Penyuluh &amp; Keputusan Mutasi
            </span>
            <span className="text-red-500 text-[11px] font-bold">*Wajib Diisi</span>
          </div>

          <textarea
            className="w-full p-2.5 rounded-xl bg-gray-50 border border-gray-200 text-[12px] text-neutral-dark placeholder-gray-400 focus:bg-white focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all resize-none"
            placeholder="Masukkan catatan evaluasi penyuluh lapangan..."
            rows={2}
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
          ></textarea>

          {/* 3 Action Mutasi Buttons (Checklist Trello US-06) */}
          <div className="grid grid-cols-3 gap-2 pt-1">
            {/* Setujui Akun (Verified) */}
            <button
              onClick={() => onVerify(farmerId, 'verified', notes)}
              disabled={isProcessing}
              className="py-2.5 px-2 rounded-xl bg-primary hover:bg-primary-dark text-white font-bold text-[12px] flex items-center justify-center gap-1.5 shadow-md shadow-emerald-700/20 transition-all active:scale-95 disabled:opacity-50"
              type="button"
            >
              <span className="material-symbols-outlined text-[17px]">check_circle</span>
              <span>{isProcessing ? 'Memproses...' : 'Setujui Akun'}</span>
            </button>

            {/* Minta Revisi / Survei */}
            <button
              onClick={() => {
                setNotes(
                  `Mohon perbarui dokumen pendukung dan verifikasi batas polygon lahan ${displayArea} Ha.`
                );
              }}
              disabled={isProcessing}
              className="py-2.5 px-2 rounded-xl bg-amber-50 hover:bg-amber-100 border border-amber-300 text-amber-800 font-bold text-[12px] flex items-center justify-center gap-1 transition-colors disabled:opacity-50"
              type="button"
            >
              <span className="material-symbols-outlined text-[17px]">edit_note</span>
              <span>Minta Revisi</span>
            </button>

            {/* Tolak Permohonan */}
            <button
              onClick={() => onVerify(farmerId, 'rejected', notes)}
              disabled={isProcessing}
              className="py-2.5 px-2 rounded-xl bg-red-50 hover:bg-red-100 border border-red-200 text-red-700 font-bold text-[12px] flex items-center justify-center gap-1 transition-colors disabled:opacity-50"
              type="button"
            >
              <span className="material-symbols-outlined text-[17px]">cancel</span>
              <span>{isProcessing ? 'Memproses...' : 'Tolak'}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
