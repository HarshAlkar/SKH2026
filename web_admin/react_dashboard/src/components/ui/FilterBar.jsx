import { Search } from 'lucide-react';

export default function FilterBar({ search, onSearchChange, searchPlaceholder = 'Search...', children, hideSearch = false }) {
  return (
    <div className="flex flex-col sm:flex-row gap-3 mb-4">
      {!hideSearch ? (
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={16} />
          <input
            type="search"
            value={search}
            onChange={(e) => onSearchChange?.(e.target.value)}
            placeholder={searchPlaceholder}
            className="w-full pl-9 pr-3 py-2 rounded-xl border border-slate-200 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-light"
          />
        </div>
      ) : null}
      {children ? <div className="flex flex-wrap gap-2">{children}</div> : null}
    </div>
  );
}

export function FilterSelect({ label, value, onChange, options }) {
  return (
    <label className="flex items-center gap-2 text-xs font-medium text-muted">
      {label ? <span>{label}</span> : null}
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="rounded-lg border border-slate-200 px-2 py-1.5 text-sm text-ink bg-white"
      >
        {options.map(([v, t]) => (
          <option key={v} value={v}>{t}</option>
        ))}
      </select>
    </label>
  );
}
