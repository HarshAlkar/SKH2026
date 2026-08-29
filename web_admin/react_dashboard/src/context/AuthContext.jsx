import { createContext, useContext, useEffect, useMemo, useState } from 'react';
import {
  adminApi,
  clearSession,
  getStoredUser,
  getToken,
  persistSession,
  setUnauthorizedHandler,
} from '../services/apiService';
import { getApiBaseUrl, subscribeConnection } from '../services/apiHost';

const AuthContext = createContext(null);
const LAST_API_KEY = 'vr_admin_last_api';

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
    const current = getApiBaseUrl();
    const previous = sessionStorage.getItem(LAST_API_KEY);
    if (previous && previous !== current && getToken()) {
      logout();
    }
    sessionStorage.setItem(LAST_API_KEY, current);
    const unsub = subscribeConnection((snap) => {
      const last = sessionStorage.getItem(LAST_API_KEY);
      if (last && last !== snap.apiBase) {
        logout();
      }
      sessionStorage.setItem(LAST_API_KEY, snap.apiBase);
    });
    setReady(true);
    return unsub;
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
