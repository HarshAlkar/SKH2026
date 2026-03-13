import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const apiService = {
  // Auth
  login: (credentials) => api.post('/auth/login/', credentials),
  register: (userData) => api.post('/auth/register/', userData),

  // Users
  getUsers: () => api.get('/users/'),
  getPatients: () => api.get('/patients/'),
  
  // Doctors
  getDoctors: () => api.get('/doctors/'),
  addDoctor: (doctorData) => api.post('/doctors/', doctorData),

  // Symptoms
  analyzeSymptoms: (symptoms) => api.post('/symptoms/analyze/', { symptoms }),

  // Consultations
  getConsultations: () => api.get('/consultations/history/'),
  startConsultation: (data) => api.post('/consultations/start/', data),

  // Prescriptions
  getPrescriptions: () => api.get('/prescriptions/'),
  addPrescription: (data) => api.post('/prescriptions/', data),
};

export default api;
