import { useCallback, useEffect, useRef, useState } from 'react';
import { useRealtime } from './useRealtime';

/**
 * HTTP polling with Socket.IO refresh when events arrive.
 */
export function usePolling(fetchFn, intervalMs = 15000, enabled = true, realtimeEvents = []) {
  const [data, setData] = useState(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const fnRef = useRef(fetchFn);
  fnRef.current = fetchFn;

  const reload = useCallback(async () => {
    setError('');
    try {
      const result = await fnRef.current();
      setData(result);
      return result;
    } catch (e) {
      setError(e.message);
      throw e;
    } finally {
      setLoading(false);
    }
  }, []);

  const onRealtime = useCallback(() => {
    reload().catch(() => {});
  }, [reload]);

  const { connected: realtimeConnected } = useRealtime(
    realtimeEvents.length ? realtimeEvents : ['consultation-updated', 'appointment-updated', 'verification-updated'],
    onRealtime,
    'admin',
  );

  useEffect(() => {
    if (!enabled) return undefined;
    let cancelled = false;
    const tick = async () => {
      try {
        const result = await fnRef.current();
        if (!cancelled) setData(result);
      } catch (e) {
        if (!cancelled) setError(e.message);
      } finally {
        if (!cancelled) setLoading(false);
      }
    };
    tick();
    // Slow polling when socket is live; keep 15s as fallback when offline.
    const ms = realtimeConnected ? Math.max(intervalMs, 30000) : intervalMs;
    const id = setInterval(tick, ms);
    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, [intervalMs, enabled, reload, realtimeConnected]);

  return { data, error, loading, reload, realtimeConnected };
}
