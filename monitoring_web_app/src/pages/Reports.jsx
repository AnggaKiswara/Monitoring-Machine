import { useEffect, useState } from 'react';
import { useAuth } from '../auth/AuthContext';
import { API } from '../lib/api';
import { Card, Button } from '../components/ui';
import { useToast } from '../components/Toast';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from 'recharts';

const ORIGIN = 'http://103.93.135.108:3000';
const COLORS = ['#22c55e', '#f59e0b', '#ef4444'];

export default function Reports() {
  const { token } = useAuth();
  const toast = useToast();

  const [factories, setFactories] = useState([]);
  const [stations, setStations] = useState([]);
  const [machines, setMachines] = useState([]);
  const [machineHistories, setMachineHistories] = useState({});

  const [selFactory, setSelFactory] = useState('');

  const [loading, setLoading] = useState(true);
  const [reportLoading, setReportLoading] = useState(false);

  useEffect(() => {
    API.getFactories(token).then((r) => {
      const f = r.data ?? r;
      setFactories(f);
      if (f.length) setSelFactory(String(f[0].id_factory));
      setLoading(false);
    });
  }, [token]);

  useEffect(() => {
    if (!selFactory) {
      setStations([]);
      setMachines([]);
      setMachineHistories({});
      return;
    }
    setLoading(true);
    API.getStations(token, selFactory).then((r) => setStations(r.data ?? r));
    (async () => {
      const st = await API.getStations(token, selFactory);
      const stationList = st.data ?? st;
      let all = [];
      for (const s of stationList) {
        const m = await API.getMachines(token, s.id_station);
        all = all.concat(m.data ?? m);
      }
      setMachines(all);
      const histories = {};
      for (const m of all) {
        try {
          const h = await API.getServiceHistory(token, m.id_mesin, 1, 0);
          histories[m.id_mesin] = h.data ?? h;
        } catch {
          histories[m.id_mesin] = [];
        }
      }
      setMachineHistories(histories);
      setLoading(false);
    })();
  }, [selFactory, token]);

  const total = machines.length;
  const withInspection = machines.filter((m) => (machineHistories[m.id_mesin] || []).length > 0).length;
  const withoutInspection = total - withInspection;
  const avgHealth = total ? Math.round(machines.reduce((t, m) => t + Number(m.health_mesin || 0), 0) / total) : 0;

  const excellent = machines.filter((m) => Number(m.health_mesin) >= 95).length;
  const good = machines.filter((m) => { const h = Number(m.health_mesin); return h >= 86 && h <= 94; }).length;
  const satisfactory = machines.filter((m) => { const h = Number(m.health_mesin); return h >= 61 && h <= 85; }).length;
  const poor = machines.filter((m) => Number(m.health_mesin) <= 60).length;

  const pieData = [
    { name: 'Excellent', value: excellent },
    { name: 'Good', value: good },
    { name: 'Satisfactory', value: satisfactory },
    { name: 'Poor', value: poor },
  ];

  function getHealthColor(h) {
    if (h >= 95) return 'text-green-600';
    if (h >= 86) return 'text-teal-600';
    if (h >= 61) return 'text-orange-500';
    return 'text-red-600';
  }
  function getHealthBg(h) {
    if (h >= 95) return 'bg-green-50';
    if (h >= 86) return 'bg-teal-50';
    if (h >= 61) return 'bg-orange-50';
    return 'bg-red-50';
  }

  async function buildReport() {
    setReportLoading(true);
    try {
      const rows = [];
      for (const m of machines) {
        const hist = machineHistories[m.id_mesin] || [];
        if (!hist.length) continue;
        const history = await API.getServiceHistory(token, m.id_mesin, 50, 0);
        const inspections = history.data ?? history;
        const details = [];
        for (const ins of inspections) {
          try {
            const d = await API.getInspectionDetail(token, m.id_mesin, ins.id_service);
            details.push(d.data ?? d);
          } catch {
            details.push({ ...ins, komponen: [], photos: [] });
          }
        }
        rows.push({ machine: m, inspections: details });
      }
      setReportRows(rows);
    } catch (e) {
      toast.notify(e.message, 'error');
    } finally {
      setReportLoading(false);
    }
  }

  const [reportRows, setReportRows] = useState([]);

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-extrabold text-navy">Laporan</h1>
          <p className="text-indigo-500 text-sm">Ringkasan kondisi lori & service</p>
        </div>
        <Button onClick={buildReport} disabled={reportLoading || !machines.length}>
          {reportLoading ? 'Membuat...' : 'Tampilkan Pratinjau'}
        </Button>
      </div>

      {!selFactory ? (
        <Card className="p-6 mb-4">
          <p className="text-navy/60">Pilih pabrik terlebih dahulu untuk melihat kondisi lori.</p>
        </Card>
      ) : loading ? (
        <Card className="p-6 mb-4"><p className="text-navy/60">Memuat data mesin...</p></Card>
      ) : (
        <>
          {/* Overall condition cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
            <Card className={`p-5 ${getHealthBg(avgHealth)}`}>
              <p className="text-sm text-navy/60 mb-1">Overall Condition</p>
              <p className={`text-4xl font-bold ${getHealthColor(avgHealth)}`}>{avgHealth}%</p>
              <p className="text-xs text-navy/50 mt-1">Rata-rata {total} unit</p>
            </Card>
            <Card className="p-5">
              <p className="text-sm text-navy/60 mb-1">Lori Aktif</p>
              <p className="text-4xl font-bold text-navy">{withInspection}</p>
              <p className="text-xs text-navy/50 mt-1">Dari {total} total</p>
            </Card>
            <Card className="p-5">
              <p className="text-sm text-navy/60 mb-1">Perlu Service</p>
              <p className="text-4xl font-bold text-orange-600">{withoutInspection + poor + satisfactory}</p>
              <p className="text-xs text-navy/50 mt-1">Tanpa inspeksi + Poor + Satisfactory</p>
            </Card>
            <Card className="p-5">
              <p className="text-sm text-navy/60 mb-1">Rata-rata Service</p>
              <p className="text-4xl font-bold text-navy">
                {machines.length ? Math.round(machines.reduce((t, m) => t + ((machineHistories[m.id_mesin] || []).length), 0) / machines.length) : 0}
              </p>
              <p className="text-xs text-navy/50 mt-1">Inspeksi per unit</p>
            </Card>
          </div>

          {/* Chart + breakdown */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-4">
            <Card className="p-5 lg:col-span-2">
              <p className="text-sm font-medium text-navy/70 mb-2">Distribusi Kondisi Lori</p>
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={pieData} dataKey="value" nameKey="name" innerRadius={55} outerRadius={90} paddingAngle={4}>
                      {pieData.map((_, i) => (
                        <Cell key={i} fill={COLORS[i % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </Card>
            <Card className="p-5 space-y-3">
              <p className="text-sm font-medium text-navy/70">Ringkasan</p>
              {[
                ['Excellent (≥95%)', excellent, '#22c55e'],
                ['Good (86-94%)', good, '#14b8a6'],
                ['Satisfactory (61-85%)', satisfactory, '#f59e0b'],
                ['Poor (≤60%)', poor, '#ef4444'],
              ].map(([label, value, color]) => (
                <div key={label} className="flex items-center justify-between">
                  <span className="text-sm text-navy/70">{label}</span>
                  <span className="font-bold" style={{ color }}>{String(value)}</span>
                </div>
              ))}
            </Card>
          </div>

          {/* Machine list cards */}
          <Card className="p-5 mb-4">
            <div className="flex items-center justify-between mb-3">
              <p className="font-bold text-navy">Daftar Lori</p>
              <span className="text-xs text-navy/50">{machines.length} unit</span>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
              {machines.map((m) => {
                const health = Number(m.health_mesin || 0);
                const status = health >= 95 ? 'Baik' : health >= 86 ? 'Good' : health >= 61 ? 'Layak' : 'Perlu Service';
                const inspection = (machineHistories[m.id_mesin] || [])[0];
                return (
                  <Card key={m.id_mesin} className="p-4">
                    <div className="flex items-start justify-between">
                      <div>
                        <p className="font-bold text-navy">{m.nama_mesin}</p>
                        <p className="text-sm text-navy/60">{m.kode_mesin}</p>
                      </div>
                      <span className={`px-2 py-1 rounded-lg text-xs font-semibold ${getHealthBg(health)} ${getHealthColor(health)}`}>
                        {status}
                      </span>
                    </div>
                    <div className="flex items-center justify-between mt-3">
                      <span className="text-xs text-navy/50">Kesehatan: {health}%</span>
                      <span className="text-xs text-navy/50">
                        {inspection ? `Inspeksi: ${inspection.service_date}` : 'Tanpa inspeksi'}
                      </span>
                    </div>
                  </Card>
                );
              })}
              {!machines.length && <p className="text-navy/50 col-span-full">Belum ada lori.</p>}
            </div>
          </Card>

          {/* Report preview table */}
          {reportRows.length > 0 && (
            <Card className="p-5">
              <div className="flex items-center justify-between mb-3">
                <p className="font-bold text-navy">Pratinjau Laporan</p>
                <Button variant="outline" onClick={() => window.print()}>Cetak</Button>
              </div>
              <div className="space-y-4">
                {reportRows.map((sec) => (
                  <div key={sec.machine.id_mesin} className="border rounded-xl p-4">
                    <p className="font-bold text-navy mb-1">{sec.machine.nama_mesin} ({sec.machine.kode_mesin})</p>
                    <div className="space-y-2">
                      {sec.inspections.map((ins) => (
                        <div key={ins.id_service} className="grid grid-cols-2 md:grid-cols-4 gap-2 text-sm">
                          <div>
                            <p className="text-navy/50 text-xs">Tanggal</p>
                            <p className="font-medium text-navy">{ins.service_date || '-'}</p>
                          </div>
                          <div>
                            <p className="text-navy/50 text-xs">Before</p>
                            <p className="font-medium text-navy">{ins.health_mesin_before ?? 0}%</p>
                          </div>
                          <div>
                            <p className="text-navy/50 text-xs">After</p>
                            <p className="font-medium text-navy">{ins.health_mesin_after ?? 0}%</p>
                          </div>
                          <div>
                            <p className="text-navy/50 text-xs">Teknisi</p>
                            <p className="font-medium text-navy">{ins.teknisi_name || '-'}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </Card>
          )}
        </>
      )}
    </div>
  );
}
