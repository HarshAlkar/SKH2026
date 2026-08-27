import { useCallback, useEffect, useMemo, useState } from 'react';
import { Calendar, CheckCircle, Clock, MapPin } from 'lucide-react';
import { adminApi } from '../../services/apiService';
import { useResource } from '../../hooks/useResource';
import { useMapMarkers } from '../../hooks/useMapMarkers';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import StatCard from '../../components/ui/StatCard';
import { DataTable } from '../../components/ui/DataTable';
import { Badge } from '../../components/ui/Badge';
import EmergencyMap from '../../components/map/EmergencyMap';
import { Modal, Field, inputClass } from '../../components/ui/Modal';
import { toast } from '../../components/ui/Toast';

export default function VisitsPage() {
  const fetchList = useCallback(() => adminApi.visits(), []);
  const { rows, loading, error, reload } = useResource(fetchList);
  const [view, setView] = useState('list');
  const [open, setOpen] = useState(false);
  const [patients, setPatients] = useState([]);
  const [ashas, setAshas] = useState([]);
  const [form, setForm] = useState({
    asha_worker: '',
    patient: '',
    visit_date: new Date().toISOString().slice(0, 10),
    visit_time: '10:00',
    notes: '',
  });
  const [saving, setSaving] = useState(false);
  const { data: mapData } = useMapMarkers(view === 'map');

  useEffect(() => {
    adminApi.patients().then(setPatients).catch(() => {});
    adminApi.ashaWorkers().then(setAshas).catch(() => {});
  }, []);

  const stats = useMemo(() => ({
    total: rows.length,
    pending: rows.filter((r) => r.status === 'PENDING').length,
    completed: rows.filter((r) => r.status === 'COMPLETED').length,
  }), [rows]);

  const setStatus = async (id, status) => {
    try {
      await adminApi.patchVisit(id, { status });
      toast('Visit updated');
      reload();
    } catch (e) {
      toast(e.message, 'error');
    }
  };

  const save = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      await adminApi.createVisit({
        ...form,
        asha_worker: Number(form.asha_worker),
        patient: Number(form.patient),
      });
      toast('Visit scheduled');
      setOpen(false);
      reload();
    } catch (err) {
      toast(err.message, 'error');
    } finally {
      setSaving(false);
    }
  };

  const statusTone = (s) => {
    if (s === 'COMPLETED') return 'green';
    if (s === 'MISSED') return 'rose';
    return 'amber';
  };

  return (
    <div>
      <PageHeader
        title="Village Visits"
        subtitle="ASHA home visits and follow-ups."
        actions={
          <button type="button" className="rounded-lg bg-primary text-white px-4 py-2 text-sm font-semibold" onClick={() => setOpen(true)}>
            + Schedule Visit
          </button>
        }
      />
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <StatCard title="Scheduled" value={stats.total} sub="All visits" icon={Calendar} color="bg-primary" />
        <StatCard title="Pending" value={stats.pending} sub="Upcoming visits" icon={Clock} color="bg-accent" />
        <StatCard title="Completed" value={stats.completed} sub="Finished visits" icon={CheckCircle} color="bg-secondary" />
      </div>
      <div className="mb-4 flex gap-2">
        {[
          ['list', 'List view'],
          ['map', 'Map view'],
        ].map(([id, label]) => (
          <button
            key={id}
            type="button"
            onClick={() => setView(id)}
            className={`px-3 py-1.5 rounded-full text-xs font-semibold flex items-center gap-1 ${
              view === id ? 'bg-primary text-white' : 'bg-white border border-slate-200 text-muted'
            }`}
          >
            {id === 'map' ? <MapPin size={14} /> : null}
            {label}
          </button>
        ))}
      </div>
      <ErrorBanner error={error} onRetry={reload} />
      {view === 'map' ? (
        <div className="bg-white rounded-2xl border p-4 shadow-sm">
          <EmergencyMap data={mapData} height={420} />
        </div>
      ) : (
        <DataTable
          loading={loading}
          rows={rows}
          empty="No visits scheduled."
          columns={[
            { key: 'patient_name', header: 'Patient' },
            { key: 'asha_name', header: 'ASHA' },
            { key: 'village', header: 'Village' },
            { key: 'visit_date', header: 'Date' },
            { key: 'visit_time', header: 'Time' },
            {
              key: 'status',
              header: 'Status',
              render: (r) => (
                <div className="flex items-center gap-2">
                  <Badge tone={statusTone(r.status)}>{r.status}</Badge>
                  <select
                    className="text-xs border border-slate-200 rounded-lg px-2 py-1"
                    value={r.status}
                    onChange={(e) => setStatus(r.id, e.target.value)}
                  >
                    {['PENDING', 'COMPLETED', 'MISSED'].map((s) => (
                      <option key={s} value={s}>{s}</option>
                    ))}
                  </select>
                </div>
              ),
            },
          ]}
        />
      )}
      <Modal open={open} title="Schedule visit" onClose={() => setOpen(false)}>
        <form onSubmit={save}>
          <Field label="ASHA worker">
            <select className={inputClass} required value={form.asha_worker} onChange={(e) => setForm({ ...form, asha_worker: e.target.value })}>
              <option value="">Select</option>
              {ashas.map((a) => (
                <option key={a.id} value={a.id}>{a.full_name}</option>
              ))}
            </select>
          </Field>
          <Field label="Patient">
            <select className={inputClass} required value={form.patient} onChange={(e) => setForm({ ...form, patient: e.target.value })}>
              <option value="">Select</option>
              {patients.map((p) => (
                <option key={p.id} value={p.id}>{p.name}</option>
              ))}
            </select>
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Date">
              <input type="date" className={inputClass} value={form.visit_date} onChange={(e) => setForm({ ...form, visit_date: e.target.value })} />
            </Field>
            <Field label="Time">
              <input type="time" className={inputClass} value={form.visit_time} onChange={(e) => setForm({ ...form, visit_time: e.target.value })} />
            </Field>
          </div>
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
