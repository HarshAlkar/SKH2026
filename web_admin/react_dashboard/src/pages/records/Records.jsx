import { useCallback, useEffect, useMemo, useState } from 'react';
import { FileText, AlertTriangle, Activity } from 'lucide-react';
import { adminApi } from '../../services/apiService';
import { useResource } from '../../hooks/useResource';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import StatCard from '../../components/ui/StatCard';
import { DataTable } from '../../components/ui/DataTable';
import { Badge, statusTone } from '../../components/ui/Badge';
import { Modal, Field, inputClass } from '../../components/ui/Modal';
import { toast } from '../../components/ui/Toast';

export default function RecordsPage() {
  const fetchList = useCallback(() => adminApi.records(), []);
  const { rows, loading, error, reload } = useResource(fetchList);
  const [open, setOpen] = useState(false);
  const [patients, setPatients] = useState([]);
  const [form, setForm] = useState({
    patient: '',
    temperature: '',
    blood_pressure: '',
    blood_sugar: '',
    weight: '',
    symptoms: '',
    risk_level: 'normal',
  });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    adminApi.patients().then(setPatients).catch(() => {});
  }, []);

  const stats = useMemo(() => {
    const high = rows.filter((r) => r.risk_level === 'high').length;
    const moderate = rows.filter((r) => r.risk_level === 'moderate').length;
    return { total: rows.length, high, moderate };
  }, [rows]);

  const save = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      await adminApi.createRecord({ ...form, patient: Number(form.patient) });
      toast('Record saved');
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
        title="Health Records"
        subtitle="Vitals captured by ASHA workers and clinics."
        actions={
          <button type="button" className="rounded-lg bg-primary text-white px-4 py-2 text-sm font-semibold" onClick={() => setOpen(true)}>
            + Add Record
          </button>
        }
      />
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <StatCard title="Total Records" value={stats.total} sub="All vitals logged" icon={FileText} color="bg-primary" />
        <StatCard title="High Risk" value={stats.high} sub="Needs follow-up" icon={AlertTriangle} color="bg-rose-500" />
        <StatCard title="Moderate Risk" value={stats.moderate} sub="Monitor closely" icon={Activity} color="bg-accent" />
      </div>
      <ErrorBanner error={error} onRetry={reload} />
      <DataTable
        loading={loading}
        rows={rows}
        empty="No health records."
        columns={[
          { key: 'patient_name', header: 'Patient' },
          { key: 'village', header: 'Village' },
          { key: 'temperature', header: 'Temp' },
          { key: 'blood_pressure', header: 'BP' },
          { key: 'blood_sugar', header: 'Sugar' },
          { key: 'weight', header: 'Weight' },
          {
            key: 'risk_level',
            header: 'Risk',
            render: (r) => <Badge tone={statusTone(r.risk_level)}>{r.risk_level}</Badge>,
          },
          {
            key: 'created_at',
            header: 'When',
            render: (r) => (r.created_at ? new Date(r.created_at).toLocaleString() : '—'),
          },
        ]}
      />
      <Modal open={open} title="Add health record" onClose={() => setOpen(false)}>
        <form onSubmit={save}>
          <Field label="Patient">
            <select className={inputClass} required value={form.patient} onChange={(e) => setForm({ ...form, patient: e.target.value })}>
              <option value="">Select</option>
              {patients.map((p) => (
                <option key={p.id} value={p.id}>{p.name}</option>
              ))}
            </select>
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Temperature">
              <input className={inputClass} value={form.temperature} onChange={(e) => setForm({ ...form, temperature: e.target.value })} />
            </Field>
            <Field label="Blood pressure">
              <input className={inputClass} value={form.blood_pressure} onChange={(e) => setForm({ ...form, blood_pressure: e.target.value })} />
            </Field>
            <Field label="Blood sugar">
              <input className={inputClass} value={form.blood_sugar} onChange={(e) => setForm({ ...form, blood_sugar: e.target.value })} />
            </Field>
            <Field label="Weight">
              <input className={inputClass} value={form.weight} onChange={(e) => setForm({ ...form, weight: e.target.value })} />
            </Field>
          </div>
          <Field label="Risk level">
            <select className={inputClass} value={form.risk_level} onChange={(e) => setForm({ ...form, risk_level: e.target.value })}>
              {['normal', 'moderate', 'high'].map((level) => (
                <option key={level} value={level}>{level}</option>
              ))}
            </select>
          </Field>
          <Field label="Symptoms">
            <textarea className={inputClass} rows={2} value={form.symptoms} onChange={(e) => setForm({ ...form, symptoms: e.target.value })} />
          </Field>
          <button type="submit" disabled={saving} className="w-full rounded-lg bg-primary text-white py-2.5 font-semibold">
            {saving ? 'Saving…' : 'Save'}
          </button>
        </form>
      </Modal>
    </div>
  );
}
