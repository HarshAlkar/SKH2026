import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { stockApi } from '../services/apiService';
import { enqueueAdjustment, listPending, pendingCount, removePending, bumpRetry } from '../services/offlineStore';
import { useAuth } from './AuthContext';

const SyncContext = createContext(null);

function uuid() {
  if (crypto?.randomUUID) return crypto.randomUUID();
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

export function SyncProvider({ children }) {
  const { isAuthed } = useAuth();
  const [online, setOnline] = useState(typeof navigator !== 'undefined' ? navigator.onLine : true);
  const [pending, setPending] = useState(0);
  const [syncing, setSyncing] = useState(false);
  const [lastError, setLastError] = useState(null);

  const refreshPending = useCallback(async () => {
    setPending(await pendingCount());
  }, []);

  const flush = useCallback(async () => {
    if (!isAuthed || !navigator.onLine) return;
    const items = await listPending();
    if (!items.length) {
      setPending(0);
      return;
    }
    setSyncing(true);
    setLastError(null);
    try {
      const payload = items.map(({ queued_at, retries, ...rest }) => rest);
      const res = await stockApi.sync(payload);
      for (const row of res.results || []) {
        if (row.ok && row.client_id) {
          await removePending(row.client_id);
        } else if (row.client_id) {
          await bumpRetry(row.client_id);
        }
      }
    } catch (e) {
      setLastError(e.message);
    } finally {
      setSyncing(false);
      await refreshPending();
    }
  }, [isAuthed, refreshPending]);

  const queueAdjust = useCallback(
    async (body) => {
      const client_id = body.client_id || uuid();
      const item = { ...body, client_id };
      await enqueueAdjustment(item);
      await refreshPending();
      if (navigator.onLine) {
        try {
          const res = await stockApi.adjust(item);
          await removePending(client_id);
          await refreshPending();
          return { synced: true, ...res };
        } catch {
          // stay queued
          return { synced: false, queued: true, client_id };
        }
      }
      return { synced: false, queued: true, client_id };
    },
    [refreshPending],
  );

  useEffect(() => {
    const on = () => {
      setOnline(true);
      flush();
    };
    const off = () => setOnline(false);
    window.addEventListener('online', on);
    window.addEventListener('offline', off);
    refreshPending();
    return () => {
      window.removeEventListener('online', on);
      window.removeEventListener('offline', off);
    };
  }, [flush, refreshPending]);

  useEffect(() => {
    if (isAuthed && online) flush();
  }, [isAuthed, online, flush]);

  const value = useMemo(
    () => ({
      online,
      pending,
      syncing,
      lastError,
      flush,
      queueAdjust,
      refreshPending,
      uuid,
    }),
    [online, pending, syncing, lastError, flush, queueAdjust, refreshPending],
  );

  return <SyncContext.Provider value={value}>{children}</SyncContext.Provider>;
}

export function useSync() {
  return useContext(SyncContext);
}
