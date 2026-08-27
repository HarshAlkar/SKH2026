import { Link } from 'react-router-dom';

export default function StatCard({ title, value, sub, icon: Icon, color = 'bg-primary', to, danger }) {
  const inner = (
    <div
      className={`p-5 rounded-2xl border shadow-sm flex items-start justify-between h-full ${
        danger ? 'bg-rose-50 border-rose-200' : 'bg-white border-slate-100'
      }`}
    >
      <div>
        <p className={`text-sm font-medium ${danger ? 'text-rose-700' : 'text-muted'}`}>{title}</p>
        <h3 className={`text-2xl font-bold mt-1 ${danger ? 'text-rose-800' : 'text-ink'}`}>{value ?? '—'}</h3>
        {sub ? <p className={`text-xs mt-1 ${danger ? 'text-rose-600' : 'text-muted'}`}>{sub}</p> : null}
      </div>
      {Icon ? (
        <div className={`p-3 rounded-xl text-white shrink-0 ${danger ? 'bg-rose-500' : color}`}>
          <Icon size={22} />
        </div>
      ) : null}
    </div>
  );
  return to ? <Link to={to} className="block">{inner}</Link> : inner;
}
