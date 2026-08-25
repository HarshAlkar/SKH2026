module.exports = (io, socket) => {
  socket.on('join-consultation', (consultationId) => {
    socket.join(`consultation-${consultationId}`);
    console.log(`User ${socket.id} joined consultation ${consultationId}`);

    socket.to(`consultation-${consultationId}`).emit('peer-joined', {
      socketId: socket.id
    });

    const room = io.sockets.adapter.rooms.get(`consultation-${consultationId}`);
    if (room && room.size > 1) {
      socket.emit('peer-joined', {
        socketId: 'existing-peer'
      });
    }
  });

  socket.on('leave-consultation', (consultationId) => {
    socket.leave(`consultation-${consultationId}`);
  });

  socket.on('call-request', (data) => {
    const { receiverId, consultationId, callerName, callType } = data;
    console.log(`Call request from ${callerName} to ${receiverId} for consultation ${consultationId}`);
    socket.to(`user-${receiverId}`).emit('incoming-call', {
      consultationId,
      callerName,
      callType,
      senderId: socket.id
    });
  });

  socket.on('reject-call', (data) => {
    const { consultationId, receiverId } = data || {};
    const payload = {
      consultationId,
      senderId: socket.id
    };
    socket.to(`consultation-${consultationId}`).emit('call-rejected', payload);
    if (receiverId) {
      socket.to(`user-${receiverId}`).emit('call-rejected', payload);
    }
  });

  socket.on('hangup', (data) => {
    const consultationId = data && data.consultationId;
    socket.to(`consultation-${consultationId}`).emit('hangup', {
      consultationId,
      senderId: socket.id
    });
  });

  socket.on('offer', (data) => {
    console.log(`Relaying offer for room ${data.consultationId} from ${socket.id}`);
    socket.to(`consultation-${data.consultationId}`).emit('offer', {
      offer: data.offer,
      senderId: socket.id
    });
  });

  socket.on('answer', (data) => {
    console.log(`Relaying answer for room ${data.consultationId} from ${socket.id}`);
    socket.to(`consultation-${data.consultationId}`).emit('answer', {
      answer: data.answer,
      senderId: socket.id
    });
  });

  socket.on('ice-candidate', (data) => {
    socket.to(`consultation-${data.consultationId}`).emit('ice-candidate', {
      candidate: data.candidate,
      senderId: socket.id
    });
  });

  socket.on('send-message', (data) => {
    io.to(`consultation-${data.consultationId}`).emit('new-message', {
      text: data.text,
      senderId: data.senderId || socket.id,
      timestamp: new Date().toISOString()
    });
  });

  socket.on('fallback-to-chat', (data) => {
    const consultationId = data && data.consultationId;
    socket.to(`consultation-${consultationId}`).emit('fallback-to-chat', {
      consultationId,
      reason: (data && data.reason) || 'network',
      senderId: socket.id
    });
  });

  socket.on('chat-message', (data) => {
    const payload = data || {};
    const receiverId = payload.receiverId;
    if (!receiverId) return;
    socket.to(`user-${receiverId}`).emit('chat-message', {
      threadId: payload.threadId,
      text: payload.text,
      senderId: payload.senderId || socket.id,
      senderName: payload.senderName || '',
      messageId: payload.messageId,
      timestamp: payload.timestamp || new Date().toISOString()
    });
  });
};
