import { useCallback, useEffect, useState } from 'react';
import {
  Bolt,
  Database,
  Lock,
  RotateCcw,
  Send,
  Trash2,
} from 'lucide-react';
import { adminApi } from '../../services/apiService';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import { toast } from '../../components/ui/Toast';

const phaseStyles = {
  idle: 'bg-slate-100 text-slate-700 border-slate-200',
  ready: 'bg-sky-50 text-sky-800 border-sky-200',
  detecting: 'bg-rose-50 text-rose-800 border-rose-200',
  wiped: 'bg-rose-100 text-rose-900 border-rose-300',
  restoring: 'bg-amber-50 text-amber-900 border-amber-200',
  recovered: 'bg-emerald-50 text-emerald-900 border-emerald-200',
};

export default function BlackoutPage() {
  const [status, setStatus] = useState(null);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    try {
      const data = await adminApi.blackoutStatus();
      setStatus(data);
      setError(null);
    } catch (e) {
      setError(e.message || 'Failed to load blackout status');
    }
  }, []);

  useEffect(() => {
    load();
    const id = setInterval(load, 1200);
    return () => clearInterval(id);
  }, [load]);

  const run = async (fn, okMsg) => {
    setBusy(true);
    try {
      const data = await fn();
      setStatus(data);
      if (okMsg) toast(okMsg);
      await load();
    } catch (e) {
      toast(e.message, 'error');
    } finally {
      setBusy(false);
    }
  };

  const phase = (status?.phase || 'idle').toLowerCase();
  const phaseClass = phaseStyles[phase] || phaseStyles.idle;
  const liveRows = status?.live_rows || status?.primary_rows || [];
  const vaultRows = status?.vault_rows || status?.shadow_rows || [];
  const liveCount = status?.live_count ?? status?.primary_count ?? 0;
  const vaultCount = status?.vault_count ?? status?.shadow_count ?? 0;

  return (
    <div>
      <PageHeader
        title="The Blackout"
        subtitle="Livestock screening + doctor prescription — wipe live DB mid-op, hold in admin TEMP vault, then send back to patients."
      />

      <ErrorBanner error={error} onRetry={load} />

      {/* Story in plain language */}
      <div className="mb-6 rounded-2xl border border-indigo-200 bg-indigo-50 p-5 text-sm text-indigo-950 space-y-2">
        <p className="font-bold text-base">Scene (bolo judges ko)</p>
        <p>
          1) Doctor prescription / livestock screening → pehle <strong>TEMP vault</strong> mein
          (patient ko seedha nahi milta).
        </p>
        <p>
          2) <strong>Blackout wipe</strong> — live empty (data contention / corruption). Patient
          My Prescriptions empty dikhega.
        </p>
        <p>
          3) Admin <strong>Restore &amp; send to patients</strong> → TEMP se patient ke pass active
          prescription chali jati hai.
        </p>
      </div>

      <div className="mb-6 grid gap-3 sm:grid-cols-3">
        <StepCard step="1" title="Hold in TEMP vault" desc="Copy live → admin vault">
          <button
            type="button"
            disabled={busy}
            onClick={() =>
              run(adminApi.blackoutSnapshot, 'TEMP vault updated (livestock + Rx)')
            }
            className="w-full flex items-center justify-center gap-2 rounded-xl bg-sky-600 hover:bg-sky-700 disabled:opacity-60 text-white py-3 text-sm font-bold"
          >
            <RotateCcw size={16} />
            Save to TEMP vault
          </button>
        </StepCard>

        <StepCard step="2" title="Blackout wipe" desc="Live EMPTY — vault stays" danger>
          <button
            type="button"
            disabled={busy}
            onClick={() =>
              run(
                adminApi.blackoutWipe,
                'LIVE wiped — show EMPTY left table, vault still has data',
              )
            }
            className="w-full flex items-center justify-center gap-2 rounded-xl bg-rose-600 hover:bg-rose-700 disabled:opacity-60 text-white py-3 text-sm font-bold"
          >
            <Trash2 size={16} />
            Simulate Blackout (wipe live)
          </button>
        </StepCard>

        <StepCard step="3" title="Send to patients" desc="Vault → live again">
          <button
            type="button"
            disabled={busy}
            onClick={() =>
              run(adminApi.blackoutRecover, 'Restored — patients can see data again')
            }
            className="w-full flex items-center justify-center gap-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 text-white py-3 text-sm font-bold"
          >
            <Send size={16} />
            Restore &amp; send to patients
          </button>
        </StepCard>
      </div>

      <div className={`mb-6 rounded-2xl border px-5 py-4 ${phaseClass}`}>
        <p className="text-xs font-semibold uppercase tracking-wide opacity-70">Status</p>
        <p className="text-2xl font-extrabold mt-1">{(status?.phase || 'idle').toUpperCase()}</p>
        <p className="mt-2 text-sm font-medium">{status?.message}</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 mb-6">
        <Metric
          icon={Database}
          label="LIVE (patient / doctor app)"
          value={liveCount}
          empty={phase === 'wiped' || liveCount === 0}
          hint={phase === 'wiped' ? 'EMPTY after blackout' : 'What users see online'}
        />
        <Metric
          icon={Lock}
          label="TEMP VAULT (admin only)"
          value={vaultCount}
          hint="Temporary hold — not wiped"
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-2 mb-6">
        <RecordPanel
          title="LIVE APP DATABASE"
          badge="Patients & doctors see this"
          subtitle={
            phase === 'wiped'
              ? 'BLACKOUT — empty / corrupted mid-operation'
              : 'Livestock screenings + doctor prescriptions'
          }
          rows={liveRows}
          emptyLabel="EMPTY after Blackout — users cannot see records until admin restores"
          tone={phase === 'wiped' || liveRows.length === 0 ? 'danger' : 'ok'}
        />
        <RecordPanel
          title="TEMP VAULT"
          badge="Admin only — temporary block"
          subtitle="Safe copy while live DB is wiped. You refresh & send from here."
          rows={vaultRows}
          emptyLabel="Vault empty — create livestock screening or Rx, then Save to TEMP vault"
          tone={vaultRows.length === 0 ? 'warn' : 'vault'}
        />
      </div>

      <div className="rounded-2xl border border-slate-200 bg-white p-5">
        <div className="flex flex-wrap items-center justify-between gap-3 mb-3">
          <h2 className="font-bold text-ink">Event log</h2>
          <button
            type="button"
            disabled={busy}
            onClick={() => run(adminApi.blackoutSimulate, 'Full wipe + restore done')}
            className="flex items-center gap-2 rounded-lg border border-rose-300 text-rose-700 px-3 py-2 text-xs font-semibold hover:bg-rose-50 disabled:opacity-60"
          >
            <Bolt size={14} />
            One-tap wipe+restore
          </button>
        </div>
        <pre className="h-40 overflow-auto rounded-xl bg-slate-950 text-emerald-300 text-xs leading-relaxed p-4 font-mono">
          {(status?.log || []).join('\n') || 'Waiting…'}
        </pre>
      </div>
    </div>
  );
}

function StepCard({ step, title, desc, children, danger }) {
  return (
    <div
      className={`rounded-2xl border p-4 space-y-3 bg-white ${
        danger ? 'border-rose-200' : 'border-slate-200'
      }`}
    >
      <div>
        <p className="text-xs font-bold text-muted">STEP {step}</p>
        <p className="font-bold text-ink">{title}</p>
        <p className="text-xs text-muted">{desc}</p>
      </div>
      {children}
    </div>
  );
}

function Metric({ icon: Icon, label, value, hint, empty }) {
  return (
    <div
      className={`rounded-2xl border p-5 ${
        empty ? 'border-rose-300 bg-rose-50' : 'border-slate-200 bg-white'
      }`}
    >
      <div className="flex items-center gap-2 text-muted text-xs font-semibold uppercase tracking-wide">
        <Icon size={14} />
        {label}
      </div>
      <p className={`mt-2 text-4xl font-extrabold tabular-nums ${empty ? 'text-rose-700' : 'text-ink'}`}>
        {value}
      </p>
      <p className="mt-1 text-xs text-muted">{hint}</p>
    </div>
  );
}

function RecordPanel({ title, badge, subtitle, rows, emptyLabel, tone }) {
  const border =
    tone === 'danger'
      ? 'border-rose-300'
      : tone === 'warn'
        ? 'border-amber-300'
        : tone === 'vault'
          ? 'border-violet-300'
          : 'border-slate-200';
  const head =
    tone === 'vault' ? 'bg-violet-50' : tone === 'danger' ? 'bg-rose-50' : 'bg-slate-50';

  return (
    <div className={`rounded-2xl border bg-white overflow-hidden ${border}`}>
      <div className={`px-4 py-3 border-b border-slate-100 ${head}`}>
        <div className="flex items-center justify-between gap-2">
          <h2 className="font-bold text-ink text-sm">{title}</h2>
          <span className="text-[10px] font-bold uppercase tracking-wide px-2 py-0.5 rounded-full bg-white/80 text-slate-600 border border-slate-200">
            {badge}
          </span>
        </div>
        <p className="text-xs text-muted mt-1">{subtitle}</p>
      </div>
      {rows.length === 0 ? (
        <div
          className={`px-4 py-10 text-center text-sm font-semibold ${
            tone === 'danger' ? 'text-rose-700 bg-rose-50' : 'text-muted'
          }`}
        >
          {emptyLabel}
        </div>
      ) : (
        <div className="overflow-auto max-h-96">
          <table className="w-full text-left text-xs">
            <thead className="sticky top-0 bg-white border-b border-slate-100 text-muted">
              <tr>
                <th className="px-3 py-2 font-semibold">Type</th>
                <th className="px-3 py-2 font-semibold">Title</th>
                <th className="px-3 py-2 font-semibold">Detail</th>
                <th className="px-3 py-2 font-semibold">Meta</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr
                  key={`${r.type}-${r.id}-${r.created_at}`}
                  className="border-b border-slate-50 hover:bg-slate-50"
                >
                  <td className="px-3 py-2 whitespace-nowrap">
                    <span
                      className={`inline-block rounded px-1.5 py-0.5 text-[10px] font-bold ${
                        r.type === 'prescription'
                          ? 'bg-blue-100 text-blue-800'
                          : 'bg-orange-100 text-orange-800'
                      }`}
                    >
                      {r.kind || r.type}
                    </span>
                  </td>
                  <td className="px-3 py-2 max-w-[140px] truncate font-medium" title={r.title}>
                    {r.title || '—'}
                  </td>
                  <td className="px-3 py-2 max-w-[140px] truncate text-muted" title={r.detail}>
                    {r.detail || '—'}
                  </td>
                  <td className="px-3 py-2 whitespace-nowrap text-muted">
                    {r.severity || '—'} · {r.who || ''}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
