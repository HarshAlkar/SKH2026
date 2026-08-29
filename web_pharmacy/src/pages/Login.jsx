import { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { Pill } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import ConnectionSwitcher from '../components/connection/ConnectionSwitcher';

export default function Login() {
  const { isAuthed, login } = useAuth();
  const [identifier, setIdentifier] = useState('pharmacist');
  const [password, setPassword] = useState('pharma123');
  const [role, setRole] = useState('medical_staff');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  if (isAuthed) return <Navigate to="/" replace />;

  const onSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(identifier.trim(), password, role);
    } catch (err) {
      setError(err.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-navy flex items-center justify-center p-4">
      <form onSubmit={onSubmit} className="w-full max-w-md bg-white rounded-3xl p-8 shadow-xl space-y-5">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-2xl bg-primary text-white grid place-items-center">
            <Pill size={24} />
          </div>
          <div>
            <h1 className="text-xl font-bold text-ink">VitalReach Pharmacy</h1>
            <p className="text-sm text-muted">Stock update portal</p>
          </div>
        </div>

        {error ? (
          <div className="rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-sm px-3 py-2">{error}</div>
        ) : null}

        <label className="block text-sm font-medium text-ink">
          Role
          <select
            className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5"
            value={role}
            onChange={(e) => setRole(e.target.value)}
          >
            <option value="medical_staff">Medical Staff / Pharmacist</option>
            <option value="asha_worker">ASHA Worker</option>
          </select>
        </label>

        <label className="block text-sm font-medium text-ink">
          Username / Phone
          <input
            className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5"
            value={identifier}
            onChange={(e) => setIdentifier(e.target.value)}
            autoComplete="username"
          />
        </label>

        <label className="block text-sm font-medium text-ink">
          Password
          <input
            type="password"
            className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="current-password"
          />
        </label>

        <button
          type="submit"
          disabled={loading}
          className="w-full rounded-xl bg-primary text-white font-semibold py-3 hover:bg-primary-dark disabled:opacity-60"
        >
          {loading ? 'Signing in…' : 'Sign in'}
        </button>

        <p className="text-xs text-muted text-center">
          Demo: pharmacist / pharma123 (Medical Staff)
        </p>
        <ConnectionSwitcher />
        <p className="text-[11px] text-muted text-center">
          Auto uses the PC Wi-Fi Django server when it is running, otherwise cloud.
        </p>
      </form>
    </div>
  );
}
