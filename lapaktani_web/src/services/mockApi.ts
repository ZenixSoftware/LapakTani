export interface CommodityItem {
  name: string;
  estimate?: string;
}

export interface FarmerProfile {
  id: string;
  full_name: string;
  nik: string;
  phone_number: string;
  land_area: string;
  poktan: string;
  poktan_id: string;
  village: string;
  district: string;
  location_detail: string;
  coordinates: string;
  status: 'pending' | 'verified' | 'rejected';
  initials: string;
  avatar_url?: string;
  ktp_image_url: string;
  supporting_doc_name: string;
  supporting_doc_size: string;
  supporting_doc_image?: string;
  ocr_match_percent: number;
  commodities: CommodityItem[];
  verified_by?: string;
  rejection_reason?: string;
  rejection_note?: string;
  created_at: string;
}

export const INITIAL_FARMERS: FarmerProfile[] = [
  {
    id: "PTN-2024-00412",
    full_name: "I Wayan Sudirta",
    nik: "3204 1284 7291 0002",
    phone_number: "0812-3456-7890",
    land_area: "1.2 Ha",
    poktan: "Tani Makmur Sejahtera",
    poktan_id: "PKT-3204-09",
    village: "Desa Kayuambon",
    district: "Kec. Lembang",
    location_detail: "Blok Cisarua RT 02/05, Desa Kayuambon, Kec. Lembang",
    coordinates: "GPS: -6.8124, 107.6189 (Lahan Produktif)",
    status: "pending",
    initials: "WS",
    avatar_url: "https://lh3.googleusercontent.com/aida-public/AB6AXuDxXiX_b02nx_V9TCZy0QBT115C8-wTsVld0x6HWoQrDfKQlwEG6sG1lAbw_dPloyMM627iCc1hNy-KP--bZ327J1tTh4axpy9qNwNnjYseAzrjYZjFpI9Mx4haQPtWWH8M0a57vLKIHHVXIxPKHt3K_2VgXFZaih6mOblXI9pV6S9k5dYrCM6WmUdDRRQSJP-AghabSbFQSIdNrFIGf1bL0qyLylzUqgxZyLPGg1BQttMh3Uw_vcM3tg",
    ktp_image_url: "https://lh3.googleusercontent.com/aida-public/AB6AXuCtCa8K3DzOh3cD-R1pymG-_sp3wyBYHTyQthFVv2JaH96TaDehoD03vbeHYvZSIZOpbBE0UaTzVukC99WMfOOEVpH__F4Iqz4abkR2ggxBPwqc3JaClHL6dZpmbjT-7SUxAOb5HOREr18eq8l-qAF7QQvpgZXzuU8Acbe-0BpIjEnw4CTrYBB7X0gMmhhoZbR_NoTcIHOurwBFo3gUETpjoTAKcxXh5dLnPOf7XMAYwfPC-sAK3w6P7A",
    supporting_doc_name: "SPPT-PBB-Lahan-2024.pdf",
    supporting_doc_size: "1.8 MB • Bukti Hak Milik",
    supporting_doc_image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBgJQ83OqQaystjBwW4XIZiKT46BapDUxnY6f8x-48XhbS1c7xbWZZg-joTuKNtc0Q67w2F3Cj8twV1YW_-0Nf2sCeCbG17OaSmnc8k32QvColQQV9nD6RV0ipCgb-TvEr-WDvI8_XDRQA1urHTYAaDFJfYFloconU-5okJ54fVLMVo4zFokgWbPoT8He9gZAwLNKMuudgC6MLVwweWnYca3rcW9aUF-ahAZzs9O-5-r-w1RtRd0w8-cQ",
    ocr_match_percent: 98,
    commodities: [
      { name: "Brokoli Super", estimate: "400 kg" },
      { name: "Kubis Organik", estimate: "800 kg" },
      { name: "Wortel Brastagi" }
    ],
    created_at: "2026-10-04 08:30"
  },
  {
    id: "PTN-2024-00413",
    full_name: "Bu Siti Aminah",
    nik: "3204 1299 8124 0001",
    phone_number: "0813-8899-2211",
    land_area: "0.8 Ha",
    poktan: "Harapan Mandiri",
    poktan_id: "PKT-3204-12",
    village: "Desa Cikole",
    district: "Kec. Lembang",
    location_detail: "Kp. Cikole Barat No. 14, Desa Cikole, Kec. Lembang",
    coordinates: "GPS: -6.7820, 107.6321 (Lahan Dataran Tinggi)",
    status: "pending",
    initials: "SA",
    avatar_url: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80",
    ktp_image_url: "https://lh3.googleusercontent.com/aida-public/AB6AXuCtCa8K3DzOh3cD-R1pymG-_sp3wyBYHTyQthFVv2JaH96TaDehoD03vbeHYvZSIZOpbBE0UaTzVukC99WMfOOEVpH__F4Iqz4abkR2ggxBPwqc3JaClHL6dZpmbjT-7SUxAOb5HOREr18eq8l-qAF7QQvpgZXzuU8Acbe-0BpIjEnw4CTrYBB7X0gMmhhoZbR_NoTcIHOurwBFo3gUETpjoTAKcxXh5dLnPOf7XMAYwfPC-sAK3w6P7A",
    supporting_doc_name: "Surat-Keterangan-Garapan-Desa.pdf",
    supporting_doc_size: "2.1 MB • Girik / Letter C",
    supporting_doc_image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBgJQ83OqQaystjBwW4XIZiKT46BapDUxnY6f8x-48XhbS1c7xbWZZg-joTuKNtc0Q67w2F3Cj8twV1YW_-0Nf2sCeCbG17OaSmnc8k32QvColQQV9nD6RV0ipCgb-TvEr-WDvI8_XDRQA1urHTYAaDFJfYFloconU-5okJ54fVLMVo4zFokgWbPoT8He9gZAwLNKMuudgC6MLVwweWnYca3rcW9aUF-ahAZzs9O-5-r-w1RtRd0w8-cQ",
    ocr_match_percent: 95,
    commodities: [
      { name: "Stroberi Manis", estimate: "250 kg" },
      { name: "Selada Keriting", estimate: "300 kg" }
    ],
    created_at: "2026-10-04 09:15"
  },
  {
    id: "PTN-2024-00414",
    full_name: "Bpk. Joko Santoso",
    nik: "3204 1123 4567 0003",
    phone_number: "0821-7766-5544",
    land_area: "2.5 Ha",
    poktan: "Subur Barokah",
    poktan_id: "PKT-3204-05",
    village: "Desa Jayagiri",
    district: "Kec. Lembang",
    location_detail: "Lereng Tangkuban Perahu, Desa Jayagiri, Kec. Lembang",
    coordinates: "GPS: -6.7954, 107.6102 (Kebun Kopi Agroforestri)",
    status: "pending",
    initials: "JS",
    avatar_url: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80",
    ktp_image_url: "https://lh3.googleusercontent.com/aida-public/AB6AXuCtCa8K3DzOh3cD-R1pymG-_sp3wyBYHTyQthFVv2JaH96TaDehoD03vbeHYvZSIZOpbBE0UaTzVukC99WMfOOEVpH__F4Iqz4abkR2ggxBPwqc3JaClHL6dZpmbjT-7SUxAOb5HOREr18eq8l-qAF7QQvpgZXzuU8Acbe-0BpIjEnw4CTrYBB7X0gMmhhoZbR_NoTcIHOurwBFo3gUETpjoTAKcxXh5dLnPOf7XMAYwfPC-sAK3w6P7A",
    supporting_doc_name: "Sertifikat-Hak-Milik-0941.pdf",
    supporting_doc_size: "3.4 MB • SHM Asli BPN",
    supporting_doc_image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBgJQ83OqQaystjBwW4XIZiKT46BapDUxnY6f8x-48XhbS1c7xbWZZg-joTuKNtc0Q67w2F3Cj8twV1YW_-0Nf2sCeCbG17OaSmnc8k32QvColQQV9nD6RV0ipCgb-TvEr-WDvI8_XDRQA1urHTYAaDFJfYFloconU-5okJ54fVLMVo4zFokgWbPoT8He9gZAwLNKMuudgC6MLVwweWnYca3rcW9aUF-ahAZzs9O-5-r-w1RtRd0w8-cQ",
    ocr_match_percent: 92,
    commodities: [
      { name: "Kopi Arabika Java Preanger", estimate: "1.2 Ton" },
      { name: "Alpukat Mentega", estimate: "500 kg" }
    ],
    created_at: "2026-10-04 10:00"
  },
  {
    id: "PTN-2024-00408",
    full_name: "Bpk. Dadang Kusnadi",
    nik: "3204 1088 7123 0005",
    phone_number: "0819-0912-3344",
    land_area: "3.0 Ha",
    poktan: "Tani Mukti",
    poktan_id: "PKT-3204-02",
    village: "Desa Cibodas",
    district: "Kec. Lembang",
    location_detail: "Kp. Cibodas Hilir RW 03, Desa Cibodas, Kec. Lembang",
    coordinates: "GPS: -6.8289, 107.6521 (Greenhouse Holtikultura)",
    status: "verified",
    verified_by: "Oleh: Andi P.",
    initials: "DK",
    avatar_url: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80",
    ktp_image_url: "https://lh3.googleusercontent.com/aida-public/AB6AXuCtCa8K3DzOh3cD-R1pymG-_sp3wyBYHTyQthFVv2JaH96TaDehoD03vbeHYvZSIZOpbBE0UaTzVukC99WMfOOEVpH__F4Iqz4abkR2ggxBPwqc3JaClHL6dZpmbjT-7SUxAOb5HOREr18eq8l-qAF7QQvpgZXzuU8Acbe-0BpIjEnw4CTrYBB7X0gMmhhoZbR_NoTcIHOurwBFo3gUETpjoTAKcxXh5dLnPOf7XMAYwfPC-sAK3w6P7A",
    supporting_doc_name: "SHM-Lahan-Pertanian-No112.pdf",
    supporting_doc_size: "1.5 MB • Bukti Hak Milik",
    supporting_doc_image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBgJQ83OqQaystjBwW4XIZiKT46BapDUxnY6f8x-48XhbS1c7xbWZZg-joTuKNtc0Q67w2F3Cj8twV1YW_-0Nf2sCeCbG17OaSmnc8k32QvColQQV9nD6RV0ipCgb-TvEr-WDvI8_XDRQA1urHTYAaDFJfYFloconU-5okJ54fVLMVo4zFokgWbPoT8He9gZAwLNKMuudgC6MLVwweWnYca3rcW9aUF-ahAZzs9O-5-r-w1RtRd0w8-cQ",
    ocr_match_percent: 99,
    commodities: [
      { name: "Tomat Beef Hidroponik", estimate: "2.5 Ton" },
      { name: "Paprika Merah", estimate: "800 kg" }
    ],
    created_at: "2026-10-03 14:20"
  },
  {
    id: "PTN-2024-00401",
    full_name: "Bpk. Rahmat Hidayat",
    nik: "3204 1982 7364 0004",
    phone_number: "0877-3321-9988",
    land_area: "0.5 Ha",
    poktan: "Mitra Sejati",
    poktan_id: "PKT-3204-18",
    village: "Desa Sukajaya",
    district: "Kec. Lembang",
    location_detail: "Jl. Kolonel Masturi No. 88, Desa Sukajaya",
    coordinates: "GPS: -6.8401, 107.5923 (Lahan Terasering)",
    status: "rejected",
    rejection_reason: "KTP non-wilayah",
    rejection_note: "Alamat domisili pada e-KTP tercatat luar Kab. Bandung Barat dan belum ada Surat Domisili Usaha Tani.",
    initials: "RH",
    avatar_url: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80",
    ktp_image_url: "https://lh3.googleusercontent.com/aida-public/AB6AXuCtCa8K3DzOh3cD-R1pymG-_sp3wyBYHTyQthFVv2JaH96TaDehoD03vbeHYvZSIZOpbBE0UaTzVukC99WMfOOEVpH__F4Iqz4abkR2ggxBPwqc3JaClHL6dZpmbjT-7SUxAOb5HOREr18eq8l-qAF7QQvpgZXzuU8Acbe-0BpIjEnw4CTrYBB7X0gMmhhoZbR_NoTcIHOurwBFo3gUETpjoTAKcxXh5dLnPOf7XMAYwfPC-sAK3w6P7A",
    supporting_doc_name: "Surat-Perjanjian-Sewa-2023.pdf",
    supporting_doc_size: "0.9 MB • Perjanjian Sewa",
    supporting_doc_image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBgJQ83OqQaystjBwW4XIZiKT46BapDUxnY6f8x-48XhbS1c7xbWZZg-joTuKNtc0Q67w2F3Cj8twV1YW_-0Nf2sCeCbG17OaSmnc8k32QvColQQV9nD6RV0ipCgb-TvEr-WDvI8_XDRQA1urHTYAaDFJfYFloconU-5okJ54fVLMVo4zFokgWbPoT8He9gZAwLNKMuudgC6MLVwweWnYca3rcW9aUF-ahAZzs9O-5-r-w1RtRd0w8-cQ",
    ocr_match_percent: 64,
    commodities: [
      { name: "Bawang Daun Super", estimate: "600 kg" }
    ],
    created_at: "2026-10-02 11:10"
  }
];

let cachedFarmers = [...INITIAL_FARMERS];

export const mockApi = {
  fetchPendingFarmers: async (): Promise<FarmerProfile[]> => {
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve(cachedFarmers.filter(f => f.status === 'pending'));
      }, 800);
    });
  },

  fetchAllFarmers: async (): Promise<FarmerProfile[]> => {
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve([...cachedFarmers]);
      }, 800);
    });
  },

  approveFarmer: async (id: string): Promise<{ success: boolean; farmer: FarmerProfile }> => {
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        const index = cachedFarmers.findIndex(f => f.id === id);
        if (index !== -1) {
          cachedFarmers[index] = {
            ...cachedFarmers[index],
            status: 'verified',
            verified_by: 'Oleh: Andi P.'
          };
          resolve({ success: true, farmer: cachedFarmers[index] });
        } else {
          reject(new Error("Petani tidak ditemukan"));
        }
      }, 800);
    });
  },

  rejectFarmer: async (
    id: string,
    reason: string,
    note?: string
  ): Promise<{ success: boolean; farmer: FarmerProfile }> => {
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        const index = cachedFarmers.findIndex(f => f.id === id);
        if (index !== -1) {
          cachedFarmers[index] = {
            ...cachedFarmers[index],
            status: 'rejected',
            rejection_reason: reason,
            rejection_note: note
          };
          resolve({ success: true, farmer: cachedFarmers[index] });
        } else {
          reject(new Error("Petani tidak ditemukan"));
        }
      }, 800);
    });
  },

  resetMockData: (): void => {
    cachedFarmers = [...INITIAL_FARMERS];
  }
};
