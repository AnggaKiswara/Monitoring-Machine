import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { Button } from '../components/ui';

export default function Login() {
  const { login, loading, error } = useAuth();
  const navigate = useNavigate();
  const [username, setUsername] = useState('fallah@engineer-mtc');
  const [password, setPassword] = useState('');

  async function handle(e) {
    e.preventDefault();
    const ok = await login(username, password);
    if (ok) navigate('/');
  }

  return (
    <div className="min-h-screen flex items-center justify-center relative overflow-hidden px-4">
      <div className="pointer-events-none fixed inset-0 -z-10">
        <div className="absolute top-16 left-1/4 w-40 h-40 rounded-full bg-indigo-400/30 blur-3xl" />
        <div className="absolute bottom-10 right-1/4 w-52 h-52 rounded-full border-[16px] border-purple-400/25" />
        <div className="absolute top-1/3 right-10 w-32 h-32 rounded-2xl bg-teal-300/30 blur-3xl rotate-12" />
      </div>
      <div className="w-full max-w-md glass p-8">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-extrabold text-navy">Monitoring Machine</h1>
          <p className="text-sm text-indigo-500 mt-1">Login Admin Panel</p>
        </div>
        <form onSubmit={handle}>
          <label className="block mb-4">
            <span className="text-sm font-medium text-navy/70">Username</span>
            <input
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="mt-1 w-full px-3 py-2.5 rounded-xl bg-white/50 border border-white/60 focus:outline-none focus:ring-2 focus:ring-brand/40 backdrop-blur"
            />
          </label>
          <label className="block mb-5">
            <span className="text-sm font-medium text-navy/70">Password</span>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="mt-1 w-full px-3 py-2.5 rounded-xl bg-white/50 border border-white/60 focus:outline-none focus:ring-2 focus:ring-brand/40 backdrop-blur"
            />
          </label>
          {error && <p className="text-sm text-red-600 mb-3">{error}</p>}
          <Button type="submit" disabled={loading} className="w-full">
            {loading ? 'Masuk...' : 'Login'}
          </Button>
        </form>
      </div>
    </div>
  );
}
