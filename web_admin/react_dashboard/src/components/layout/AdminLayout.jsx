import { useState } from 'react';
import { Link, NavLink, Outlet, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  Users,
  Stethoscope,
  UserRound,
  History,
  FileText,
  BarChart3,
  Bell,
  HeartPulse,
  Pill,
  Package,
  MapPin,
  Brain,
  MessageSquare,
  Menu,
  X,
  LogOut,
  Activity,
  AlertTriangle,
  Settings,
  Search,
  HelpCircle,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { ToastHost } from '../ui/Toast';

const items = [
  { title: 'Dashboard', icon: LayoutDashboard, path: '/' },
  { title: 'Patients', icon: Users, path: '/patients' },
  { title: 'Doctors', icon: Stethoscope, path: '/doctors' },
  { title: 'ASHA Workers', icon: UserRound, path: '/asha-workers' },
  { title: 'Consultations', icon: History, path: '/consultations' },
  { title: 'Prescriptions', icon: FileText, path: '/prescriptions' },
  { title: 'Alerts', icon: Bell, path: '/alerts' },
  { title: 'Health Records', icon: HeartPulse, path: '/records' },
  { title: 'Inventory', icon: Package, path: '/inventory' },
  { title: 'Medicine Schedules', icon: Pill, path: '/medicines' },
  { title: 'Village Visits', icon: MapPin, path: '/visits' },
  { title: 'AI Analyses', icon: Brain, path: '/symptoms' },
  { title: 'Chat', icon: MessageSquare, path: '/chat' },
  { title: 'Reports', icon: BarChart3, path: '/reports' },
];

export default function AdminLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState('');
  const initial = (user?.name || user?.username || 'A').charAt(0).toUpperCase();

  const onSearchSubmit = (e) => {
    e.preventDefault();
    const q = search.trim();
    if (q) navigate(`/patients?q=${encodeURIComponent(q)}`);
  };

  return (
    <div className="min-h-screen bg-page flex">
      {open ? (
        <button type="button" className="fixed inset-0 z-30 bg-slate-900/40 lg:hidden" onClick={() => setOpen(false)} />
      ) : null}

      <aside
        className={`fixed lg:sticky top-0 z-40 h-screen w-64 bg-white border-r border-slate-200 flex flex-col shrink-0 transition-transform ${
          open ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
        }`}
      >
        <div className="p-5 flex items-center gap-3 border-b border-slate-100">
          <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center text-white">
            <Activity size={22} />
          </div>
          <div>
            <p className="font-bold leading-tight text-primary">VitalReach</p>
            <p className="text-xs text-muted">Healthcare Admin</p>
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
                  `flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors border-l-4 ${
                    isActive
                      ? 'bg-light text-primary border-primary'
                      : 'text-muted border-transparent hover:bg-slate-50 hover:text-ink'
                  }`
                }
              >
                <Icon size={18} />
                {item.title}
              </NavLink>
            );
          })}
        </nav>

        <div className="p-3 space-y-2 border-t border-slate-100">
          <button
            type="button"
            onClick={() => navigate('/alerts')}
            className="w-full flex items-center justify-center gap-2 rounded-xl bg-rose-600 hover:bg-rose-700 text-white py-2.5 text-sm font-semibold"
          >
            <AlertTriangle size={16} />
            Urgent Alert
          </button>
          <NavLink
            to="/reports"
            className="flex items-center gap-2 px-3 py-2 text-sm text-muted hover:text-ink rounded-lg hover:bg-slate-50"
          >
            <Settings size={16} />
            Settings
          </NavLink>
          <button
            type="button"
            onClick={logout}
            className="w-full flex items-center gap-2 px-3 py-2 text-sm text-rose-600 hover:bg-rose-50 rounded-lg"
          >
            <LogOut size={16} />
            Logout
          </button>
        </div>
      </aside>

      <div className="flex-1 min-w-0 flex flex-col">
        <header className="sticky top-0 z-20 bg-white/95 backdrop-blur border-b border-slate-100 px-4 lg:px-8 h-16 flex items-center gap-4">
          <button type="button" className="lg:hidden text-ink" onClick={() => setOpen(true)}>
            {open ? <X size={22} /> : <Menu size={22} />}
          </button>
          <p className="hidden md:block font-semibold text-ink shrink-0">VitalReach Admin</p>
          <form onSubmit={onSearchSubmit} className="flex-1 max-w-xl mx-auto hidden sm:block">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={16} />
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search patients, doctors, records..."
                className="w-full pl-9 pr-3 py-2 rounded-full border border-slate-200 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-light bg-slate-50"
              />
            </div>
          </form>
          <div className="flex items-center gap-2 ml-auto">
            <Link to="/alerts" className="p-2 rounded-lg hover:bg-slate-50 text-muted relative" title="Alerts">
              <Bell size={20} />
            </Link>
            <button type="button" className="p-2 rounded-lg hover:bg-slate-50 text-muted hidden sm:block" title="Help">
              <HelpCircle size={20} />
            </button>
            <div className="w-9 h-9 rounded-full bg-primary text-white flex items-center justify-center font-bold text-sm">
              {initial}
            </div>
          </div>
        </header>
        <main className="flex-1 p-4 lg:p-8">
          <Outlet />
        </main>
      </div>
      <ToastHost />
    </div>
  );
}
