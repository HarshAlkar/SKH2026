const assert = require('assert');
const handlerFactory = require('./consultation_socket');

function createMock() {
  const rooms = new Map();
  const sockets = new Map();

  const io = {
    sockets: { adapter: { rooms } },
    to(name) {
      return {
        emit(event, payload) {
          for (const sock of sockets.values()) {
            if (sock.rooms.has(name) && sock.id !== payload.__skip) {
              sock._inbox.push({ event, payload });
            }
          }
        },
      };
    },
  };

  function makeSocket(id) {
    const socket = {
      id,
      rooms: new Set(),
      handshake: { query: { userId: id } },
      _inbox: [],
      _listeners: {},
      on(event, fn) {
        this._listeners[event] = fn;
      },
      emit(event, payload) {
        this._inbox.push({ event, payload });
      },
      to(name) {
        return {
          emit: (event, payload) => {
            for (const sock of sockets.values()) {
              if (sock.id !== id && sock.rooms.has(name)) {
                sock._inbox.push({ event, payload });
              }
            }
          },
        };
      },
      async join(name) {
        this.rooms.add(name);
        if (!rooms.has(name)) rooms.set(name, new Set());
        rooms.get(name).add(id);
      },
      leave(name) {
        this.rooms.delete(name);
        rooms.get(name)?.delete(id);
      },
    };
    sockets.set(id, socket);
    handlerFactory(io, socket);
    return socket;
  }

  return { makeSocket };
}

(async () => {
  const { makeSocket } = createMock();
  const caller = makeSocket('caller');
  const callee = makeSocket('callee');

  await caller._listeners['join-consultation']('42');
  await callee._listeners['join-consultation']('42');

  const callerPeer = caller._inbox.filter((m) => m.event === 'peer-joined');
  assert.strictEqual(callerPeer.length, 1, 'caller gets peer-joined once');

  callee._inbox = [];
  await callee._listeners['join-consultation']('42');
  const extraPeer = callee._inbox.filter((m) => m.event === 'peer-joined');
  assert.strictEqual(extraPeer.length, 0, 're-join does not emit peer-joined');

  caller._listeners['offer']({ consultationId: 42, offer: { sdp: 'v=0', type: 'offer' } });
  caller._listeners['ice-candidate']({
    consultationId: 42,
    candidate: { candidate: 'candidate:1', sdpMid: '0', sdpMLineIndex: 0 },
  });

  callee._inbox = [];
  await callee._listeners['join-consultation']('42');
  const offers = callee._inbox.filter((m) => m.event === 'offer');
  const ice = callee._inbox.filter((m) => m.event === 'ice-candidate');
  assert.strictEqual(offers.length, 1, 'late joiner gets buffered offer');
  assert.strictEqual(ice.length, 1, 'late joiner gets buffered ICE');
  assert.strictEqual(ice[0].payload.candidate.candidate, 'candidate:1');

  console.log('consultation_socket tests passed');
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
