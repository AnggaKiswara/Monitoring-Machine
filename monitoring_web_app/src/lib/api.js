const DEFAULT_API_BASE_URL = 'http://localhost:3000/api';
const STORAGE_KEYS = {
  apiBaseUrl: 'monitoring-web-api-base-url',
  token: 'monitoring-web-token',
  user: 'monitoring-web-user',
};

export function getStoredApiBaseUrl() {
  if (typeof window === 'undefined') {
    return DEFAULT_API_BASE_URL;
  }

  return window.localStorage.getItem(STORAGE_KEYS.apiBaseUrl) || DEFAULT_API_BASE_URL;
}

export function setStoredApiBaseUrl(apiBaseUrl) {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.setItem(STORAGE_KEYS.apiBaseUrl, apiBaseUrl);
}

export function getStoredSession() {
  if (typeof window === 'undefined') {
    return { token: '', user: null };
  }

  const token = window.localStorage.getItem(STORAGE_KEYS.token) || '';
  const userRaw = window.localStorage.getItem(STORAGE_KEYS.user);

  return {
    token,
    user: userRaw ? JSON.parse(userRaw) : null,
  };
}

export function saveSession(token, user) {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.setItem(STORAGE_KEYS.token, token);
  window.localStorage.setItem(STORAGE_KEYS.user, JSON.stringify(user));
}

export function clearSession() {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.removeItem(STORAGE_KEYS.token);
  window.localStorage.removeItem(STORAGE_KEYS.user);
}

function normalizeApiBaseUrl(apiBaseUrl) {
  return apiBaseUrl.replace(/\/$/, '');
}

export function unwrapData(payload) {
  if (Array.isArray(payload)) {
    return payload;
  }

  if (payload && Array.isArray(payload.data)) {
    return payload.data;
  }

  return payload?.data ?? payload ?? [];
}

export async function apiRequest(path, options = {}) {
  const {
    apiBaseUrl = getStoredApiBaseUrl(),
    token,
    method = 'GET',
    body,
  } = options;

  const response = await fetch(`${normalizeApiBaseUrl(apiBaseUrl)}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  let payload = null;
  try {
    payload = await response.json();
  } catch (error) {
    payload = null;
  }

  if (!response.ok) {
    throw new Error(payload?.message || payload?.error || `Request failed (${response.status})`);
  }

  return payload;
}

export async function loginRequest(apiBaseUrl, username, password) {
  return apiRequest('/auth/login', {
    apiBaseUrl,
    method: 'POST',
    body: { username, password },
  });
}