import { Link } from 'react-router-dom';

export default function StatCard({ title, value, sub, icon: Icon, color = 'bg-primary', to, badge }) {
  const inner = (
    <div className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm flex items-start justify-between h-full hover:shadow-md transition-shadow">
      <div>
        <p className="text-muted text-sm font-medium">{title}</p>
        <h3 className="text-2xl font-bold mt-1 text-ink">{value ?? '—'}</h3>
        {sub ? <p className="text-xs text-muted mt-1">{sub}</p> : null}
        {badge ? <span className="inline-block mt-2 text-xs font-semibold px-2 py-0.5 rounded-full bg-light text-primary">{badge}</span> : null}
      </div>
      {Icon ? (
        <div className={`p-3 rounded-xl text-white shrink-0 ${color}`}>
          <Icon size={22} />
        </div>
      ) : null}
    </div>
  );
  return to ? <Link to={to} className="block">{inner}</Link> : inner;
}
