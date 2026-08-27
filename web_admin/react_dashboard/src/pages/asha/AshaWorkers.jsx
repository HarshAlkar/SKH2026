import { useCallback, useMemo, useState } from 'react';
import { Users, MapPin, CheckCircle } from 'lucide-react';
import { adminApi } from '../../services/apiService';
import { useResource } from '../../hooks/useResource';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import StatCard from '../../components/ui/StatCard';
import FilterBar, { FilterSelect } from '../../components/ui/FilterBar';
import ProgressBar from '../../components/ui/ProgressBar';
import AvatarInitials from '../../components/ui/AvatarInitials';
import { DataTable } from '../../components/ui/DataTable';
import { Badge } from '../../components/ui/Badge';
import { Modal, Field, inputClass } from '../../components/ui/Modal';
import { toast } from '../../components/ui/Toast';

const empty = {
  name: '',
  phone_number: '',
  password: 'asha123',
  assigned_village: '',
  phc_center: '',
  worker_id: '',
  district: '',
};

export default function AshaPage() {
  const fetchList = useCallback(() => adminApi.ashaWorkers(), []);
  const { rows, loading, error, reload } = useResource(fetchList);
  const [open, setOpen] = useState(false);
  const [edit, setEdit] = useState(null);
  const [form, setForm] = useState(empty);
  const [saving, setSaving] = useState(false);
  const [village, setVillage] = useState('');

  const villages = useMemo(() => [...new Set(rows.map((r) => r.assigned_village).filter(Boolean))], [rows]);
  const filtered = useMemo(
    () => (village ? rows.filter((r) => r.assigned_village === village) : rows),
    [rows, village],
  );
  const activeCount = rows.filter((r) => r.is_active).length;

  const save = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      if (edit) {
        await adminApi.patchAsha(edit.id, {
          full_name: form.name || form.full_name,
          assigned_village: form.assigned_village,
          phc_center: form.phc_center,
          worker_id: form.worker_id,
          district: form.district,
        });
        toast('ASHA worker updated');
      } else {
        await adminApi.createAsha(form);
        toast('ASHA worker created');
      }
      setOpen(false);
      reload();
    } catch (err) {
      toast(err.message, 'error');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <PageHeader
        title="ASHA Workers"
        subtitle="Community health workers and village visit coverage."
        actions={
          <button
            type="button"
            className="rounded-lg bg-primary text-white px-4 py-2 text-sm font-semibold"
            onClick={() => {
              setEdit(null);
              setForm(empty);
              setOpen(true);
            }}
          >
            + Add ASHA
          </button>
        }
      />
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <StatCard title="Total Workers" value={rows.length} sub="Registered ASHA staff" icon={Users} color="bg-primary" />
        <StatCard title="Active" value={activeCount} sub="Currently active" icon={CheckCircle} color="bg-secondary" />
        <StatCard title="Villages Covered" value={villages.length} sub="Assigned villages" icon={MapPin} color="bg-violet-500" />
      </div>
      <FilterBar hideSearch>
        <FilterSelect
          label="Village"
          value={village}
          onChange={setVillage}
          options={[['', 'All villages'], ...villages.map((v) => [v, v])]}
        />
      </FilterBar>
      <ErrorBanner error={error} onRetry={reload} />
      <DataTable
        loading={loading}
        rows={filtered}
        empty="No ASHA workers found."
        columns={[
          {
            key: 'full_name',
            header: 'Worker',
            render: (r) => (
              <div className="flex items-center gap-3">
                <AvatarInitials name={r.full_name} size="sm" />
                <div>
                  <p className="font-medium">{r.full_name}</p>
                  <p className="text-xs text-muted">{r.worker_id || `ASHA-${r.id}`}</p>
                </div>
              </div>
            ),
          },
          { key: 'phone_number', header: 'Phone' },
          { key: 'assigned_village', header: 'Village' },
          { key: 'phc_center', header: 'PHC' },
          {
            key: 'visits',
            header: 'Visit progress',
            render: (r) => {
              const done = r.visits_completed || 0;
              const target = r.visits_target || 10;
              const pct = Math.min(100, Math.round((done / target) * 100));
              return <ProgressBar value={pct} label={`${done}/${target} visits`} />;
            },
          },
          {
            key: 'is_active',
            header: 'Status',
            render: (r) => <Badge tone={r.is_active ? 'green' : 'rose'}>{r.is_active ? 'Active' : 'Inactive'}</Badge>,
          },
          {
            key: 'a',
            header: '',
            render: (r) => (
              <button
                type="button"
                className="text-primary text-xs font-semibold"
                onClick={() => {
                  setEdit(r);
                  setForm({ ...empty, ...r, name: r.full_name });
                  setOpen(true);
                }}
              >
                Edit
              </button>
            ),
          },
        ]}
      />
      <Modal open={open} title={edit ? 'Edit ASHA' : 'Add ASHA'} onClose={() => setOpen(false)}>
        <form onSubmit={save}>
          <Field label="Full name">
            <input className={inputClass} required value={form.name || form.full_name || ''} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          </Field>
          {!edit ? (
            <>
              <Field label="Phone">
                <input className={inputClass} required value={form.phone_number} onChange={(e) => setForm({ ...form, phone_number: e.target.value })} />
              </Field>
              <Field label="Password">
                <input className={inputClass} value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} />
              </Field>
            </>
          ) : null}
          <Field label="Assigned village">
            <input className={inputClass} required value={form.assigned_village || ''} onChange={(e) => setForm({ ...form, assigned_village: e.target.value })} />
          </Field>
          <Field label="PHC center">
            <input className={inputClass} value={form.phc_center || ''} onChange={(e) => setForm({ ...form, phc_center: e.target.value })} />
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Worker ID">
              <input className={inputClass} value={form.worker_id || ''} onChange={(e) => setForm({ ...form, worker_id: e.target.value })} />
            </Field>
            <Field label="District">
              <input className={inputClass} value={form.district || ''} onChange={(e) => setForm({ ...form, district: e.target.value })} />
            </Field>
          </div>
          <button type="submit" disabled={saving} className="w-full rounded-lg bg-primary text-white py-2.5 font-semibold">
            {saving ? 'Saving…' : 'Save'}
          </button>
        </form>
      </Modal>
    </div>
  );
}
