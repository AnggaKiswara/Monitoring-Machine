import { useEffect, useState } from 'react';
import { useAuth } from '../auth/AuthContext';
import { API } from '../lib/api';
import { Card, Button, StatusBadge } from '../components/ui';
import { Modal, Field, inputClass } from '../components/Modal';
import { useToast } from '../components/Toast';

export default function Users() {
  const { token } = useAuth();
  const toast = useToast();
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({
    nama_lengkap: '',
    username: '',
    password: '',
    role_user: 'teknisi',
  });

  async function load() {
    const res = await API.getUsers(token);
    setUsers(res.data ?? res);
    setLoading(false);
  }
  useEffect(() => {
    load();
  }, [token]);

  function openAdd() {
    setEditing(null);
    setForm({ nama_lengkap: '', username: '', password: '', role_user: 'teknisi' });
    setModal(true);
  }
  function openEdit(u) {
    setEditing(u);
    setForm({ nama_lengkap: u.nama_lengkap, username: u.username, password: '', role_user: u.role_user });
    setModal(true);
  }

  async function save() {
    try {
      if (editing) {
        const body = { nama_lengkap: form.nama_lengkap, role_user: form.role_user };
        await API.updateUser(token, editing.id_user, body);
      } else {
        if (!form.password) {
          toast.notify('Password wajib diisi', 'warning');
          return;
        }
        await API.registerUser(token, {
          nama_lengkap: form.nama_lengkap,
          username: form.username,
          password: form.password,
          role_user: form.role_user,
        });
      }
      toast.notify('User disimpan', 'success');
      setModal(false);
      load();
    } catch (e) {
      toast.notify(e.message, 'error');
    }
  }

  async function toggleActive(u) {
    try {
      await API.setUserActive(token, u.id_user, !u.is_active);
      toast.notify(u.is_active ? 'User dinonaktifkan' : 'User diaktifkan', 'success');
      load();
    } catch (e) {
      toast.notify(e.message, 'error');
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-navy">User</h1>
          <p className="text-gray-500 text-sm">Kelola akun & role</p>
        </div>
        <Button onClick={openAdd}>+ Tambah User</Button>
      </div>

      {loading ? (
        <p className="text-gray-500">Memuat...</p>
      ) : (
        <Card className="overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-gray-500 border-b bg-gray-50">
                <th className="py-3 px-4">Username</th>
                <th className="px-4">Nama</th>
                <th className="px-4">Role</th>
                <th className="px-4">Status</th>
                <th className="px-4"></th>
              </tr>
            </thead>
            <tbody>
              {users.map((u) => (
                <tr key={u.id_user} className="border-b border-gray-50">
                  <td className="py-3 px-4 font-medium text-navy">{u.username}</td>
                  <td className="px-4">{u.nama_lengkap}</td>
                  <td className="px-4">{u.role_user}</td>
                  <td className="px-4">
                    <StatusBadge active={u.is_active} />
                  </td>
                  <td className="px-4 text-right">
                    <button onClick={() => openEdit(u)} className="text-brand mr-3">
                      Edit
                    </button>
                    <button onClick={() => toggleActive(u)} className="text-gray-600">
                      {u.is_active ? 'Non-aktifkan' : 'Aktifkan'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}

      <Modal
        open={modal}
        title={editing ? 'Edit User' : 'Tambah User'}
        onClose={() => setModal(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setModal(false)}>
              Batal
            </Button>
            <Button onClick={save}>Simpan</Button>
          </>
        }
      >
        <Field label="Nama Lengkap">
          <input className={inputClass} value={form.nama_lengkap} onChange={(e) => setForm({ ...form, nama_lengkap: e.target.value })} />
        </Field>
        <Field label="Username">
          <input className={inputClass} value={form.username} disabled={editing} onChange={(e) => setForm({ ...form, username: e.target.value })} />
        </Field>
        <Field label={editing ? 'Password (kosongkan jika tidak diubah)' : 'Password'}>
          <input type="password" className={inputClass} value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} />
        </Field>
        <Field label="Role">
          <select className={inputClass} value={form.role_user} onChange={(e) => setForm({ ...form, role_user: e.target.value })}>
            <option value="admin">admin</option>
            <option value="staff">staff</option>
            <option value="teknisi">teknisi</option>
          </select>
        </Field>
      </Modal>
    </div>
  );
}
