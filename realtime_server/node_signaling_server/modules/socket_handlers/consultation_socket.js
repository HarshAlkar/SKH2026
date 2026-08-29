// Last SDP offer + ICE per consultation — late joiners still get a usable handshake.
const lastOffers = new Map();
const lastCandidates = new Map();

function roomName(consultationId) {
  return `consultation-${String(consultationId)}`;
}

function clearRoomState(consultationId) {
  if (consultationId == null) return;
  const id = String(consultationId);
  lastOffers.delete(id);
  lastCandidates.delete(id);
}

function bufferCandidate(id, candidate, senderId) {
  if (!candidate) return;
  const list = lastCandidates.get(id) || [];
  if (list.length < 64) {
    list.push({ candidate, senderId });
    lastCandidates.set(id, list);
  }
}

module.exports = (io, socket) => {
  socket.on('join-consultation', async (consultationId) => {
    const id = String(consultationId);
    const room = roomName(id);
    const alreadyIn = socket.rooms.has(room);
    await socket.join(room);
    console.log(`User ${socket.id} joined consultation ${id}`);

    // Re-join (CallScreen after IncomingCall Accept) must not retrigger offer.
    if (!alreadyIn) {
      socket.to(room).emit('peer-joined', {
        socketId: socket.id
      });

      const members = io.sockets.adapter.rooms.get(room);
      if (members && members.size > 1) {
        socket.emit('peer-joined', {
          socketId: 'existing-peer'
        });
      }
    }

    const buffered = lastOffers.get(id);
    if (buffered) {
      console.log(`Sending buffered offer for room ${id} to ${socket.id}`);
      socket.emit('offer', {
        offer: buffered,
        senderId: 'buffered',
        consultationId: id
      });
    }

    const queuedIce = lastCandidates.get(id) || [];
    for (const item of queuedIce) {
      const candidate = item && item.candidate !== undefined ? item.candidate : item;
      const senderId = item && item.senderId ? item.senderId : 'buffered';
      if (senderId === socket.id) continue;
      socket.emit('ice-candidate', {
        candidate,
        senderId,
        consultationId: id
      });
    }
  });

  socket.on('leave-consultation', (consultationId) => {
    const id = String(consultationId);
    socket.leave(roomName(id));
    const members = io.sockets.adapter.rooms.get(roomName(id));
    if (!members || members.size === 0) {
      clearRoomState(id);
    }
  });

  socket.on('join-admin', () => {
    socket.join('admin');
    console.log(`Socket ${socket.id} joined admin room`);
  });

  socket.on('join-pharmacy', () => {
    socket.join('pharmacy');
    console.log(`Socket ${socket.id} joined pharmacy room`);
  });

  socket.on('call-request', (data) => {
    const { receiverId, consultationId, callerName, callType, callerUserId } = data;
    clearRoomState(consultationId);
    console.log(`Call request from ${callerName} to ${receiverId} for consultation ${consultationId}`);
    socket.to(`user-${receiverId}`).emit('incoming-call', {
      consultationId,
      callerName,
      callType,
      callerUserId: callerUserId || null,
      senderId: socket.id
    });
    io.to('admin').emit('consultation-updated', {
      type: 'call-request',
      consultationId,
      callerName,
      callType,
      receiverId,
      timestamp: new Date().toISOString()
    });
  });

  socket.on('accept-call', (data) => {
    const { consultationId, receiverId, callerUserId } = data || {};
    const payload = {
      consultationId,
      senderId: socket.id,
      acceptedBy: socket.handshake.query.userId || null
    };
    if (consultationId != null) {
      socket.to(roomName(consultationId)).emit('call-accepted', payload);
    }
    if (callerUserId) {
      socket.to(`user-${callerUserId}`).emit('call-accepted', payload);
    }
    if (receiverId) {
      socket.to(`user-${receiverId}`).emit('call-accepted', payload);
    }
    io.to('admin').emit('consultation-updated', {
      type: 'call-accepted',
      consultationId,
      timestamp: new Date().toISOString()
    });
  });

  socket.on('reject-call', (data) => {
    const { consultationId, receiverId } = data || {};
    clearRoomState(consultationId);
    const payload = {
      consultationId,
      senderId: socket.id
    };
    if (consultationId != null) {
      socket.to(roomName(consultationId)).emit('call-rejected', payload);
    }
    if (receiverId) {
      socket.to(`user-${receiverId}`).emit('call-rejected', payload);
    }
    io.to('admin').emit('consultation-updated', {
      type: 'call-rejected',
      consultationId,
      timestamp: new Date().toISOString()
    });
  });

  socket.on('hangup', (data) => {
    const consultationId = data && data.consultationId;
    clearRoomState(consultationId);
    if (consultationId != null) {
      socket.to(roomName(consultationId)).emit('hangup', {
        consultationId,
        senderId: socket.id
      });
    }
    io.to('admin').emit('consultation-updated', {
      type: 'hangup',
      consultationId,
      timestamp: new Date().toISOString()
    });
  });

  socket.on('request-offer', (data) => {
    const consultationId = data && data.consultationId;
    if (!consultationId) return;
    console.log(`Request-offer for room ${consultationId} from ${socket.id}`);
    socket.to(roomName(consultationId)).emit('request-offer', {
      consultationId,
      senderId: socket.id
    });
  });

  socket.on('offer', (data) => {
    const id = String(data.consultationId);
    const prev = lastOffers.get(id);
    const nextSdp = data.offer && data.offer.sdp;
    const prevSdp = prev && prev.sdp;
    lastOffers.set(id, data.offer);
    // Same SDP resent for a late joiner — keep already-gathered ICE.
    if (nextSdp !== prevSdp) {
      lastCandidates.set(id, []);
    }
    console.log(`Relaying offer for room ${id} from ${socket.id}`);
    socket.to(roomName(id)).emit('offer', {
      offer: data.offer,
      senderId: socket.id,
      consultationId: id
    });
  });

  socket.on('answer', (data) => {
    const id = String(data.consultationId);
    lastOffers.delete(id);
    console.log(`Relaying answer for room ${id} from ${socket.id}`);
    socket.to(roomName(id)).emit('answer', {
      answer: data.answer,
      senderId: socket.id,
      consultationId: id
    });
  });

  socket.on('ice-candidate', (data) => {
    const id = data && data.consultationId != null ? String(data.consultationId) : '';
    if (!id || !data.candidate) return;
    bufferCandidate(id, data.candidate, socket.id);
    socket.to(roomName(id)).emit('ice-candidate', {
      candidate: data.candidate,
      senderId: socket.id,
      consultationId: id
    });
  });

  socket.on('send-message', (data) => {
    io.to(roomName(data.consultationId)).emit('new-message', {
      text: data.text,
      senderId: data.senderId || socket.id,
      timestamp: new Date().toISOString()
    });
  });

  socket.on('fallback-to-chat', (data) => {
    const consultationId = data && data.consultationId;
    if (consultationId == null) return;
    socket.to(roomName(consultationId)).emit('fallback-to-chat', {
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
