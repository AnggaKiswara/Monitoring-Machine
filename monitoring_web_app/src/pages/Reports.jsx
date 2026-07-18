import { useEffect, useState } from 'react';
import { useAuth } from '../auth/AuthContext';
import { API } from '../lib/api';
import { Card, Button } from '../components/ui';
import { useToast } from '../components/Toast';

const ORIGIN = 'http://103.93.135.108:3000';

export default function Reports() {
  const { token } = useAuth();
  const toast = useToast();

  const [factories, setFactories] = useState([]);
  const [stations, setStations] = useState([]);
  const [machines, setMachines] = useState([]);

  const [selFactory, setSelFactory] = useState('');
  const [selMachines, setSelMachines] = useState([]); // array id_mesin
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');

  const [cols, setCols] = useState({ info: true, komponen: true, foto: true, health: true });
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    API.getFactories(token).then((r) => {
      const f = r.data ?? r;
      setFactories(f);
      if (f.length) setSelFactory(String(f[0].id_factory));
    });
  }, [token]);

  useEffect(() => {
    if (!selFactory) {
      setStations([]);
      setMachines([]);
      setSelMachines([]);
      return;
    }
    API.getStations(token, selFactory).then((r) => setStations(r.data ?? r));
  }, [selFactory, token]);

  useEffect(() => {
    if (!selFactory) return;
    (async () => {
      const st = await API.getStations(token, selFactory);
      const stationList = st.data ?? st;
      let all = [];
      for (const s of stationList) {
        const m = await API.getMachines(token, s.id_station);
        all = all.concat(m.data ?? m);
      }
      setMachines(all);
      setSelMachines(all.map((x) => String(x.id_mesin)));
    })();
  }, [selFactory, token]);

  function toggleMachine(id) {
    setSelMachines((cur) =>
      cur.includes(id) ? cur.filter((x) => x !== id) : [...cur, id]
    );
  }

  async function buildReport() {
    setLoading(true);
    try {
      const ids = selMachines.filter((id) => machines.some((m) => String(m.id_mesin) === id));
      const data = [];
      for (const id of ids) {
        const m = machines.find((x) => String(x.id_mesin) === id);
        // ambil semua history lori
        const hist = await API.getServiceHistory ? null : null;
        // pakai endpoint history per machine
        const hres = await fetch(
          `${ORIGIN}/api/machines/${id}/history?limit=200`,
          { headers: { Authorization: `Bearer ${token}` } }
        ).then((r) => r.json());
        const rows = (hres?.data || []).filter((h) => {
          if (dateFrom && h.service_date < dateFrom) return false;
          if (dateTo && h.service_date > dateTo) return false;
          return true;
        });
        // ambil detail+foto per inspeksi
        const details = [];
        for (const h of rows) {
          const d = await API.getInspectionDetail(token, id, h.id_service);
          details.push(d?.data ?? d);
        }
        data.push({ machine: m, details });
      }
      setResult(data);
    } catch (e) {
      toast.notify(e.message, 'error');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6 no-print">
        <div>
          <h1 className="text-2xl font-extrabold text-navy">Laporan Inspeksi</h1>
          <p className="text-indigo-500 text-sm">Pilih pabrik & machine, lalu cetak</p>
        </div>
      </div>

      <Card className="p-5 mb-4 no-print space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <label className="block">
            <span className="text-sm font-medium text-navy/70">Pabrik</span>
            <select
              className="mt-1 w-full px-3 py-2.5 rounded-xl bg-white/50 border border-white/60 focus:outline-none focus:ring-2 focus:ring-brand/40 backdrop-blur"
              value={selFactory}
              onChange={(e) => setSelFactory(e.target.value)}
            >
              <option value="">— Pilih Pabrik —</option>
              {factories.map((f) => (
                <option key={f.id_factory} value={String(f.id_factory)}>
                  {f.nama_factory}
                </option>
              ))}
            </select>
          </label>
          <label className="block">
            <span className="text-sm font-medium text-navy/70">Dari</span>
            <input
              type="date"
              value={dateFrom}
              onChange={(e) => setDateFrom(e.target.value)}
              className="mt-1 w-full px-3 py-2.5 rounded-xl bg-white/50 border border-white/60 focus:outline-none focus:ring-2 focus:ring-brand/40 backdrop-blur"
            />
          </label>
          <label className="block">
            <span className="text-sm font-medium text-navy/70">Sampai</span>
            <input
              type="date"
              value={dateTo}
              onChange={(e) => setDateTo(e.target.value)}
              className="mt-1 w-full px-3 py-2.5 rounded-xl bg-white/50 border border-white/60 focus:outline-none focus:ring-2 focus:ring-brand/40 backdrop-blur"
            />
          </label>
        </div>

        <div>
          <p className="text-sm font-medium text-navy/70 mb-2">Pilih Machine (Lori)</p>
          <div className="flex flex-wrap gap-2 max-h-40 overflow-y-auto">
            {machines.map((m) => (
              <label
                key={m.id_mesin}
                className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-white/40 border border-white/50 text-sm cursor-pointer"
              >
                <input
                  type="checkbox"
                  checked={selMachines.includes(String(m.id_mesin))}
                  onChange={() => toggleMachine(String(m.id_mesin))}
                />
                {m.nama_mesin}
              </label>
            ))}
            {!machines.length && <span className="text-navy/40 text-sm">Pilih pabrik dulu.</span>}
          </div>
        </div>

        <div>
          <p className="text-sm font-medium text-navy/70 mb-2">Kolom yang dicetak</p>
          <div className="flex flex-wrap gap-4 text-sm">
            {[
              ['info', 'Info Inspeksi'],
              ['komponen', 'Komponen'],
              ['foto', 'Foto'],
              ['health', 'Health'],
            ].map(([k, label]) => (
              <label key={k} className="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" checked={cols[k]} onChange={() => setCols({ ...cols, [k]: !cols[k] })} />
                {label}
              </label>
            ))}
          </div>
        </div>

        <div className="flex gap-2">
          <Button onClick={buildReport} disabled={loading || !selMachines.length}>
            {loading ? 'Membuat...' : 'Tampilkan Pratinjau'}
          </Button>
          <Button variant="outline" onClick={() => window.print()} disabled={!result}>
            Cetak
          </Button>
        </div>
      </Card>

      {/* PRINT AREA */}
      {result && (
        <div className="print-area space-y-6">
          {result.map((sec) => (
            <div key={sec.machine.id_mesin} className="bg-white rounded-2xl p-5 shadow print-section">
              <h2 className="text-lg font-bold text-navy mb-1">
                {sec.machine.nama_mesin} ({sec.machine.kode_mesin})
              </h2>
              <p className="text-sm text-gray-500 mb-3">
                {factories.find((f) => String(f.id_factory) === selFactory)?.nama_factory}
              </p>
              {sec.details.map((d) => (
                <div key={d.id_service} className="mb-4 border-b pb-3">
                  <div className="flex justify-between text-sm font-medium">
                    <span>Inspeksi #{d.id_service} · {d.service_date}</span>
                    {cols.health && <span>Health: {d.health_mesin_after}%</span>}
                  </div>
                  {cols.info && (
                    <p className="text-xs text-gray-600">
                      Teknisi: {d.teknisi_name || '-'} | {d.description || ''}
                    </p>
                  )}
                  {cols.komponen && d.komponen?.length > 0 && (
                    <table className="w-full text-xs mt-1 border">
                      <thead>
                        <tr className="bg-gray-100">
                          <th className="text-left p-1">Komponen</th>
                          <th className="text-left p-1">Kondisi</th>
                          <th className="text-left p-1">Nilai</th>
                        </tr>
                      </thead>
                      <tbody>
                        {d.komponen.map((c, i) => (
                          <tr key={i}>
                            <td className="p-1">{c.nama_komponen}</td>
                            <td className="p-1">{c.kondisi}</td>
                            <td className="p-1">{c.nilai}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  )}
                  {cols.foto && d.photos?.length > 0 && (
                    <div className="flex flex-wrap gap-2 mt-2">
                      {d.photos.map((p, i) => (
                        <img
                          key={p.id_photo || i}
                          src={p.photo_path.startsWith('http') ? p.photo_path : `${ORIGIN}/${p.photo_path}`}
                          className="w-24 h-24 object-cover border"
                        />
                      ))}
                    </div>
                  )}
                </div>
              ))}
              {!sec.details.length && <p className="text-xs text-gray-400">Tidak ada inspeksi di periode ini.</p>}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
