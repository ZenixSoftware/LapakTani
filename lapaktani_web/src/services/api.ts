const API_BASE_URL = 'http://localhost:3000/api';
export const TOKEN_KEY = 'lapaktani_token';
export const USER_KEY = 'lapaktani_user';

/**
 * Resolves local/relative or Android-emulated image URLs to accessible backend URLs
 */
export const resolveImageUrl = (url?: string | null): string | null => {
  if (!url || typeof url !== 'string' || !url.trim()) return null;
  const trimmed = url.trim();
  if (trimmed.startsWith('http://10.0.2.2:3000')) {
    return trimmed.replace('http://10.0.2.2:3000', 'http://localhost:3000');
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('data:')) {
    return trimmed;
  }
  const cleanPath = trimmed.startsWith('/') ? trimmed : `/${trimmed}`;
  return `http://localhost:3000${cleanPath}`;
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
