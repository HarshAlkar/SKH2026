import { useCallback, useEffect, useMemo, useState } from 'react';
import { useSearchParams, useLocation } from 'react-router-dom';
import { adminApi } from '../../services/apiService';
import { useResource } from '../../hooks/useResource';
import { useDebounce } from '../../hooks/useDebounce';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import FilterBar, { FilterSelect } from '../../components/ui/FilterBar';
import ExportButton from '../../components/ui/ExportButton';
import AvatarInitials from '../../components/ui/AvatarInitials';
import { DataTable } from '../../components/ui/DataTable';
import { Badge } from '../../components/ui/Badge';
import { Modal, Field, inputClass } from '../../components/ui/Modal';
import { toast } from '../../components/ui/Toast';

const empty = {
  name: '',
  phone_number: '',
  password: 'patient123',
  village: '',
  age: 30,
  gender: 'Not Set',
  blood_group: '',
  medical_history: '',
};

export default function PatientsPage() {
  const [searchParams] = useSearchParams();
  const location = useLocation();
  const [q, setQ] = useState(searchParams.get('q') || '');
  const [village, setVillage] = useState('');
  const debouncedQ = useDebounce(q, 300);
  const fetchList = useCallback(
    () => adminApi.patients({ ...(debouncedQ ? { q: debouncedQ } : {}), ...(village ? { village } : {}) }),
    [debouncedQ, village],
  );
  const { rows, loading, error, reload } = useResource(fetchList);
  const villages = useMemo(() => [...new Set(rows.map((r) => r.village).filter(Boolean))].sort(), [rows]);

  useEffect(() => {
    if (location.state?.openCreate) {
      setEdit(null);
      setForm(empty);
      setOpen(true);
    }
  }, [location.state]);
  const [open, setOpen] = useState(false);
  const [edit, setEdit] = useState(null);
  const [form, setForm] = useState(empty);
  const [saving, setSaving] = useState(false);

  const save = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      if (edit) {
        await adminApi.patchPatient(edit.id, {
          name: form.name,
          village: form.village,
          age: Number(form.age) || 0,
          gender: form.gender,
          blood_group: form.blood_group,
          medical_history: form.medical_history,
          is_active: form.is_active !== false,
        });
        toast('Patient updated');
      } else {
        await adminApi.createPatient(form);
        toast('Patient created');
      }
      setOpen(false);
      setEdit(null);
      reload();
    } catch (err) {
      toast(err.message, 'error');
    } finally {
      setSaving(false);
    }
  };

  const toggle = async (row) => {
    try {
      await adminApi.patchPatient(row.id, { is_active: !row.is_active });
      toast(row.is_active ? 'Deactivated' : 'Activated');
      reload();
    } catch (err) {
      toast(err.message, 'error');
    }
  };

  return (
    <div>
      <PageHeader
        title="Patient Management"
        subtitle="Manage patient records, demographics, and clinical status on VitalReach."
        actions={
          <div className="flex gap-2">
            <ExportButton
              rows={rows}
              filename="vitalreach-patients.csv"
              columns={[
                { key: 'name', header: 'Name' },
                { key: 'phone_number', header: 'Phone' },
                { key: 'village', header: 'Village' },
                { key: 'age', header: 'Age' },
                { key: 'gender', header: 'Gender' },
              ]}
            />
            <button
              type="button"
              className="rounded-lg bg-primary text-white px-4 py-2 text-sm font-semibold"
              onClick={() => {
                setEdit(null);
                setForm(empty);
                setOpen(true);
              }}
            >
              + Add Patient
            </button>
          </div>
        }
      />
      <FilterBar search={q} onSearchChange={setQ} searchPlaceholder="Search by name, phone, village...">
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
        rows={rows}
        empty="No patients found."
        columns={[
          {
            key: 'name',
            header: 'Patient',
            render: (r) => (
              <div className="flex items-center gap-3">
                <AvatarInitials name={r.name} size="sm" />
                <div>
                  <p className="font-medium">{r.name}</p>
                  <p className="text-xs text-muted">PT-{r.id}</p>
                </div>
              </div>
            ),
          },
          { key: 'phone_number', header: 'Phone' },
          { key: 'village', header: 'Village' },
          { key: 'age', header: 'Age' },
          { key: 'gender', header: 'Gender' },
          {
            key: 'is_active',
            header: 'Status',
            render: (r) => <Badge tone={r.is_active ? 'green' : 'rose'}>{r.is_active ? 'Active' : 'Inactive'}</Badge>,
          },
          {
            key: 'actions',
            header: '',
            render: (r) => (
              <div className="flex gap-2 justify-end">
                <button
                  type="button"
                  className="text-primary text-xs font-semibold"
                  onClick={() => {
                    setEdit(r);
                    setForm({ ...empty, ...r, is_active: r.is_active });
                    setOpen(true);
                  }}
                >
                  Edit
                </button>
                <button type="button" className="text-xs font-semibold text-muted" onClick={() => toggle(r)}>
                  {r.is_active ? 'Deactivate' : 'Activate'}
                </button>
              </div>
            ),
          },
        ]}
      />
      <Modal open={open} title={edit ? 'Edit patient' : 'Add patient'} onClose={() => setOpen(false)}>
        <form onSubmit={save}>
          <Field label="Full name">
            <input className={inputClass} required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
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
          <Field label="Village">
            <input className={inputClass} required value={form.village || ''} onChange={(e) => setForm({ ...form, village: e.target.value })} />
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Age">
              <input type="number" className={inputClass} value={form.age} onChange={(e) => setForm({ ...form, age: e.target.value })} />
            </Field>
            <Field label="Gender">
              <input className={inputClass} value={form.gender} onChange={(e) => setForm({ ...form, gender: e.target.value })} />
            </Field>
          </div>
          <Field label="Blood group">
            <input className={inputClass} value={form.blood_group || ''} onChange={(e) => setForm({ ...form, blood_group: e.target.value })} />
          </Field>
          <Field label="Medical history">
            <textarea className={inputClass} rows={3} value={form.medical_history || ''} onChange={(e) => setForm({ ...form, medical_history: e.target.value })} />
          </Field>
          <button type="submit" disabled={saving} className="mt-2 w-full rounded-lg bg-primary text-white py-2.5 font-semibold">
            {saving ? 'Saving…' : 'Save'}
          </button>
        </form>
      </Modal>
    </div>
  );
}
