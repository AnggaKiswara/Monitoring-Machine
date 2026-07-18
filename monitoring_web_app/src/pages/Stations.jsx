import { useEffect, useState } from 'react';
import { useAuth } from '../auth/AuthContext';
import { API } from '../lib/api';
import { Card, Button, HealthBadge } from '../components/ui';
import { Modal, Field, inputClass } from '../components/Modal';
import { useToast } from '../components/Toast';

export default function Stations() {
  const { token } = useAuth();
  const toast = useToast();
  const [factories, setFactories] = useState([]);
  const [selectedFactory, setSelectedFactory] = useState('');
  const [stations, setStations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({ id_factory: '', nama_station: '', lokasi_station: '' });

  async function loadFactories() {
    const res = await API.getFactories(token);
    const f = res.data ?? res;
    setFactories(f);
    if (!selectedFactory && f.length) setSelectedFactory(String(f[0].id_factory));
  }
  async function loadStations() {
    if (!selectedFactory) {
      setStations([]);
      setLoading(false);
      return;
    }
    const res = await API.getStations(token, selectedFactory);
    setStations(res.data ?? res);
    setLoading(false);
  }
  useEffect(() => {
    loadFactories();
  }, [token]);
  useEffect(() => {
    loadStations();
  }, [selectedFactory]);

  function openAdd() {
    setEditing(null);
    setForm({ id_factory: selectedFactory, nama_station: '', lokasi_station: '' });
    setModal(true);
  }
  function openEdit(s) {
    setEditing(s);
    setForm({
      id_factory: String(s.id_factory),
      nama_station: s.nama_station,
      lokasi_station: s.lokasi_station || '',
    });
    setModal(true);
  }

  async function save() {
    if (!form.id_factory) {
      toast.notify('Pilih pabrik dulu', 'warning');
      return;
    }
    try {
      if (editing) await API.updateStation(token, editing.id_station, form);
      else await API.createStation(token, form);
      toast.notify('Station disimpan', 'success');
      setModal(false);
      loadStations();
    } catch (e) {
      toast.notify(e.message, 'error');
    }
  }
  async function remove(s) {
    if (!confirm(`Hapus station "${s.nama_station}"?`)) return;
    await API.deleteStation(token, s.id_station);
    toast.notify('Station dihapus', 'success');
    loadStations();
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-extrabold text-navy">Station</h1>
          <p className="text-indigo-500 text-sm">Pilih pabrik dulu, lalu kelola station</p>
        </div>
        <Button onClick={openAdd} disabled={!selectedFactory}>
          + Tambah Station
        </Button>
      </div>

      <div className="mb-5 max-w-xs">
        <label className="text-sm font-medium text-navy/70">Pabrik</label>
        <select
          className="mt-1 w-full px-3 py-2.5 rounded-xl bg-white/50 border border-white/60 focus:outline-none focus:ring-2 focus:ring-brand/40 backdrop-blur"
          value={selectedFactory}
          onChange={(e) => setSelectedFactory(e.target.value)}
        >
          <option value="">— Pilih Pabrik —</option>
          {factories.map((f) => (
            <option key={f.id_factory} value={String(f.id_factory)}>
              {f.nama_factory}
            </option>
          ))}
        </select>
      </div>

      {!selectedFactory ? (
        <p className="text-navy/50">Silakan pilih pabrik terlebih dahulu.</p>
      ) : loading ? (
        <p className="text-navy/60">Memuat...</p>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {stations.map((s) => (
            <Card key={s.id_station} className="p-5">
              <div className="flex items-start justify-between">
                <div>
                  <p className="font-bold text-navy">{s.nama_station}</p>
                  <p className="text-sm text-navy/60">{s.lokasi_station || '-'}</p>
                </div>
                <HealthBadge value={s.health_station} />
              </div>
              <div className="flex gap-2 mt-4">
                <Button variant="ghost" onClick={() => openEdit(s)}>
                  Edit
                </Button>
                <Button variant="danger" onClick={() => remove(s)}>
                  Hapus
                </Button>
              </div>
            </Card>
          ))}
          {!stations.length && (
            <p className="text-navy/50 col-span-full">Belum ada station di pabrik ini.</p>
          )}
        </div>
      )}

      <Modal
        open={modal}
        title={editing ? 'Edit Station' : 'Tambah Station'}
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
        <Field label="Pabrik">
          <select
            className={inputClass}
            value={form.id_factory}
            onChange={(e) => setForm({ ...form, id_factory: e.target.value })}
          >
            <option value="">— Pilih Pabrik —</option>
            {factories.map((f) => (
              <option key={f.id_factory} value={String(f.id_factory)}>
                {f.nama_factory}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Nama Station">
          <input
            className={inputClass}
            value={form.nama_station}
            onChange={(e) => setForm({ ...form, nama_station: e.target.value })}
          />
        </Field>
        <Field label="Lokasi">
          <input
            className={inputClass}
            value={form.lokasi_station}
            onChange={(e) => setForm({ ...form, lokasi_station: e.target.value })}
          />
        </Field>
      </Modal>
    </div>
  );
}
