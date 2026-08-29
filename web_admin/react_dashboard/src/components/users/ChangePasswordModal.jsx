import { useEffect, useState } from 'react';
import { Modal, Field, inputClass } from '../ui/Modal';
import { toast } from '../ui/Toast';
import { useAuth } from '../../context/AuthContext';

export function useChangePassword() {
  const { replaceToken } = useAuth();
  const [target, setTarget] = useState(null);
  const [saving, setSaving] = useState(false);

  const submit = async (password) => {
    if (!target?.request) return;
    setSaving(true);
    try {
      const result = await target.request(password);
      if (result?.token) replaceToken(result.token);
      toast('Password updated');
      setTarget(null);
    } catch (err) {
      toast(err.message, 'error');
    } finally {
      setSaving(false);
    }
  };

  return { target, setTarget, saving, submit };
}

export default function ChangePasswordModal({
  open,
  title = 'Change password',
  subtitle,
  onClose,
  onSubmit,
  saving = false,
}) {
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    if (open) {
      setPassword('');
      setConfirm('');
      setError('');
    }
  }, [open]);

  const submit = async (e) => {
    e.preventDefault();
    if (password.length < 8) {
      setError('Password must be at least 8 characters.');
      return;
    }
    if (password !== confirm) {
      setError('Passwords do not match.');
      return;
    }
    setError('');
    await onSubmit(password);
  };

  return (
    <Modal open={open} title={title} onClose={onClose}>
      {subtitle ? <p className="text-sm text-muted -mt-2 mb-3">{subtitle}</p> : null}
      <form onSubmit={submit}>
        {error ? (
          <div className="mb-3 rounded-lg bg-rose-50 text-rose-700 text-sm px-3 py-2">{error}</div>
        ) : null}
        <Field label="New password">
          <input
            type="password"
            className={inputClass}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="new-password"
            minLength={8}
            required
          />
        </Field>
        <Field label="Confirm password">
          <input
            type="password"
            className={inputClass}
            value={confirm}
            onChange={(e) => setConfirm(e.target.value)}
            autoComplete="new-password"
            minLength={8}
            required
          />
        </Field>
        <p className="text-xs text-muted mb-3">
          This immediately replaces the current password. The user will need to sign in again.
        </p>
        <button
          type="submit"
          disabled={saving}
          className="w-full rounded-lg bg-primary text-white py-2.5 font-semibold disabled:opacity-60"
        >
          {saving ? 'Updating…' : 'Update password'}
        </button>
      </form>
    </Modal>
  );
}
