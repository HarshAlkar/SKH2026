export default function ProgressBar({ value = 0, max = 100, tone = 'primary', label, color }) {
  const pct = max > 0 ? Math.min(100, Math.round((value / max) * 100)) : Math.min(100, value);
  const bar =
    color ||
    (tone === 'danger' ? 'bg-rose-500' : tone === 'muted' ? 'bg-slate-300' : tone === 'secondary' ? 'bg-secondary' : tone === 'accent' ? 'bg-accent' : 'bg-primary');
  return (
    <div className="w-full">
      {label ? <p className="text-xs text-muted mb-1">{label}</p> : null}
      <div className="w-full h-2 rounded-full bg-slate-100 overflow-hidden">
        <div className={`h-full rounded-full ${bar}`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}
