module.exports = (io, socket) => {
  // Join a consultation room
  socket.on('join-consultation', (consultationId) => {
    socket.join(`consultation-${consultationId}`);
    console.log(`User ${socket.id} joined consultation ${consultationId}`);
    
    // Notify others in room that a peer has joined
    socket.to(`consultation-${consultationId}`).emit('peer-joined', {
      socketId: socket.id
    });

    // If there's already another peer in the room, notify the joiner too
    const room = io.sockets.adapter.rooms.get(`consultation-${consultationId}`);
    if (room && room.size > 1) {
      console.log(`Room ${consultationId} now has ${room.size} members. Notifying joiner of existing peer.`);
      // We don't need the actual ID of the other person, just a trigger
      socket.emit('peer-joined', {
        socketId: 'existing-peer'
      });
    }
  });

  // Notify a specific user of an incoming call
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

  // WebRTC Signaling: Offer
  socket.on('offer', (data) => {
    console.log(`Relaying offer for room ${data.consultationId} from ${socket.id}`);
    socket.to(`consultation-${data.consultationId}`).emit('offer', {
      offer: data.offer,
      senderId: socket.id
    });
  });

  // WebRTC Signaling: Answer
  socket.on('answer', (data) => {
    console.log(`Relaying answer for room ${data.consultationId} from ${socket.id}`);
    socket.to(`consultation-${data.consultationId}`).emit('answer', {
      answer: data.answer,
      senderId: socket.id
    });
  });

  // WebRTC Signaling: ICE Candidate
  socket.on('ice-candidate', (data) => {
    socket.to(`consultation-${data.consultationId}`).emit('ice-candidate', {
      candidate: data.candidate,
      senderId: socket.id
    });
  });

  // Chat messaging
  socket.on('send-message', (data) => {
    io.to(`consultation-${data.consultationId}`).emit('new-message', {
      text: data.text,
      senderId: socket.id,
      timestamp: new Date().toISOString()
    });
  });
};
