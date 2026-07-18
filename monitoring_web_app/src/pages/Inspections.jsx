import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { API } from '../lib/api';
import { Card, HealthBadge, Button } from '../components/ui';
import { Printer } from 'lucide-react';
import { useToast } from '../components/Toast';

export default function Inspections() {
  const { token } = useAuth();
  const toast = useToast();
  const navigate = useNavigate();
  const [list, setList] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const res = await API.getInspections(token, 200, 0);
        setList(res.data ?? res);
      } catch (e) {
        toast.notify(e.message, 'error');
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [token]);

  async function handleDelete(machineId, serviceId) {
    if (!confirm('Hapus inspeksi ini? Foto & komponen ikut terhapus.')) return;
    try {
      await API.deleteInspection(token, machineId, serviceId);
      toast.notify('Inspeksi dihapus', 'success');
      setList((l) => l.filter((r) => r.id_service !== serviceId));
    } catch (e) {
      toast.notify(e.message, 'error');
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6 no-print">
        <div>
          <h1 className="text-2xl font-extrabold text-navy">Riwayat Inspeksi</h1>
          <p className="text-indigo-500 text-sm">Semua inspeksi dari seluruh pabrik</p>
        </div>
        <Button variant="outline" onClick={() => navigate('/reports')}>
          <Printer size={16} /> Laporan
        </Button>
      </div>

      {loading ? (
        <p className="text-navy/60">Memuat...</p>
      ) : (
        <Card className="overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-navy/50 border-b bg-white/40">
                <th className="py-3 px-4">Lori</th>
                <th className="px-4">Pabrik</th>
                <th className="px-4">Station</th>
                <th className="px-4">Tanggal</th>
                <th className="px-4">Teknisi</th>
                <th className="px-4">Health</th>
                <th className="px-4 no-print"></th>
              </tr>
            </thead>
            <tbody>
              {list.map((r) => (
                <tr
                  key={r.id_service}
                  className="border-b border-white/40 hover:bg-white/40"
                >
                  <td className="py-3 px-4 font-medium text-navy">
                    {r.nama_lori}
                    {r.kode_mesin ? ` (${r.kode_mesin})` : ''}
                  </td>
                  <td className="px-4">{r.nama_factory}</td>
                  <td className="px-4">{r.nama_station}</td>
                  <td className="px-4">{r.service_date}</td>
                  <td className="px-4">{r.teknisi_name || '-'}</td>
                  <td className="px-4">
                    <HealthBadge value={r.health_mesin_after} />
                  </td>
                  <td className="px-4 no-print">
                    <div className="flex gap-2 justify-end">
                      <Button
                        variant="ghost"
                        onClick={() => navigate(`/inspections/${r.id_mesin}/${r.id_service}`)}
                      >
                        Detail
                      </Button>
                      <Button
                        variant="outline"
                        onClick={() => navigate(`/inspections/${r.id_mesin}/${r.id_service}/edit`)}
                      >
                        Edit
                      </Button>
                      <Button
                        variant="danger"
                        onClick={() => handleDelete(r.id_mesin, r.id_service)}
                      >
                        Hapus
                      </Button>
                    </div>
                  </td>
                </tr>
              ))}
              {!list.length && (
                <tr>
                  <td colSpan={7} className="py-6 text-center text-navy/40">
                    Belum ada inspeksi
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </Card>
      )}
    </div>
  );
}
