import { useEffect, useState } from 'react';
import { stockApi } from '../services/apiService';
import { DataTable } from '../components/ui/DataTable';
import { PageHeader, ErrorBanner } from '../components/ui/PageHeader';

export default function Suppliers() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [form, setForm] = useState({ name: '', contact: '', notes: '' });
  const [saving, setSaving] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const data = await stockApi.suppliers();
      setRows(Array.isArray(data) ? data : data.results || []);
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const onCreate = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError('');
    try {
      await stockApi.createSupplier(form);
      setForm({ name: '', contact: '', notes: '' });
      await load();
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <PageHeader title="Suppliers" subtitle="Manage procurement sources" />
      <ErrorBanner error={error} />

      <form onSubmit={onCreate} className="bg-white rounded-2xl border border-slate-100 p-4 mb-4 grid sm:grid-cols-4 gap-3">
        <input
          className="rounded-xl border border-slate-200 px-3 py-2 text-sm"
          placeholder="Supplier name"
          value={form.name}
          onChange={(e) => setForm({ ...form, name: e.target.value })}
          required
        />
        <input
          className="rounded-xl border border-slate-200 px-3 py-2 text-sm"
          placeholder="Contact"
          value={form.contact}
          onChange={(e) => setForm({ ...form, contact: e.target.value })}
        />
        <input
          className="rounded-xl border border-slate-200 px-3 py-2 text-sm"
          placeholder="Notes"
          value={form.notes}
          onChange={(e) => setForm({ ...form, notes: e.target.value })}
        />
        <button type="submit" disabled={saving} className="rounded-xl bg-primary text-white text-sm font-semibold px-4 py-2 disabled:opacity-60">
          {saving ? 'Saving…' : '+ Add Supplier'}
        </button>
      </form>

      <DataTable
        loading={loading}
        rows={rows}
        empty="No suppliers yet"
        columns={[
          { key: 'name', header: 'Name' },
          { key: 'contact', header: 'Contact' },
          { key: 'notes', header: 'Notes' },
          {
            key: 'is_active',
            header: 'Active',
            render: (r) => (r.is_active ? 'Yes' : 'No'),
          },
        ]}
      />
    </div>
  );
}
