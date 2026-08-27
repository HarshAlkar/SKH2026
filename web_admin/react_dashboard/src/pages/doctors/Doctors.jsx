import { useCallback, useMemo, useState } from 'react';
import { Stethoscope, UserCheck, Users } from 'lucide-react';
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
  password: 'doctor123',
  specialization: 'General',
  hospital_name: '',
  experience_years: 1,
  qualification: '',
  license_number: '',
  is_available: true,
};

export default function DoctorsPage() {
  const fetchList = useCallback(() => adminApi.doctors(), []);
  const { rows, loading, error, reload } = useResource(fetchList);
  const [open, setOpen] = useState(false);
  const [edit, setEdit] = useState(null);
  const [form, setForm] = useState(empty);
  const [saving, setSaving] = useState(false);
  const [spec, setSpec] = useState('');

  const specs = useMemo(() => [...new Set(rows.map((r) => r.specialization).filter(Boolean))], [rows]);
  const filtered = useMemo(
    () => (spec ? rows.filter((r) => r.specialization === spec) : rows),
    [rows, spec],
  );
  const activeCount = rows.filter((r) => r.is_available).length;

  const save = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      if (edit) {
        await adminApi.patchDoctor(edit.id, {
          full_name: form.name || form.full_name,
          specialization: form.specialization,
          hospital_name: form.hospital_name,
          experience_years: Number(form.experience_years) || 0,
          qualification: form.qualification,
          license_number: form.license_number,
          is_available: form.is_available,
        });
        toast('Doctor updated');
      } else {
        await adminApi.createDoctor(form);
        toast('Doctor created');
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
        title="Doctor Management"
        subtitle="Registered doctors, availability, and consultation load."
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
            + Add Doctor
          </button>
        }
      />
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <StatCard title="Total Doctors" value={rows.length} sub="Registered on VitalReach" icon={Stethoscope} color="bg-primary" />
        <StatCard title="Available Now" value={activeCount} sub="Ready for consults" icon={UserCheck} color="bg-secondary" />
        <StatCard title="Specializations" value={specs.length} sub="Unique fields" icon={Users} color="bg-violet-500" />
      </div>
      <FilterBar hideSearch>
        <FilterSelect
          label="Specialization"
          value={spec}
          onChange={setSpec}
          options={[['', 'All specializations'], ...specs.map((s) => [s, s])]}
        />
      </FilterBar>
      <ErrorBanner error={error} onRetry={reload} />
      <DataTable
        loading={loading}
        rows={filtered}
        empty="No doctors found."
        columns={[
          {
            key: 'full_name',
            header: 'Doctor',
            render: (r) => (
              <div className="flex items-center gap-3">
                <AvatarInitials name={r.full_name} size="sm" />
                <div>
                  <p className="font-medium">{r.full_name}</p>
                  <p className="text-xs text-muted">{r.specialization}</p>
                </div>
              </div>
            ),
          },
          { key: 'phone_number', header: 'Phone' },
          { key: 'hospital_name', header: 'Hospital' },
          { key: 'experience_years', header: 'Years' },
          {
            key: 'load',
            header: 'Load',
            render: (r) => {
              const load = Math.min(100, (r.consultation_count || 0) * 10);
              return <ProgressBar value={load} label={`${r.consultation_count || 0} consults`} />;
            },
          },
          {
            key: 'is_available',
            header: 'Status',
            render: (r) => <Badge tone={r.is_available ? 'green' : 'slate'}>{r.is_available ? 'Available' : 'Offline'}</Badge>,
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
      <Modal open={open} title={edit ? 'Edit doctor' : 'Add doctor'} onClose={() => setOpen(false)}>
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
          <Field label="Specialization">
            <input className={inputClass} value={form.specialization} onChange={(e) => setForm({ ...form, specialization: e.target.value })} />
          </Field>
          <Field label="Hospital">
            <input className={inputClass} value={form.hospital_name || ''} onChange={(e) => setForm({ ...form, hospital_name: e.target.value })} />
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Experience (years)">
              <input type="number" className={inputClass} value={form.experience_years} onChange={(e) => setForm({ ...form, experience_years: e.target.value })} />
            </Field>
            <Field label="License">
              <input className={inputClass} value={form.license_number || ''} onChange={(e) => setForm({ ...form, license_number: e.target.value })} />
            </Field>
          </div>
          <Field label="Qualification">
            <input className={inputClass} value={form.qualification || ''} onChange={(e) => setForm({ ...form, qualification: e.target.value })} />
          </Field>
          {edit ? (
            <label className="flex items-center gap-2 mb-4 text-sm">
              <input type="checkbox" checked={!!form.is_available} onChange={(e) => setForm({ ...form, is_available: e.target.checked })} />
              Available for consults
            </label>
          ) : null}
          <button type="submit" disabled={saving} className="w-full rounded-lg bg-primary text-white py-2.5 font-semibold">
            {saving ? 'Saving…' : 'Save'}
          </button>
        </form>
      </Modal>
    </div>
  );
}
