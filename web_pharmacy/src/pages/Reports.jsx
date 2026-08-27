import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Pill, Boxes, AlertTriangle, CalendarClock } from 'lucide-react';
import { stockApi } from '../services/apiService';
import StatCard from '../components/ui/StatCard';
import { PageHeader, ErrorBanner } from '../components/ui/PageHeader';

export default function Reports() {
  const [data, setData] = useState(null);
  const [error, setError] = useState('');

  useEffect(() => {
    (async () => {
      try {
        setData(await stockApi.dashboard());
      } catch (e) {
        setError(e.message);
      }
    })();
  }, []);

  return (
    <div>
      <PageHeader title="Reports" subtitle="Quick snapshot of inventory health" />
      <ErrorBanner error={error} />
      <div className="grid sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
        <StatCard title="Medicines" value={data?.total_medicines} icon={Pill} to="/inventory" />
        <StatCard title="Stock Units" value={data?.stock_units} icon={Boxes} color="bg-secondary" to="/inventory" />
        <StatCard title="Low Stock" value={data?.low_stock} icon={AlertTriangle} color="bg-accent" to="/low-stock" />
        <StatCard title="Expiring Soon" value={data?.expiring_soon} icon={CalendarClock} color="bg-orange-500" to="/expiry" />
      </div>
      <div className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm space-y-2 text-sm">
        <p className="font-semibold">Open detailed views</p>
        <Link className="text-primary font-medium block" to="/history">Stock movement history →</Link>
        <Link className="text-primary font-medium block" to="/expiry">Expiry management →</Link>
        <Link className="text-primary font-medium block" to="/low-stock">Low stock list →</Link>
        <Link className="text-primary font-medium block" to="/map">Facility map →</Link>
      </div>
    </div>
  );
}
