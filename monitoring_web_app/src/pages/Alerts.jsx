import { useEffect, useState } from 'react';
import { useAuth } from '../auth/AuthContext';
import { API } from '../lib/api';
import { Card } from '../components/ui';
import { useToast } from '../components/Toast';

export default function Alerts() {
  const { token } = useAuth();
  const toast = useToast();
  const [alerts, setAlerts] = useState([]);
  const [loading, setLoading] = useState(true);

  async function load() {
    const res = await API.getAlerts(token);
    setAlerts(res.data ?? res);
    setLoading(false);
  }
  useEffect(() => {
    load();
  }, [token]);

  async function resolve(id) {
    try {
      await API.updateAlert(token, id, { status: 'resolved', is_resolved: true });
      toast.notify('Alert diselesaikan', 'success');
      load();
    } catch (e) {
      toast.notify(e.message, 'error');
    }
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-navy mb-1">Alert</h1>
      <p className="text-gray-500 mb-6">Daftar peringatan dari seluruh lori</p>
      {loading ? (
        <p className="text-gray-500">Memuat...</p>
      ) : (
        <div className="space-y-3">
          {alerts.map((a) => (
            <Card key={a.id_alert} className="p-4 flex items-center justify-between">
              <div>
                <p className="font-medium text-navy">{a.description || 'Alert'}</p>
                <p className="text-sm text-gray-500">
                  {a.status} · {a.severity} · Lori #{a.id_mesin}
                </p>
              </div>
              <div className="flex items-center gap-2">
                <span
                  className={`px-2 py-1 rounded-full text-xs font-semibold ${
                    a.is_resolved || a.status === 'resolved'
                      ? 'bg-green-100 text-green-700'
                      : 'bg-red-100 text-red-700'
                  }`}
                >
                  {a.is_resolved || a.status === 'resolved' ? 'Selesai' : 'Terbuka'}
                </span>
                {!(a.is_resolved || a.status === 'resolved') && (
                  <button
                    onClick={() => resolve(a.id_alert)}
                    className="px-3 py-1.5 rounded-lg bg-brand text-white text-sm font-medium"
                  >
                    Selesaikan
                  </button>
                )}
              </div>
            </Card>
          ))}
          {!alerts.length && <p className="text-gray-400">Tidak ada alert.</p>}
        </div>
      )}
    </div>
  );
}
