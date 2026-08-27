import { useAuth } from '../context/AuthContext';
import { useSync } from '../context/SyncContext';
import { PageHeader } from '../components/ui/PageHeader';

export default function Settings() {
  const { user, logout } = useAuth();
  const { online, pending, syncing, flush } = useSync();
  const profile = user?.profile_details || {};

  return (
    <div>
      <PageHeader title="Settings" subtitle="Account and sync preferences" />
      <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-6 max-w-xl space-y-4">
        <div>
          <p className="text-xs text-muted uppercase tracking-wide">Signed in as</p>
          <p className="font-semibold text-lg">{user?.name || user?.username}</p>
          <p className="text-sm text-muted">
            {user?.role === 'asha_worker' ? 'ASHA Worker' : 'Medical Staff'} · {user?.village || '—'}
          </p>
        </div>
        {profile.facility_name ? (
          <div>
            <p className="text-xs text-muted uppercase tracking-wide">Facility</p>
            <p className="font-medium">{profile.facility_name}</p>
            <p className="text-sm text-muted">{profile.facility_village || profile.designation}</p>
          </div>
        ) : null}
        <div className="rounded-xl bg-slate-50 border border-slate-100 p-4 text-sm space-y-2">
          <p>
            Connection:{' '}
            <strong className={online ? 'text-emerald-700' : 'text-amber-700'}>
              {online ? 'Online' : 'Offline'}
            </strong>
          </p>
          <p>
            Pending sync: <strong>{pending}</strong> {syncing ? '(syncing…)' : ''}
          </p>
          <button
            type="button"
            onClick={flush}
            className="rounded-xl bg-primary text-white px-4 py-2 text-sm font-semibold"
          >
            Sync now
          </button>
        </div>
        <button
          type="button"
          onClick={logout}
          className="rounded-xl border border-rose-200 text-rose-700 px-4 py-2 text-sm font-semibold"
        >
          Log out
        </button>
      </div>
    </div>
  );
}
