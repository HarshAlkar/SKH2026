import { useCallback, useMemo, useState } from 'react';
import { Brain, AlertTriangle, Activity } from 'lucide-react';
import { adminApi } from '../../services/apiService';
import { useResource } from '../../hooks/useResource';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import StatCard from '../../components/ui/StatCard';
import ProgressBar from '../../components/ui/ProgressBar';
import { DataTable } from '../../components/ui/DataTable';
import { Badge, statusTone } from '../../components/ui/Badge';
import { Modal } from '../../components/ui/Modal';

export default function SymptomsPage() {
  const fetchList = useCallback(() => adminApi.symptoms(), []);
  const { rows, loading, error, reload } = useResource(fetchList);
  const [detail, setDetail] = useState(null);

  const stats = useMemo(() => {
    const high = rows.filter((r) => ['high', 'severe'].includes(String(r.severity_level).toLowerCase())).length;
    const moderate = rows.filter((r) => ['moderate', 'medium'].includes(String(r.severity_level).toLowerCase())).length;
    const avgConf = rows.length
      ? Math.round(rows.reduce((sum, r) => sum + (Number(r.confidence) || 0), 0) / rows.length)
      : 0;
    return { total: rows.length, high, moderate, avgConf };
  }, [rows]);

  const riskDistribution = useMemo(() => {
    const low = rows.length - stats.high - stats.moderate;
    const total = rows.length || 1;
    return {
      high: Math.round((stats.high / total) * 100),
      moderate: Math.round((stats.moderate / total) * 100),
      low: Math.round((low / total) * 100),
    };
  }, [rows.length, stats]);

  return (
    <div>
      <PageHeader title="AI Symptom Analyses" subtitle="Symptom checker history stored by Django." />
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <StatCard title="Total Analyses" value={stats.total} sub="All screenings" icon={Brain} color="bg-primary" />
        <StatCard title="Avg Confidence" value={stats.avgConf ? `${stats.avgConf}%` : '—'} sub="Model certainty" icon={Activity} color="bg-secondary" />
        <StatCard title="High Severity" value={stats.high} sub="Needs review" icon={AlertTriangle} color="bg-rose-500" />
      </div>
      <div className="bg-white rounded-2xl border p-4 mb-6 shadow-sm">
        <p className="text-sm font-semibold text-ink mb-3">Risk distribution</p>
        <div className="space-y-2">
          <ProgressBar value={riskDistribution.high} label={`High ${riskDistribution.high}%`} color="bg-rose-500" />
          <ProgressBar value={riskDistribution.moderate} label={`Moderate ${riskDistribution.moderate}%`} color="bg-accent" />
          <ProgressBar value={riskDistribution.low} label={`Low ${riskDistribution.low}%`} color="bg-secondary" />
        </div>
      </div>
      <ErrorBanner error={error} onRetry={reload} />
      <DataTable
        loading={loading}
        rows={rows}
        empty="No AI analyses yet."
        columns={[
          { key: 'user_name', header: 'User' },
          { key: 'village', header: 'Village' },
          {
            key: 'symptoms_text',
            header: 'Symptoms',
            render: (r) => (
              <span className="line-clamp-1 max-w-xs" title={r.symptoms_text}>
                {r.symptoms_text?.slice(0, 50)}{r.symptoms_text?.length > 50 ? '…' : ''}
              </span>
            ),
          },
          { key: 'predicted_disease', header: 'Prediction' },
          {
            key: 'severity_level',
            header: 'Severity',
            render: (r) => <Badge tone={statusTone(r.severity_level)}>{r.severity_level}</Badge>,
          },
          {
            key: 'created_at',
            header: 'When',
            render: (r) => (r.created_at ? new Date(r.created_at).toLocaleString() : '—'),
          },
          {
            key: 'a',
            header: '',
            render: (r) => (
              <button type="button" className="text-xs font-semibold text-primary" onClick={() => setDetail(r)}>
                Review
              </button>
            ),
          },
        ]}
      />
      <Modal open={Boolean(detail)} title="Analysis detail" onClose={() => setDetail(null)} wide>
        {detail ? (
          <div className="space-y-4 text-sm">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-muted">Patient</p>
                <p className="font-semibold">{detail.user_name}</p>
              </div>
              <div>
                <p className="text-xs text-muted">Village</p>
                <p className="font-semibold">{detail.village || '—'}</p>
              </div>
              <div>
                <p className="text-xs text-muted">Prediction</p>
                <p className="font-semibold">{detail.predicted_disease}</p>
              </div>
              <div>
                <p className="text-xs text-muted">Severity</p>
                <Badge tone={statusTone(detail.severity_level)}>{detail.severity_level}</Badge>
              </div>
            </div>
            <div>
              <p className="text-xs text-muted mb-1">Symptoms reported</p>
              <p className="rounded-xl bg-slate-50 p-3">{detail.symptoms_text || '—'}</p>
            </div>
            {detail.recommendations ? (
              <div>
                <p className="text-xs text-muted mb-1">Recommendations</p>
                <p className="rounded-xl bg-slate-50 p-3">{detail.recommendations}</p>
              </div>
            ) : null}
            <p className="text-xs text-muted">
              Analyzed {detail.created_at ? new Date(detail.created_at).toLocaleString() : '—'}
            </p>
          </div>
        ) : null}
      </Modal>
    </div>
  );
}
