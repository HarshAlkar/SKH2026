import { useCallback, useEffect, useMemo, useState } from 'react';
import { Video, Clock, AlertCircle, CheckCircle } from 'lucide-react';
import { adminApi } from '../../services/apiService';
import { useResource } from '../../hooks/useResource';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import StatCard from '../../components/ui/StatCard';
import LiveBadge from '../../components/ui/LiveBadge';
import { DataTable } from '../../components/ui/DataTable';
import { Badge, statusTone } from '../../components/ui/Badge';
import { toast } from '../../components/ui/Toast';

export default function ConsultationsPage() {
  const [status, setStatus] = useState('');
  const fetchList = useCallback(() => adminApi.consultations(status ? { status } : {}), [status]);
  const { rows, loading, error, reload } = useResource(fetchList);

  useEffect(() => {
    const id = setInterval(reload, 15000);
    return () => clearInterval(id);
  }, [reload]);

  const stats = useMemo(() => ({
    ongoing: rows.filter((r) => r.status === 'ONGOING').length,
    pending: rows.filter((r) => r.status === 'PENDING').length,
    emergency: rows.filter((r) => r.is_emergency).length,
    completed: rows.filter((r) => r.status === 'COMPLETED').length,
  }), [rows]);

  const endCall = async (id) => {
    try {
      await adminApi.endConsultation(id);
      toast('Consultation ended');
      reload();
    } catch (e) {
      toast(e.message, 'error');
    }
  };

  const cancel = async (id) => {
    try {
      await adminApi.patchConsultation(id, { status: 'CANCELLED' });
      toast('Marked cancelled');
      reload();
    } catch (e) {
      toast(e.message, 'error');
    }
  };

  const typeBadge = (r) => {
    if (r.is_emergency) return <Badge tone="rose">Emergency</Badge>;
    if (r.call_type?.toLowerCase().includes('video')) return <Badge tone="blue">Video</Badge>;
    return <Badge tone="slate">General</Badge>;
  };

  return (
    <div>
      <PageHeader
        title="Consultations"
        subtitle="Audio and video consults across all roles."
        actions={<LiveBadge />}
      />
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
        <StatCard title="Ongoing" value={stats.ongoing} sub="Active calls" icon={Video} color="bg-primary" />
        <StatCard title="Pending" value={stats.pending} sub="Awaiting start" icon={Clock} color="bg-accent" />
        <StatCard title="Emergency" value={stats.emergency} sub="Priority consults" icon={AlertCircle} color="bg-rose-500" />
        <StatCard title="Completed" value={stats.completed} sub="Finished sessions" icon={CheckCircle} color="bg-secondary" />
      </div>
      <div className="mb-4 flex gap-2 flex-wrap">
        {['', 'PENDING', 'ONGOING', 'COMPLETED', 'CANCELLED'].map((s) => (
          <button
            key={s || 'all'}
            type="button"
            onClick={() => setStatus(s)}
            className={`px-3 py-1.5 rounded-full text-xs font-semibold ${
              status === s ? 'bg-primary text-white' : 'bg-white border border-slate-200 text-muted'
            }`}
          >
            {s || 'All'}
          </button>
        ))}
      </div>
      <ErrorBanner error={error} onRetry={reload} />
      <DataTable
        loading={loading}
        rows={rows}
        empty="No consultations found."
        columns={[
          { key: 'patient_name', header: 'Patient' },
          { key: 'doctor_name', header: 'Doctor' },
          { key: 'asha_name', header: 'ASHA' },
          { key: 'type', header: 'Type', render: typeBadge },
          {
            key: 'status',
            header: 'Status',
            render: (r) => <Badge tone={statusTone(r.status)}>{r.status}</Badge>,
          },
          {
            key: 'created_at',
            header: 'Started',
            render: (r) => (r.created_at ? new Date(r.created_at).toLocaleString() : '—'),
          },
          {
            key: 'a',
            header: '',
            render: (r) =>
              ['PENDING', 'ONGOING'].includes(r.status) ? (
                <div className="flex gap-2">
                  <button type="button" className="text-xs font-semibold text-primary" onClick={() => endCall(r.id)}>
                    End
                  </button>
                  <button type="button" className="text-xs font-semibold text-rose-600" onClick={() => cancel(r.id)}>
                    Cancel
                  </button>
                </div>
              ) : null,
          },
        ]}
      />
    </div>
  );
}
