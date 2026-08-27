export function PageHeader({ title, subtitle, action, actions }) {
  const right = actions || action;
  return (
    <header className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
      <div>
        <h1 className="text-2xl font-bold text-ink">{title}</h1>
        {subtitle ? <p className="text-muted mt-1 text-sm">{subtitle}</p> : null}
      </div>
      {right}
    </header>
  );
}

export function ErrorBanner({ error, onRetry }) {
  if (!error) return null;
  return (
    <div className="mb-4 rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800 flex items-start justify-between gap-3">
      <p>
        {error}. Check that the API is reachable (Render may take ~30s to wake on Free tier).
      </p>
      {onRetry ? (
        <button type="button" onClick={onRetry} className="shrink-0 font-semibold underline">
          Retry
        </button>
      ) : null}
    </div>
  );
}

export function EmptyState({ text }) {
  return (
    <div className="py-12 text-center text-muted text-sm">{text || 'No records yet.'}</div>
  );
}
