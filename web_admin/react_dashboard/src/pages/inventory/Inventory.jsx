import { useCallback, useEffect, useMemo, useState } from 'react';
import { Package, AlertTriangle, CalendarClock, PackageX, MapPin } from 'lucide-react';
import { adminApi } from '../../services/apiService';
import { useResource } from '../../hooks/useResource';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import StatCard from '../../components/ui/StatCard';
import { DataTable } from '../../components/ui/DataTable';
import { Badge } from '../../components/ui/Badge';
import { Modal, Field, inputClass } from '../../components/ui/Modal';
import { toast } from '../../components/ui/Toast';
import EmergencyMap from '../../components/map/EmergencyMap';
import { useMapMarkers } from '../../hooks/useMapMarkers';

function stockTone(status) {
  if (status === 'in_stock') return 'blue';
  if (status === 'low_stock') return 'amber';
  if (status === 'expiring') return 'violet';
  if (status === 'expired' || status === 'out_of_stock') return 'rose';
  return 'slate';
}

function stockLabel(status) {
  return String(status || '').replace(/_/g, ' ');
}

export default function InventoryPage() {
  const [tab, setTab] = useState('batches');
  const [q, setQ] = useState('');
  const [status, setStatus] = useState('');
  const [stats, setStats] = useState(null);
  const [facilityOpen, setFacilityOpen] = useState(false);
  const [facilityForm, setFacilityForm] = useState({
    name: '',
    facility_type: 'pharmacy',
    village: '',
    district: '',
    latitude: '',
    longitude: '',
  });
  const [saving, setSaving] = useState(false);

  const fetchBatches = useCallback(
    () => adminApi.stockBatches({ q: q || undefined, status: status || undefined }),
    [q, status],
  );
  const fetchFacilities = useCallback(() => adminApi.facilities(), []);
  const fetchMovements = useCallback(() => adminApi.stockMovements(), []);

  const batches = useResource(fetchBatches);
  const facilities = useResource(fetchFacilities);
  const movements = useResource(fetchMovements);
  const { data: mapData } = useMapMarkers(true);

  useEffect(() => {
    adminApi.inventoryStats().then(setStats).catch(() => {});
  }, [batches.rows]);

  const saveFacility = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      await adminApi.createFacility({
        ...facilityForm,
        latitude: facilityForm.latitude === '' ? null : Number(facilityForm.latitude),
        longitude: facilityForm.longitude === '' ? null : Number(facilityForm.longitude),
      });
      toast('Facility created');
      setFacilityOpen(false);
      setFacilityForm({
        name: '',
        facility_type: 'pharmacy',
        village: '',
        district: '',
        latitude: '',
        longitude: '',
      });
      facilities.reload();
    } catch (err) {
      toast(err.message, 'error');
    } finally {
      setSaving(false);
    }
  };

  const batchColumns = useMemo(
    () => [
      {
        key: 'medicine',
        header: 'Medicine',
        render: (r) => (
          <div>
            <p className="font-semibold">{r.medicine_name}</p>
            <p className="text-xs text-muted">{r.sku} · {r.batch_no}</p>
          </div>
        ),
      },
      { key: 'facility_name', header: 'Facility' },
      {
        key: 'quantity',
        header: 'Qty',
        render: (r) => `${r.quantity} ${r.unit || ''}`,
      },
      {
        key: 'status',
        header: 'Status',
        render: (r) => <Badge tone={stockTone(r.status)}>{stockLabel(r.status)}</Badge>,
      },
      {
        key: 'expiry_date',
        header: 'Expiry',
        render: (r) => (
          <span className={r.days_to_expiry != null && r.days_to_expiry <= 30 ? 'text-rose-600 font-semibold' : ''}>
            {r.expiry_date}
          </span>
        ),
      },
      { key: 'reorder_level', header: 'Reorder' },
    ],
    [],
  );

  const tabs = [
    { id: 'batches', label: 'Stock Batches' },
    { id: 'facilities', label: 'Facilities' },
    { id: 'history', label: 'Stock History' },
    { id: 'map', label: 'Map' },
  ];

  return (
    <div>
      <PageHeader
        title="Medicine Inventory"
        subtitle="Monitor pharmacy/PHC stock across all facilities"
        actions={
          <button
            type="button"
            onClick={() => setFacilityOpen(true)}
            className="rounded-xl bg-primary text-white px-4 py-2 text-sm font-semibold"
          >
            + Add Facility
          </button>
        }
      />
      <ErrorBanner error={batches.error || facilities.error || movements.error} />

      <div className="grid sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
        <StatCard title="Total Medicines" value={stats?.total_medicines} icon={Package} />
        <StatCard title="Low Stock" value={stats?.low_stock} icon={AlertTriangle} color="bg-accent" />
        <StatCard title="Expiring Soon" value={stats?.expiring_soon} icon={CalendarClock} color="bg-orange-500" />
        <StatCard title="Out of Stock" value={stats?.out_of_stock} icon={PackageX} color="bg-rose-500" />
      </div>

      <div className="flex flex-wrap gap-2 mb-4">
        {tabs.map((t) => (
          <button
            key={t.id}
            type="button"
            onClick={() => setTab(t.id)}
            className={`px-3 py-1.5 rounded-lg text-sm font-semibold ${
              tab === t.id ? 'bg-primary text-white' : 'bg-white border border-slate-200 text-muted'
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      {tab === 'batches' ? (
        <>
          <div className="flex flex-wrap gap-2 mb-4">
            <input
              className="rounded-xl border border-slate-200 px-3 py-2 text-sm flex-1 min-w-[180px]"
              placeholder="Search medicine, batch, facility…"
              value={q}
              onChange={(e) => setQ(e.target.value)}
            />
            <select
              className="rounded-xl border border-slate-200 px-3 py-2 text-sm"
              value={status}
              onChange={(e) => setStatus(e.target.value)}
            >
              <option value="">All statuses</option>
              <option value="in_stock">In stock</option>
              <option value="low_stock">Low stock</option>
              <option value="expiring">Expiring</option>
              <option value="out_of_stock">Out of stock</option>
              <option value="expired">Expired</option>
            </select>
            <button
              type="button"
              onClick={batches.reload}
              className="rounded-xl bg-slate-900 text-white px-4 py-2 text-sm font-semibold"
            >
              Filter
            </button>
          </div>
          <DataTable
            columns={batchColumns}
            rows={batches.rows}
            loading={batches.loading}
            empty="No stock batches"
          />
        </>
      ) : null}

      {tab === 'facilities' ? (
        <DataTable
          loading={facilities.loading}
          rows={facilities.rows}
          empty="No facilities"
          columns={[
            { key: 'name', header: 'Name', render: (r) => (
              <div>
                <p className="font-semibold">{r.name}</p>
                <p className="text-xs text-muted">{r.facility_type}</p>
              </div>
            ) },
            { key: 'village', header: 'Village' },
            { key: 'district', header: 'District' },
            {
              key: 'coords',
              header: 'Coords',
              render: (r) =>
                r.latitude != null ? `${r.latitude.toFixed?.(4) ?? r.latitude}, ${r.longitude?.toFixed?.(4) ?? r.longitude}` : '—',
            },
            {
              key: 'health',
              header: 'Stock health',
              render: (r) => (
                <span className="text-xs text-muted">
                  Low {r.stock_health?.low_stock ?? 0} · Out {r.stock_health?.out_of_stock ?? 0}
                </span>
              ),
            },
            {
              key: 'active',
              header: 'Active',
              render: (r) => <Badge tone={r.is_active ? 'green' : 'slate'}>{r.is_active ? 'Yes' : 'No'}</Badge>,
            },
          ]}
        />
      ) : null}

      {tab === 'history' ? (
        <DataTable
          loading={movements.loading}
          rows={movements.rows}
          empty="No movements"
          columns={[
            {
              key: 'created_at',
              header: 'When',
              render: (r) => new Date(r.created_at).toLocaleString(),
            },
            { key: 'medicine_name', header: 'Medicine' },
            { key: 'facility_name', header: 'Facility' },
            { key: 'action', header: 'Action', render: (r) => <Badge>{r.action}</Badge> },
            {
              key: 'qty',
              header: 'Qty',
              render: (r) => `${r.previous_quantity} → ${r.new_quantity}`,
            },
            { key: 'actor_name', header: 'By' },
          ]}
        />
      ) : null}

      {tab === 'map' ? (
        <div>
          <div className="flex items-center gap-2 text-sm text-muted mb-3">
            <MapPin size={16} />
            Orange markers = pharmacies / PHCs with stock health
          </div>
          <EmergencyMap data={mapData} height={420} />
        </div>
      ) : null}

      <Modal open={facilityOpen} onClose={() => setFacilityOpen(false)} title="Add Facility">
        <form onSubmit={saveFacility} className="space-y-3">
          <Field label="Name">
            <input className={inputClass} value={facilityForm.name} onChange={(e) => setFacilityForm({ ...facilityForm, name: e.target.value })} required />
          </Field>
          <Field label="Type">
            <select className={inputClass} value={facilityForm.facility_type} onChange={(e) => setFacilityForm({ ...facilityForm, facility_type: e.target.value })}>
              <option value="pharmacy">Pharmacy</option>
              <option value="phc">PHC</option>
              <option value="hospital">Hospital</option>
            </select>
          </Field>
          <Field label="Village">
            <input className={inputClass} value={facilityForm.village} onChange={(e) => setFacilityForm({ ...facilityForm, village: e.target.value })} />
          </Field>
          <Field label="District">
            <input className={inputClass} value={facilityForm.district} onChange={(e) => setFacilityForm({ ...facilityForm, district: e.target.value })} />
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Latitude">
              <input className={inputClass} value={facilityForm.latitude} onChange={(e) => setFacilityForm({ ...facilityForm, latitude: e.target.value })} />
            </Field>
            <Field label="Longitude">
              <input className={inputClass} value={facilityForm.longitude} onChange={(e) => setFacilityForm({ ...facilityForm, longitude: e.target.value })} />
            </Field>
          </div>
          <button type="submit" disabled={saving} className="w-full rounded-xl bg-primary text-white py-2.5 font-semibold disabled:opacity-60">
            {saving ? 'Saving…' : 'Create Facility'}
          </button>
        </form>
      </Modal>
    </div>
  );
}
