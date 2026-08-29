import axios from 'axios';
import { getApiBaseUrl, subscribeConnection } from './apiHost';

const TOKEN_KEY = 'vr_admin_token';
const USER_KEY = 'vr_admin_user';

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
  if (token) {
    config.headers.Authorization = `Token ${token}`;
  }
  return config;
});

let onUnauthorized = null;
export const setUnauthorizedHandler = (fn) => {
  onUnauthorized = fn;
};

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401 && onUnauthorized) {
      onUnauthorized();
    }
    const message =
      err.response?.data?.error ||
      err.response?.data?.detail ||
      (typeof err.response?.data === 'object'
        ? Object.values(err.response.data).flat()?.[0]
        : null) ||
      err.message ||
      'Request failed';
    return Promise.reject(new Error(typeof message === 'string' ? message : JSON.stringify(message)));
  },
);

const unwrap = (p) => p.then((r) => r.data);

export const adminApi = {
  login: (body) => unwrap(api.post('/admin/login/', body)),
  stats: () => unwrap(api.get('/admin/stats/')),

  users: (params) => unwrap(api.get('/admin/users/', { params })),
  createUser: (body) => unwrap(api.post('/admin/users/', body)),
  patchUser: (id, body) => unwrap(api.patch(`/admin/users/${id}/`, body)),

  patients: (params) => unwrap(api.get('/admin/patients/', { params })),
  createPatient: (body) => unwrap(api.post('/admin/patients/', body)),
  patchPatient: (id, body) => unwrap(api.patch(`/admin/patients/${id}/`, body)),

  doctors: (params) => unwrap(api.get('/admin/doctors/', { params })),
  createDoctor: (body) => unwrap(api.post('/admin/doctors/', body)),
  patchDoctor: (id, body) => unwrap(api.patch(`/admin/doctors/${id}/`, body)),
  approveDoctor: (id) => unwrap(api.post(`/admin/doctors/${id}/approve/`)),
  rejectDoctor: (id, reason) => unwrap(api.post(`/admin/doctors/${id}/reject/`, { reason })),

  ashaWorkers: (params) => unwrap(api.get('/admin/asha-workers/', { params })),
  createAsha: (body) => unwrap(api.post('/admin/asha-workers/', body)),
  patchAsha: (id, body) => unwrap(api.patch(`/admin/asha-workers/${id}/`, body)),
  approveAsha: (id) => unwrap(api.post(`/admin/asha-workers/${id}/approve/`)),
  rejectAsha: (id, reason) => unwrap(api.post(`/admin/asha-workers/${id}/reject/`, { reason })),

  consultations: (params) => unwrap(api.get('/admin/consultations/', { params })),
  patchConsultation: (id, body) => unwrap(api.patch(`/admin/consultations/${id}/`, body)),
  endConsultation: (id) => unwrap(api.post(`/admin/consultations/${id}/end/`)),

  prescriptions: () => unwrap(api.get('/admin/prescriptions/')),
  createPrescription: (body) => unwrap(api.post('/admin/prescriptions/', body)),

  emergencies: (params) => unwrap(api.get('/admin/emergencies/', { params })),
  patchEmergency: (id, body) => unwrap(api.patch(`/admin/emergencies/${id}/`, body)),
  assignEmergency: (id, doctorId) => unwrap(api.patch(`/admin/emergencies/${id}/`, { assigned_doctor: doctorId })),
  mapMarkers: () => unwrap(api.get('/admin/map-markers/')),
  notifications: () => unwrap(api.get('/admin/notifications/')),
  referrals: () => unwrap(api.get('/admin/referrals/')),
  patchReferral: (id, body) => unwrap(api.patch(`/admin/referrals/${id}/`, body)),

  records: () => unwrap(api.get('/admin/records/')),
  createRecord: (body) => unwrap(api.post('/admin/records/', body)),

  medicines: () => unwrap(api.get('/admin/medicines/')),
  createMedicine: (body) => unwrap(api.post('/admin/medicines/', body)),
  patchMedicine: (id, body) => unwrap(api.patch(`/admin/medicines/${id}/`, body)),

  inventoryStats: () => unwrap(api.get('/admin/inventory-stats/')),
  facilities: (params) => unwrap(api.get('/admin/facilities/', { params })),
  createFacility: (body) => unwrap(api.post('/admin/facilities/', body)),
  patchFacility: (id, body) => unwrap(api.patch(`/admin/facilities/${id}/`, body)),
  catalog: (params) => unwrap(api.get('/admin/catalog/', { params })),
  createCatalog: (body) => unwrap(api.post('/admin/catalog/', body)),
  stockBatches: (params) => unwrap(api.get('/admin/stock-batches/', { params })),
  createStockBatch: (body) => unwrap(api.post('/admin/stock-batches/', body)),
  patchStockBatch: (id, body) => unwrap(api.patch(`/admin/stock-batches/${id}/`, body)),
  stockMovements: (params) => unwrap(api.get('/admin/stock-movements/', { params })),
  suppliers: (params) => unwrap(api.get('/admin/suppliers/', { params })),

  visits: () => unwrap(api.get('/admin/visits/')),
  createVisit: (body) => unwrap(api.post('/admin/visits/', body)),
  patchVisit: (id, body) => unwrap(api.patch(`/admin/visits/${id}/`, body)),

  symptoms: () => unwrap(api.get('/admin/symptoms/')),
  chats: () => unwrap(api.get('/admin/chat/')),
  chatMessages: (id) => unwrap(api.get(`/admin/chat/${id}/messages/`)),
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
