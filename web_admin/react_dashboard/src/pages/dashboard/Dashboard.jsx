import { useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Users, Stethoscope, Clock, AlertCircle, UserRound, Brain, Video } from 'lucide-react';
import { adminApi } from '../../services/apiService';
import { usePolling } from '../../hooks/usePolling';
import { useMapMarkers } from '../../hooks/useMapMarkers';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import StatCard from '../../components/ui/StatCard';
import LiveBadge from '../../components/ui/LiveBadge';
import { Badge, statusTone } from '../../components/ui/Badge';
import EmergencyMap from '../../components/map/EmergencyMap';

export default function Dashboard() {
  const navigate = useNavigate();
  const fetchStats = useCallback(() => adminApi.stats(), []);
  const { data: stats, error, reload } = usePolling(fetchStats, 15000);
  const { data: mapData } = useMapMarkers(true);

  return (
    <div>
      <PageHeader
        title="Healthcare Operations Overview"
        subtitle="Live counts from the VitalReach Django API."
        actions={
          <div className="flex items-center gap-2">
            <LiveBadge />
            <button
              type="button"
              onClick={() => navigate('/patients', { state: { openCreate: true } })}
              className="rounded-lg bg-primary text-white px-4 py-2 text-sm font-semibold"
            >
              + New Admission
            </button>
          </div>
        }
      />
      <ErrorBanner error={error} onRetry={reload} />

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4 mb-8">
        <StatCard title="Total Patients" value={stats?.patients} sub="Registered village patients" icon={Users} color="bg-primary" to="/patients" />
        <StatCard title="Doctors" value={stats?.doctors} sub={`${stats?.active_doctors ?? 0} available now`} icon={Stethoscope} color="bg-secondary" to="/doctors" />
        <StatCard title="ASHA Workers" value={stats?.asha_workers} sub="Community health workers" icon={UserRound} color="bg-violet-500" to="/asha-workers" />
        <StatCard title="Consultations" value={stats?.pending_consultations} sub="Pending or ongoing" icon={Video} color="bg-accent" to="/consultations" />
        <StatCard title="Emergency Alerts" value={stats?.emergency_alerts} sub="Unresolved" icon={AlertCircle} color="bg-rose-500" to="/alerts" />
        <StatCard title="AI Analyses" value={stats?.symptom_analyses} sub="Symptom screenings" icon={Brain} color="bg-slate-600" to="/symptoms" />
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6 mb-8">
        <section className="xl:col-span-2 bg-white rounded-2xl border border-slate-100 p-5 shadow-sm">
          <div className="flex justify-between items-center mb-4">
            <h2 className="font-bold text-ink">Active Emergencies</h2>
            <Link to="/alerts" className="text-sm text-primary font-medium">View all</Link>
          </div>
          <div className="space-y-2">
            {(stats?.open_alerts || []).length === 0 ? (
              <p className="text-sm text-muted py-6 text-center">No open emergency alerts.</p>
            ) : (
              stats.open_alerts.map((a) => (
                <div key={a.id} className="flex items-center justify-between p-3 rounded-xl hover:bg-slate-50 border border-slate-50">
                  <div>
                    <p className="font-medium">{a.user_name}</p>
                    <p className="text-xs text-muted">{a.alert_type} · {a.village || '—'}</p>
                  </div>
                  <Badge tone="rose">Open</Badge>
                </div>
              ))
            )}
          </div>
        </section>
        <section className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm">
          <h2 className="font-bold text-ink mb-3">Live Tracking Map</h2>
          <EmergencyMap data={mapData} height={260} />
        </section>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <section className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm">
          <div className="flex justify-between items-center mb-4">
            <h2 className="font-bold">Recent Consultations</h2>
            <Link to="/consultations" className="text-sm text-primary font-medium">View all</Link>
          </div>
          <div className="space-y-2">
            {(stats?.recent_consultations || []).length === 0 ? (
              <p className="text-sm text-muted py-6 text-center">No consultations yet.</p>
            ) : (
              stats.recent_consultations.map((c) => (
                <div key={c.id} className="flex items-center justify-between p-3 rounded-xl hover:bg-slate-50">
                  <div>
                    <p className="font-medium">{c.patient_name}</p>
                    <p className="text-xs text-muted">with {c.doctor_name || 'unassigned'} · {c.call_type}</p>
                  </div>
                  <Badge tone={statusTone(c.status)}>{c.status}</Badge>
                </div>
              ))
            )}
          </div>
        </section>
        <section className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm">
          <div className="flex justify-between items-center mb-4">
            <h2 className="font-bold">ASHA Activity</h2>
            <Link to="/asha-workers" className="text-sm text-primary font-medium">Workers</Link>
          </div>
          <div className="space-y-2">
            {(stats?.asha_activity || []).length === 0 ? (
              <p className="text-sm text-muted py-6 text-center">No ASHA workers yet.</p>
            ) : (
              stats.asha_activity.map((a) => (
                <div key={a.id} className="flex items-center justify-between p-3 rounded-xl hover:bg-slate-50">
                  <div>
                    <p className="font-medium">{a.name}</p>
                    <p className="text-xs text-muted">{a.village || 'Unassigned'}</p>
                  </div>
                  <p className="text-xs font-semibold text-primary">{a.visits_today} visits today</p>
                </div>
              ))
            )}
          </div>
        </section>
      </div>
    </div>
  );
}
