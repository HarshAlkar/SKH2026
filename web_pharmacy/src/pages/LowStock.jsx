import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { stockApi } from '../services/apiService';
import { DataTable } from '../components/ui/DataTable';
import { Badge, stockStatusLabel, stockStatusTone } from '../components/ui/Badge';
import { PageHeader, ErrorBanner } from '../components/ui/PageHeader';

export default function LowStock() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    (async () => {
      try {
        setRows(await stockApi.lowStock());
      } catch (e) {
        setError(e.message);
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  return (
    <div>
      <PageHeader title="Low Stock" subtitle="Batches at or below reorder level" />
      <ErrorBanner error={error} />
      <DataTable
        loading={loading}
        rows={rows}
        empty="No low stock items"
        columns={[
          { key: 'medicine_name', header: 'Medicine', render: (r) => (
            <div>
              <p className="font-semibold">{r.medicine_name}</p>
              <p className="text-xs text-muted">{r.batch_no}</p>
            </div>
          ) },
          { key: 'quantity', header: 'Qty' },
          { key: 'reorder_level', header: 'Reorder at' },
          { key: 'status', header: 'Status', render: (r) => <Badge tone={stockStatusTone(r.status)}>{stockStatusLabel(r.status)}</Badge> },
          { key: 'a', header: 'Action', render: (r) => (
            <Link to={`/update-stock?batch=${r.id}`} className="text-primary text-xs font-semibold">Reorder / Update</Link>
          ) },
        ]}
      />
    </div>
  );
}
