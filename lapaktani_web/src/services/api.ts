const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL || 'https://api-lapaktani.velosixraptor.my.id/api').replace(/\/+$/, '');
const API_ORIGIN = API_BASE_URL.replace(/\/api$/, '');
const API_KEY = import.meta.env.VITE_API_KEY || '';
export const TOKEN_KEY = 'lapaktani_token';
export const USER_KEY = 'lapaktani_user';

/**
 * Resolves local/relative or Android-emulated image URLs to accessible backend URLs
 */
export const resolveImageUrl = (url?: string | null): string | null => {
  if (!url || typeof url !== 'string' || !url.trim()) return null;
  const trimmed = url.trim();
  if (trimmed.startsWith('data:')) {
    return trimmed;
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed.replace(/^http:\/\/(localhost|127\.0\.0\.1|10\.0\.2\.2)(:\d+)?/i, API_ORIGIN);
  }
  const cleanPath = trimmed.startsWith('/') ? trimmed : `/${trimmed}`;
  return `${API_ORIGIN}${cleanPath}`;
};

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
  selfie_image_url?: string | null;
  birth_date?: string | null;
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

export interface AuthUser {
  id: string;
  full_name: string;
  email: string;
  role_id: number;
  role: string;
  is_verified?: boolean;
}

export interface LoginResponse {
  success: boolean;
  message: string;
  token: string;
  user: AuthUser;
}

/**
 * Retrieves the stored auth token from localStorage
 */
export const getAuthToken = (): string | null => {
  return localStorage.getItem(TOKEN_KEY) || localStorage.getItem('token');
};

/**
 * Stores the auth token in localStorage under both standard keys
 */
export const setAuthToken = (token: string): void => {
  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem('token', token);
};

/**
 * Clears stored auth tokens and user data
 */
export const removeAuthToken = (): void => {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem('token');
  localStorage.removeItem(USER_KEY);
};

/**
 * Retrieves stored user metadata
 */
export const getStoredUser = (): AuthUser | null => {
  const userStr = localStorage.getItem(USER_KEY);
  if (!userStr) return null;
  try {
    return JSON.parse(userStr) as AuthUser;
  } catch {
    return null;
  }
};

/**
 * Stores user metadata in localStorage
 */
export const setStoredUser = (user: AuthUser): void => {
  localStorage.setItem(USER_KEY, JSON.stringify(user));
};

/**
 * Authenticated fetch wrapper that automatically retrieves and attaches
 * Authorization: Bearer <token> from localStorage.
 */
export const authFetch = async (
  input: string,
  init: RequestInit = {}
): Promise<Response> => {
  const token = getAuthToken();
  const headers = new Headers(init.headers || {});

  if (!headers.has('Content-Type') && !(init.body instanceof FormData)) {
    headers.set('Content-Type', 'application/json');
  }

  headers.set('X-API-Key', API_KEY);

  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }

  const response = await fetch(input, {
    ...init,
    headers,
  });

  return response;
};

/**
 * Authenticate Penyuluh with backend and persist token & user info
 */
export const loginPenyuluh = async (
  email: string,
  password: string
): Promise<LoginResponse> => {
  const response = await fetch(`${API_BASE_URL}/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': API_KEY,
    },
    body: JSON.stringify({ email, password }),
  });

  const data: LoginResponse = await response.json();

  if (!response.ok || !data.success) {
    throw new Error(data.message || 'Gagal masuk. Periksa email dan kata sandi.');
  }

  if (data.token) {
    setAuthToken(data.token);
  }
  if (data.user) {
    setStoredUser(data.user);
  }

  return data;
};

/**
 * Fetch pending farmers queue from protected Penyuluh endpoint
 */
export const fetchPendingFarmers = async (): Promise<PendingFarmer[]> => {
  const response = await authFetch(`${API_BASE_URL}/penyuluh/pending-farmers`);

  if (!response.ok) {
    if (response.status === 401) {
      throw new Error('401: Akses ditolak. Sesi tidak valid atau belum masuk.');
    }
    throw new Error(`Gagal mengambil data antrean: status ${response.status}`);
  }

  const result = await response.json();
  const data: PendingFarmer[] = result.data || [];
  return data;
};

/**
 * Submit farmer verification decision
 */
export const verifyFarmer = async (
  id: string,
  status: 'verified' | 'rejected',
  notes?: string
): Promise<{ success: boolean; message: string }> => {
  const response = await authFetch(`${API_BASE_URL}/penyuluh/verify-farmer/${id}`, {
    method: 'PUT',
    body: JSON.stringify({
      status,
      notes: notes || undefined,
    }),
  });

  if (!response.ok) {
    if (response.status === 401) {
      throw new Error('401: Akses ditolak. Sesi tidak valid atau kedaluwarsa.');
    }
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.message || `Gagal memverifikasi petani: status ${response.status}`);
  }

  return response.json();
};

export interface LandPlotRecord {
  id: number;
  farm_id?: string | null;
  user_id?: string | null;
  latitude: number | string;
  longitude: number | string;
  nama_desa: string;
  kecamatan?: string | null;
  irigasi: string;
  listrik: string;
  pompa_air: string;
  sumber_air: string;
  kondisi_air: string;
  sumber_energi_pompa: string;
  pembajak: string;
  tadahan_hujan: string;
  komoditas: string;
  varietas?: string | null;
  luas_lahan: string;
  status_lahan: string;
  kelompok_tani: string;
  gagal_panen: string;
  hasil_panen_lalu?: number | string | null;
  satuan_panen?: string | null;
  temp: number | string;
  moisture: number | string;
  conductivity: number | string;
  ph: number | string;
  nitrogen: number | string;
  phosphorus: number | string;
  potassium: number | string;
  fertility: number | string;
  foto_daun?: string | null;
  foto_pohon?: string | null;
  foto_tanah?: string | null;
  tipe_penginput?: string | null;
  rekomendasi_ppl?: string | null;
  status_verifikasi_ppl?: 'pending' | 'verified' | 'needs_action' | string | null;
  created_at?: string;
}

export interface MonitoringSummaryStats {
  total_titik: number;
  avg_ph: number | string | null;
  avg_moisture: number | string | null;
  avg_temp: number | string | null;
  avg_conductivity: number | string | null;
  avg_nitrogen: number | string | null;
  avg_phosphorus: number | string | null;
  avg_potassium: number | string | null;
  avg_fertility: number | string | null;
  total_irigasi: number | string | null;
  total_pompa_air: number | string | null;
  total_gagal_panen: number | string | null;
  total_titik_kritis: number | string | null;
}

export interface CommodityDistribution {
  komoditas: string;
  jumlah_titik: number;
  avg_fertility: number | string | null;
  avg_ph: number | string | null;
}

export interface MonitoringSummaryResponse {
  ringkasan_umum: MonitoringSummaryStats;
  distribusi_komoditas: CommodityDistribution[];
  sampel_titik_kritis: LandPlotRecord[];
  recent_logs: LandPlotRecord[];
}

export const fetchMonitoringLahan = async (
  kategori = 'all',
  komoditas = ''
): Promise<LandPlotRecord[]> => {
  const params = new URLSearchParams();
  if (kategori && kategori !== 'all') params.set('kategori', kategori);
  if (komoditas.trim()) params.set('komoditas', komoditas.trim());
  const qs = params.toString() ? `?${params.toString()}` : '';

  let response = await authFetch(`${API_BASE_URL}/penyuluh/monitoring-lahan${qs}`);
  if (response.status === 401 || response.status === 403) {
    response = await authFetch(`${API_BASE_URL}/soil/monitoring-lahan${qs}`);
  }
  if (!response.ok) {
    throw new Error(`Gagal memuat data monitoring lahan: status ${response.status}`);
  }
  const result = await response.json();
  return (result.data || []) as LandPlotRecord[];
};

export const fetchMonitoringSummary = async (): Promise<MonitoringSummaryResponse> => {
  let response = await authFetch(`${API_BASE_URL}/penyuluh/monitoring-summary`);
  if (response.status === 401 || response.status === 403) {
    response = await authFetch(`${API_BASE_URL}/soil/monitoring-summary`);
  }
  if (!response.ok) {
    throw new Error(`Gagal memuat ringkasan monitoring lahan: status ${response.status}`);
  }
  const result = await response.json();
  return result.data as MonitoringSummaryResponse;
};

export const submitPplPlotRecommendation = async (
  id: number,
  rekomendasi_ppl: string,
  status_verifikasi_ppl: 'pending' | 'verified' | 'needs_action'
): Promise<LandPlotRecord> => {
  const response = await authFetch(`${API_BASE_URL}/penyuluh/monitoring-lahan/${id}/recommend`, {
    method: 'PUT',
    body: JSON.stringify({
      rekomendasi_ppl,
      status_verifikasi_ppl,
    }),
  });
  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.message || `Gagal menyimpan rekomendasi PPL (${response.status})`);
  }
  const result = await response.json();
  return result.data as LandPlotRecord;
};
