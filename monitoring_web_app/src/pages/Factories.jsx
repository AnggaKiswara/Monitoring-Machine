import { useEffect, useState } from 'react';
import { useAuth } from '../auth/AuthContext';
import { API } from '../lib/api';
import { Card, Button, HealthBadge } from '../components/ui';
import { Modal, Field, inputClass } from '../components/Modal';
import { useToast } from '../components/Toast';

export default function Factories() {
  const { token } = useAuth();
  const toast = useToast();
  const [factories, setFactories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({ nama_factory: '', lokasi_factory: '' });

  async function load() {
    const res = await API.getFactories(token);
    setFactories(res.data ?? res);
    setLoading(false);
  }
  useEffect(() => {
    load();
  }, [token]);

  function openAdd() {
    setEditing(null);
    setForm({ nama_factory: '', lokasi_factory: '' });
    setModal(true);
  }
  function openEdit(f) {
    setEditing(f);
    setForm({ nama_factory: f.nama_factory, lokasi_factory: f.lokasi_factory || '' });
    setModal(true);
  }

  async function save() {
    try {
      if (editing) {
        await API.updateFactory(token, editing.id_factory, form);
        toast.notify('Pabrik diperbarui', 'success');
      } else {
        await API.createFactory(token, form);
        toast.notify('Pabrik ditambahkan', 'success');
      }
      setModal(false);
      load();
    } catch (e) {
      toast.notify(e.message, 'error');
    }
  }

  async function remove(f) {
    if (!confirm(`Hapus pabrik "${f.nama_factory}"? Station & lori ikut terhapus.`)) return;
    try {
      await API.deleteFactory(token, f.id_factory);
      toast.notify('Pabrik dihapus', 'success');
      load();
    } catch (e) {
      toast.notify(e.message, 'error');
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-extrabold text-navy">Pabrik</h1>
          <p className="text-indigo-500 text-sm">Kelola data awal pabrik</p>
        </div>
        <Button onClick={openAdd}>+ Tambah Pabrik</Button>
      </div>

      {loading ? (
        <p className="text-navy/60">Memuat...</p>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {factories.map((f) => (
            <Card key={f.id_factory} className="p-5">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <span className="text-2xl">🏭</span>
                  <div>
                    <p className="font-bold text-navy">{f.nama_factory}</p>
                    <p className="text-sm text-navy/60">{f.lokasi_factory || '-'}</p>
                  </div>
                </div>
                <HealthBadge value={f.health_factory} />
              </div>
              <div className="flex gap-2 mt-4">
                <Button variant="ghost" onClick={() => openEdit(f)}>
                  Edit
                </Button>
                <Button variant="danger" onClick={() => remove(f)}>
                  Hapus
                </Button>
              </div>
            </Card>
          ))}
          {!factories.length && (
            <p className="text-navy/50 col-span-full">Belum ada pabrik.</p>
          )}
        </div>
      )}

      <Modal
        open={modal}
        title={editing ? 'Edit Pabrik' : 'Tambah Pabrik'}
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
        <Field label="Nama Pabrik">
          <input
            className={inputClass}
            value={form.nama_factory}
            onChange={(e) => setForm({ ...form, nama_factory: e.target.value })}
          />
        </Field>
        <Field label="Lokasi">
          <input
            className={inputClass}
            value={form.lokasi_factory}
            onChange={(e) => setForm({ ...form, lokasi_factory: e.target.value })}
          />
        </Field>
      </Modal>
    </div>
  );
}
