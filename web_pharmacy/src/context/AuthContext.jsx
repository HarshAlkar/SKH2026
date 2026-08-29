import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { getStoredUser, getToken, persistSession, clearSession, setUnauthorizedHandler, stockApi } from '../services/apiService';
import { getApiBaseUrl, subscribeConnection } from '../services/apiHost';

const AuthContext = createContext(null);
const LAST_API_KEY = 'vr_pharmacy_last_api';
const ALLOWED_ROLES = ['medical_staff', 'asha_worker'];

export function AuthProvider({ children }) {
  const [user, setUser] = useState(getStoredUser);
  const [token, setToken] = useState(getToken);
  const [ready, setReady] = useState(false);

  const logout = useCallback(() => {
    clearSession();
    setToken(null);
    setUser(null);
  }, []);

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
  }, [logout]);

  const login = useCallback(async (identifier, password, role) => {
    const data = await stockApi.login({
      username: identifier,
      phone_number: identifier,
      password,
      role,
    });
    if (!ALLOWED_ROLES.includes(data.user?.role)) {
      throw new Error('Only Medical Staff or ASHA Worker can use the pharmacy portal.');
    }
    persistSession(data.token, data.user);
    setToken(data.token);
    setUser(data.user);
    return data.user;
  }, []);

  const value = useMemo(
    () => ({
      user,
      token,
      ready,
      isAuthed: Boolean(token && user && ALLOWED_ROLES.includes(user.role)),
      login,
      logout,
    }),
    [user, token, ready, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  return useContext(AuthContext);
}
