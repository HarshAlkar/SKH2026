import { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { adminApi } from '../../services/apiService';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import StatCard from '../../components/ui/StatCard';
import { Users, Stethoscope, AlertCircle, Video, Brain, MapPin, Sparkles } from 'lucide-react';
import { toast } from '../../components/ui/Toast';

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
  const [aiBusy, setAiBusy] = useState(false);
  const [aiReport, setAiReport] = useState('');
  const [aiMeta, setAiMeta] = useState(null);

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

  const generateAiReport = async () => {
    if (!stats) {
      toast('Load stats first', 'error');
      return;
    }
    setAiBusy(true);
    setError('');
    try {
      const data = await adminApi.geminiReportAnalysis({
        report_type: 'network',
        focus: 'Supervisor weekly briefing with evidence',
        context: {
          patients: stats.patients,
          doctors: stats.doctors,
          asha_workers: stats.asha_workers,
          pending_consultations: stats.pending_consultations,
          emergency_alerts: stats.emergency_alerts,
          prescriptions: stats.prescriptions,
          symptom_analyses: stats.symptom_analyses,
          human_screenings: stats.human_screenings,
          animal_screenings: stats.animal_screenings,
          visits: stats.visits,
          pending_verifications: stats.pending_verifications,
        },
      });
      setAiReport(data.report || '');
      setAiMeta({ model: data.model, disclaimer: data.disclaimer });
      toast('Gemini report ready');
    } catch (e) {
      setError(e.message);
      toast(e.message, 'error');
    } finally {
      setAiBusy(false);
    }
  };

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
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
        {extraItems.map(([label, value, to]) => (
          <Link key={label} to={to} className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm hover:shadow-md transition-shadow block">
            <p className="text-sm text-muted">{label}</p>
            <p className="text-3xl font-bold mt-2">{value ?? '—'}</p>
            <p className="text-xs text-primary mt-2 font-medium">Open page →</p>
          </Link>
        ))}
      </div>

      <div className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-3 mb-4">
          <div>
            <p className="text-sm font-semibold text-ink flex items-center gap-2">
              <Sparkles size={16} className="text-primary" />
              AI Analysis (Gemini)
            </p>
            <p className="text-xs text-muted mt-1">
              Generate a supervisor briefing from live network stats — with evidence bullets.
            </p>
          </div>
          <button
            type="button"
            disabled={aiBusy || !stats}
            onClick={generateAiReport}
            className="rounded-xl bg-primary text-white text-sm font-semibold px-4 py-2 disabled:opacity-50"
          >
            {aiBusy ? 'Generating…' : 'Generate Gemini report'}
          </button>
        </div>
        {aiReport ? (
          <div className="rounded-xl bg-slate-50 border border-slate-100 p-4 whitespace-pre-wrap text-sm leading-relaxed text-ink">
            {aiReport}
            {aiMeta?.disclaimer ? (
              <p className="text-xs text-muted mt-4 italic">{aiMeta.disclaimer}{aiMeta.model ? ` · ${aiMeta.model}` : ''}</p>
            ) : null}
          </div>
        ) : (
          <p className="text-sm text-muted">No AI report yet. Click generate after stats load.</p>
        )}
      </div>
    </div>
  );
}
