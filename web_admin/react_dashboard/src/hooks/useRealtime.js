import { useEffect, useRef, useState } from 'react';
import {
  acquireRealtimeSocket,
  releaseRealtimeSocket,
  getSocketUrl,
  isRealtimeConnected,
} from '../services/realtimeSocket';

/**
 * Subscribe to signaling events and run `onEvent` (usually reload).
 * @param {string[]} events
 * @param {() => void} onEvent
 * @param {'admin'|'pharmacy'} room
 */
export function useRealtime(events = [], onEvent, room = 'admin') {
  const [connected, setConnected] = useState(false);
  const onEventRef = useRef(onEvent);
  onEventRef.current = onEvent;
  const eventsKey = Array.isArray(events) ? events.join('|') : '';

  useEffect(() => {
    const socket = acquireRealtimeSocket(room);
    const sync = () => setConnected(isRealtimeConnected());
    socket.on('connect', sync);
    socket.on('disconnect', sync);
    sync();

    const handler = () => {
      if (typeof onEventRef.current === 'function') onEventRef.current();
    };
    const list = eventsKey ? eventsKey.split('|').filter(Boolean) : [];
    for (const event of list) {
      socket.on(event, handler);
    }

    return () => {
      for (const event of list) {
        socket.off(event, handler);
      }
      socket.off('connect', sync);
      socket.off('disconnect', sync);
      releaseRealtimeSocket();
    };
  }, [room, eventsKey]);

  return { connected, socketUrl: getSocketUrl() };
}
