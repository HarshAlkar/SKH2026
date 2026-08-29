const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  },
  transports: ['websocket', 'polling']
});

const consultationHandler = require('./modules/socket_handlers/consultation_socket');

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'vitalreach-signaling' });
});

/** Django / web apps can POST events to broadcast to admin/pharmacy rooms. */
app.post('/notify', (req, res) => {
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

io.on('connection', (socket) => {
  const userId = socket.handshake.query.userId;
  console.log('User connected:', socket.id, 'UserId:', userId);

  if (userId) {
    socket.join(`user-${userId}`);
    console.log(`Socket ${socket.id} joined room user-${userId}`);
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
