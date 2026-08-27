import { Navigate, Route, Routes } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import AdminLayout from '../components/layout/AdminLayout';
import LoginPage from '../pages/login/Login';
import Dashboard from '../pages/dashboard/Dashboard';
import PatientsPage from '../pages/patients/Patients';
import DoctorsPage from '../pages/doctors/Doctors';
import AshaPage from '../pages/asha/AshaWorkers';
import ConsultationsPage from '../pages/consultations/Consultations';
import PrescriptionsPage from '../pages/prescriptions/Prescriptions';
import AlertsPage from '../pages/alerts/Alerts';
import RecordsPage from '../pages/records/Records';
import MedicinesPage from '../pages/medicines/Medicines';
import InventoryPage from '../pages/inventory/Inventory';
import VisitsPage from '../pages/visits/Visits';
import SymptomsPage from '../pages/symptoms/Symptoms';
import ChatPage from '../pages/chat/Chat';
import ReportsPage from '../pages/reports/Reports';

function Guard({ children }) {
  const { ready, isAuthed } = useAuth();
  if (!ready) {
    return (
      <div className="min-h-screen bg-page flex items-center justify-center">
        <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }
  if (!isAuthed) return <Navigate to="/login" replace />;
  return children;
}

export default function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        element={
          <Guard>
            <AdminLayout />
          </Guard>
        }
      >
        <Route path="/" element={<Dashboard />} />
        <Route path="/patients" element={<PatientsPage />} />
        <Route path="/users" element={<Navigate to="/patients" replace />} />
        <Route path="/doctors" element={<DoctorsPage />} />
        <Route path="/asha-workers" element={<AshaPage />} />
        <Route path="/consultations" element={<ConsultationsPage />} />
        <Route path="/prescriptions" element={<PrescriptionsPage />} />
        <Route path="/alerts" element={<AlertsPage />} />
        <Route path="/records" element={<RecordsPage />} />
        <Route path="/inventory" element={<InventoryPage />} />
        <Route path="/medicines" element={<MedicinesPage />} />
        <Route path="/visits" element={<VisitsPage />} />
        <Route path="/symptoms" element={<SymptomsPage />} />
        <Route path="/chat" element={<ChatPage />} />
        <Route path="/reports" element={<ReportsPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
