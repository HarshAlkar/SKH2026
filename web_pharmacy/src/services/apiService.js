import axios from 'axios';
import { getApiBaseUrl, subscribeConnection } from './apiHost';

const TOKEN_KEY = 'vr_pharmacy_token';
const USER_KEY = 'vr_pharmacy_user';

export const getToken = () => localStorage.getItem(TOKEN_KEY);
export const getStoredUser = () => {
  try {
    return JSON.parse(localStorage.getItem(USER_KEY) || 'null');
  } catch {
    return null;
  }
};

const api = axios.create({
  baseURL: getApiBaseUrl(),
  headers: { 'Content-Type': 'application/json' },
});

subscribeConnection((snap) => {
  api.defaults.baseURL = snap.apiBase;
});

api.interceptors.request.use((config) => {
  config.baseURL = getApiBaseUrl();
  const token = getToken();
  if (token) config.headers.Authorization = `Token ${token}`;
  return config;
});

let onUnauthorized = null;
export const setUnauthorizedHandler = (fn) => {
  onUnauthorized = fn;
};

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401 && onUnauthorized) onUnauthorized();
    const message =
      err.response?.data?.error ||
      err.response?.data?.detail ||
      (typeof err.response?.data === 'object'
        ? Object.values(err.response.data).flat()?.[0]
        : null) ||
      err.message ||
      'Request failed';
    const wrapped = new Error(typeof message === 'string' ? message : JSON.stringify(message));
    wrapped.status = err.response?.status;
    return Promise.reject(wrapped);
  },
);

const unwrap = (p) => p.then((r) => r.data);

export const stockApi = {
  login: (body) => unwrap(api.post('/auth/login/', body)),
  me: () => unwrap(api.get('/users/me/')),
  dashboard: () => unwrap(api.get('/stock/dashboard/')),
  batches: (params) => unwrap(api.get('/stock/batches/', { params })),
  catalog: (params) => unwrap(api.get('/stock/catalog/', { params })),
  createCatalog: (body) => unwrap(api.post('/stock/catalog/', body)),
  suppliers: (params) => unwrap(api.get('/stock/suppliers/', { params })),
  createSupplier: (body) => unwrap(api.post('/stock/suppliers/', body)),
  facilities: () => unwrap(api.get('/stock/facilities/')),
  map: () => unwrap(api.get('/stock/map/')),
  expiry: () => unwrap(api.get('/stock/expiry/')),
  lowStock: () => unwrap(api.get('/stock/low-stock/')),
  history: (params) => unwrap(api.get('/stock/history/', { params })),
  adjust: (body) => unwrap(api.post('/stock/adjust/', body)),
  sync: (items) => unwrap(api.post('/stock/sync/', { items })),
};

export const persistSession = (token, user) => {
  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem(USER_KEY, JSON.stringify(user));
};

export const clearSession = () => {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
};

export default api;
