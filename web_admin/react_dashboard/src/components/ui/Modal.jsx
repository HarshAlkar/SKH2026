export function Modal({ open, title, onClose, children, wide }) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <button type="button" className="absolute inset-0 bg-slate-900/40" onClick={onClose} aria-label="Close" />
      <div className={`relative bg-white rounded-2xl shadow-xl w-full ${wide ? 'max-w-2xl' : 'max-w-lg'} max-h-[90vh] overflow-y-auto p-6`}>
        <div className="flex items-start justify-between mb-4">
          <h2 className="text-lg font-bold text-ink">{title}</h2>
          <button type="button" onClick={onClose} className="text-muted hover:text-ink text-xl leading-none">
            ×
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

export function Field({ label, children }) {
  return (
    <label className="block mb-3">
      <span className="block text-sm font-medium text-ink mb-1">{label}</span>
      {children}
    </label>
  );
}

export const inputClass =
  'w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-light';
