import { Navigate, Outlet, Route, Routes } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import PharmacyLayout from '../components/layout/PharmacyLayout';
import Login from '../pages/Login';
import Dashboard from '../pages/Dashboard';
import Inventory from '../pages/Inventory';
import UpdateStock from '../pages/UpdateStock';
import Expiry from '../pages/Expiry';
import LowStock from '../pages/LowStock';
import Suppliers from '../pages/Suppliers';
import History from '../pages/History';
import MapPage from '../pages/MapPage';
import Reports from '../pages/Reports';
import Settings from '../pages/Settings';

function Guard() {
  const { ready, isAuthed } = useAuth();
  if (!ready) {
    return <div className="min-h-screen grid place-items-center text-muted">Loading…</div>;
  }
  if (!isAuthed) return <Navigate to="/login" replace />;
  return <Outlet />;
}

export default function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route element={<Guard />}>
        <Route element={<PharmacyLayout />}>
          <Route index element={<Dashboard />} />
          <Route path="inventory" element={<Inventory />} />
          <Route path="update-stock" element={<UpdateStock />} />
          <Route path="expiry" element={<Expiry />} />
          <Route path="low-stock" element={<LowStock />} />
          <Route path="suppliers" element={<Suppliers />} />
          <Route path="history" element={<History />} />
          <Route path="map" element={<MapPage />} />
          <Route path="reports" element={<Reports />} />
          <Route path="settings" element={<Settings />} />
        </Route>
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
