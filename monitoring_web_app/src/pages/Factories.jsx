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
  const [expanded, setExpanded] = useState(null);

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
          <h1 className="text-2xl font-bold text-navy">Pabrik</h1>
          <p className="text-gray-500 text-sm">Kelola pabrik, station, dan lori</p>
        </div>
        <Button onClick={openAdd}>+ Tambah Pabrik</Button>
      </div>

      {loading ? (
        <p className="text-gray-500">Memuat...</p>
      ) : (
        <div className="space-y-3">
          {factories.map((f) => (
            <Card key={f.id_factory} className="p-4">
              <div className="flex items-center justify-between">
                <button
                  className="flex-1 text-left"
                  onClick={() => setExpanded(expanded === f.id_factory ? null : f.id_factory)}
                >
                  <div className="flex items-center gap-3">
                    <span className="text-xl">🏭</span>
                    <div>
                      <p className="font-semibold text-navy">{f.nama_factory}</p>
                      <p className="text-sm text-gray-500">{f.lokasi_factory || '-'}</p>
                    </div>
                  </div>
                </button>
                <HealthBadge value={f.health_factory} />
                <div className="flex gap-2 ml-3">
                  <Button variant="ghost" onClick={() => openEdit(f)}>
                    Edit
                  </Button>
                  <Button variant="danger" onClick={() => remove(f)}>
                    Hapus
                  </Button>
                </div>
              </div>
              {expanded === f.id_factory && (
                <StationList factoryId={f.id_factory} token={token} onChanged={load} toast={toast} />
              )}
            </Card>
          ))}
          {!factories.length && <p className="text-gray-400">Belum ada pabrik.</p>}
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

function StationList({ factoryId, token, onChanged, toast }) {
  const [stations, setStations] = useState([]);
  const [expanded, setExpanded] = useState(null);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({ nama_station: '', lokasi_station: '' });

  async function load() {
    const res = await API.getStations(token, factoryId);
    setStations(res.data ?? res);
  }
  useEffect(() => {
    load();
  }, [factoryId]);

  function openAdd() {
    setEditing(null);
    setForm({ nama_station: '', lokasi_station: '' });
    setModal(true);
  }
  async function save() {
    try {
      if (editing) await API.updateStation(token, editing.id_station, form);
      else await API.createStation(token, { id_factory: factoryId, ...form });
      setModal(false);
      load();
      onChanged();
      toast.notify('Station disimpan', 'success');
    } catch (e) {
      toast.notify(e.message, 'error');
    }
  }
  async function remove(s) {
    if (!confirm(`Hapus station "${s.nama_station}"?`)) return;
    await API.deleteStation(token, s.id_station);
    load();
    onChanged();
    toast.notify('Station dihapus', 'success');
  }

  return (
    <div className="mt-4 pl-6 border-l-2 border-gray-100 space-y-2">
      <Button variant="ghost" onClick={openAdd}>
        + Tambah Station
      </Button>
      {stations.map((s) => (
        <div key={s.id_station} className="bg-gray-50 rounded-lg p-3">
          <div className="flex items-center justify-between">
            <button
              className="flex-1 text-left"
              onClick={() => setExpanded(expanded === s.id_station ? null : s.id_station)}
            >
              <span className="font-medium text-navy">{s.nama_station}</span>
              <span className="text-sm text-gray-500 ml-2">{s.lokasi_station}</span>
            </button>
            <HealthBadge value={s.health_station} />
            <div className="flex gap-2 ml-2">
              <Button variant="ghost" onClick={() => { setEditing(s); setForm({ nama_station: s.nama_station, lokasi_station: s.lokasi_station || '' }); setModal(true); }}>
                Edit
              </Button>
              <Button variant="danger" onClick={() => remove(s)}>
                Hapus
              </Button>
            </div>
          </div>
          {expanded === s.id_station && (
            <MachineList stationId={s.id_station} token={token} onChanged={onChanged} toast={toast} />
          )}
        </div>
      ))}

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
        <Field label="Nama Station">
          <input className={inputClass} value={form.nama_station} onChange={(e) => setForm({ ...form, nama_station: e.target.value })} />
        </Field>
        <Field label="Lokasi">
          <input className={inputClass} value={form.lokasi_station} onChange={(e) => setForm({ ...form, lokasi_station: e.target.value })} />
        </Field>
      </Modal>
    </div>
  );
}

function MachineList({ stationId, token, onChanged, toast }) {
  const [machines, setMachines] = useState([]);
  const [modal, setModal] = useState(false);
  const [form, setForm] = useState({ nama_mesin: '', kode_mesin: '' });

  async function load() {
    const res = await API.getMachines(token, stationId);
    setMachines(res.data ?? res);
  }
  useEffect(() => {
    load();
  }, [stationId]);

  async function save() {
    try {
      await API.createMachine(token, { id_station: stationId, ...form });
      setModal(false);
      setForm({ nama_mesin: '', kode_mesin: '' });
      load();
      onChanged();
      toast.notify('Lori ditambahkan', 'success');
    } catch (e) {
      toast.notify(e.message, 'error');
    }
  }
  async function remove(m) {
    if (!confirm(`Hapus lori "${m.nama_mesin}"?`)) return;
    await API.deleteMachine(token, m.id_mesin);
    load();
    onChanged();
    toast.notify('Lori dihapus', 'success');
  }

  return (
    <div className="mt-3 pl-6 border-l-2 border-gray-100 space-y-2">
      <Button variant="ghost" onClick={() => setModal(true)}>
        + Tambah Lori
      </Button>
      {machines.map((m) => (
        <div key={m.id_mesin} className="bg-white rounded-lg p-3 border border-gray-100 flex items-center justify-between">
          <div>
            <span className="font-medium text-navy">{m.nama_mesin}</span>
            <span className="text-sm text-gray-500 ml-2">{m.kode_mesin}</span>
          </div>
          <div className="flex items-center gap-2">
            <HealthBadge value={m.health_mesin} />
            <Button variant="danger" onClick={() => remove(m)}>
              Hapus
            </Button>
          </div>
        </div>
      ))}
      <Modal
        open={modal}
        title="Tambah Lori"
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
        <Field label="Nama Lori">
          <input className={inputClass} value={form.nama_mesin} onChange={(e) => setForm({ ...form, nama_mesin: e.target.value })} />
        </Field>
        <Field label="Kode">
          <input className={inputClass} value={form.kode_mesin} onChange={(e) => setForm({ ...form, kode_mesin: e.target.value })} />
        </Field>
      </Modal>
    </div>
  );
}
