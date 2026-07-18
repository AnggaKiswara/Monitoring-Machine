import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';

const NAV = [
  { to: '/', label: 'Dashboard', icon: '▦', end: true },
  { to: '/factories', label: 'Pabrik', icon: '🏭' },
  { to: '/stations', label: 'Station', icon: '🏬' },
  { to: '/machines', label: 'Machine (Lori)', icon: '🚛' },
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
    <div className="flex min-h-screen relative overflow-hidden">
      {/* Floating decorative shapes */}
      <div className="pointer-events-none fixed inset-0 -z-10">
        <div className="absolute top-16 left-10 w-28 h-28 rounded-full bg-indigo-400/30 blur-2xl" />
        <div className="absolute top-24 right-24 w-40 h-40 rounded-full border-[14px] border-indigo-400/30" />
        <div className="absolute bottom-20 left-1/3 w-32 h-32 rounded-2xl bg-teal-300/30 blur-2xl rotate-12" />
        <div className="absolute bottom-10 right-10 w-24 h-24 rounded-full bg-purple-400/30 blur-2xl" />
        <div className="absolute top-1/2 left-2 w-20 h-20 rounded-full border-8 border-purple-400/30" />
      </div>

      <aside className="w-64 m-4 mr-2 rounded-3xl glass flex flex-col">
        <div className="px-6 py-5 border-b border-white/40">
          <h1 className="text-lg font-extrabold text-navy">Monitoring Machine</h1>
          <p className="text-xs text-indigo-500 font-medium">Admin Panel</p>
        </div>
        <nav className="flex-1 px-3 py-4 space-y-1">
          {NAV.map((n) => (
            <NavLink
              key={n.to}
              to={n.to}
              end={n.end}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition ${
                  isActive
                    ? 'bg-gradient-to-r from-brand to-indigo-500 text-white shadow-lg shadow-brand/20'
                    : 'text-navy/70 hover:bg-white/50'
                }`
              }
            >
              <span>{n.icon}</span>
              {n.label}
            </NavLink>
          ))}
        </nav>
        <div className="px-4 py-4 border-t border-white/40">
          <p className="text-xs text-navy/60 mb-2">
            Login: {user?.nama_lengkap || user?.username}
          </p>
          <button
            onClick={handleLogout}
            className="w-full px-3 py-2 rounded-xl bg-white/40 hover:bg-white/60 text-sm font-medium backdrop-blur transition"
          >
            Logout
          </button>
        </div>
      </aside>

      <main className="flex-1 overflow-y-auto p-6">
        <div className="m-2">{children}</div>
      </main>
    </div>
  );
}
