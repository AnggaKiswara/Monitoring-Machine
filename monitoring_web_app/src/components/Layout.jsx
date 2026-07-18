import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';

const NAV = [
  { to: '/', label: 'Dashboard', icon: '▦', end: true },
  { to: '/factories', label: 'Pabrik', icon: '🏭' },
  { to: '/inspections', label: 'Riwayat Inspeksi', icon: '📋' },
  { to: '/alerts', label: 'Alert', icon: '⚠' },
  { to: '/alert-rules', label: 'Aturan Alert', icon: '⚙' },
  { to: '/users', label: 'User', icon: '👤' },
];

export function Layout({ children }) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  function handleLogout() {
    logout();
    navigate('/login');
  }

  return (
    <div className="flex min-h-screen">
      <aside className="w-64 bg-navy text-white flex flex-col">
        <div className="px-6 py-5 border-b border-white/10">
          <h1 className="text-lg font-bold">Monitoring Machine</h1>
          <p className="text-xs text-white/60">Admin Panel</p>
        </div>
        <nav className="flex-1 px-3 py-4 space-y-1">
          {NAV.map((n) => (
            <NavLink
              key={n.to}
              to={n.to}
              end={n.end}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium ${
                  isActive ? 'bg-brand text-white' : 'text-white/70 hover:bg-white/10'
                }`
              }
            >
              <span>{n.icon}</span>
              {n.label}
            </NavLink>
          ))}
        </nav>
        <div className="px-4 py-4 border-t border-white/10">
          <p className="text-xs text-white/60 mb-2">
            Login: {user?.nama_lengkap || user?.username}
          </p>
          <button
            onClick={handleLogout}
            className="w-full px-3 py-2 rounded-lg bg-white/10 hover:bg-white/20 text-sm font-medium"
          >
            Logout
          </button>
        </div>
      </aside>
      <main className="flex-1 overflow-y-auto">
        <div className="p-8">{children}</div>
      </main>
    </div>
  );
}
