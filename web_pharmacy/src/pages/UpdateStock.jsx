import { useEffect, useMemo, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { stockApi } from '../services/apiService';
import { useSync } from '../context/SyncContext';
import { PageHeader, ErrorBanner } from '../components/ui/PageHeader';

export default function UpdateStock() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const { queueAdjust } = useSync();
  const [batches, setBatches] = useState([]);
  const [catalog, setCatalog] = useState([]);
  const [facilities, setFacilities] = useState([]);
  const [batchId, setBatchId] = useState(params.get('batch') || '');
  const [action, setAction] = useState('add');
  const [quantity, setQuantity] = useState(50);
  const [reason, setReason] = useState('New Delivery Received');
  const [supplierName, setSupplierName] = useState('');
  const [invoiceNo, setInvoiceNo] = useState('');
  const [notes, setNotes] = useState('');
  const [error, setError] = useState('');
  const [ok, setOk] = useState('');
  const [saving, setSaving] = useState(false);
  const [mode, setMode] = useState(params.get('add') ? 'new' : 'existing');
  const [newForm, setNewForm] = useState({
    facility_id: '',
    catalog_id: '',
    batch_no: '',
    expiry_date: '',
    reorder_level: 20,
  });

  useEffect(() => {
    (async () => {
      try {
        const [b, c, f] = await Promise.all([
          stockApi.batches(),
          stockApi.catalog({ active: 1 }),
          stockApi.facilities(),
        ]);
        setBatches(Array.isArray(b) ? b : b.results || []);
        setCatalog(Array.isArray(c) ? c : c.results || []);
        const facs = Array.isArray(f) ? f : f.results || [];
        setFacilities(facs);
        if (facs[0] && !newForm.facility_id) {
          setNewForm((s) => ({ ...s, facility_id: String(facs[0].id) }));
        }
      } catch (e) {
        setError(e.message);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const selected = useMemo(
    () => batches.find((b) => String(b.id) === String(batchId)),
    [batches, batchId],
  );

  const preview = useMemo(() => {
    const current = selected?.quantity ?? 0;
    const qty = Number(quantity) || 0;
    let next = current;
    if (action === 'add') next = current + qty;
    else if (action === 'adjust') next = qty;
    else next = Math.max(0, current - qty);
    return { current, qty, next };
  }, [selected, quantity, action]);

  const onSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setOk('');
    setSaving(true);
    try {
      let body;
      if (mode === 'new') {
        body = {
          facility_id: Number(newForm.facility_id),
          catalog_id: Number(newForm.catalog_id),
          batch_no: newForm.batch_no,
          expiry_date: newForm.expiry_date,
          reorder_level: Number(newForm.reorder_level) || 20,
          action,
          quantity: Number(quantity),
          reason,
          supplier_name: supplierName,
          invoice_no: invoiceNo,
          notes,
        };
      } else {
        if (!batchId) throw new Error('Select a medicine batch');
        body = {
          batch_id: Number(batchId),
          action,
          quantity: Number(quantity),
          reason,
          supplier_name: supplierName,
          invoice_no: invoiceNo,
          notes,
        };
      }
      const res = await queueAdjust(body);
      setOk(res.synced ? 'Stock updated and synced.' : 'Saved offline — will sync when internet is back.');
      setTimeout(() => navigate('/inventory'), 900);
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <PageHeader
        title="Update Stock Workflow"
        subtitle="Adjust inventory levels, log stock movements, and maintain compliance records."
      />
      <ErrorBanner error={error} />
      {ok ? <div className="mb-4 rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">{ok}</div> : null}

      <form onSubmit={onSubmit} className="bg-white rounded-2xl border border-slate-100 shadow-sm p-6 space-y-8 max-w-3xl">
        <div className="flex gap-2">
          <button type="button" onClick={() => setMode('existing')} className={`px-3 py-1.5 rounded-lg text-sm font-semibold ${mode === 'existing' ? 'bg-primary text-white' : 'bg-slate-100'}`}>
            Existing batch
          </button>
          <button type="button" onClick={() => setMode('new')} className={`px-3 py-1.5 rounded-lg text-sm font-semibold ${mode === 'new' ? 'bg-primary text-white' : 'bg-slate-100'}`}>
            New medicine / batch
          </button>
        </div>

        <section>
          <h2 className="font-semibold text-lg mb-3">1. Select Medicine</h2>
          {mode === 'existing' ? (
            <label className="block text-sm">
              Medicine / Batch
              <select
                className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5"
                value={batchId}
                onChange={(e) => setBatchId(e.target.value)}
                required
              >
                <option value="">Search SKU / Medicine Name</option>
                {batches.map((b) => (
                  <option key={b.id} value={b.id}>
                    {b.medicine_name} — {b.batch_no} (Exp: {b.expiry_date}) · {b.quantity} units
                  </option>
                ))}
              </select>
            </label>
          ) : (
            <div className="grid sm:grid-cols-2 gap-3">
              <label className="block text-sm">
                Facility
                <select
                  className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5"
                  value={newForm.facility_id}
                  onChange={(e) => setNewForm({ ...newForm, facility_id: e.target.value })}
                  required
                >
                  {facilities.map((f) => (
                    <option key={f.id} value={f.id}>{f.name}</option>
                  ))}
                </select>
              </label>
              <label className="block text-sm">
                Medicine
                <select
                  className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5"
                  value={newForm.catalog_id}
                  onChange={(e) => setNewForm({ ...newForm, catalog_id: e.target.value })}
                  required
                >
                  <option value="">Select catalog item</option>
                  {catalog.map((c) => (
                    <option key={c.id} value={c.id}>{c.display_name || c.name} ({c.sku})</option>
                  ))}
                </select>
              </label>
              <label className="block text-sm">
                Batch Number
                <input
                  className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5"
                  value={newForm.batch_no}
                  onChange={(e) => setNewForm({ ...newForm, batch_no: e.target.value })}
                  required
                />
              </label>
              <label className="block text-sm">
                Expiry Date
                <input
                  type="date"
                  className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5"
                  value={newForm.expiry_date}
                  onChange={(e) => setNewForm({ ...newForm, expiry_date: e.target.value })}
                  required
                />
              </label>
            </div>
          )}
        </section>

        <section>
          <h2 className="font-semibold text-lg mb-3">2. Stock Adjustment</h2>
          <div className="grid sm:grid-cols-2 gap-3">
            <label className="block text-sm">
              Action Type
              <select className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5" value={action} onChange={(e) => setAction(e.target.value)}>
                <option value="add">Add Stock (+)</option>
                <option value="remove">Remove Stock (−)</option>
                <option value="adjust">Set Absolute Qty</option>
                <option value="disposal">Mark Disposal</option>
                <option value="return">Return to Supplier</option>
              </select>
            </label>
            <label className="block text-sm">
              Quantity
              <input
                type="number"
                min="0"
                className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5"
                value={quantity}
                onChange={(e) => setQuantity(e.target.value)}
                required
              />
            </label>
          </div>
          {mode === 'existing' && selected ? (
            <div className="mt-4 flex flex-wrap items-center gap-3 text-sm">
              <span className="rounded-xl bg-slate-100 px-3 py-2">Current ({preview.current})</span>
              <span className="text-muted">{action === 'add' ? '+' : action === 'adjust' ? '→' : '−'}</span>
              <span className="rounded-xl bg-slate-100 px-3 py-2">Adjustment ({preview.qty})</span>
              <span className="text-muted">→</span>
              <span className="rounded-xl bg-primary text-white px-3 py-2 font-semibold">New Stock ({preview.next})</span>
            </div>
          ) : null}
        </section>

        <section>
          <h2 className="font-semibold text-lg mb-3">3. Traceability Details</h2>
          <div className="grid sm:grid-cols-2 gap-3">
            <label className="block text-sm">
              Reason for Update
              <select className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5" value={reason} onChange={(e) => setReason(e.target.value)}>
                <option>New Delivery Received</option>
                <option>Correction / Recount</option>
                <option>Dispensed to Patient</option>
                <option>Expired Disposal</option>
                <option>Return to Supplier</option>
                <option>Transfer</option>
              </select>
            </label>
            <label className="block text-sm">
              Supplier / Source
              <input className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5" value={supplierName} onChange={(e) => setSupplierName(e.target.value)} />
            </label>
            <label className="block text-sm sm:col-span-2">
              Invoice / PO Number
              <input className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5" value={invoiceNo} onChange={(e) => setInvoiceNo(e.target.value)} />
            </label>
            <label className="block text-sm sm:col-span-2">
              Additional Notes
              <textarea className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5 min-h-[90px]" value={notes} onChange={(e) => setNotes(e.target.value)} />
            </label>
          </div>
        </section>

        <div className="flex justify-end gap-3">
          <Link to="/inventory" className="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold">Cancel</Link>
          <button type="submit" disabled={saving} className="rounded-xl bg-primary text-white px-5 py-2.5 text-sm font-semibold disabled:opacity-60">
            {saving ? 'Saving…' : 'Update Stock'}
          </button>
        </div>
      </form>
    </div>
  );
}
