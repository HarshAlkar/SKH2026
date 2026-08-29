import { Wifi, Cloud, Loader2 } from 'lucide-react';
import { useEffect, useState } from 'react';
import {
  getConnectionSnapshot,
  setConnectionMode,
  subscribeConnection,
} from '../../services/apiHost';

const MODES = [
  { id: 'auto', label: 'Auto' },
  { id: 'wifi', label: 'Wi-Fi' },
  { id: 'cloud', label: 'Cloud' },
];

export default function ConnectionSwitcher({ variant = 'light' }) {
  const [snap, setSnap] = useState(getConnectionSnapshot);
  const [busy, setBusy] = useState(false);

  useEffect(() => subscribeConnection(setSnap), []);

  const onMode = async (mode) => {
    setBusy(true);
    try {
      setSnap(await setConnectionMode(mode));
    } finally {
      setBusy(false);
    }
  };

  const dark = variant === 'dark';
  const kindLabel = snap.kind === 'wifi' ? 'Wi-Fi server' : 'Cloud';
  const KindIcon = snap.kind === 'wifi' ? Wifi : Cloud;

  return (
    <div className={`rounded-xl border p-3 ${dark ? 'border-white/15 bg-white/5 text-white' : 'border-slate-200 bg-slate-50'}`}>
      <div className="flex items-center justify-between gap-2 mb-2">
        <p className={`text-xs font-semibold ${dark ? 'text-white/80' : 'text-slate-600'}`}>Server</p>
        <span className={`inline-flex items-center gap-1 text-[11px] font-semibold ${snap.kind === 'wifi' ? 'text-emerald-500' : dark ? 'text-sky-300' : 'text-sky-700'}`}>
          {busy ? <Loader2 size={12} className="animate-spin" /> : <KindIcon size={12} />}
          {kindLabel}
        </span>
      </div>
      <div className={`grid grid-cols-3 rounded-lg overflow-hidden border ${dark ? 'border-white/15' : 'border-slate-200'}`}>
        {MODES.map((mode) => {
          const active = snap.mode === mode.id;
          return (
            <button
              key={mode.id}
              type="button"
              disabled={busy}
              onClick={() => onMode(mode.id)}
              className={`text-xs font-semibold py-1.5 ${
                active
                  ? 'bg-primary text-white'
                  : dark
                    ? 'bg-transparent text-white/70 hover:bg-white/10'
                    : 'bg-white text-slate-600 hover:bg-slate-100'
              }`}
            >
              {mode.label}
            </button>
          );
        })}
      </div>
      <p className={`mt-2 text-[11px] truncate ${dark ? 'text-white/50' : 'text-muted'}`} title={snap.apiBase}>
        {snap.apiBase}
      </p>
    </div>
  );
}
