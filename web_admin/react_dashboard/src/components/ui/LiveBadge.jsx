import { useEffect, useState } from 'react';
import {
  acquireRealtimeSocket,
  releaseRealtimeSocket,
  isRealtimeConnected,
  getSocketUrl,
} from '../../services/realtimeSocket';

export default function LiveBadge({ room = 'admin' }) {
  const [active, setActive] = useState(false);

  useEffect(() => {
    const socket = acquireRealtimeSocket(room);
    const sync = () => setActive(isRealtimeConnected());
    socket.on('connect', sync);
    socket.on('disconnect', sync);
    sync();
    return () => {
      socket.off('connect', sync);
      socket.off('disconnect', sync);
      releaseRealtimeSocket();
    };
  }, [room]);

  return (
    <span
      title={getSocketUrl()}
      className={`inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full ${
        active
          ? 'text-emerald-700 bg-emerald-50'
          : 'text-amber-700 bg-amber-50'
      }`}
    >
      <span
        className={`w-2 h-2 rounded-full ${
          active ? 'bg-emerald-500 animate-pulse' : 'bg-amber-500'
        }`}
      />
      {active ? 'Live updates active' : 'Polling (socket offline)'}
    </span>
  );
}
