import { useCallback, useEffect, useRef, useState } from 'react';

export function usePolling(fetchFn, intervalMs = 15000, enabled = true) {
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
    const id = setInterval(tick, intervalMs);
    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, [intervalMs, enabled, reload]);

  return { data, error, loading, reload };
}
