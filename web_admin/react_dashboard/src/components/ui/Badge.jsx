export function Badge({ children, tone = 'slate' }) {
  const tones = {
    slate: 'bg-slate-100 text-slate-700',
    blue: 'bg-blue-100 text-blue-700',
    green: 'bg-emerald-100 text-emerald-700',
    amber: 'bg-amber-100 text-amber-800',
    rose: 'bg-rose-100 text-rose-700',
    violet: 'bg-violet-100 text-violet-700',
  };
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold ${tones[tone] || tones.slate}`}>
      {children}
    </span>
  );
}

export function statusTone(value) {
  const v = String(value || '').toUpperCase();
  if (['COMPLETED', 'ACTIVE', 'SENT', 'ACCEPTED', 'TAKEN', 'TRUE'].includes(v)) return 'green';
  if (['PENDING', 'ONGOING', 'MODERATE'].includes(v)) return 'amber';
  if (['CANCELLED', 'MISSED', 'CRITICAL', 'HIGHRISK', 'HIGH', 'EMERGENCY'].includes(v)) return 'rose';
  if (['LOW', 'NORMAL'].includes(v)) return 'blue';
  return 'slate';
}
