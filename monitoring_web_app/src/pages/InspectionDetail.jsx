import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { API } from '../lib/api';
import { Card } from '../components/ui';

const ORIGIN = 'http://103.93.135.108:3000';

export default function InspectionDetail() {
  const { machineId, serviceId } = useParams();
  const { token } = useAuth();
  const navigate = useNavigate();
  const [detail, setDetail] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const res = await API.getInspectionDetail(token, machineId, serviceId);
        // backend: {success, data: {...}} atau langsung object
        const d = res?.data ?? res;
        setDetail(d);
      } catch (e) {
        console.error(e);
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [token, machineId, serviceId]);

  if (loading) return <p className="text-gray-500">Memuat...</p>;
  if (!detail) return <p className="text-red-600">Gagal memuat detail.</p>;

  const photos = Array.isArray(detail.photos) ? detail.photos : [];
  const components = Array.isArray(detail.components) ? detail.components : [];

  return (
    <div>
      <button className="text-brand mb-4" onClick={() => navigate('/inspections')}>
        ← Kembali
      </button>
      <h1 className="text-2xl font-bold text-navy mb-1">Detail Inspeksi #{serviceId}</h1>
      <p className="text-gray-500 mb-6">
        {detail.nama_lori || detail.machine_name || `Lori #${machineId}`} · {detail.service_date}
      </p>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        <Card className="p-5">
          <h3 className="font-bold text-navy mb-3">Informasi</h3>
          <Row label="Pabrik" value={detail.nama_factory} />
          <Row label="Station" value={detail.nama_station} />
          <Row label="Lori" value={detail.nama_lori} />
          <Row label="Teknisi" value={detail.teknisi_name} />
          <Row label="Health Before" value={detail.health_mesin_before} />
          <Row label="Health After" value={detail.health_mesin_after} />
          <Row label="Keterangan" value={detail.description} />
        </Card>

        <Card className="p-5">
          <h3 className="font-bold text-navy mb-3">Komponen</h3>
          {components.length ? (
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-gray-500 border-b">
                  <th className="py-1">Komponen</th>
                  <th>Kondisi</th>
                  <th>Nilai</th>
                </tr>
              </thead>
              <tbody>
                {components.map((c, i) => (
                  <tr key={i} className="border-b border-gray-50">
                    <td className="py-1">{c.nama_komponen || c.komponen}</td>
                    <td>{c.kondisi}</td>
                    <td>{c.nilai}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <p className="text-gray-400 text-sm">Tidak ada data komponen.</p>
          )}
        </Card>
      </div>

      <Card className="p-5">
        <h3 className="font-bold text-navy mb-3">Foto Inspeksi</h3>
        {photos.length ? (
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {photos.map((p, i) => {
              const src = p.startsWith('http') ? p : `${ORIGIN}/uploads/inspections/${p.replace(/^.*[\\/]/, '')}`;
              return (
                <a key={i} href={src} target="_blank" rel="noreferrer">
                  <img
                    src={src}
                    alt={`foto ${i + 1}`}
                    className="w-full h-40 object-cover rounded-lg border border-gray-100"
                    onError={(e) => {
                      e.target.style.display = 'none';
                    }}
                  />
                </a>
              );
            })}
          </div>
        ) : (
          <p className="text-gray-400 text-sm">Tidak ada foto.</p>
        )}
      </Card>
    </div>
  );
}

function Row({ label, value }) {
  return (
    <div className="flex justify-between py-1 border-b border-gray-50 text-sm">
      <span className="text-gray-500">{label}</span>
      <span className="font-medium text-navy">{value ?? '-'}</span>
    </div>
  );
}
