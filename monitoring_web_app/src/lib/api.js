// API client untuk Monitoring Machine admin web.
// Base URL mengarah ke backend di server.
const DEFAULT_API_BASE_URL = 'http://103.93.135.108:3000/api';

const STORAGE_KEYS = {
  apiBaseUrl: 'mm_web_api_base',
  token: 'mm_web_token',
  user: 'mm_web_user',
};

export function getApiBaseUrl() {
  if (typeof window === 'undefined') return DEFAULT_API_BASE_URL;
  return window.localStorage.getItem(STORAGE_KEYS.apiBaseUrl) || DEFAULT_API_BASE_URL;
}

export function setApiBaseUrl(url) {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(STORAGE_KEYS.apiBaseUrl, url);
}

export function getStoredSession() {
  if (typeof window === 'undefined') return { token: '', user: null };
  const token = window.localStorage.getItem(STORAGE_KEYS.token) || '';
  const userRaw = window.localStorage.getItem(STORAGE_KEYS.user);
  return { token, user: userRaw ? JSON.parse(userRaw) : null };
}

export function saveSession(token, user) {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(STORAGE_KEYS.token, token);
  window.localStorage.setItem(STORAGE_KEYS.user, JSON.stringify(user));
}

export function clearSession() {
  if (typeof window === 'undefined') return;
  window.localStorage.removeItem(STORAGE_KEYS.token);
  window.localStorage.removeItem(STORAGE_KEYS.user);
}

function normalize(url) {
  return (url || '').replace(/\/$/, '');
}

export function unwrap(payload) {
  if (Array.isArray(payload)) return payload;
  if (payload && Array.isArray(payload.data)) return payload.data;
  if (payload && payload.data) return payload.data;
  return payload ?? [];
}

// request dasar
export async function apiRequest(path, options = {}) {
  const { apiBaseUrl = getApiBaseUrl(), token, method = 'GET', body } = options;
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${normalize(apiBaseUrl)}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  let payload = null;
  try {
    payload = await res.json();
  } catch {
    payload = null;
  }

  if (!res.ok) {
    const msg = payload?.message || payload?.error || `Request gagal (${res.status})`;
    throw new Error(msg);
  }
  return payload;
}

export async function loginRequest(username, password) {
  const res = await apiRequest('/auth/login', {
    method: 'POST',
    body: { username, password },
  });
  // backend: { success, data: { token, user } }
  const data = res?.data ?? res;
  if (!data?.token) throw new Error('Respons login tidak memuat token');
  return data;
}

// ===== Helper spesifik =====
export const API = {
  // Factories
  getFactories: (token) => apiRequest('/factories', { token }),
  createFactory: (token, body) => apiRequest('/factories', { token, method: 'POST', body }),
  updateFactory: (token, id, body) => apiRequest(`/factories/${id}`, { token, method: 'PUT', body }),
  deleteFactory: (token, id) => apiRequest(`/factories/${id}`, { token, method: 'DELETE' }),

  // Stations
  getStations: (token, factoryId) =>
    apiRequest(`/stations?limit=300${factoryId ? `&id_factory=${factoryId}` : ''}`, { token }),
  createStation: (token, body) => apiRequest('/stations', { token, method: 'POST', body }),
  updateStation: (token, id, body) => apiRequest(`/stations/${id}`, { token, method: 'PUT', body }),
  deleteStation: (token, id) => apiRequest(`/stations/${id}`, { token, method: 'DELETE' }),

  // Machines (lori)
  getMachines: (token, stationId) =>
    apiRequest(`/machines?limit=500${stationId ? `&id_station=${stationId}` : ''}`, { token }),
  createMachine: (token, body) => apiRequest('/machines', { token, method: 'POST', body }),
  updateMachine: (token, id, body) => apiRequest(`/machines/${id}`, { token, method: 'PUT', body }),
  deleteMachine: (token, id) => apiRequest(`/machines/${id}`, { token, method: 'DELETE' }),

  // Inspections (global)
  getInspections: (token, limit = 50, offset = 0) =>
    apiRequest(`/service-history/global?limit=${limit}&offset=${offset}`, { token }),
  getInspectionDetail: (token, machineId, serviceId) =>
    apiRequest(`/machines/${machineId}/inspection/${serviceId}`, { token }),
  updateInspection: (token, machineId, serviceId, body) =>
    apiRequest(`/machines/${machineId}/inspection/${serviceId}`, { token, method: 'PUT', body }),
  deleteInspection: (token, machineId, serviceId) =>
    apiRequest(`/machines/${machineId}/inspection/${serviceId}`, { token, method: 'DELETE' }),
  deletePhoto: (token, machineId, serviceId, photoId) =>
    apiRequest(`/machines/${machineId}/inspection/${serviceId}/photos/${photoId}`, { token, method: 'DELETE' }),

  // Users
  getUsers: (token) => apiRequest('/users', { token }),
  updateUser: (token, id, body) => apiRequest(`/users/${id}`, { token, method: 'PUT', body }),
  setUserActive: (token, id, isActive) =>
    apiRequest(`/users/${id}/active`, { token, method: 'PATCH', body: { is_active: isActive } }),
  registerUser: (token, body) => apiRequest('/auth/register', { token, method: 'POST', body }),

  // Alerts
  getAlerts: (token) => apiRequest('/service-alerts?limit=100', { token }),
  updateAlert: (token, id, body) => apiRequest(`/service-alerts/${id}`, { token, method: 'PUT', body }),

  // Alert rules
  getAlertRules: (token) => apiRequest('/alert-rules', { token }),
  createAlertRule: (token, body) => apiRequest('/alert-rules', { token, method: 'POST', body }),
  updateAlertRule: (token, id, body) => apiRequest(`/alert-rules/${id}`, { token, method: 'PUT', body }),
  deleteAlertRule: (token, id) => apiRequest(`/alert-rules/${id}`, { token, method: 'DELETE' }),
};
