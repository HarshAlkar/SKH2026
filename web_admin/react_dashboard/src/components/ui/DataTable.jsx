import { EmptyState } from './PageHeader';

export function DataTable({ columns, rows, loading, empty, rowKey = 'id' }) {
  if (loading) {
    return (
      <div className="bg-white rounded-2xl border border-slate-100 p-8 text-center text-muted text-sm">
        Loading…
      </div>
    );
  }

  return (
    <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-left text-muted">
            <tr>
              {columns.map((col) => (
                <th key={col.key} className="px-4 py-3 font-semibold whitespace-nowrap">
                  {col.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 ? (
              <tr>
                <td colSpan={columns.length}>
                  <EmptyState text={empty} />
                </td>
              </tr>
            ) : (
              rows.map((row, i) => (
                <tr key={row[rowKey] ?? i} className="border-t border-slate-100 hover:bg-slate-50/80">
                  {columns.map((col) => (
                    <td key={col.key} className="px-4 py-3 align-middle">
                      {col.render ? col.render(row) : row[col.key] ?? '—'}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
