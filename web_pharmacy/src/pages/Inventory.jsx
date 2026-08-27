import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { Pill, AlertTriangle, CalendarClock, PackageX } from 'lucide-react';
import { stockApi } from '../services/apiService';
import StatCard from '../components/ui/StatCard';
import { DataTable } from '../components/ui/DataTable';
import { Badge, stockStatusLabel, stockStatusTone } from '../components/ui/Badge';
import { PageHeader, ErrorBanner } from '../components/ui/PageHeader';

export default function Inventory() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [q, setQ] = useState('');
  const [status, setStatus] = useState('');
  const [category, setCategory] = useState('');

  const load = async () => {
    setLoading(true);
    setError('');
    try {
      const data = await stockApi.batches({
        q: q || undefined,
        status: status || undefined,
        category: category || undefined,
      });
      setRows(Array.isArray(data) ? data : data.results || []);
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const stats = useMemo(() => {
    const low = rows.filter((r) => r.status === 'low_stock').length;
    const exp = rows.filter((r) => r.status === 'expiring').length;
    const out = rows.filter((r) => r.status === 'out_of_stock').length;
    return { total: rows.length, low, exp, out };
  }, [rows]);

  const categories = useMemo(
    () => [...new Set(rows.map((r) => r.category).filter(Boolean))],
    [rows],
  );

  const columns = [
    {
      key: 'medicine',
      header: 'Name & ID',
      render: (r) => (
        <div>
          <p className="font-semibold">{r.medicine_name}</p>
          <p className="text-xs text-muted">{r.sku} · {r.batch_no}</p>
        </div>
      ),
    },
    { key: 'category', header: 'Category' },
    {
      key: 'quantity',
      header: 'Quantity',
      render: (r) => (
        <span>
          {r.quantity} <span className="text-muted text-xs">{r.unit}</span>
        </span>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (r) => <Badge tone={stockStatusTone(r.status)}>{stockStatusLabel(r.status)}</Badge>,
    },
    {
      key: 'expiry_date',
      header: 'Expiry Date',
      render: (r) => (
        <span className={r.days_to_expiry < 0 || r.days_to_expiry <= 30 ? 'text-rose-600 font-semibold' : ''}>
          {r.expiry_date}
        </span>
      ),
    },
    {
      key: 'actions',
      header: 'Actions',
      render: (r) => (
        <Link to={`/update-stock?batch=${r.id}`} className="text-primary text-xs font-semibold">
          Update
        </Link>
      ),
    },
  ];

  return (
    <div>
      <PageHeader
        title="Inventory"
        subtitle="Browse and filter medicine batches at your facility"
        actions={
          <Link to="/update-stock?add=1" className="rounded-xl bg-primary text-white px-4 py-2 text-sm font-semibold">
            + Add Medicine
          </Link>
        }
      />
      <ErrorBanner error={error} />

      <div className="grid sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
        <StatCard title="Total Medicines" value={stats.total} icon={Pill} />
        <StatCard title="Low Stock" value={stats.low} icon={AlertTriangle} color="bg-accent" />
        <StatCard title="Expiring Soon" value={stats.exp} icon={CalendarClock} color="bg-orange-500" />
        <StatCard title="Out of Stock" value={stats.out} icon={PackageX} color="bg-slate-500" />
      </div>

      <div className="flex flex-wrap gap-2 mb-4">
        <input
          className="rounded-xl border border-slate-200 px-3 py-2 text-sm min-w-[200px] flex-1"
          placeholder="Search by name or ID…"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
        <select className="rounded-xl border border-slate-200 px-3 py-2 text-sm" value={category} onChange={(e) => setCategory(e.target.value)}>
          <option value="">All Categories</option>
          {categories.map((c) => (
            <option key={c} value={c}>{c}</option>
          ))}
        </select>
        <select className="rounded-xl border border-slate-200 px-3 py-2 text-sm" value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="">All Statuses</option>
          <option value="in_stock">In Stock</option>
          <option value="low_stock">Low Stock</option>
          <option value="expiring">Expiring</option>
          <option value="out_of_stock">Out of Stock</option>
          <option value="expired">Expired</option>
        </select>
        <button type="button" onClick={load} className="rounded-xl bg-slate-900 text-white px-4 py-2 text-sm font-semibold">
          Filter
        </button>
      </div>

      <DataTable columns={columns} rows={rows} loading={loading} empty="No inventory found" />
    </div>
  );
}
