const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();

const ALLOWED_ORIGINS = (process.env.SIGNALING_ALLOWED_ORIGINS || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

const corsOptions = ALLOWED_ORIGINS.length
  ? { origin: ALLOWED_ORIGINS, credentials: true }
  : { origin: true, credentials: true };

app.use(cors(corsOptions));
app.use(express.json({ limit: '256kb' }));

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: ALLOWED_ORIGINS.length ? ALLOWED_ORIGINS : true,
    methods: ['GET', 'POST']
  },
  transports: ['websocket', 'polling']
});

const consultationHandler = require('./modules/socket_handlers/consultation_socket');

const DJANGO_API_BASE = (process.env.DJANGO_API_BASE || 'https://skh2026.onrender.com/api').replace(/\/$/, '');
const NOTIFY_SECRET = process.env.SIGNALING_NOTIFY_SECRET || '';

async function validateAuthToken(token) {
  if (!token || typeof token !== 'string') return null;
  try {
    const res = await fetch(`${DJANGO_API_BASE}/users/me/`, {
      headers: {
        Accept: 'application/json',
        Authorization: `Token ${token}`,
      },
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) return null;
    return await res.json();
  } catch (_) {
    return null;
  }
}

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'vitalreach-signaling' });
});

/** Django / web apps can POST events — require shared secret in production. */
app.post('/notify', (req, res) => {
  if (NOTIFY_SECRET) {
    const provided = req.headers['x-signaling-secret'] || req.body?.secret;
    if (provided !== NOTIFY_SECRET) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
  }
  const { room, event, payload } = req.body || {};
  const targetRoom = room === 'pharmacy' ? 'pharmacy' : room === 'admin' ? 'admin' : null;
  const eventName = event || 'consultation-updated';
  if (!targetRoom) {
    return res.status(400).json({ error: 'room must be admin or pharmacy' });
  }
  io.to(targetRoom).emit(eventName, {
    ...(payload || {}),
    timestamp: new Date().toISOString()
  });
  if (eventName === 'stock-updated' || targetRoom === 'pharmacy') {
    io.to('pharmacy').emit('stock-updated', {
      ...(payload || {}),
      timestamp: new Date().toISOString()
    });
  }
  return res.json({ ok: true });
});

io.use(async (socket, next) => {
  const token = socket.handshake.auth?.token || socket.handshake.query?.token;
  // Allow health probes without token; require token for app clients when enforced
  const requireAuth = (process.env.SIGNALING_REQUIRE_AUTH || '1') === '1';
  if (!requireAuth) {
    socket.data.user = null;
    return next();
  }
  const user = await validateAuthToken(token);
  if (!user) {
    return next(new Error('Unauthorized'));
  }
  socket.data.user = user;
  socket.data.userId = String(user.id);
  return next();
});

io.on('connection', (socket) => {
  const userId = socket.data.userId || socket.handshake.query.userId;
  console.log('User connected:', socket.id, 'UserId:', userId);

  if (userId) {
    socket.join(`user-${userId}`);
  }

  consultationHandler(io, socket);

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Signaling server running on 0.0.0.0:${PORT}`);
});
