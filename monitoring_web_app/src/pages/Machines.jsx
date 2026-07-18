import { useEffect, useState } from 'react';
import { useAuth } from '../auth/AuthContext';
import { API } from '../lib/api';
import { Card, Button, HealthBadge } from '../components/ui';
import { Modal, Field, inputClass } from '../components/Modal';
import { useToast } from '../components/Toast';

export default function Machines() {
  const { token } = useAuth();
  const toast = useToast();
  const [factories, setFactories] = useState([]);
  const [stations, setStations] = useState([]);
  const [selectedFactory, setSelectedFactory] = useState('');
  const [selectedStation, setSelectedStation] = useState('');
  const [machines, setMachines] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [form, setForm] = useState({ id_station: '', nama_mesin: '', kode_mesin: '' });

  async function loadFactories() {
    const res = await API.getFactories(token);
    const f = res.data ?? res;
    setFactories(f);
    if (!selectedFactory && f.length) setSelectedFactory(String(f[0].id_factory));
  }
  async function loadStations(fid) {
    if (!fid) {
      setStations([]);
      setSelectedStation('');
      return;
    }
    const res = await API.getStations(token, fid);
    setStations(res.data ?? res);
  }
  async function loadMachines() {
    if (!selectedStation) {
      setMachines([]);
      setLoading(false);
      return;
    }
    const res = await API.getMachines(token, selectedStation);
    setMachines(res.data ?? res);
    setLoading(false);
  }

  useEffect(() => {
    loadFactories();
  }, [token]);
  useEffect(() => {
    if (selectedFactory) {
      loadStations(selectedFactory);
      setSelectedStation('');
    }
    loadMachines();
    // eslint-disable-next-line
  }, [selectedFactory]);
  useEffect(() => {
    loadMachines();
    // eslint-disable-next-line
  }, [selectedStation]);

  function openAdd() {
    setForm({ id_station: selectedStation, nama_mesin: '', kode_mesin: '' });
    setModal(true);
  }

  async function save() {
    if (!form.id_station) {
      toast.notify('Pilih pabrik & station dulu', 'warning');
      return;
    }
    try {
      await API.createMachine(token, form);
      toast.notify('Lori ditambahkan', 'success');
      setModal(false);
      loadMachines();
    } catch (e) {
      toast.notify(e.message, 'error');
    }
  }
  async function remove(m) {
    if (!confirm(`Hapus lori "${m.nama_mesin}"?`)) return;
    await API.deleteMachine(token, m.id_mesin);
    toast.notify('Lori dihapus', 'success');
    loadMachines();
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-extrabold text-navy">Machine (Lori)</h1>
          <p className="text-indigo-500 text-sm">Pilih pabrik → station, lalu kelola lori</p>
        </div>
        <Button onClick={openAdd} disabled={!selectedStation}>
          + Tambah Lori
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-5 max-w-xl">
        <div>
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
        <div>
          <label className="text-sm font-medium text-navy/70">Station</label>
          <select
            className="mt-1 w-full px-3 py-2.5 rounded-xl bg-white/50 border border-white/60 focus:outline-none focus:ring-2 focus:ring-brand/40 backdrop-blur disabled:opacity-50"
            value={selectedStation}
            disabled={!selectedFactory}
            onChange={(e) => setSelectedStation(e.target.value)}
          >
            <option value="">— Pilih Station —</option>
            {stations.map((s) => (
              <option key={s.id_station} value={String(s.id_station)}>
                {s.nama_station}
              </option>
            ))}
          </select>
        </div>
      </div>

      {!selectedFactory ? (
        <p className="text-navy/50">Silakan pilih pabrik terlebih dahulu.</p>
      ) : !selectedStation ? (
        <p className="text-navy/50">Silakan pilih station terlebih dahulu.</p>
      ) : loading ? (
        <p className="text-navy/60">Memuat...</p>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {machines.map((m) => (
            <Card key={m.id_mesin} className="p-5">
              <div className="flex items-start justify-between">
                <div>
                  <p className="font-bold text-navy">{m.nama_mesin}</p>
                  <p className="text-sm text-navy/60">{m.kode_mesin}</p>
                </div>
                <HealthBadge value={m.health_mesin} />
              </div>
              <div className="flex gap-2 mt-4">
                <Button variant="danger" onClick={() => remove(m)}>
                  Hapus
                </Button>
              </div>
            </Card>
          ))}
          {!machines.length && (
            <p className="text-navy/50 col-span-full">Belum ada lori di station ini.</p>
          )}
        </div>
      )}

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
        <Field label="Station terpilih">
          <input
            className={inputClass}
            value={
              stations.find((s) => String(s.id_station) === selectedStation)?.nama_station ||
              '—'
            }
            disabled
          />
        </Field>
        <Field label="Nama Lori">
          <input
            className={inputClass}
            value={form.nama_mesin}
            onChange={(e) => setForm({ ...form, nama_mesin: e.target.value })}
          />
        </Field>
        <Field label="Kode">
          <input
            className={inputClass}
            value={form.kode_mesin}
            onChange={(e) => setForm({ ...form, kode_mesin: e.target.value })}
          />
        </Field>
      </Modal>
    </div>
  );
}
