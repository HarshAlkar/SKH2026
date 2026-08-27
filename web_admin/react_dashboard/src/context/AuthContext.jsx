import { createContext, useContext, useEffect, useMemo, useState } from 'react';
import {
  adminApi,
  clearSession,
  getStoredUser,
  getToken,
  persistSession,
  setUnauthorizedHandler,
} from '../services/apiService';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(getStoredUser);
  const [token, setToken] = useState(getToken);
  const [ready, setReady] = useState(false);

  const logout = () => {
    clearSession();
    setUser(null);
    setToken(null);
  };

  useEffect(() => {
    setUnauthorizedHandler(logout);
    setReady(true);
  }, []);

  const login = async (username, password) => {
    const data = await adminApi.login({ username, password });
    persistSession(data.token, data.user);
    setToken(data.token);
    setUser(data.user);
    return data.user;
  };

  const value = useMemo(
    () => ({ user, token, ready, isAuthed: Boolean(token && user?.is_staff), login, logout }),
    [user, token, ready],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
}
