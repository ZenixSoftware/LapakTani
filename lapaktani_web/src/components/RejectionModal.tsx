import { useState } from 'react';
import { AlertTriangle, X } from 'lucide-react';

interface RejectionModalProps {
  isOpen: boolean;
  farmerName: string;
  onClose: () => void;
  onConfirm: (reason: string, note?: string) => void;
  isProcessing?: boolean;
}

const REASONS = [
  "Foto KTP buram / tidak terbaca sistem OCR",
  "Titik lokasi lahan berada di luar wilayah binaan",
  "Nama Poktan tidak terdaftar dalam SIMLUHTAN"
];

export const RejectionModal = ({
  isOpen,
  farmerName,
  onClose,
  onConfirm,
  isProcessing = false
}: RejectionModalProps) => {
  const [selectedReason, setSelectedReason] = useState(REASONS[0]);
  const [note, setNote] = useState('');

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onConfirm(selectedReason, note);
  };

  return (
    <div
      className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-sm flex items-center justify-center p-4 animate-in fade-in duration-200"
      id="rejectionModal"
      onClick={onClose}
    >
      <div
        className="bg-cream-50 border-2 border-brutal-border rounded-3xl max-w-md w-full p-6 shadow-brutal-lg flex flex-col gap-4"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between border-b-2 border-brutal-border pb-3">
          <div className="flex items-center gap-2">
            <AlertTriangle className="text-rose-600 w-6 h-6" />
            <span className="font-extrabold text-base text-brutal-dark">Tolak / Permintaan Revisi</span>
          </div>
          <button
            className="w-8 h-8 rounded-xl bg-white border border-brutal-border flex items-center justify-center text-slate-500 hover:text-brutal-dark shadow-brutal-sm cursor-pointer"
            onClick={onClose}
            type="button"
          >
            <X className="w-[18px] h-[18px]" />
          </button>
        </div>

        <p className="text-xs text-slate-600 font-medium">
          Pilih alasan penolakan untuk dikirimkan secara langsung melalui WhatsApp ke petani{' '}
          <strong id="modalFarmerTarget">{farmerName}</strong>:
        </p>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div className="space-y-2 text-xs">
            {REASONS.map((reason) => (
              <label
                key={reason}
                className={`flex items-center gap-2.5 p-2.5 rounded-xl border-2 border-brutal-border shadow-brutal-sm cursor-pointer transition-colors ${
                  selectedReason === reason ? 'bg-amberSoft/40' : 'bg-white hover:bg-cream-100'
                }`}
              >
                <input
                  checked={selectedReason === reason}
                  onChange={() => setSelectedReason(reason)}
                  className="accent-brand cursor-pointer"
                  name="reject_reason"
                  type="radio"
                />
                <span className="font-bold text-slate-800">{reason}</span>
              </label>
            ))}
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-[11px] font-bold text-slate-600">Catatan Tambahan Penyuluh (Opsional)</label>
            <textarea
              className="w-full p-2.5 rounded-xl bg-white border-2 border-brutal-border text-xs font-medium text-slate-800 placeholder:text-slate-400 focus:outline-none focus:shadow-brutal-sm"
              placeholder="Tulis instruksi perbaikan foto dokumen..."
              rows={2}
              value={note}
              onChange={(e) => setNote(e.target.value)}
            ></textarea>
          </div>

          <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-200">
            <button
              className="px-4 py-2 rounded-xl bg-white border border-brutal-border text-slate-700 font-bold text-xs hover:bg-cream-200 cursor-pointer"
              onClick={onClose}
              type="button"
              disabled={isProcessing}
            >
              Batal
            </button>
            <button
              className="px-4 py-2 rounded-xl bg-rose-600 text-white font-bold text-xs border border-brutal-border shadow-brutal-sm hover:bg-rose-700 cursor-pointer disabled:opacity-70"
              type="submit"
              disabled={isProcessing}
            >
              {isProcessing ? 'Mengirim...' : 'Kirim Penolakan'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
