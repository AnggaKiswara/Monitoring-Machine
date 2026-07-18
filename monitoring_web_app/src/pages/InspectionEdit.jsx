import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { API } from '../lib/api';
import { Card, Button } from '../components/ui';
import { useToast } from '../components/Toast';

const ORIGIN = 'http://103.93.135.108:3000';

export default function InspectionEdit() {
  const { machineId, serviceId } = useParams();
  const { token } = useAuth();
  const toast = useToast();
  const navigate = useNavigate();

  const [tanggal, setTanggal] = useState('');
  const [pic, setPic] = useState('');
  const [keterangan, setKeterangan] = useState('');
  const [komponen, setKomponen] = useState([]);
  const [photos, setPhotos] = useState([]);
  const [files, setFiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    async function load() {
      try {
        const res = await API.getInspectionDetail(token, machineId, serviceId);
        const d = res?.data ?? res;
        setTanggal(d.service_date || '');
        setKeterangan(d.description || '');
        setPic(d.pic_name || '');
        setKomponen(
          (d.komponen || []).map((c) => ({
            id_komponen: c.id_komponen,
            nama_komponen: c.nama_komponen,
            nilai: c.nilai ?? 0,
          }))
        );
        setPhotos(d.photos || []);
      } catch (e) {
        toast.notify(e.message, 'error');
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [token, machineId, serviceId]);

  function setNilai(idx, v) {
    setKomponen((k) => k.map((c, i) => (i === idx ? { ...c, nilai: Number(v) } : c)));
  }

  async function handleDeletePhoto(photoId) {
    try {
      await API.deletePhoto(token, machineId, serviceId, photoId);
      setPhotos((p) => p.filter((x) => x.id_photo !== photoId));
      toast.notify('Foto dihapus', 'success');
    } catch (e) {
      toast.notify(e.message, 'error');
    }
  }

  async function save() {
    setSaving(true);
    try {
      await API.updateInspection(token, machineId, serviceId, {
        tanggal_inspeksi: tanggal,
        pic,
        keterangan,
        komponen_conditions: komponen.map((c) => ({
          id_komponen: c.id_komponen,
          kondisi: '',
          nilai: c.nilai,
        })),
      });
      // upload foto baru jika ada
      if (files.length > 0) {
        const fd = new FormData();
        files.forEach((f) => fd.append('photos', f));
        await fetch(`${ORIGIN}/api/machines/${machineId}/inspection/${serviceId}/photos`, {
          method: 'POST',
          headers: { Authorization: `Bearer ${token}` },
          body: fd,
        });
      }
      toast.notify('Inspeksi diperbarui', 'success');
      navigate(`/inspections/${machineId}/${serviceId}`);
    } catch (e) {
      toast.notify(e.message, 'error');
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <p className="text-navy/60">Memuat...</p>;

  return (
    <div>
      <button className="text-brand mb-4" onClick={() => navigate(`/inspections/${machineId}/${serviceId}`)}>
        ← Batal
      </button>
      <h1 className="text-2xl font-extrabold text-navy mb-6">Edit Inspeksi #{serviceId}</h1>

      <Card className="p-5 mb-4 space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <label className="block">
            <span className="text-sm font-medium text-navy/70">Tanggal</span>
            <input
              type="date"
              value={tanggal}
              onChange={(e) => setTanggal(e.target.value)}
              className="mt-1 w-full px-3 py-2.5 rounded-xl bg-white/50 border border-white/60 focus:outline-none focus:ring-2 focus:ring-brand/40 backdrop-blur"
            />
          </label>
          <label className="block">
            <span className="text-sm font-medium text-navy/70">PIC</span>
            <input
              value={pic}
              onChange={(e) => setPic(e.target.value)}
              className="mt-1 w-full px-3 py-2.5 rounded-xl bg-white/50 border border-white/60 focus:outline-none focus:ring-2 focus:ring-brand/40 backdrop-blur"
            />
          </label>
          <label className="block">
            <span className="text-sm font-medium text-navy/70">Keterangan</span>
            <input
              value={keterangan}
              onChange={(e) => setKeterangan(e.target.value)}
              className="mt-1 w-full px-3 py-2.5 rounded-xl bg-white/50 border border-white/60 focus:outline-none focus:ring-2 focus:ring-brand/40 backdrop-blur"
            />
          </label>
        </div>
      </Card>

      <Card className="p-5 mb-4">
        <h3 className="font-bold text-navy mb-3">Nilai Komponen</h3>
        <div className="space-y-2">
          {komponen.map((c, i) => (
            <div key={c.id_komponen} className="flex items-center gap-3">
              <span className="flex-1 text-sm text-navy">{c.nama_komponen}</span>
              <input
                type="number"
                min="0"
                max="100"
                value={c.nilai}
                onChange={(e) => setNilai(i, e.target.value)}
                className="w-24 px-3 py-2 rounded-xl bg-white/50 border border-white/60 focus:outline-none focus:ring-2 focus:ring-brand/40 backdrop-blur"
              />
            </div>
          ))}
          {!komponen.length && <p className="text-navy/40 text-sm">Tidak ada komponen.</p>}
        </div>
      </Card>

      <Card className="p-5 mb-4">
        <h3 className="font-bold text-navy mb-3">Foto</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-3">
          {photos.map((p) => (
            <div key={p.id_photo} className="relative">
              <img
                src={p.photo_path.startsWith('http') ? p.photo_path : `${ORIGIN}/${p.photo_path}`}
                className="w-full h-32 object-cover rounded-xl border border-white/50"
                onError={(e) => (e.target.style.display = 'none')}
              />
              <button
                onClick={() => handleDeletePhoto(p.id_photo)}
                className="absolute top-1 right-1 bg-red-600 text-white text-xs px-2 py-0.5 rounded"
              >
                x
              </button>
            </div>
          ))}
        </div>
        <input
          type="file"
          accept="image/*"
          multiple
          onChange={(e) => setFiles(Array.from(e.target.files || []))}
          className="text-sm"
        />
      </Card>

      <div className="flex gap-2 no-print">
        <Button onClick={save} disabled={saving}>
          {saving ? 'Menyimpan...' : 'Simpan'}
        </Button>
        <Button variant="ghost" onClick={() => navigate(`/inspections/${machineId}/${serviceId}`)}>
          Batal
        </Button>
      </div>
    </div>
  );
}
