module.exports = (io, socket) => {
  // Join a consultation room
  socket.on('join-consultation', (consultationId) => {
    socket.join(`consultation-${consultationId}`);
    console.log(`User ${socket.id} joined consultation ${consultationId}`);
  });

  // WebRTC Signaling: Offer
  socket.on('offer', (data) => {
    socket.to(`consultation-${data.consultationId}`).emit('offer', {
      offer: data.offer,
      senderId: socket.id
    });
  });

  // WebRTC Signaling: Answer
  socket.on('answer', (data) => {
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
