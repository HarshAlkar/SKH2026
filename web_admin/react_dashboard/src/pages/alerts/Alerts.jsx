import { useCallback, useEffect, useState } from 'react';
import { adminApi } from '../../services/apiService';
import { useResource } from '../../hooks/useResource';
import { useMapMarkers } from '../../hooks/useMapMarkers';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import { DataTable } from '../../components/ui/DataTable';
import { Badge, statusTone } from '../../components/ui/Badge';
import LiveBadge from '../../components/ui/LiveBadge';
import EmergencyMap from '../../components/map/EmergencyMap';
import { toast } from '../../components/ui/Toast';

export default function AlertsPage() {
  const [tab, setTab] = useState('emergencies');
  const [focus, setFocus] = useState(null);
  const [doctors, setDoctors] = useState([]);
  const [selected, setSelected] = useState(null);

  const fetchEmergencies = useCallback(() => adminApi.emergencies({ is_resolved: false }), []);
  const fetchNotes = useCallback(() => adminApi.notifications(), []);
  const fetchRefs = useCallback(() => adminApi.referrals(), []);

  const emergencies = useResource(fetchEmergencies);
  const notes = useResource(fetchNotes);
  const refs = useResource(fetchRefs);
  const { data: mapData } = useMapMarkers(tab === 'emergencies');

  useEffect(() => {
    if (tab !== 'emergencies') return undefined;
    const id = setInterval(() => emergencies.reload(), 15000);
    return () => clearInterval(id);
  }, [tab, emergencies.reload]);

  useEffect(() => {
    adminApi.doctors().then(setDoctors).catch(() => {});
  }, []);

  const resolve = async (id) => {
    try {
      await adminApi.patchEmergency(id, { is_resolved: true });
      toast('Alert resolved');
      emergencies.reload();
      setSelected(null);
    } catch (e) {
      toast(e.message, 'error');
    }
  };

  const assignDoctor = async (alertId, doctorId) => {
    if (!doctorId) return;
    try {
      await adminApi.assignEmergency(alertId, Number(doctorId));
      toast('Doctor assigned');
      emergencies.reload();
    } catch (e) {
      toast(e.message, 'error');
    }
  };

  const setRefStatus = async (id, status) => {
    try {
      await adminApi.patchReferral(id, { status });
      toast('Referral updated');
      refs.reload();
    } catch (e) {
      toast(e.message, 'error');
    }
  };

  const tabs = [
    ['emergencies', 'Emergencies'],
    ['notifications', 'Notifications'],
    ['referrals', 'Referrals'],
  ];

  const openCount = emergencies.rows?.length ?? 0;

  return (
    <div>
      <PageHeader
        title="Emergency Alert Center"
        subtitle="Real-time emergencies, disease notifications, and ASHA referrals."
        actions={<LiveBadge />}
      />
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <div className="bg-white rounded-2xl border p-4 shadow-sm">
          <p className="text-sm text-muted">Active Emergencies</p>
          <p className="text-2xl font-bold text-rose-600">{openCount}</p>
        </div>
        <div className="bg-white rounded-2xl border p-4 shadow-sm">
          <p className="text-sm text-muted">Notifications</p>
          <p className="text-2xl font-bold text-primary">{notes.rows?.length ?? '—'}</p>
        </div>
        <div className="bg-white rounded-2xl border p-4 shadow-sm">
          <p className="text-sm text-muted">Referrals</p>
          <p className="text-2xl font-bold text-secondary">{refs.rows?.length ?? '—'}</p>
        </div>
      </div>

      <div className="mb-4 flex gap-2">
        {tabs.map(([id, label]) => (
          <button
            key={id}
            type="button"
            onClick={() => setTab(id)}
            className={`px-3 py-1.5 rounded-full text-xs font-semibold ${
              tab === id ? 'bg-primary text-white' : 'bg-white border border-slate-200 text-muted'
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {tab === 'emergencies' && (
        <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
          <div className="xl:col-span-2 space-y-4">
            <ErrorBanner error={emergencies.error} onRetry={emergencies.reload} />
            <DataTable
              loading={emergencies.loading}
              rows={emergencies.rows}
              empty="No emergency alerts."
              columns={[
                { key: 'id', header: 'ID', render: (r) => `#EM-${r.id}` },
                { key: 'user_name', header: 'Patient' },
                { key: 'alert_type', header: 'Type' },
                { key: 'location', header: 'Location' },
                { key: 'village', header: 'Village' },
                {
                  key: 'timestamp',
                  header: 'When',
                  render: (r) => (r.timestamp ? new Date(r.timestamp).toLocaleString() : '—'),
                },
                {
                  key: 'a',
                  header: '',
                  render: (r) => (
                    <button
                      type="button"
                      className="text-xs font-semibold text-primary"
                      onClick={() => {
                        setSelected(r);
                        if (r.latitude != null && r.longitude != null) {
                          setFocus({ lat: r.latitude, lng: r.longitude });
                        }
                      }}
                    >
                      View
                    </button>
                  ),
                },
              ]}
            />
          </div>
          <div className="space-y-4">
            <EmergencyMap data={mapData} height={240} focusTarget={focus} onMarkerClick={(m) => setFocus({ lat: m.lat, lng: m.lng })} />
            {selected ? (
              <div className="bg-white rounded-2xl border p-4 shadow-sm">
                <h3 className="font-bold mb-2">Active Response: #EM-{selected.id}</h3>
                <p className="text-sm text-muted mb-3">{selected.alert_type} · {selected.user_name}</p>
                <label className="block text-xs font-semibold text-muted mb-1">Assign doctor</label>
                <select
                  className="w-full rounded-lg border px-2 py-2 text-sm mb-3"
                  defaultValue={selected.assigned_doctor || ''}
                  onChange={(e) => assignDoctor(selected.id, e.target.value)}
                >
                  <option value="">Select doctor</option>
                  {doctors.map((d) => (
                    <option key={d.id} value={d.id}>{d.full_name}</option>
                  ))}
                </select>
                <button
                  type="button"
                  className="w-full rounded-lg bg-primary text-white py-2 text-sm font-semibold"
                  onClick={() => resolve(selected.id)}
                >
                  Mark resolved
                </button>
              </div>
            ) : (
              <p className="text-sm text-muted text-center py-4">Select an alert to assign a doctor.</p>
            )}
          </div>
        </div>
      )}

      {tab === 'notifications' && (
        <>
          <ErrorBanner error={notes.error} onRetry={notes.reload} />
          <DataTable
            loading={notes.loading}
            rows={notes.rows}
            empty="No care-team notifications."
            columns={[
              { key: 'patient_name', header: 'Patient' },
              { key: 'disease', header: 'Disease' },
              { key: 'severity', header: 'Severity', render: (r) => <Badge tone={statusTone(r.severity)}>{r.severity}</Badge> },
              { key: 'village', header: 'Village' },
              { key: 'created_at', header: 'When', render: (r) => (r.created_at ? new Date(r.created_at).toLocaleString() : '—') },
            ]}
          />
        </>
      )}

      {tab === 'referrals' && (
        <>
          <ErrorBanner error={refs.error} onRetry={refs.reload} />
          <DataTable
            loading={refs.loading}
            rows={refs.rows}
            empty="No referrals."
            columns={[
              { key: 'patient_name', header: 'Patient' },
              { key: 'asha_name', header: 'ASHA' },
              { key: 'symptoms', header: 'Symptoms' },
              { key: 'severity', header: 'Severity', render: (r) => <Badge tone={statusTone(r.severity)}>{r.severity}</Badge> },
              { key: 'status', header: 'Status', render: (r) => <Badge tone={statusTone(r.status)}>{r.status}</Badge> },
              {
                key: 'a',
                header: '',
                render: (r) => (
                  <select className="text-xs border rounded-lg px-2 py-1" value={r.status} onChange={(e) => setRefStatus(r.id, e.target.value)}>
                    {['pending', 'sent', 'accepted', 'completed'].map((s) => (
                      <option key={s} value={s}>{s}</option>
                    ))}
                  </select>
                ),
              },
            ]}
          />
        </>
      )}
    </div>
  );
}
