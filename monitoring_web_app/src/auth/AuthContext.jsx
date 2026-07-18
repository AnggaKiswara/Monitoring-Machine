import { createContext, useContext, useEffect, useState } from 'react';
import {
  clearSession,
  getStoredSession,
  loginRequest,
  saveSession,
} from '../lib/api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [session, setSession] = useState(() => getStoredSession());
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function login(username, password) {
    setLoading(true);
    setError('');
    try {
      const data = await loginRequest(username, password);
      saveSession(data.token, data.user);
      setSession({ token: data.token, user: data.user });
      return true;
    } catch (e) {
      setError(e.message);
      return false;
    } finally {
      setLoading(false);
    }
  }

  function logout() {
    clearSession();
    setSession({ token: '', user: null });
  }

  // cek token masih valid
  useEffect(() => {
    if (!session.token) return;
    // opsional: bisa panggil /auth/me; skip untuk simpel
  }, []);

  const isAdmin = session.user?.role_user === 'admin';

  return (
    <AuthContext.Provider value={{ ...session, isAdmin, loading, error, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
