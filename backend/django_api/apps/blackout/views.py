from django.http import HttpResponse
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from . import service


class BlackoutStatusView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        return Response(service.get_status())


class BlackoutSnapshotView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        return Response(service.snapshot_screenings(reason='api'))


class BlackoutSimulateView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        return Response(service.simulate_blackout())


class BlackoutWipeView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        return Response(service.wipe_primary())


class BlackoutRecoverView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        try:
            return Response(service.recover_from_shadow())
        except Exception as e:
            return Response(
                {'error': str(e), 'phase': 'wiped', 'message': f'Restore failed: {e}'},
                status=500,
            )


def display_page(request):
    """Projector-friendly live board — open on laptop display for judges."""
    html = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>VitalReach — The Blackout</title>
  <style>
    :root { color-scheme: dark; }
    * { box-sizing: border-box; }
    body {
      margin: 0; min-height: 100vh;
      font-family: "Segoe UI", system-ui, sans-serif;
      background: #0b1220; color: #e2e8f0;
      display: flex; flex-direction: column;
    }
    header {
      padding: 1.25rem 2rem;
      border-bottom: 1px solid #1e293b;
      display: flex; justify-content: space-between; align-items: center;
    }
    header h1 { margin: 0; font-size: 1.35rem; letter-spacing: 0.04em; }
    header span { color: #94a3b8; font-size: 0.9rem; }
    main { flex: 1; padding: 2rem; display: grid; gap: 1.5rem;
      grid-template-columns: 1.2fr 1fr; }
    @media (max-width: 900px) { main { grid-template-columns: 1fr; } }
    .card {
      background: #111827; border: 1px solid #1f2937;
      border-radius: 16px; padding: 1.5rem;
    }
    .phase {
      font-size: clamp(1.8rem, 4vw, 3rem);
      font-weight: 800; margin: 0 0 0.5rem;
    }
    .msg { font-size: 1.15rem; color: #cbd5e1; min-height: 2.5rem; }
    .metrics { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; margin-top: 1.5rem; }
    .metric {
      background: #0f172a; border-radius: 12px; padding: 1rem; text-align: center;
    }
    .metric b { display: block; font-size: 2.4rem; font-weight: 800; }
    .metric span { color: #94a3b8; font-size: 0.85rem; text-transform: uppercase; }
    .idle .phase { color: #94a3b8; }
    .ready .phase { color: #38bdf8; }
    .detecting .phase, .wiped .phase { color: #f87171; }
    .restoring .phase { color: #fbbf24; }
    .recovered .phase { color: #4ade80; }
    button {
      margin-top: 1.25rem; width: 100%;
      padding: 1rem 1.25rem; font-size: 1.1rem; font-weight: 700;
      border: none; border-radius: 12px; cursor: pointer;
      background: #dc2626; color: white;
    }
    button:disabled { opacity: 0.6; cursor: wait; }
    button.secondary { background: #1d4ed8; margin-top: 0.75rem; }
    pre {
      margin: 0; height: 320px; overflow: auto;
      font-size: 0.85rem; line-height: 1.45; color: #86efac;
      background: #020617; border-radius: 12px; padding: 1rem;
    }
    .hint { margin-top: 1rem; color: #64748b; font-size: 0.9rem; }
  </style>
</head>
<body>
  <header>
    <h1>THE BLACKOUT — Live Recovery Board</h1>
    <span>VitalReach · primary datastore wipe demo</span>
  </header>
  <main>
    <section class="card" id="board">
      <p class="phase" id="phase">IDLE</p>
      <p class="msg" id="message">Open Django terminal beside this page.</p>
      <div class="metrics">
        <div class="metric"><b id="primary">0</b><span>Primary DB rows</span></div>
        <div class="metric"><b id="shadow">0</b><span>Shadow backup</span></div>
        <div class="metric"><b id="recovered">0</b><span>Recovered</span></div>
      </div>
      <button id="btnWipe" type="button">SIMULATE BLACKOUT (wipe primary)</button>
      <button id="btnSnap" class="secondary" type="button">Refresh shadow snapshot</button>
      <p class="hint">
        Judges: Primary = ScreeningEvent in SQLite. Shadow = JSON dual-write.
        Wipe empties primary; recovery restores from shadow. Watch the Django terminal.
      </p>
    </section>
    <section class="card">
      <h2 style="margin-top:0">Event log</h2>
      <pre id="log">Waiting…</pre>
    </section>
  </main>
  <script>
    const board = document.getElementById('board');
    const phaseEl = document.getElementById('phase');
    const msgEl = document.getElementById('message');
    const primaryEl = document.getElementById('primary');
    const shadowEl = document.getElementById('shadow');
    const recoveredEl = document.getElementById('recovered');
    const logEl = document.getElementById('log');
    const btnWipe = document.getElementById('btnWipe');
    const btnSnap = document.getElementById('btnSnap');

    function paint(s) {
      const phase = (s.phase || 'idle').toLowerCase();
      board.className = 'card ' + phase;
      phaseEl.textContent = (s.phase || 'idle').toUpperCase();
      msgEl.textContent = s.message || '';
      primaryEl.textContent = s.primary_count ?? 0;
      shadowEl.textContent = s.shadow_count ?? 0;
      recoveredEl.textContent = s.recovered ?? 0;
      logEl.textContent = (s.log || []).join('\\n') || 'Waiting…';
      logEl.scrollTop = logEl.scrollHeight;
    }

    async function refresh() {
      try {
        const r = await fetch('/api/blackout/status/');
        paint(await r.json());
      } catch (e) {
        msgEl.textContent = 'Cannot reach API — is Django running?';
      }
    }

    btnWipe.onclick = async () => {
      btnWipe.disabled = true;
      btnWipe.textContent = 'WIPING / RECOVERING…';
      try {
        const r = await fetch('/api/blackout/simulate/', { method: 'POST' });
        paint(await r.json());
      } catch (e) {
        msgEl.textContent = String(e);
      } finally {
        btnWipe.disabled = false;
        btnWipe.textContent = 'SIMULATE BLACKOUT (wipe primary)';
      }
    };

    btnSnap.onclick = async () => {
      btnSnap.disabled = true;
      try {
        const r = await fetch('/api/blackout/snapshot/', { method: 'POST' });
        paint(await r.json());
      } finally {
        btnSnap.disabled = false;
      }
    };

    refresh();
    setInterval(refresh, 1500);
  </script>
</body>
</html>
"""
    return HttpResponse(html)
