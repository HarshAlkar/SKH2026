const MODE_KEY = 'vr_connection_mode';
const BASE_KEY = 'vr_api_base_url';
const SOCKET_KEY = 'vr_socket_url';
const KIND_KEY = 'vr_connection_kind';

const CLOUD_API = (
  import.meta.env.VITE_CLOUD_API_BASE_URL ||
  import.meta.env.VITE_API_BASE_URL ||
  'https://skh2026.onrender.com/api'
).replace(/\/$/, '');

const CLOUD_SOCKET = (
  import.meta.env.VITE_CLOUD_SOCKET_URL ||
  import.meta.env.VITE_SOCKET_URL ||
  'https://vitalreach-signaling.onrender.com'
).replace(/\/$/, '');

const CHANGE_EVENT = 'vr-connection-change';

function stripSlash(value) {
  return String(value || '').replace(/\/$/, '');
}

function originFromApi(apiBase) {
  return stripSlash(apiBase).replace(/\/api$/i, '');
}

function isCloudHostname(hostname) {
  const h = (hostname || '').toLowerCase();
  return (
    h.includes('onrender.com') ||
    h.includes('railway.app') ||
    h.includes('fly.dev') ||
    h.includes('vercel.app') ||
    h.includes('netlify.app')
  );
}

export function getMode() {
  return localStorage.getItem(MODE_KEY) || 'auto';
}

export function getApiBaseUrl() {
  return stripSlash(localStorage.getItem(BASE_KEY) || CLOUD_API);
}

export function getSocketUrl() {
  return stripSlash(localStorage.getItem(SOCKET_KEY) || CLOUD_SOCKET);
}

export function getConnectionKind() {
  return localStorage.getItem(KIND_KEY) || 'cloud';
}

export function getConnectionSnapshot() {
  return {
    mode: getMode(),
    kind: getConnectionKind(),
    apiBase: getApiBaseUrl(),
    socketUrl: getSocketUrl(),
  };
}

export function mediaUrl(file) {
  if (!file) return '';
  if (/^https?:\/\//i.test(file)) {
    try {
      const parsed = new URL(file);
      if (['localhost', '127.0.0.1'].includes(parsed.hostname)) {
        const api = getApiBaseUrl();
        if (api.startsWith('/')) return `${parsed.pathname}${parsed.search}`;
        return `${originFromApi(api)}${parsed.pathname}${parsed.search}`;
      }
    } catch {
      return file;
    }
    return file;
  }
  const api = getApiBaseUrl();
  if (api.startsWith('/')) return file.startsWith('/') ? file : `/${file}`;
  const path = file.startsWith('/') ? file : `/${file}`;
  return `${originFromApi(api)}${path}`;
}

function applyConnection({ api, socket, kind }) {
  localStorage.setItem(BASE_KEY, stripSlash(api));
  localStorage.setItem(SOCKET_KEY, stripSlash(socket));
  localStorage.setItem(KIND_KEY, kind);
  window.dispatchEvent(new CustomEvent(CHANGE_EVENT, { detail: getConnectionSnapshot() }));
  return getConnectionSnapshot();
}

function wifiCandidates() {
  const host = window.location.hostname;
  const list = [];
  const seen = new Set();
  const push = (api, socket) => {
    const key = `${api}|${socket}`;
    if (seen.has(key)) return;
    seen.add(key);
    list.push({ api: stripSlash(api), socket: stripSlash(socket) });
  };

  if (import.meta.env.DEV) {
    push(`${window.location.origin}/api`, `http://${host}:5000`);
  }
  if (host && host !== 'localhost' && host !== '127.0.0.1') {
    push(`http://${host}:8000/api`, `http://${host}:5000`);
  }
  push('http://127.0.0.1:8000/api', 'http://127.0.0.1:5000');
  push('http://localhost:8000/api', 'http://localhost:5000');
  return list;
}

async function isReachable(apiBase, timeoutMs = 2200) {
  const origin = originFromApi(apiBase);
  const urls = [`${stripSlash(apiBase)}/health/`, `${origin}/health/`, `${origin}/`];
  for (const url of urls) {
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), timeoutMs);
    try {
      const res = await fetch(url, { signal: ctrl.signal, cache: 'no-store' });
      clearTimeout(timer);
      if (res.ok) return true;
    } catch {
      clearTimeout(timer);
    }
  }
  return false;
}

async function firstReachable(candidates, timeoutMs) {
  const results = await Promise.all(
    candidates.map(async (candidate) => ({
      candidate,
      ok: await isReachable(candidate.api, timeoutMs),
    })),
  );
  return results.find((row) => row.ok)?.candidate || null;
}

export async function resolveConnection({ force = false } = {}) {
  const params = new URLSearchParams(window.location.search);
  const modeParam = (params.get('mode') || '').toLowerCase();
  if (modeParam === 'auto' || modeParam === 'wifi' || modeParam === 'cloud') {
    localStorage.setItem(MODE_KEY, modeParam);
  }

  const mode = getMode();
  if (isCloudHostname(window.location.hostname) && mode === 'auto') {
    return applyConnection({ api: CLOUD_API, socket: CLOUD_SOCKET, kind: 'cloud' });
  }

  if (mode === 'cloud') {
    return applyConnection({ api: CLOUD_API, socket: CLOUD_SOCKET, kind: 'cloud' });
  }

  const wifi = await firstReachable(wifiCandidates(), 2200);
  if (wifi) {
    return applyConnection({ api: wifi.api, socket: wifi.socket, kind: 'wifi' });
  }

  if (mode === 'wifi') {
    const fallback = wifiCandidates()[0];
    return applyConnection({
      api: fallback?.api || 'http://127.0.0.1:8000/api',
      socket: fallback?.socket || 'http://127.0.0.1:5000',
      kind: 'wifi',
    });
  }

  if (!force && localStorage.getItem(BASE_KEY) && getConnectionKind() === 'cloud') {
    return getConnectionSnapshot();
  }

  return applyConnection({ api: CLOUD_API, socket: CLOUD_SOCKET, kind: 'cloud' });
}

export async function setConnectionMode(mode) {
  localStorage.setItem(MODE_KEY, mode);
  return resolveConnection({ force: true });
}

export function subscribeConnection(listener) {
  const handler = (event) => listener(event.detail || getConnectionSnapshot());
  window.addEventListener(CHANGE_EVENT, handler);
  return () => window.removeEventListener(CHANGE_EVENT, handler);
}
