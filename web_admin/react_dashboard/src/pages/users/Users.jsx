import { useCallback, useMemo, useState } from 'react';
import { KeyRound, Shield } from 'lucide-react';
import { adminApi } from '../../services/apiService';
import { useResource } from '../../hooks/useResource';
import { useDebounce } from '../../hooks/useDebounce';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import FilterBar, { FilterSelect } from '../../components/ui/FilterBar';
import AvatarInitials from '../../components/ui/AvatarInitials';
import { DataTable } from '../../components/ui/DataTable';
import { Badge } from '../../components/ui/Badge';
import { Modal, Field, inputClass } from '../../components/ui/Modal';
import { toast } from '../../components/ui/Toast';
import ChangePasswordModal, { useChangePassword } from '../../components/users/ChangePasswordModal';

const ROLE_LABELS = {
  user: 'Patient',
  doctor: 'Doctor',
  asha_worker: 'ASHA Worker',
  medical_staff: 'Medical Staff',
};

const ROLE_TONES = {
  user: 'blue',
  doctor: 'violet',
  asha_worker: 'green',
  medical_staff: 'amber',
};

const emptyAccount = {
  name: '',
  phone_number: '',
  password: '',
  role: 'medical_staff',
  village: '',
  facility_id: '',
  designation: 'Pharmacist',
};

function moduleLabel(row) {
  if (row.is_staff) return row.role === 'user' ? 'Staff Admin' : `${ROLE_LABELS[row.role] || row.role} · Staff`;
  return ROLE_LABELS[row.role] || row.role;
}

export default function UsersPage() {
  const [q, setQ] = useState('');
  const [role, setRole] = useState('');
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState(emptyAccount);
  const [saving, setSaving] = useState(false);
  const debouncedQ = useDebounce(q, 300);
  const password = useChangePassword();

  const fetchList = useCallback(() => {
    const params = {};
    if (debouncedQ) params.q = debouncedQ;
    if (role === 'staff') params.is_staff = true;
    else if (role) params.role = role;
    return adminApi.users(params);
  }, [debouncedQ, role]);
  const { rows, loading, error, reload } = useResource(fetchList);
  const facilities = useResource(useCallback(() => adminApi.facilities(), []));

  const stats = useMemo(() => {
    const byRole = (value) => rows.filter((r) => r.role === value).length;
    return {
      total: rows.length,
      staff: rows.filter((r) => r.is_staff).length,
      medical: byRole('medical_staff'),
    };
  }, [rows]);

  const save = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      const payload = {
        name: form.name,
        phone_number: form.phone_number,
        password: form.password,
        role: form.role,
        village: form.village,
      };
      if (form.role === 'asha_worker') {
        payload.assigned_village = form.village;
        payload.village = form.village;
      }
      if (form.role === 'medical_staff') {
        payload.facility_id = form.facility_id ? Number(form.facility_id) : null;
        payload.designation = form.designation;
      }
      await adminApi.createUser(payload);
      toast('Account created');
      setOpen(false);
      setForm(emptyAccount);
      reload();
    } catch (err) {
      toast(err.message, 'error');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <PageHeader
        title="Account Passwords"
        subtitle="Reset login passwords for every module: patients, doctors, ASHA workers, medical staff, and staff admins."
        actions={
          <button
            type="button"
            className="rounded-lg bg-primary text-white px-4 py-2 text-sm font-semibold"
            onClick={() => {
              setForm(emptyAccount);
              setOpen(true);
            }}
          >
            + Add account
          </button>
        }
      />
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <div className="bg-white rounded-2xl border border-slate-100 p-4">
          <p className="text-xs text-muted">Visible accounts</p>
          <p className="text-2xl font-bold">{stats.total}</p>
        </div>
        <div className="bg-white rounded-2xl border border-slate-100 p-4">
          <p className="text-xs text-muted">Medical staff</p>
          <p className="text-2xl font-bold">{stats.medical}</p>
        </div>
        <div className="bg-white rounded-2xl border border-slate-100 p-4">
          <p className="text-xs text-muted">Staff admins</p>
          <p className="text-2xl font-bold">{stats.staff}</p>
        </div>
      </div>
      <FilterBar search={q} onSearchChange={setQ} searchPlaceholder="Search name, phone, email...">
        <FilterSelect
          label="Module"
          value={role}
          onChange={setRole}
          options={[
            ['', 'All modules'],
            ['user', 'Patients'],
            ['doctor', 'Doctors'],
            ['asha_worker', 'ASHA Workers'],
            ['medical_staff', 'Medical Staff'],
            ['staff', 'Staff Admins'],
          ]}
        />
      </FilterBar>
      <ErrorBanner error={error} onRetry={reload} />
      <DataTable
        loading={loading}
        rows={rows}
        empty="No accounts found."
        columns={[
          {
            key: 'name',
            header: 'Account',
            render: (r) => (
              <div className="flex items-center gap-3">
                <AvatarInitials name={r.name || r.username} size="sm" />
                <div>
                  <p className="font-medium">{r.name || r.username}</p>
                  <p className="text-xs text-muted">{r.username}</p>
                </div>
              </div>
            ),
          },
          { key: 'phone_number', header: 'Phone' },
          {
            key: 'role',
            header: 'Module',
            render: (r) => <Badge tone={ROLE_TONES[r.role] || 'slate'}>{moduleLabel(r)}</Badge>,
          },
          {
            key: 'village',
            header: 'Location',
            render: (r) =>
              r.profile_details?.facility_name || r.village || r.profile_details?.assigned_village || '—',
          },
          {
            key: 'is_active',
            header: 'Status',
            render: (r) => <Badge tone={r.is_active ? 'green' : 'rose'}>{r.is_active ? 'Active' : 'Inactive'}</Badge>,
          },
          {
            key: 'actions',
            header: '',
            render: (r) => (
              <button
                type="button"
                className="text-primary text-xs font-semibold inline-flex items-center gap-1"
                onClick={() =>
                  password.setTarget({
                    name: r.name || r.username,
                    userId: r.id,
                    request: (pw) => adminApi.setUserPassword(r.id, pw),
                  })
                }
              >
                <KeyRound size={14} />
                Password
              </button>
            ),
          },
        ]}
      />

      <ChangePasswordModal
        open={!!password.target}
        title="Change password"
        subtitle={password.target ? `Module account: ${password.target.name}` : ''}
        onClose={() => password.setTarget(null)}
        onSubmit={password.submit}
        saving={password.saving}
      />

      <Modal open={open} title="Add module account" onClose={() => setOpen(false)}>
        <form onSubmit={save}>
          <Field label="Module">
            <select
              className={inputClass}
              value={form.role}
              onChange={(e) => setForm({ ...form, role: e.target.value })}
            >
              <option value="user">Patient</option>
              <option value="doctor">Doctor</option>
              <option value="asha_worker">ASHA Worker</option>
              <option value="medical_staff">Medical Staff / Pharmacy</option>
            </select>
          </Field>
          <Field label="Full name">
            <input className={inputClass} required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          </Field>
          <Field label="Phone">
            <input className={inputClass} required value={form.phone_number} onChange={(e) => setForm({ ...form, phone_number: e.target.value })} />
          </Field>
          <Field label="Password">
            <input
              type="password"
              className={inputClass}
              required
              minLength={8}
              value={form.password}
              onChange={(e) => setForm({ ...form, password: e.target.value })}
            />
          </Field>
          {form.role === 'user' || form.role === 'asha_worker' ? (
            <Field label={form.role === 'asha_worker' ? 'Assigned village' : 'Village'}>
              <input
                className={inputClass}
                required={form.role === 'user'}
                value={form.village}
                onChange={(e) => setForm({ ...form, village: e.target.value })}
              />
            </Field>
          ) : null}
          {form.role === 'medical_staff' ? (
            <>
              <Field label="Facility">
                <select
                  className={inputClass}
                  value={form.facility_id}
                  onChange={(e) => setForm({ ...form, facility_id: e.target.value })}
                >
                  <option value="">Unassigned</option>
                  {facilities.rows.map((f) => (
                    <option key={f.id} value={f.id}>
                      {f.name} ({f.facility_type})
                    </option>
                  ))}
                </select>
              </Field>
              <Field label="Designation">
                <input className={inputClass} value={form.designation} onChange={(e) => setForm({ ...form, designation: e.target.value })} />
              </Field>
            </>
          ) : null}
          <p className="text-xs text-muted mb-3 inline-flex items-center gap-1">
            <Shield size={12} />
            Staff admin logins are created separately. Use Password on any row to reset an existing account.
          </p>
          <button type="submit" disabled={saving} className="w-full rounded-lg bg-primary text-white py-2.5 font-semibold">
            {saving ? 'Creating…' : 'Create account'}
          </button>
        </form>
      </Modal>
    </div>
  );
}
