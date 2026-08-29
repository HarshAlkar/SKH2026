import { useCallback, useEffect, useState } from 'react';
import { ShieldAlert, ShieldCheck, ShieldQuestion } from 'lucide-react';
import { adminApi } from '../../services/apiService';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import { toast } from '../../components/ui/Toast';

const demos = [
  'WhatsApp says antibiotics cure dengue in two days.',
  'Drinking a particular household substance is a guaranteed cure for diabetes.',
  'DRINKIN WATER IS GOOD FOR HEALTH',
  'Washing hands with soap helps reduce infection risk.',
  'A rare mineral tea reverses all heart disease overnight without doctors.',
  'Give antibiotics immediately to all cattle if milk drop starts.',
];

export default function TrustShieldPage() {
  const [claim, setClaim] = useState(demos[0]);
  const [result, setResult] = useState(null);
  const [reports, setReports] = useState([]);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);

  const loadReports = useCallback(async () => {
    try {
      const data = await adminApi.trustshieldReports();
      setReports(data.results || []);
    } catch (_) {
      /* optional */
    }
  }, []);

  useEffect(() => {
    loadReports();
  }, [loadReports]);

  const verify = async () => {
    setBusy(true);
    setError(null);
    try {
      const data = await adminApi.trustshieldVerify(claim);
      setResult(data);
      toast(`Status: ${data.status}`);
      loadReports();
    } catch (e) {
      setError(e.message);
      toast(e.message, 'error');
    } finally {
      setBusy(false);
    }
  };

  const status = (result?.status || '').toUpperCase();
  const tone =
    status === 'VERIFIED'
      ? 'border-emerald-300 bg-emerald-50 text-emerald-900'
      : status === 'UNVERIFIED'
        ? 'border-amber-300 bg-amber-50 text-amber-950'
        : 'border-rose-300 bg-rose-50 text-rose-950';

  return (
    <div>
      <PageHeader
        title="TrustShield — The Bad Reading"
        subtitle="AI-assisted health misinformation verification. Curated KB is source of truth — not the LLM."
      />
      <ErrorBanner error={error} onRetry={verify} />

      <div className="mb-6 rounded-2xl border border-indigo-200 bg-indigo-50 p-5 text-sm text-indigo-950 space-y-2">
        <p className="font-bold">Judge demo (60s)</p>
        <p>1) Paste WhatsApp claim → Check Claim</p>
        <p>2) See VERIFIED / UNVERIFIED / MISLEADING + HIGH risk</p>
        <p>3) Evidence + corrected guidance for ASHA to share</p>
        <p>Blackout page stays separate — both challenges coexist.</p>
      </div>

      <div className="grid gap-4 lg:grid-cols-2 mb-6">
        <div className="rounded-2xl border border-slate-200 bg-white p-5 space-y-3">
          <h2 className="font-bold text-ink">Paste health claim</h2>
          <textarea
            className="w-full min-h-[120px] rounded-xl border border-slate-200 p-3 text-sm"
            value={claim}
            onChange={(e) => setClaim(e.target.value)}
          />
          <div className="flex flex-wrap gap-2">
            {demos.map((d) => (
              <button
                key={d}
                type="button"
                onClick={() => setClaim(d)}
                className="text-xs rounded-full border border-slate-200 px-3 py-1 hover:bg-slate-50"
              >
                {d.slice(0, 40)}…
              </button>
            ))}
          </div>
          <button
            type="button"
            disabled={busy}
            onClick={verify}
            className="w-full rounded-xl bg-primary text-white py-3 font-bold disabled:opacity-60"
          >
            {busy ? 'Checking…' : 'Check Claim'}
          </button>
        </div>

        <div className={`rounded-2xl border p-5 ${result ? tone : 'border-slate-200 bg-white'}`}>
          {!result ? (
            <p className="text-muted text-sm">Result appears here after Check Claim.</p>
          ) : (
            <div className="space-y-3 text-sm">
              <div className="flex items-center gap-2">
                {status === 'VERIFIED' ? (
                  <ShieldCheck size={22} />
                ) : status === 'UNVERIFIED' ? (
                  <ShieldQuestion size={22} />
                ) : (
                  <ShieldAlert size={22} />
                )}
                <p className="text-xl font-extrabold">{status}</p>
              </div>
              <p>
                <strong>Claim:</strong> {result.claim}
              </p>
              <p>
                <strong>Risk:</strong> {result.riskLevel}
              </p>
              <p>
                <strong>Why:</strong> {result.explanation}
              </p>
              <p>
                <strong>Action:</strong> {result.recommendedAction}
              </p>
              <div>
                <strong>Evidence:</strong>
                <ul className="list-disc ml-5 mt-1">
                  {(result.sources || []).map((s) => (
                    <li key={`${s.name}-${s.reference}`}>
                      {s.name} ({s.type})
                    </li>
                  ))}
                </ul>
              </div>
              {result.correctedGuidance ? (
                <pre className="whitespace-pre-wrap rounded-xl bg-white/70 p-3 text-xs border border-black/5">
                  {result.correctedGuidance}
                </pre>
              ) : null}
              <p className="text-xs opacity-80">{result.disclaimer}</p>
              {result.kbLabel ? (
                <p className="text-xs font-semibold">Dataset: {result.kbLabel}</p>
              ) : null}
            </div>
          )}
        </div>
      </div>

      <div className="rounded-2xl border border-slate-200 bg-white p-5">
        <h2 className="font-bold text-ink mb-3">Reported misinformation</h2>
        {reports.length === 0 ? (
          <p className="text-sm text-muted">No reports yet.</p>
        ) : (
          <ul className="space-y-2 text-sm">
            {reports.map((r) => (
              <li key={r.id} className="rounded-lg border border-slate-100 p-3">
                <span className="font-semibold">{r.status}</span> — {r.claim}
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
