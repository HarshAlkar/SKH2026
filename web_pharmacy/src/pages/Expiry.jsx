import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { stockApi } from '../services/apiService';
import { useSync } from '../context/SyncContext';
import { PageHeader, ErrorBanner } from '../components/ui/PageHeader';
import { Badge } from '../components/ui/Badge';
import { DataTable } from '../components/ui/DataTable';

export default function Expiry() {
  const { queueAdjust } = useSync();
  const [data, setData] = useState({ expired: [], within_30_days: [], within_60_days: [] });
  const [error, setError] = useState('');
  const [msg, setMsg] = useState('');

  const load = async () => {
    try {
      setData(await stockApi.expiry());
    } catch (e) {
      setError(e.message);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const dispose = async (batch, action) => {
    setMsg('');
    setError('');
    try {
      const res = await queueAdjust({
        batch_id: batch.id,
        action,
        quantity: batch.quantity,
        reason: action === 'disposal' ? 'Expired Disposal' : 'Return to Supplier',
      });
      setMsg(res.synced ? 'Recorded.' : 'Queued offline.');
      await load();
    } catch (e) {
      setError(e.message);
    }
  };

  return (
    <div>
      <PageHeader title="Expiry Management" subtitle="Monitor expirations and dispose or return batches" />
      <ErrorBanner error={error} />
      {msg ? <div className="mb-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-700 text-sm px-4 py-3">{msg}</div> : null}

      {(data.expired || []).length > 0 ? (
        <div className="mb-4 rounded-2xl border border-rose-200 bg-rose-50 p-4 flex flex-wrap items-center justify-between gap-3">
          <div>
            <p className="font-semibold text-rose-800">{data.expired.length} expired batch(es)</p>
            <p className="text-sm text-rose-700">Review disposal items to keep inventory accurate.</p>
          </div>
        </div>
      ) : null}

      <h2 className="font-semibold text-rose-700 mb-3">Expired</h2>
      <div className="grid md:grid-cols-2 gap-3 mb-8">
        {(data.expired || []).map((b) => (
          <div key={b.id} className="bg-white border border-rose-100 rounded-2xl p-4 shadow-sm">
            <div className="flex justify-between gap-2">
              <div>
                <p className="font-semibold">{b.medicine_name}</p>
                <p className="text-xs text-muted">Batch {b.batch_no}</p>
              </div>
              <Badge tone="rose">Expired</Badge>
            </div>
            <p className="text-sm mt-2 text-rose-600 font-semibold">Expiry: {b.expiry_date}</p>
            <p className="text-sm text-muted">Qty: {b.quantity}</p>
            <div className="flex gap-2 mt-3">
              <button type="button" onClick={() => dispose(b, 'return')} className="text-xs font-semibold px-3 py-1.5 rounded-lg border">Return to Supplier</button>
              <button type="button" onClick={() => dispose(b, 'disposal')} className="text-xs font-semibold px-3 py-1.5 rounded-lg bg-rose-600 text-white">Mark Disposal</button>
            </div>
          </div>
        ))}
        {(data.expired || []).length === 0 ? <p className="text-sm text-muted">No expired items</p> : null}
      </div>

      <h2 className="font-semibold text-orange-700 mb-3">Expiring Within 30 Days</h2>
      <div className="grid md:grid-cols-2 gap-3 mb-8">
        {(data.within_30_days || []).map((b) => (
          <div key={b.id} className="bg-white border border-orange-100 rounded-2xl p-4 shadow-sm">
            <p className="font-semibold">{b.medicine_name}</p>
            <p className="text-xs text-muted">Batch {b.batch_no}</p>
            <p className="text-sm mt-2 text-orange-600 font-semibold">{b.days_to_expiry} days left</p>
            <p className="text-sm text-muted">Qty: {b.quantity}</p>
            <Link to={`/update-stock?batch=${b.id}`} className="inline-block mt-3 text-xs font-semibold px-3 py-1.5 rounded-lg bg-primary text-white">Update Stock</Link>
          </div>
        ))}
        {(data.within_30_days || []).length === 0 ? <p className="text-sm text-muted">None in next 30 days</p> : null}
      </div>

      <h2 className="font-semibold text-emerald-700 mb-3">Expiring Within 60 Days</h2>
      <DataTable
        columns={[
          { key: 'medicine_name', header: 'Medicine Name' },
          { key: 'batch_no', header: 'Batch No.' },
          { key: 'expiry_date', header: 'Expiry Date' },
          { key: 'days_to_expiry', header: 'Days Left', render: (r) => <span className="text-emerald-600 font-semibold">{r.days_to_expiry}</span> },
          { key: 'quantity', header: 'Quantity' },
        ]}
        rows={data.within_60_days || []}
        empty="None in 31–60 day window"
      />
    </div>
  );
}
