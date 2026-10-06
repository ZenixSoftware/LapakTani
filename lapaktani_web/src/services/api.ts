const API_BASE_URL = 'http://localhost:3000/api';

export interface PendingFarmer {
  id: string;
  user_id: string;
  profile_id?: string;
  name: string;
  full_name: string;
  nik: string;
  nik_number: string;
  phone?: string;
  detail_address?: string;
  avatar_url?: string;
  verification_status: 'pending' | 'verified' | 'rejected';
  poktan: string;
  village: string;
  land_area: number | string;
  land_area_ha: number | string;
  gps_latitude?: number | string | null;
  gps_longitude?: number | string | null;
  soil_type?: string | null;
  ktp_image_url?: string | null;
  email?: string;
  created_at?: string;
  // UI derived attributes
  commodities?: string[];
  ownership_type?: string;
  dukcapil_match_percent?: number;
  kt_number?: string;
}

export const fetchPendingFarmers = async (): Promise<PendingFarmer[]> => {
  const response = await fetch(`${API_BASE_URL}/penyuluh/pending-farmers`);
  if (!response.ok) {
    throw new Error(`Gagal mengambil data antrean: status ${response.status}`);
  }
  const result = await response.json();
  const data: PendingFarmer[] = result.data || [];
  return data;
};

export const verifyFarmer = async (
  id: string,
  status: 'verified' | 'rejected',
  notes?: string
): Promise<{ success: boolean; message: string }> => {
  const response = await fetch(`${API_BASE_URL}/penyuluh/verify-farmer/${id}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      status,
      notes: notes || undefined,
    }),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.message || `Gagal memverifikasi petani: status ${response.status}`);
  }

  return response.json();
};
