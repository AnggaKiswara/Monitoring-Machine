import { Navigate, Route, Routes } from 'react-router-dom';
import { useAuth } from './auth/AuthContext';
import { ToastProvider } from './components/Toast';
import { Layout } from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Factories from './pages/Factories';
import Stations from './pages/Stations';
import Machines from './pages/Machines';
import Inspections from './pages/Inspections';
import InspectionDetail from './pages/InspectionDetail';
import Alerts from './pages/Alerts';
import AlertRules from './pages/AlertRules';
import Users from './pages/Users';

function RequireAuth({ children }) {
  const { token } = useAuth();
  if (!token) return <Navigate to="/login" replace />;
  return <Layout>{children}</Layout>;
}

export default function App() {
  const { token } = useAuth();
  return (
    <ToastProvider>
      <Routes>
        <Route path="/login" element={token ? <Navigate to="/" replace /> : <Login />} />
        <Route path="/" element={<RequireAuth><Dashboard /></RequireAuth>} />
        <Route path="/factories" element={<RequireAuth><Factories /></RequireAuth>} />
        <Route path="/stations" element={<RequireAuth><Stations /></RequireAuth>} />
        <Route path="/machines" element={<RequireAuth><Machines /></RequireAuth>} />
        <Route path="/inspections" element={<RequireAuth><Inspections /></RequireAuth>} />
        <Route path="/inspections/:machineId/:serviceId" element={<RequireAuth><InspectionDetail /></RequireAuth>} />
        <Route path="/alerts" element={<RequireAuth><Alerts /></RequireAuth>} />
        <Route path="/alert-rules" element={<RequireAuth><AlertRules /></RequireAuth>} />
        <Route path="/users" element={<RequireAuth><Users /></RequireAuth>} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </ToastProvider>
  );
}
