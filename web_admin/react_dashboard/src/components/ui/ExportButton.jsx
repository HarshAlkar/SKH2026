import { Download } from 'lucide-react';

function escapeCsv(val) {
  const s = val == null ? '' : String(val);
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

export default function ExportButton({ rows = [], columns = [], filename = 'export.csv', label = 'Export' }) {
  const download = () => {
    if (!rows.length || !columns.length) return;
    const header = columns.map((c) => escapeCsv(c.header)).join(',');
    const body = rows.map((row) =>
      columns.map((c) => escapeCsv(c.render ? c.render(row) : row[c.key])).join(','),
    ).join('\n');
    const blob = new Blob([`${header}\n${body}`], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <button
      type="button"
      onClick={download}
      disabled={!rows.length}
      className="inline-flex items-center gap-2 rounded-lg border border-primary text-primary px-4 py-2 text-sm font-semibold hover:bg-light disabled:opacity-50"
    >
      <Download size={16} />
      {label}
    </button>
  );
}
