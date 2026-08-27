import { useCallback, useEffect, useMemo, useState } from 'react';
import { Pill, CheckCircle, Clock } from 'lucide-react';
import { adminApi } from '../../services/apiService';
import { useResource } from '../../hooks/useResource';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import StatCard from '../../components/ui/StatCard';
import { DataTable } from '../../components/ui/DataTable';
import { Badge } from '../../components/ui/Badge';
import { Modal, Field, inputClass } from '../../components/ui/Modal';
import { toast } from '../../components/ui/Toast';

export default function MedicinesPage() {
  const fetchList = useCallback(() => adminApi.medicines(), []);
  const { rows, loading, error, reload } = useResource(fetchList);
  const [open, setOpen] = useState(false);
  const [patients, setPatients] = useState([]);
  const [form, setForm] = useState({
    patient: '',
    medicine_name: '',
    dosage: '',
    frequency: 'Daily',
    start_date: new Date().toISOString().slice(0, 10),
    end_date: new Date().toISOString().slice(0, 10),
    reminder_time: '09:00',
    instructions: '',
  });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    adminApi.patients().then(setPatients).catch(() => {});
  }, []);

  const stats = useMemo(() => {
    const taken = rows.filter((r) => r.is_taken).length;
    const pending = rows.length - taken;
    return { total: rows.length, taken, pending };
  }, [rows]);

  const save = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      await adminApi.createMedicine({ ...form, patient: Number(form.patient) });
      toast('Schedule saved');
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
        title="Medicine Schedules"
        subtitle="Track medicine schedules and reminders for village patients."
        actions={
          <button type="button" className="rounded-lg bg-primary text-white px-4 py-2 text-sm font-semibold" onClick={() => setOpen(true)}>
            + Add Schedule
          </button>
        }
      />
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <StatCard title="Total Schedules" value={stats.total} sub="Active medicine plans" icon={Pill} color="bg-primary" />
        <StatCard title="Taken Today" value={stats.taken} sub="Marked as taken" icon={CheckCircle} color="bg-secondary" />
        <StatCard title="Pending" value={stats.pending} sub="Awaiting intake" icon={Clock} color="bg-accent" />
      </div>
      <ErrorBanner error={error} onRetry={reload} />
      <DataTable
        loading={loading}
        rows={rows}
        empty="No medicine schedules."
        columns={[
          { key: 'patient_name', header: 'Patient' },
          { key: 'medicine_name', header: 'Medicine' },
          { key: 'dosage', header: 'Dosage' },
          { key: 'frequency', header: 'Frequency' },
          { key: 'start_date', header: 'Start' },
          { key: 'end_date', header: 'End' },
          { key: 'reminder_time', header: 'Reminder' },
          {
            key: 'is_taken',
            header: 'Status',
            render: (r) => <Badge tone={r.is_taken ? 'green' : 'amber'}>{r.is_taken ? 'Taken' : 'Pending'}</Badge>,
          },
        ]}
      />
      <Modal open={open} title="Add medicine schedule" onClose={() => setOpen(false)}>
        <form onSubmit={save}>
          <Field label="Patient">
            <select className={inputClass} required value={form.patient} onChange={(e) => setForm({ ...form, patient: e.target.value })}>
              <option value="">Select</option>
              {patients.map((p) => (
                <option key={p.id} value={p.id}>{p.name}</option>
              ))}
            </select>
          </Field>
          <Field label="Medicine">
            <input className={inputClass} required value={form.medicine_name} onChange={(e) => setForm({ ...form, medicine_name: e.target.value })} />
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Dosage">
              <input className={inputClass} required value={form.dosage} onChange={(e) => setForm({ ...form, dosage: e.target.value })} />
            </Field>
            <Field label="Frequency">
              <input className={inputClass} value={form.frequency} onChange={(e) => setForm({ ...form, frequency: e.target.value })} />
            </Field>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Start date">
              <input type="date" className={inputClass} value={form.start_date} onChange={(e) => setForm({ ...form, start_date: e.target.value })} />
            </Field>
            <Field label="End date">
              <input type="date" className={inputClass} value={form.end_date} onChange={(e) => setForm({ ...form, end_date: e.target.value })} />
            </Field>
          </div>
          <Field label="Reminder time">
            <input type="time" className={inputClass} value={form.reminder_time} onChange={(e) => setForm({ ...form, reminder_time: e.target.value })} />
          </Field>
          <Field label="Instructions">
            <textarea className={inputClass} rows={2} value={form.instructions} onChange={(e) => setForm({ ...form, instructions: e.target.value })} />
          </Field>
          <button type="submit" disabled={saving} className="w-full rounded-lg bg-primary text-white py-2.5 font-semibold">
            {saving ? 'Saving…' : 'Save'}
          </button>
        </form>
      </Modal>
    </div>
  );
}
