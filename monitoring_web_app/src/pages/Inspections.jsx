import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { API } from '../lib/api';
import { Card, HealthBadge } from '../components/ui';
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
        const res = await API.getInspections(token, 100, 0);
        setList(res.data ?? res);
      } catch (e) {
        toast.notify(e.message, 'error');
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [token]);

  return (
    <div>
      <h1 className="text-2xl font-bold text-navy mb-1">Riwayat Inspeksi</h1>
      <p className="text-gray-500 mb-6">Semua inspeksi dari seluruh pabrik</p>

      {loading ? (
        <p className="text-gray-500">Memuat...</p>
      ) : (
        <Card className="overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-gray-500 border-b bg-gray-50">
                <th className="py-3 px-4">Lori</th>
                <th className="px-4">Pabrik</th>
                <th className="px-4">Station</th>
                <th className="px-4">Tanggal</th>
                <th className="px-4">Teknisi</th>
                <th className="px-4">Health</th>
              </tr>
            </thead>
            <tbody>
              {list.map((r) => (
                <tr
                  key={r.id_service}
                  className="border-b border-gray-50 hover:bg-gray-50 cursor-pointer"
                  onClick={() => navigate(`/inspections/${r.id_mesin}/${r.id_service}`)}
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
                </tr>
              ))}
              {!list.length && (
                <tr>
                  <td colSpan={6} className="py-6 text-center text-gray-400">
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
