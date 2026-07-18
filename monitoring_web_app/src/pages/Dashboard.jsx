import { useEffect, useState } from 'react';
import { useAuth } from '../auth/AuthContext';
import { API } from '../lib/api';
import { Card, HealthBadge } from '../components/ui';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from 'recharts';

const COLORS = ['#22c55e', '#f59e0b', '#ef4444'];

export default function Dashboard() {
  const { token } = useAuth();
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const [factories, stations, machines, inspections] = await Promise.all([
          API.getFactories(token),
          API.getStations(token, ''),
          API.getMachines(token, ''),
          API.getInspections(token, 5, 0),
        ]);
        const f = factories.data ?? factories;
        const s = stations.data ?? stations;
        const m = machines.data ?? machines;
        const insp = inspections.data ?? inspections;

        const avg = (arr, key) =>
          arr.length ? arr.reduce((t, x) => t + Number(x[key] || 0), 0) / arr.length : 0;

        const mHealth = avg(m, 'health_mesin');
        const sHealth = avg(s, 'health_station');

        const breakdown = m.filter((x) => Number(x.health_mesin) < 70).length;
        const warning = m.filter((x) => {
          const h = Number(x.health_mesin);
          return h >= 70 && h < 90;
        }).length;
        const good = m.filter((x) => Number(x.health_mesin) >= 90).length;

        setStats({
          factories: f.length,
          stations: s.length,
          machines: m.length,
          mHealth,
          sHealth,
          breakdown,
          recent: insp.slice(0, 5),
          pie: [
            { name: 'Good', value: good },
            { name: 'Warning', value: warning },
            { name: 'Breakdown', value: breakdown },
          ],
        });
      } catch (e) {
        console.error(e);
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [token]);

  if (loading || !stats) return <p className="text-gray-500">Memuat...</p>;

  return (
    <div>
      <h1 className="text-2xl font-bold text-navy mb-1">Dashboard</h1>
      <p className="text-gray-500 mb-6">Gambaran umum seluruh pabrik</p>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <Kpi label="Pabrik" value={stats.factories} />
        <Kpi label="Station" value={stats.stations} />
        <Kpi label="Lori" value={stats.machines} />
        <Kpi label="Breakdown (<70%)" value={stats.breakdown} danger={stats.breakdown > 0} />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <Card className="p-5">
          <p className="text-sm text-gray-500">Rata-rata Health Lori</p>
          <div className="mt-2">
            <HealthBadge value={stats.mHealth.toFixed(0)} />
          </div>
        </Card>
        <Card className="p-5">
          <p className="text-sm text-gray-500">Rata-rata Health Station</p>
          <div className="mt-2">
            <HealthBadge value={stats.sHealth.toFixed(0)} />
          </div>
        </Card>
        <Card className="p-5">
          <p className="text-sm text-gray-500">Distribusi Kondisi Lori</p>
          <div className="h-32 mt-2">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={stats.pie} dataKey="value" nameKey="name" innerRadius={25} outerRadius={45}>
                  {stats.pie.map((_, i) => (
                    <Cell key={i} fill={COLORS[i]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>

      <Card className="p-5">
        <h3 className="font-bold text-navy mb-3">Inspeksi Terbaru</h3>
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-gray-500 border-b">
              <th className="py-2">Lori</th>
              <th>Pabrik</th>
              <th>Tanggal</th>
              <th>Health</th>
            </tr>
          </thead>
          <tbody>
            {stats.recent.map((r) => (
              <tr key={r.id_service} className="border-b border-gray-50">
                <td className="py-2 font-medium">{r.nama_lori}</td>
                <td>{r.nama_factory}</td>
                <td>{r.service_date}</td>
                <td>
                  <HealthBadge value={r.health_mesin_after} />
                </td>
              </tr>
            ))}
            {!stats.recent.length && (
              <tr>
                <td colSpan={4} className="py-4 text-center text-gray-400">
                  Belum ada inspeksi
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </Card>
    </div>
  );
}

function Kpi({ label, value, danger }) {
  return (
    <Card className="p-5">
      <p className="text-sm text-gray-500">{label}</p>
      <p className={`text-3xl font-bold mt-1 ${danger ? 'text-red-600' : 'text-navy'}`}>{value}</p>
    </Card>
  );
}
