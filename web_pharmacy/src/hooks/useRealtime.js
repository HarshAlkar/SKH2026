import { useEffect, useRef, useState, useCallback } from 'react';
import {
  acquireRealtimeSocket,
  releaseRealtimeSocket,
  getSocketUrl,
  isRealtimeConnected,
} from '../services/realtimeSocket';

export function useRealtime(events = [], onEvent, room = 'pharmacy') {
  const [connected, setConnected] = useState(false);
  const onEventRef = useRef(onEvent);
  onEventRef.current = onEvent;
  const eventsKey = events.join('|');

  useEffect(() => {
    const socket = acquireRealtimeSocket(room);
    const sync = () => setConnected(isRealtimeConnected());
    socket.on('connect', sync);
    socket.on('disconnect', sync);
    sync();

    const handler = () => {
      if (typeof onEventRef.current === 'function') onEventRef.current();
    };
    const list = eventsKey ? eventsKey.split('|') : [];
    for (const event of list) {
      if (event) socket.on(event, handler);
    }

    return () => {
      for (const event of list) {
        if (event) socket.off(event, handler);
      }
      socket.off('connect', sync);
      socket.off('disconnect', sync);
      releaseRealtimeSocket();
    };
  }, [room, eventsKey]);

  return { connected, socketUrl: getSocketUrl() };
}

/** Poll + socket refresh for pharmacy pages. */
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

  const onRealtime = useCallback(() => {
    reload().catch(() => {});
  }, [reload]);

  const { connected: realtimeConnected } = useRealtime(
    ['stock-updated', 'consultation-updated'],
    onRealtime,
    'pharmacy',
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
    const ms = realtimeConnected ? Math.max(intervalMs, 30000) : intervalMs;
    const id = setInterval(tick, ms);
    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, [intervalMs, enabled, realtimeConnected]);

  return { data, error, loading, reload, realtimeConnected, socketUrl: getSocketUrl() };
}
