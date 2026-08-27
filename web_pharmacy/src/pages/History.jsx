import { useEffect, useState } from 'react';
import { stockApi } from '../services/apiService';
import { DataTable } from '../components/ui/DataTable';
import { Badge } from '../components/ui/Badge';
import { PageHeader, ErrorBanner } from '../components/ui/PageHeader';

const actionTone = {
  add: 'green',
  remove: 'amber',
  adjust: 'blue',
  disposal: 'rose',
  return: 'orange',
};

export default function History() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [action, setAction] = useState('');

  const load = async () => {
    setLoading(true);
    setError('');
    try {
      const data = await stockApi.history({ action: action || undefined, limit: 200 });
      setRows(Array.isArray(data) ? data : []);
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

  const exportCsv = () => {
    const header = ['Date', 'Medicine', 'Batch', 'Action', 'Qty', 'Previous', 'New', 'Actor', 'Reason'];
    const lines = rows.map((r) =>
      [
        r.created_at,
        r.medicine_name,
        r.batch_no,
        r.action,
        r.quantity,
        r.previous_quantity,
        r.new_quantity,
        r.actor_name || '',
        (r.reason || '').replace(/,/g, ';'),
      ].join(','),
    );
    const blob = new Blob([[header.join(','), ...lines].join('\n')], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'stock-history.csv';
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div>
      <PageHeader
        title="Stock History"
        subtitle="Audit trail of stock movements (Added vs Sold)"
        actions={
          <button type="button" onClick={exportCsv} className="rounded-xl border border-slate-200 px-4 py-2 text-sm font-semibold">
            Export CSV
          </button>
        }
      />
      <ErrorBanner error={error} />

      <div className="flex flex-wrap gap-2 mb-4">
        <select
          className="rounded-xl border border-slate-200 px-3 py-2 text-sm"
          value={action}
          onChange={(e) => setAction(e.target.value)}
        >
          <option value="">All actions</option>
          <option value="add">Add</option>
          <option value="remove">Remove</option>
          <option value="adjust">Adjust</option>
          <option value="disposal">Disposal</option>
          <option value="return">Return</option>
        </select>
        <button type="button" onClick={load} className="rounded-xl bg-slate-900 text-white px-4 py-2 text-sm font-semibold">
          Filter
        </button>
      </div>

      <DataTable
        loading={loading}
        rows={rows}
        empty="No stock movements yet"
        columns={[
          {
            key: 'created_at',
            header: 'When',
            render: (r) => new Date(r.created_at).toLocaleString(),
          },
          {
            key: 'medicine_name',
            header: 'Medicine',
            render: (r) => (
              <div>
                <p className="font-semibold">{r.medicine_name}</p>
                <p className="text-xs text-muted">{r.batch_no}</p>
              </div>
            ),
          },
          {
            key: 'action',
            header: 'Action',
            render: (r) => <Badge tone={actionTone[r.action] || 'slate'}>{r.action}</Badge>,
          },
          { key: 'quantity', header: 'Qty' },
          {
            key: 'delta',
            header: 'Before → After',
            render: (r) => `${r.previous_quantity} → ${r.new_quantity}`,
          },
          { key: 'actor_name', header: 'By' },
          { key: 'reason', header: 'Reason' },
        ]}
      />
    </div>
  );
}
