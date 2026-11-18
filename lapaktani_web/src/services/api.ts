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
  admin_tier?: 'B2B_OFFTAKER' | 'RETAIL_MERCHANT' | string | null;
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

export interface DecisionReportRecord {
  id: string;
  plot_id?: string | null;
  village_id?: number | null;
  penyuluh_id: string;
  penyuluh_name: string;
  desa: string;
  kecamatan: string;
  poktan_id?: string | null;
  komoditas: string;
  rag_context?: Record<string, unknown> | null;
  decision_summary: string;
  action_plan: string;
  target_scope: 'DINAS_ONLY' | 'FARMERS_ONLY' | 'BOTH';
  status: 'SENT' | 'REVIEWED' | 'ACKNOWLEDGED';
  dinas_notes?: string | null;
  created_at: string;
}

export interface RagSynthesisResult {
  plot_id?: string | null;
  desa: string;
  kecamatan: string;
  komoditas: string;
  rag_context: {
    retrieved_at: string;
    desa: string;
    kecamatan: string;
    komoditas: string;
    primary_plot: LandPlotRecord | null;
    related_plots_count: number;
    pest_alerts: Array<Record<string, unknown>>;
    farmer_daily_logs: Array<Record<string, unknown>>;
  };
  decision_summary: string;
  action_plan: string;
  dinas_escalation_note?: string;
  farmer_field_steps?: string[];
  synthesizer_engine?: string;
}

export const generateRagDecision = async (payload: {
  plot_id?: string | number | null;
  desa?: string;
  kecamatan?: string;
  komoditas?: string;
  query_prompt?: string;
}): Promise<RagSynthesisResult> => {
  const response = await authFetch(`${API_BASE_URL}/penyuluh/rag-decision`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.message || `Gagal menyintesis keputusan RAG (${response.status})`);
  }
  const result = await response.json();
  return result.data as RagSynthesisResult;
};

export const dispatchRagDecision = async (payload: {
  plot_id?: string | number | null;
  village_id?: number;
  desa: string;
  kecamatan?: string;
  poktan_id?: string | null;
  komoditas?: string;
  rag_context?: Record<string, unknown> | null;
  decision_summary: string;
  action_plan: string;
  target_scope: 'DINAS_ONLY' | 'FARMERS_ONLY' | 'BOTH';
}): Promise<DecisionReportRecord> => {
  const response = await authFetch(`${API_BASE_URL}/penyuluh/dispatch-decision`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.message || `Gagal mengirim keputusan RAG (${response.status})`);
  }
  const result = await response.json();
  return result.data as DecisionReportRecord;
};

export const fetchDecisionReports = async (params?: {
  role?: string;
  desa?: string;
  village_id?: number;
  status?: string;
}): Promise<DecisionReportRecord[]> => {
  const qs = new URLSearchParams();
  if (params?.role) qs.set('role', params.role);
  if (params?.desa) qs.set('desa', params.desa);
  if (params?.village_id) qs.set('village_id', String(params.village_id));
  if (params?.status) qs.set('status', params.status);
  const queryStr = qs.toString() ? `?${qs.toString()}` : '';

  const response = await authFetch(`${API_BASE_URL}/penyuluh/decision-reports${queryStr}`);
  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.message || `Gagal memuat laporan keputusan (${response.status})`);
  }
  const result = await response.json();
  return (result.data || []) as DecisionReportRecord[];
};

export const updateDecisionReportStatus = async (
  id: string,
  status: 'SENT' | 'REVIEWED' | 'ACKNOWLEDGED',
  dinas_notes?: string
): Promise<DecisionReportRecord> => {
  const response = await authFetch(`${API_BASE_URL}/penyuluh/decision-reports/${id}/status`, {
    method: 'PUT',
    body: JSON.stringify({ status, dinas_notes }),
  });
  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.message || `Gagal memperbarui status laporan (${response.status})`);
  }
  const result = await response.json();
  return result.data as DecisionReportRecord;
};

// ============================================================================
// Streamlined Agro Supply Chain: Fertilizer, Store Quota & Scoped Forums
// ============================================================================

export interface VillageQuotaRecord {
  id: number;
  district_id: number;
  name: string;
  district_name: string;
  postal_code: string;
  is_store_quota_enabled: boolean;
  max_stores_quota: number;
  approved_stores_count: number;
  pending_stores_count: number;
  is_quota_full: boolean;
  remaining_quota: number | null;
}

export interface FertilizerAllocationRecord {
  id: string;
  village_id: number;
  district_id: number;
  village_name: string;
  penyuluh_id: string;
  penyuluh_name: string;
  jenis_pupuk: string;
  jumlah_ton: number | string;
  alasan_kebutuhan?: string | null;
  status: 'USULAN_PPL' | 'KONFIRMASI_DINAS' | 'DIKIRIM_DINAS' | 'DITERIMA_DESA';
  titik_ambil_desa?: string | null;
  catatan_dinas?: string | null;
  created_at: string;
  updated_at: string;
}

export interface StoreApplicationRecord {
  id: string;
  user_id: string;
  nama_toko: string;
  tipe_pengelola: 'POKTAN' | 'KOPERASI' | 'PENGEPUL_DESA';
  nik?: string | null;
  no_hp?: string | null;
  village_id: number;
  village_name: string;
  resolved_village_name?: string;
  postal_code?: string | null;
  alamat_lengkap?: string | null;
  dokumen_syarat_url?: string | null;
  default_min_wholesale_kg: number;
  status: 'DRAFT_FROZEN' | 'PENDING_PPL' | 'APPROVED' | 'REJECTED';
  rejection_reason?: string | null;
  applicant_name?: string | null;
  applicant_email?: string | null;
  is_store_quota_enabled?: number | boolean;
  max_stores_quota?: number;
  created_at: string;
}

export interface PplForumPost {
  id: string;
  penyuluh_id: string;
  penyuluh_name: string;
  bpp_kecamatan: string;
  topik: string;
  komoditas: string;
  isi_diskusi: string;
  rekomendasi_teknis?: string | null;
  likes_count: number;
  created_at: string;
}

export interface VillageForumPost {
  id: string;
  village_id: number;
  village_name: string;
  author_id: string;
  author_name: string;
  author_role: 'penyuluh' | 'petani' | 'admin';
  kategori: 'INFO_PUPUK' | 'TANYA_JAWAB' | 'PERINGATAN_HAMA' | 'ARAHAN_TANAM';
  judul: string;
  isi_pesan: string;
  titik_ambil_pupuk?: string | null;
  created_at: string;
}

export const fetchFertilizerSubsidies = async (): Promise<FertilizerAllocationRecord[]> => {
  const response = await authFetch(`${API_BASE_URL}/dinas/fertilizer-subsidies`);
  if (!response.ok) {
    throw new Error(`Gagal memuat data pupuk subsidi (${response.status})`);
  }
  const result = await response.json();
  return (result.data || []) as FertilizerAllocationRecord[];
};

export const confirmFertilizerSubsidy = async (payload: {
  allocation_id?: string;
  village_id?: number;
  village_name?: string;
  jenis_pupuk?: string;
  jumlah_ton?: number;
  titik_ambil_desa?: string;
  catatan_dinas?: string;
  status?: 'KONFIRMASI_DINAS' | 'DIKIRIM_DINAS';
}): Promise<FertilizerAllocationRecord> => {
  const response = await authFetch(`${API_BASE_URL}/dinas/fertilizer-subsidies/confirm`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err.message || `Gagal mengonfirmasi pupuk (${response.status})`);
  }
  const result = await response.json();
  return result.data as FertilizerAllocationRecord;
};

export const dispatchFertilizerSubsidy = async (
  id: string,
  payload: {
    status: 'KONFIRMASI_DINAS' | 'DIKIRIM_DINAS' | 'DITERIMA_DESA';
    jumlah_ton?: number;
    titik_ambil_desa?: string;
    catatan_dinas?: string;
  }
): Promise<FertilizerAllocationRecord> => {
  const response = await authFetch(`${API_BASE_URL}/dinas/fertilizer-subsidies/${id}/dispatch`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err.message || `Gagal memperbarui status pupuk (${response.status})`);
  }
  const result = await response.json();
  return result.data as FertilizerAllocationRecord;
};

export const proposeFertilizerSubsidy = async (payload: {
  village_id: number;
  jenis_pupuk: string;
  jumlah_ton: number;
  alasan_kebutuhan: string;
  titik_ambil_desa?: string;
}): Promise<FertilizerAllocationRecord> => {
  const response = await authFetch(`${API_BASE_URL}/penyuluh/fertilizer-request`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err.message || `Gagal mengusulkan pupuk (${response.status})`);
  }
  const result = await response.json();
  return result.data as FertilizerAllocationRecord;
};

export const markFertilizerReceivedByPpl = async (
  id: string,
  titik_ambil_desa?: string
): Promise<FertilizerAllocationRecord> => {
  const response = await authFetch(`${API_BASE_URL}/penyuluh/fertilizer-subsidies/${id}/receive`, {
    method: 'PUT',
    body: JSON.stringify({ titik_ambil_desa }),
  });
  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err.message || `Gagal mencatat penerimaan pupuk desa (${response.status})`);
  }
  const result = await response.json();
  return result.data as FertilizerAllocationRecord;
};

export const fetchStoreApplications = async (): Promise<{
  applications: StoreApplicationRecord[];
  villages: VillageQuotaRecord[];
}> => {
  const response = await authFetch(`${API_BASE_URL}/penyuluh/store-applications`);
  if (!response.ok) {
    throw new Error(`Gagal memuat pengajuan pembukaan toko (${response.status})`);
  }
  const result = await response.json();
  return {
    applications: (result.data || []) as StoreApplicationRecord[],
    villages: (result.villages || []) as VillageQuotaRecord[],
  };
};

export const verifyStoreApplication = async (
  id: string,
  status: 'APPROVED' | 'REJECTED',
  rejection_reason?: string
): Promise<StoreApplicationRecord> => {
  const response = await authFetch(`${API_BASE_URL}/penyuluh/store-applications/${id}/verify`, {
    method: 'PUT',
    body: JSON.stringify({ status, rejection_reason }),
  });
  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err.message || `Gagal memverifikasi toko (${response.status})`);
  }
  const result = await response.json();
  return result.data as StoreApplicationRecord;
};

export const updateVillageStoreQuota = async (payload: {
  village_id: number;
  is_store_quota_enabled: boolean;
  max_stores_quota: number;
  postal_code?: string;
}): Promise<{ data: VillageQuotaRecord | null; villages: VillageQuotaRecord[] }> => {
  const response = await authFetch(`${API_BASE_URL}/penyuluh/village-store-quota`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err.message || `Gagal memperbarui kuota toko desa (${response.status})`);
  }
  const result = await response.json();
  return {
    data: result.data as VillageQuotaRecord | null,
    villages: (result.villages || []) as VillageQuotaRecord[],
  };
};

export const fetchInterPplForum = async (): Promise<PplForumPost[]> => {
  const response = await authFetch(`${API_BASE_URL}/penyuluh/inter-ppl-forum`);
  if (!response.ok) {
    throw new Error(`Gagal memuat forum antar-penyuluh (${response.status})`);
  }
  const result = await response.json();
  return (result.data || []) as PplForumPost[];
};

export const createInterPplForumPost = async (payload: {
  topik: string;
  komoditas?: string;
  isi_diskusi: string;
  rekomendasi_teknis?: string;
}): Promise<PplForumPost> => {
  const response = await authFetch(`${API_BASE_URL}/penyuluh/inter-ppl-forum`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err.message || `Gagal mengirim diskusi antar-penyuluh (${response.status})`);
  }
  const result = await response.json();
  return result.data as PplForumPost;
};

export const fetchVillageForum = async (villageId?: number): Promise<VillageForumPost[]> => {
  const qs = villageId ? `?village_id=${villageId}` : '';
  const response = await authFetch(`${API_BASE_URL}/penyuluh/village-forum${qs}`);
  if (!response.ok) {
    throw new Error(`Gagal memuat forum privat desa (${response.status})`);
  }
  const result = await response.json();
  return (result.data || []) as VillageForumPost[];
};

export const createVillageForumPost = async (payload: {
  village_id: number;
  kategori: 'INFO_PUPUK' | 'TANYA_JAWAB' | 'PERINGATAN_HAMA' | 'ARAHAN_TANAM';
  judul: string;
  isi_pesan: string;
  titik_ambil_pupuk?: string;
}): Promise<VillageForumPost> => {
  const response = await authFetch(`${API_BASE_URL}/penyuluh/village-forum`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err.message || `Gagal mengirim pengumuman desa (${response.status})`);
  }
  const result = await response.json();
  return result.data as VillageForumPost;
};

// ============================================================================
// 5-Role Web Direct Messaging (Dinas <-> Penyuluh <-> Petani / Admin Toko)
// ============================================================================

export interface WebChatParticipant {
  id: string;
  full_name: string;
  email: string;
  role_id: number;
  role: string;
  village_id?: number | null;
  village_name?: string | null;
}

export interface WebChatMessage {
  id: string;
  conversation_id: string;
  sender_id: string;
  sender_name: string;
  sender_role?: string;
  message_type: 'TEXT' | 'ORDER_CARD' | 'ADVISORY_CARD' | string;
  body: string;
  metadata?: Record<string, unknown> | null;
  created_at: string;
}

export interface WebChatConversation {
  id: string;
  type: 'DIRECT' | 'ORDER' | string;
  order_id?: string | null;
  title?: string | null;
  participants: WebChatParticipant[];
  other_participant?: WebChatParticipant | null;
  last_message?: WebChatMessage | null;
  unread_count: number;
  updated_at?: string | null;
}

export const fetchWebChatConversations = async (): Promise<WebChatConversation[]> => {
  const response = await authFetch(`${API_BASE_URL}/chat/conversations?type=DIRECT`);
  if (!response.ok) {
    throw new Error(`Gagal memuat percakapan DM (${response.status})`);
  }
  const result = await response.json();
  return (result.data || []) as WebChatConversation[];
};

export const fetchWebChatContacts = async (): Promise<WebChatParticipant[]> => {
  const response = await authFetch(`${API_BASE_URL}/chat/contacts`);
  if (!response.ok) {
    throw new Error(`Gagal memuat kontak DM (${response.status})`);
  }
  const result = await response.json();
  return (result.data || []) as WebChatParticipant[];
};

export const openWebDirectConversation = async (payload: {
  target_user_id?: string;
  target_role?: string;
  title?: string;
  initial_message?: string;
}): Promise<WebChatConversation> => {
  const response = await authFetch(`${API_BASE_URL}/chat/conversations/direct`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err.message || `Gagal membuka ruang DM (${response.status})`);
  }
  const result = await response.json();
  return result.data as WebChatConversation;
};

export const fetchWebChatMessages = async (conversationId: string): Promise<WebChatMessage[]> => {
  const response = await authFetch(`${API_BASE_URL}/chat/conversations/${conversationId}/messages`);
  if (!response.ok) {
    throw new Error(`Gagal memuat riwayat pesan (${response.status})`);
  }
  const result = await response.json();
  return (result.data || []) as WebChatMessage[];
};

export const sendWebChatMessage = async (
  conversationId: string,
  body: string
): Promise<WebChatMessage> => {
  const response = await authFetch(`${API_BASE_URL}/chat/conversations/${conversationId}/messages`, {
    method: 'POST',
    body: JSON.stringify({ body, message_type: 'TEXT' }),
  });
  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err.message || `Gagal mengirim pesan DM (${response.status})`);
  }
  const result = await response.json();
  return result.data as WebChatMessage;
};

// ============================================================================
// SUPER ADMIN GOVERNANCE (6TH ROLE)
// ============================================================================
export interface SuperAdminRoleCount {
  role: string;
  total: number;
  active_count: number;
}

export interface SuperAdminStoreTierCount {
  admin_tier: 'B2B_OFFTAKER' | 'RETAIL_MERCHANT' | string;
  status: string;
  total: number;
}

export interface PlatformFeeLedgerEntry {
  id: string;
  ref_type?: string;
  order_or_bid_id?: string;
  reference_type?: string;
  reference_id?: string;
  cancelled_by_role: string;
  cancelled_by_user_id: string;
  actor_name?: string;
  actor_email?: string;
  gross_amount: number | string;
  fee_percent?: number | string;
  fee_charged: number | string;
  refunded_amount: number | string;
  reason?: string | null;
  created_at: string;
}

export interface SuperAdminOverviewResponse {
  users_by_role: SuperAdminRoleCount[];
  stores_by_tier_and_status: SuperAdminStoreTierCount[];
  fee_ledger_summary: {
    total_cancellations: number;
    total_cancelled_gross: number;
    total_fee_collected: number;
    total_refunded_to_users: number;
  };
  recent_fee_ledger: PlatformFeeLedgerEntry[];
  mvp_9_health: {
    compliance_score: string;
    compression?: Record<string, unknown>;
    rate_limiter?: Record<string, unknown>;
    job_queue?: Record<string, unknown>;
    notifications?: Record<string, unknown>;
  };
}

export interface AuthorityAccountRecord {
  id: string;
  email: string;
  full_name: string;
  role: 'dinas' | 'penyuluh' | string;
  role_id: number;
  is_verified: boolean;
  is_active: boolean;
  created_at?: string;
  nip?: string | null;
  bpp_unit?: string | null;
  village_id?: number | null;
  village_name?: string;
  district_id?: number | null;
  district_name?: string;
}

export interface SuperAdminStoreRecord {
  id: string;
  user_id: string;
  nama_toko: string;
  admin_tier: 'B2B_OFFTAKER' | 'RETAIL_MERCHANT' | string;
  kapasitas_gudang_kg?: number | string | null;
  auto_kyc_passed: boolean;
  status: 'PENDING_PPL' | 'APPROVED' | 'REJECTED' | 'SUSPENDED' | 'DRAFT_FROZEN' | string;
  is_store_open: boolean;
  owner_name?: string;
  owner_email?: string;
  owner_is_active?: number | boolean;
  resolved_village_name?: string;
  village_name?: string;
  ktp_number?: string | null;
  nib_or_siup?: string | null;
  rejection_reason?: string | null;
  created_at?: string;
  updated_at?: string;
}

export const fetchSuperAdminOverview = async (): Promise<SuperAdminOverviewResponse> => {
  const response = await authFetch(`${API_BASE_URL}/superadmin/overview`);
  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err.message || `Gagal memuat ringkasan Super Admin (${response.status})`);
  }
  const result = await response.json();
  return result.data as SuperAdminOverviewResponse;
};

export const fetchSuperAdminAuthorities = async (): Promise<AuthorityAccountRecord[]> => {
  const response = await authFetch(`${API_BASE_URL}/superadmin/authorities`);
  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err.message || `Gagal memuat akun otoritas (${response.status})`);
  }
  const result = await response.json();
  return (result.data || []) as AuthorityAccountRecord[];
};

export const provisionAuthorityAccount = async (payload: {
  full_name: string;
  email: string;
  password: string;
  role: 'dinas' | 'penyuluh';
  village_id?: number;
  bpp_unit?: string;
  nip?: string;
  phone?: string;
}): Promise<AuthorityAccountRecord> => {
  const response = await authFetch(`${API_BASE_URL}/superadmin/provision-authority`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  const result = await response.json().catch(() => ({}));
  if (!response.ok || !result.success) {
    throw new Error(result.message || `Gagal menerbitkan akun otoritas (${response.status})`);
  }
  return result.data as AuthorityAccountRecord;
};

export const toggleAuthorityStatus = async (
  id: string,
  isActive: boolean
): Promise<{ id: string; is_active: boolean }> => {
  const response = await authFetch(`${API_BASE_URL}/superadmin/authorities/${id}/status`, {
    method: 'PUT',
    body: JSON.stringify({ is_active: isActive }),
  });
  const result = await response.json().catch(() => ({}));
  if (!response.ok || !result.success) {
    throw new Error(result.message || `Gagal mengubah status otoritas (${response.status})`);
  }
  return result.data as { id: string; is_active: boolean };
};

export const fetchSuperAdminStores = async (filters?: {
  admin_tier?: string;
  status?: string;
}): Promise<SuperAdminStoreRecord[]> => {
  const params = new URLSearchParams();
  if (filters?.admin_tier) params.set('admin_tier', filters.admin_tier);
  if (filters?.status) params.set('status', filters.status);
  const qs = params.toString() ? `?${params.toString()}` : '';
  const response = await authFetch(`${API_BASE_URL}/superadmin/stores${qs}`);
  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err.message || `Gagal memuat daftar toko (${response.status})`);
  }
  const result = await response.json();
  return (result.data || []) as SuperAdminStoreRecord[];
};

export const updateSuperAdminStoreStatus = async (
  id: string,
  action: 'APPROVE' | 'SUSPEND' | 'REACTIVATE' | 'REJECT',
  reason?: string
): Promise<SuperAdminStoreRecord> => {
  const response = await authFetch(`${API_BASE_URL}/superadmin/stores/${id}/status`, {
    method: 'PUT',
    body: JSON.stringify({ action, reason }),
  });
  const result = await response.json().catch(() => ({}));
  if (!response.ok || !result.success) {
    throw new Error(result.message || `Gagal memperbarui status toko (${response.status})`);
  }
  return result.data as SuperAdminStoreRecord;
};

export interface SumenepVillageOption {
  id: number;
  name: string;
  district_id?: number;
  district_name?: string;
  postal_code?: string;
}

export const fetchSumenepVillages = async (): Promise<SumenepVillageOption[]> => {
  const response = await authFetch(`${API_BASE_URL}/store/villages`);
  if (!response.ok) {
    return [];
  }
  const result = await response.json().catch(() => ({}));
  return (result.villages || []) as SumenepVillageOption[];
};

export const fetchPlatformFeeLedger = async (): Promise<{
  summary: { count: number; total_fees: number; total_refunded: number };
  data: PlatformFeeLedgerEntry[];
}> => {
  const response = await authFetch(`${API_BASE_URL}/superadmin/fee-ledger`);
  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(err.message || `Gagal memuat Platform Fee Ledger (${response.status})`);
  }
  const result = await response.json();
  return {
    summary: result.summary || { count: 0, total_fees: 0, total_refunded: 0 },
    data: (result.data || []) as PlatformFeeLedgerEntry[],
  };
};
