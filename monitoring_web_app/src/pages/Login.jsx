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
    <div className="min-h-screen flex items-center justify-center bg-navy px-4">
      <div className="w-full max-w-md bg-white rounded-2xl shadow-xl p-8">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-bold text-navy">Monitoring Machine</h1>
          <p className="text-sm text-gray-500 mt-1">Login Admin Panel</p>
        </div>
        <form onSubmit={handle}>
          <label className="block mb-4">
            <span className="text-sm font-medium text-gray-600">Username</span>
            <input
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="mt-1 w-full px-3 py-2 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-brand/40 focus:border-brand"
            />
          </label>
          <label className="block mb-5">
            <span className="text-sm font-medium text-gray-600">Password</span>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="mt-1 w-full px-3 py-2 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-brand/40 focus:border-brand"
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
