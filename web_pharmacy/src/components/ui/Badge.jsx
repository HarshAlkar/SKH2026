export function Badge({ children, tone = 'slate' }) {
  const tones = {
    slate: 'bg-slate-100 text-slate-700',
    blue: 'bg-blue-100 text-blue-700',
    green: 'bg-emerald-100 text-emerald-700',
    amber: 'bg-amber-100 text-amber-800',
    rose: 'bg-rose-100 text-rose-700',
    orange: 'bg-orange-100 text-orange-800',
  };
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold ${tones[tone] || tones.slate}`}>
      {children}
    </span>
  );
}

export function stockStatusTone(status) {
  const map = {
    in_stock: 'blue',
    low_stock: 'amber',
    expiring: 'orange',
    expired: 'rose',
    out_of_stock: 'slate',
  };
  return map[status] || 'slate';
}

export function stockStatusLabel(status) {
  const map = {
    in_stock: 'In Stock',
    low_stock: 'Low Stock',
    expiring: 'Expiring',
    expired: 'Expired',
    out_of_stock: 'Out of Stock',
  };
  return map[status] || status;
}
