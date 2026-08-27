import { useCallback, useEffect, useMemo, useState } from 'react';
import { adminApi } from '../../services/apiService';
import { useResource } from '../../hooks/useResource';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import FilterBar, { FilterSelect } from '../../components/ui/FilterBar';
import ExportButton from '../../components/ui/ExportButton';
import { DataTable } from '../../components/ui/DataTable';
import { Badge } from '../../components/ui/Badge';
import { Modal, Field, inputClass } from '../../components/ui/Modal';
import { toast } from '../../components/ui/Toast';

export default function PrescriptionsPage() {
  const fetchList = useCallback(() => adminApi.prescriptions(), []);
  const { rows, loading, error, reload } = useResource(fetchList);
  const [open, setOpen] = useState(false);
  const [patients, setPatients] = useState([]);
  const [doctors, setDoctors] = useState([]);
  const [doctorFilter, setDoctorFilter] = useState('');
  const [form, setForm] = useState({ patient: '', doctor: '', medications: '', dosage_instructions: '', notes: '' });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    adminApi.patients().then(setPatients).catch(() => {});
    adminApi.doctors().then(setDoctors).catch(() => {});
  }, []);

  const filtered = useMemo(
    () => (doctorFilter ? rows.filter((r) => String(r.doctor) === doctorFilter || r.doctor_name === doctors.find((d) => String(d.id) === doctorFilter)?.full_name) : rows),
    [rows, doctorFilter, doctors],
  );

  const save = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      await adminApi.createPrescription({
        patient: Number(form.patient),
        doctor: Number(form.doctor),
        medications: form.medications,
        dosage_instructions: form.dosage_instructions,
        notes: form.notes,
      });
      toast('Prescription saved');
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
        title="Prescriptions"
        subtitle="Issued medicines across all doctors."
        actions={
          <div className="flex gap-2">
            <ExportButton
              rows={filtered}
              filename="vitalreach-prescriptions.csv"
              columns={[
                { key: 'patient_name', header: 'Patient' },
                { key: 'doctor_name', header: 'Doctor' },
                { key: 'medications', header: 'Medications' },
                { key: 'dosage_instructions', header: 'Dosage' },
                { key: 'issued_at', header: 'Issued' },
              ]}
            />
            <button type="button" className="rounded-lg bg-primary text-white px-4 py-2 text-sm font-semibold" onClick={() => setOpen(true)}>
              + Add Prescription
            </button>
          </div>
        }
      />
      <FilterBar hideSearch>
        <FilterSelect
          label="Doctor"
          value={doctorFilter}
          onChange={setDoctorFilter}
          options={[['', 'All doctors'], ...doctors.map((d) => [String(d.id), d.full_name])]}
        />
      </FilterBar>
      <ErrorBanner error={error} onRetry={reload} />
      <DataTable
        loading={loading}
        rows={filtered}
        empty="No prescriptions found."
        columns={[
          { key: 'patient_name', header: 'Patient' },
          { key: 'doctor_name', header: 'Doctor' },
          {
            key: 'medications',
            header: 'Medicines',
            render: (r) => (
              <span className="text-sm line-clamp-2 max-w-xs" title={r.medications}>
                {r.medications?.slice(0, 60)}{r.medications?.length > 60 ? '…' : ''}
              </span>
            ),
          },
          { key: 'dosage_instructions', header: 'Dosage' },
          {
            key: 'issued_at',
            header: 'Issued',
            render: (r) => (r.issued_at ? new Date(r.issued_at).toLocaleString() : '—'),
          },
          {
            key: 'status',
            header: 'Status',
            render: () => <Badge tone="green">Active</Badge>,
          },
        ]}
      />
      <Modal open={open} title="New prescription" onClose={() => setOpen(false)}>
        <form onSubmit={save}>
          <Field label="Patient">
            <select className={inputClass} required value={form.patient} onChange={(e) => setForm({ ...form, patient: e.target.value })}>
              <option value="">Select</option>
              {patients.map((p) => (
                <option key={p.id} value={p.id}>{p.name} · {p.village}</option>
              ))}
            </select>
          </Field>
          <Field label="Doctor">
            <select className={inputClass} required value={form.doctor} onChange={(e) => setForm({ ...form, doctor: e.target.value })}>
              <option value="">Select</option>
              {doctors.map((d) => (
                <option key={d.id} value={d.id}>{d.full_name}</option>
              ))}
            </select>
          </Field>
          <Field label="Medications">
            <textarea className={inputClass} rows={3} required value={form.medications} onChange={(e) => setForm({ ...form, medications: e.target.value })} />
          </Field>
          <Field label="Dosage">
            <input className={inputClass} value={form.dosage_instructions} onChange={(e) => setForm({ ...form, dosage_instructions: e.target.value })} />
          </Field>
          <Field label="Notes">
            <textarea className={inputClass} rows={2} value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} />
          </Field>
          <button type="submit" disabled={saving} className="w-full rounded-lg bg-primary text-white py-2.5 font-semibold">
            {saving ? 'Saving…' : 'Save'}
          </button>
        </form>
      </Modal>
    </div>
  );
}
