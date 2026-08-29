import { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { ShieldCheck } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import ConnectionSwitcher from '../../components/connection/ConnectionSwitcher';

export default function LoginPage() {
  const { isAuthed, login } = useAuth();
  const [username, setUsername] = useState('admin');
  const [password, setPassword] = useState('admin123');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  if (isAuthed) return <Navigate to="/" replace />;

  const onSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(username.trim(), password);
    } catch (err) {
      setError(err.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-page flex items-center justify-center p-6">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-light text-primary mb-3">
            <ShieldCheck size={32} />
          </div>
          <h1 className="text-2xl font-bold text-ink">VitalReach Admin</h1>
          <p className="text-muted text-sm mt-1">Healthcare reaching everywhere</p>
        </div>
        <form onSubmit={onSubmit} className="bg-white rounded-2xl border border-slate-100 shadow-sm p-6">
          {error ? (
            <div className="mb-4 rounded-lg bg-rose-50 text-rose-700 text-sm px-3 py-2">{error}</div>
          ) : null}
          <label className="block mb-3">
            <span className="text-sm font-medium">Username, email, or phone</span>
            <input
              className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-primary focus:ring-2 focus:ring-light"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              autoComplete="username"
            />
          </label>
          <label className="block mb-5">
            <span className="text-sm font-medium">Password</span>
            <input
              type="password"
              className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-primary focus:ring-2 focus:ring-light"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
            />
          </label>
          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-lg bg-primary hover:bg-primary-dark disabled:opacity-60 text-white font-semibold py-2.5"
          >
            {loading ? 'Signing in…' : 'Sign in'}
          </button>
          <p className="text-xs text-muted mt-4 text-center">
            Default staff account: <span className="font-semibold">admin / admin123</span>
          </p>
          <div className="mt-4">
            <ConnectionSwitcher />
          </div>
          <p className="text-[11px] text-muted mt-3 text-center">
            Auto uses the PC Wi-Fi Django server when it is running, otherwise cloud.
          </p>
        </form>
      </div>
    </div>
  );
}
