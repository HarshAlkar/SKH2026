import { useState } from 'react';
import { Link, NavLink, Outlet } from 'react-router-dom';
import {
  LayoutDashboard,
  Package,
  RefreshCw,
  CalendarClock,
  AlertTriangle,
  Truck,
  History,
  BarChart3,
  MapPin,
  Settings,
  Menu,
  X,
  LogOut,
  Plus,
  Pill,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { useSync } from '../../context/SyncContext';
import ConnectionSwitcher from '../connection/ConnectionSwitcher';

const items = [
  { title: 'Dashboard', icon: LayoutDashboard, path: '/' },
  { title: 'Inventory', icon: Package, path: '/inventory' },
  { title: 'Update Stock', icon: RefreshCw, path: '/update-stock' },
  { title: 'Expiry Management', icon: CalendarClock, path: '/expiry' },
  { title: 'Low Stock', icon: AlertTriangle, path: '/low-stock' },
  { title: 'Suppliers', icon: Truck, path: '/suppliers' },
  { title: 'Stock History', icon: History, path: '/history' },
  { title: 'Map', icon: MapPin, path: '/map' },
  { title: 'Reports', icon: BarChart3, path: '/reports' },
  { title: 'Settings', icon: Settings, path: '/settings' },
];

export default function PharmacyLayout() {
  const { user, logout } = useAuth();
  const { online, pending, syncing, flush } = useSync();
  const [open, setOpen] = useState(false);
  const facilityName =
    user?.profile_details?.facility_name ||
    user?.village ||
    'VitalReach Pharmacy';

  return (
    <div className="min-h-screen bg-page flex">
      {open ? (
        <button type="button" className="fixed inset-0 z-30 bg-slate-900/40 lg:hidden" onClick={() => setOpen(false)} />
      ) : null}

      <aside
        className={`fixed lg:sticky top-0 z-40 h-screen w-64 bg-navy text-white flex flex-col shrink-0 transition-transform ${
          open ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
        }`}
      >
        <div className="p-5 flex items-center gap-3 border-b border-white/10">
          <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center">
            <Pill size={20} />
          </div>
          <div>
            <p className="font-bold leading-tight text-sm">VitalReach</p>
            <p className="text-xs text-white/60">Pharmacy Pro</p>
          </div>
        </div>

        <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-0.5">
          {items.map((item) => {
            const Icon = item.icon;
            return (
              <NavLink
                key={item.path}
                to={item.path}
                end={item.path === '/'}
                onClick={() => setOpen(false)}
                className={({ isActive }) =>
                  `flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-colors ${
                    isActive ? 'bg-primary text-white' : 'text-white/70 hover:bg-navy-light hover:text-white'
                  }`
                }
              >
                <Icon size={18} />
                {item.title}
              </NavLink>
            );
          })}
        </nav>

        <div className="p-4 border-t border-white/10 space-y-3">
          <ConnectionSwitcher variant="dark" />
          <Link
            to="/update-stock?add=1"
            className="flex items-center justify-center gap-2 w-full py-2.5 rounded-xl bg-sky-400 text-navy font-semibold text-sm hover:bg-sky-300"
          >
            <Plus size={16} /> Add Medicine
          </Link>
          <div className="flex items-center gap-3 px-1">
            <div className="w-9 h-9 rounded-full bg-primary/80 flex items-center justify-center text-sm font-bold">
              {(user?.name || user?.username || 'P').charAt(0).toUpperCase()}
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-sm font-semibold truncate">{user?.name || user?.username}</p>
              <p className="text-xs text-white/50 truncate">
                {user?.role === 'asha_worker' ? 'ASHA Worker' : 'Pharmacist'}
              </p>
            </div>
            <button type="button" onClick={logout} className="text-white/50 hover:text-white" title="Logout">
              <LogOut size={18} />
            </button>
          </div>
        </div>
      </aside>

      <div className="flex-1 min-w-0 flex flex-col">
        <header className="sticky top-0 z-20 bg-white/90 backdrop-blur border-b border-slate-200 px-4 lg:px-6 py-3">
          <div className="flex items-center gap-3">
            <button type="button" className="lg:hidden p-2 rounded-lg hover:bg-slate-100" onClick={() => setOpen(true)}>
              <Menu size={20} />
            </button>
            <div className="flex-1 min-w-0">
              <p className="font-semibold text-ink truncate">{facilityName}</p>
              <p className="text-xs text-muted">Medicine stock & availability</p>
            </div>
            <button
              type="button"
              onClick={flush}
              className={`text-xs font-semibold px-3 py-1.5 rounded-full border ${
                !online
                  ? 'bg-amber-50 text-amber-800 border-amber-200'
                  : pending > 0
                    ? 'bg-sky-50 text-sky-800 border-sky-200'
                    : 'bg-emerald-50 text-emerald-800 border-emerald-200'
              }`}
              title={lastErrorLabel(syncing, pending, online)}
            >
              {syncing
                ? 'Syncing…'
                : !online
                  ? `Offline${pending ? ` · ${pending} pending` : ''}`
                  : pending
                    ? `${pending} pending · tap to sync`
                    : 'Online'}
            </button>
            <button type="button" className="lg:hidden p-2" onClick={() => setOpen(false)}>
              {open ? <X size={18} /> : null}
            </button>
          </div>
        </header>
        <main className="flex-1 p-4 lg:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

function lastErrorLabel(syncing, pending, online) {
  if (syncing) return 'Uploading offline stock updates';
  if (!online) return 'Changes save locally until internet returns';
  if (pending) return 'Tap to flush pending stock updates';
  return 'All changes synced';
}
