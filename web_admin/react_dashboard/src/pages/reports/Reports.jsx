import { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { adminApi } from '../../services/apiService';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import StatCard from '../../components/ui/StatCard';
import { Users, Stethoscope, AlertCircle, Video, Brain, MapPin } from 'lucide-react';

const PAGE_LINKS = [
  { to: '/patients', label: 'Patients', key: 'patients', icon: Users, color: 'bg-primary' },
  { to: '/doctors', label: 'Doctors', key: 'doctors', icon: Stethoscope, color: 'bg-secondary' },
  { to: '/consultations', label: 'Open consultations', key: 'pending_consultations', icon: Video, color: 'bg-accent' },
  { to: '/alerts', label: 'Unresolved emergencies', key: 'emergency_alerts', icon: AlertCircle, color: 'bg-rose-500' },
  { to: '/symptoms', label: 'AI analyses', key: 'symptom_analyses', icon: Brain, color: 'bg-slate-600' },
  { to: '/visits', label: 'Village visits', key: 'visits', icon: MapPin, color: 'bg-violet-500' },
];

export default function ReportsPage() {
  const [stats, setStats] = useState(null);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    setError('');
    try {
      setStats(await adminApi.stats());
    } catch (e) {
      setError(e.message);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const extraItems = [
    ['ASHA workers', stats?.asha_workers, '/asha-workers'],
    ['Prescriptions', stats?.prescriptions, '/prescriptions'],
    ['Chat threads', stats?.chat_threads, '/chat'],
  ];

  return (
    <div>
      <PageHeader title="Reports & Analytics" subtitle="Network-wide snapshot for VitalReach supervisors." />
      <ErrorBanner error={error} onRetry={load} />
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4 mb-8">
        {PAGE_LINKS.map(({ to, label, key, icon, color }) => (
          <Link key={key} to={to}>
            <StatCard title={label} value={stats?.[key]} sub="View details →" icon={icon} color={color} />
          </Link>
        ))}
      </div>
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        {extraItems.map(([label, value, to]) => (
          <Link key={label} to={to} className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm hover:shadow-md transition-shadow block">
            <p className="text-sm text-muted">{label}</p>
            <p className="text-3xl font-bold mt-2">{value ?? '—'}</p>
            <p className="text-xs text-primary mt-2 font-medium">Open page →</p>
          </Link>
        ))}
      </div>
    </div>
  );
}
