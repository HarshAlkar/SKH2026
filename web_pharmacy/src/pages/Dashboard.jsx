import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { Pill, Boxes, AlertTriangle, Siren } from 'lucide-react';
import { stockApi } from '../services/apiService';
import StatCard from '../components/ui/StatCard';
import { PageHeader, ErrorBanner } from '../components/ui/PageHeader';

export default function Dashboard() {
  const [data, setData] = useState(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const d = await stockApi.dashboard();
        if (alive) setData(d);
      } catch (e) {
        if (alive) setError(e.message);
      } finally {
        if (alive) setLoading(false);
      }
    })();
    return () => {
      alive = false;
    };
  }, []);

  return (
    <div>
      <PageHeader
        title="Pharmacy Dashboard"
        subtitle="Real-time inventory metrics and urgent stock alerts"
      />
      <ErrorBanner error={error} />

      <div className="grid sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
        <StatCard title="Total Medicines" value={loading ? '…' : data?.total_medicines} sub="Catalog SKUs in stock" icon={Pill} />
        <StatCard title="Stock Units" value={loading ? '…' : data?.stock_units} sub="Stable capacity" icon={Boxes} color="bg-secondary" />
        <StatCard title="Low Stock" value={loading ? '…' : data?.low_stock} sub="Requires reorder soon" icon={AlertTriangle} color="bg-accent" to="/low-stock" />
        <StatCard
          title="Action Required"
          value={loading ? '…' : `${data?.out_of_stock || 0} Out · ${data?.expiring_soon || 0} Expiring`}
          sub="Out of stock & expiring soon"
          icon={Siren}
          danger
          to="/expiry"
        />
      </div>

      <div className="grid xl:grid-cols-3 gap-4">
        <div className="xl:col-span-2 bg-white rounded-2xl border border-slate-100 p-5 shadow-sm">
          <h2 className="font-semibold mb-4">Stock Movement (30 days)</h2>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={data?.movement_chart || []}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis dataKey="date" tick={{ fontSize: 10 }} hide={false} interval={4} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="added" stroke="#2A7DE1" strokeWidth={2} dot={false} name="Added" />
                <Line type="monotone" dataKey="sold" stroke="#3CB371" strokeWidth={2} dot={false} name="Sold" />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm">
          <h2 className="font-semibold mb-4">Urgent Alerts</h2>
          <div className="space-y-3 max-h-80 overflow-y-auto">
            {(data?.urgent_alerts || []).length === 0 ? (
              <p className="text-sm text-muted">No urgent alerts</p>
            ) : (
              data.urgent_alerts.map((a, i) => (
                <div key={`${a.id}-${a.kind}-${i}`} className="rounded-xl border border-slate-100 p-3">
                  <p className="font-semibold text-sm">{a.medicine_name}</p>
                  <p
                    className={`text-xs font-bold mt-1 ${
                      a.kind === 'out_of_stock'
                        ? 'text-rose-600'
                        : a.kind === 'expiring'
                          ? 'text-orange-600'
                          : 'text-amber-600'
                    }`}
                  >
                    {a.label}
                  </p>
                  <Link to="/update-stock" className="text-xs text-primary font-semibold mt-2 inline-block">
                    {a.kind === 'out_of_stock' ? 'Reorder Now' : a.kind === 'expiring' ? 'Review Batch' : 'Create PO'}
                  </Link>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
