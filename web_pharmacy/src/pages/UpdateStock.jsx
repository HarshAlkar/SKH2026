import { useEffect, useMemo, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { stockApi } from '../services/apiService';
import { useSync } from '../context/SyncContext';
import { PageHeader, ErrorBanner } from '../components/ui/PageHeader';

function asList(data) {
  if (Array.isArray(data)) return data;
  if (data && Array.isArray(data.results)) return data.results;
  return [];
}

function localISODate(offsetDays = 0) {
  const d = new Date();
  d.setDate(d.getDate() + offsetDays);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function defaultBatchNo() {
  return `BAT-${localISODate().replace(/-/g, '')}`;
}

function skuFromName(name) {
  const base = String(name || 'MED')
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 16);
  return `${base || 'MED'}-${Date.now().toString(36).slice(-4).toUpperCase()}`;
}

const fieldClass = 'mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5 bg-white';

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
  const [catalogQuery, setCatalogQuery] = useState('');
  const [newForm, setNewForm] = useState({
    facility_id: '',
    catalog_id: '',
    batch_no: defaultBatchNo(),
    expiry_date: localISODate(365),
    reorder_level: 20,
    new_name: '',
    new_sku: '',
    new_strength: '',
    new_form: 'Tablet',
  });

  const addingNewMedicine = newForm.catalog_id === '__new__';

  useEffect(() => {
    let cancelled = false;
    (async () => {
      const load = async (fn, fallback) => {
        try {
          return asList(await fn());
        } catch (e) {
          if (!cancelled) setError((prev) => prev || e.message);
          return fallback;
        }
      };
      const [b, c, f] = await Promise.all([
        load(() => stockApi.batches(), []),
        load(() => stockApi.catalog({ active: 1 }), []),
        load(() => stockApi.facilities(), []),
      ]);
      if (cancelled) return;
      setBatches(b);
      setCatalog(c);
      setFacilities(f);
      setNewForm((s) => ({
        ...s,
        facility_id: s.facility_id || (f[0] ? String(f[0].id) : ''),
        catalog_id: s.catalog_id || (c[0] ? String(c[0].id) : c.length ? '' : '__new__'),
      }));
      if (!params.get('batch') && b[0]) {
        setBatchId(String(b[0].id));
      }
      if (!c.length) {
        setError((prev) => prev || 'Medicine catalog is empty — add the medicine details below, then save.');
      }
    })();
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const selected = useMemo(
    () => batches.find((b) => String(b.id) === String(batchId)),
    [batches, batchId],
  );

  const filteredCatalog = useMemo(() => {
    const q = catalogQuery.trim().toLowerCase();
    if (!q) return catalog;
    return catalog.filter((c) => {
      const hay = `${c.display_name || ''} ${c.name || ''} ${c.sku || ''} ${c.strength || ''}`.toLowerCase();
      return hay.includes(q);
    });
  }, [catalog, catalogQuery]);

  const preview = useMemo(() => {
    const current = selected?.quantity ?? 0;
    const qty = Number(quantity) || 0;
    let next = current;
    if (action === 'add') next = current + qty;
    else if (action === 'adjust') next = qty;
    else next = Math.max(0, current - qty);
    return { current, qty, next };
  }, [selected, quantity, action]);

  const patchNew = (patch) => setNewForm((s) => ({ ...s, ...patch }));

  const ensureCatalogId = async () => {
    if (newForm.catalog_id && newForm.catalog_id !== '__new__') {
      return Number(newForm.catalog_id);
    }
    const name = newForm.new_name.trim();
    if (!name) throw new Error('Enter a medicine name, or pick one from the catalog.');
    const created = await stockApi.createCatalog({
      sku: (newForm.new_sku || skuFromName(name)).trim(),
      name,
      form: newForm.new_form || 'Tablet',
      strength: newForm.new_strength.trim(),
      category: 'General',
      unit: 'units',
      is_active: true,
    });
    setCatalog((prev) => [created, ...prev]);
    patchNew({ catalog_id: String(created.id) });
    return created.id;
  };

  const onSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setOk('');
    setSaving(true);
    try {
      let body;
      if (mode === 'new') {
        if (!newForm.facility_id) throw new Error('Select a facility');
        if (!newForm.batch_no.trim()) throw new Error('Enter a batch number');
        if (!newForm.expiry_date) throw new Error('Choose an expiry date');
        const catalogId = await ensureCatalogId();
        body = {
          facility_id: Number(newForm.facility_id),
          catalog_id: catalogId,
          batch_no: newForm.batch_no.trim(),
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
                className={fieldClass}
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
              {!batches.length ? (
                <p className="mt-2 text-xs text-amber-700">No batches yet. Switch to “New medicine / batch”.</p>
              ) : null}
            </label>
          ) : (
            <div className="grid sm:grid-cols-2 gap-4">
              <label className="block text-sm sm:col-span-2">
                Facility
                <select
                  className={fieldClass}
                  value={newForm.facility_id}
                  onChange={(e) => patchNew({ facility_id: e.target.value })}
                  required
                >
                  {!facilities.length ? <option value="">No facilities found</option> : null}
                  {facilities.map((f) => (
                    <option key={f.id} value={f.id}>{f.name}{f.village ? ` · ${f.village}` : ''}</option>
                  ))}
                </select>
              </label>
              <label className="block text-sm sm:col-span-2">
                Search catalog
                <input
                  className={fieldClass}
                  placeholder="Type to filter: paracetamol, AMOX, 500mg…"
                  value={catalogQuery}
                  onChange={(e) => setCatalogQuery(e.target.value)}
                />
              </label>
              <label className="block text-sm sm:col-span-2">
                Medicine
                <select
                  className={fieldClass}
                  value={newForm.catalog_id}
                  onChange={(e) => patchNew({ catalog_id: e.target.value })}
                  required
                >
                  <option value="">Select catalog item</option>
                  {filteredCatalog.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.display_name || c.name} {c.sku ? `(${c.sku})` : ''}
                    </option>
                  ))}
                  <option value="__new__">+ Add a medicine not in this list</option>
                </select>
                {!catalog.length ? (
                  <p className="mt-2 text-xs text-amber-700">Catalog is empty. Use “Add a medicine not in this list”.</p>
                ) : null}
              </label>
              {addingNewMedicine ? (
                <>
                  <label className="block text-sm">
                    New medicine name
                    <input
                      className={fieldClass}
                      placeholder="e.g. Paracetamol"
                      value={newForm.new_name}
                      onChange={(e) => patchNew({ new_name: e.target.value })}
                      required
                    />
                  </label>
                  <label className="block text-sm">
                    Strength
                    <input
                      className={fieldClass}
                      placeholder="e.g. 500mg"
                      value={newForm.new_strength}
                      onChange={(e) => patchNew({ new_strength: e.target.value })}
                    />
                  </label>
                  <label className="block text-sm">
                    Form
                    <select
                      className={fieldClass}
                      value={newForm.new_form}
                      onChange={(e) => patchNew({ new_form: e.target.value })}
                    >
                      <option>Tablet</option>
                      <option>Capsule</option>
                      <option>Syrup</option>
                      <option>Injection</option>
                      <option>Ointment</option>
                      <option>Drops</option>
                    </select>
                  </label>
                  <label className="block text-sm">
                    SKU (optional)
                    <input
                      className={fieldClass}
                      placeholder="Auto-generated if blank"
                      value={newForm.new_sku}
                      onChange={(e) => patchNew({ new_sku: e.target.value })}
                    />
                  </label>
                </>
              ) : null}
              <label className="block text-sm">
                Batch Number
                <input
                  className={fieldClass}
                  placeholder="e.g. BAT-20260830"
                  value={newForm.batch_no}
                  onChange={(e) => patchNew({ batch_no: e.target.value })}
                  required
                />
              </label>
              <label className="block text-sm">
                Expiry Date
                <input
                  type="date"
                  className={fieldClass}
                  value={newForm.expiry_date}
                  onChange={(e) => patchNew({ expiry_date: e.target.value })}
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
              <select className={fieldClass} value={action} onChange={(e) => setAction(e.target.value)}>
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
                className={fieldClass}
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
              <select className={fieldClass} value={reason} onChange={(e) => setReason(e.target.value)}>
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
              <input className={fieldClass} value={supplierName} onChange={(e) => setSupplierName(e.target.value)} />
            </label>
            <label className="block text-sm sm:col-span-2">
              Invoice / PO Number
              <input className={fieldClass} value={invoiceNo} onChange={(e) => setInvoiceNo(e.target.value)} />
            </label>
            <label className="block text-sm sm:col-span-2">
              Additional Notes
              <textarea className={`${fieldClass} min-h-[90px]`} value={notes} onChange={(e) => setNotes(e.target.value)} />
            </label>
          </div>
        </section>

        <div className="sticky bottom-0 -mx-6 -mb-6 px-6 py-4 bg-white/95 backdrop-blur border-t border-slate-100 flex justify-end gap-3">
          <Link to="/inventory" className="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold">Cancel</Link>
          <button type="submit" disabled={saving} className="rounded-xl bg-primary text-white px-5 py-2.5 text-sm font-semibold disabled:opacity-60">
            {saving ? 'Saving…' : 'Update Stock'}
          </button>
        </div>
      </form>
    </div>
  );
}
