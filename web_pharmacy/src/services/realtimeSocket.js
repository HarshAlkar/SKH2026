import { io } from 'socket.io-client';
import { getSocketUrl, subscribeConnection } from './apiHost';

let sharedSocket = null;
let refCount = 0;
let joinedRoom = 'pharmacy';

function disconnectSocket() {
  if (sharedSocket) {
    sharedSocket.disconnect();
    sharedSocket = null;
  }
}

function createSocket(room) {
  const socket = io(getSocketUrl(), {
    transports: ['websocket', 'polling'],
    reconnection: true,
    reconnectionAttempts: 99,
    reconnectionDelay: 1500,
  });
  socket.on('connect', () => {
    socket.emit(room === 'admin' ? 'join-admin' : 'join-pharmacy');
  });
  socket.on('connect_error', (err) => {
    console.warn('[realtime] connect_error', err?.message || err);
  });
  return socket;
}

subscribeConnection(() => {
  if (!sharedSocket && refCount === 0) return;
  disconnectSocket();
  if (refCount > 0) {
    sharedSocket = createSocket(joinedRoom);
  }
});

export { getSocketUrl } from './apiHost';

export function acquireRealtimeSocket(room = 'pharmacy') {
  joinedRoom = room;
  if (!sharedSocket) {
    sharedSocket = createSocket(room);
  } else if (sharedSocket.connected) {
    sharedSocket.emit(room === 'admin' ? 'join-admin' : 'join-pharmacy');
  }
  refCount += 1;
  return sharedSocket;
}

export function releaseRealtimeSocket() {
  refCount = Math.max(0, refCount - 1);
  if (refCount === 0) {
    disconnectSocket();
  }
}

export function isRealtimeConnected() {
  return Boolean(sharedSocket?.connected);
}
