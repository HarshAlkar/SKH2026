import { BrowserRouter } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { SyncProvider } from './context/SyncContext';
import AppRoutes from './routes/AppRoutes';

export default function App() {
  return (
    <AuthProvider>
      <SyncProvider>
        <BrowserRouter>
          <AppRoutes />
        </BrowserRouter>
      </SyncProvider>
    </AuthProvider>
  );
}
