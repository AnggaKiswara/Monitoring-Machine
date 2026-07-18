import { useEffect, useState } from 'react';
import { useAuth } from '../auth/AuthContext';
import { API } from '../lib/api';
import { Card, Button } from '../components/ui';
import { Modal, Field, inputClass } from '../components/Modal';
import { useToast } from '../components/Toast';

export default function AlertRules() {
  const { token } = useAuth();
  const toast = useToast();
  const [rules, setRules] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({
    nama_rule: '',
    metric: 'health_mesin',
    operator: '<',
    threshold: 70,
    severity: 'warning',
  });

  async function load() {
    const res = await API.getAlertRules(token);
    setRules(res.data ?? res);
    setLoading(false);
  }
  useEffect(() => {
    load();
  }, [token]);

  function openAdd() {
    setEditing(null);
    setForm({ nama_rule: '', metric: 'health_mesin', operator: '<', threshold: 70, severity: 'warning' });
    setModal(true);
  }
  function openEdit(r) {
    setEditing(r);
    setForm({
      nama_rule: r.nama_rule,
      metric: r.metric,
      operator: r.operator,
      threshold: r.threshold,
      severity: r.severity,
    });
    setModal(true);
  }

  async function save() {
    try {
      if (editing) await API.updateAlertRule(token, editing.id_rule, form);
      else await API.createAlertRule(token, form);
      toast.notify('Aturan disimpan', 'success');
      setModal(false);
      load();
    } catch (e) {
      toast.notify(e.message, 'error');
    }
  }
  async function remove(r) {
    if (!confirm(`Hapus aturan "${r.nama_rule}"?`)) return;
    await API.deleteAlertRule(token, r.id_rule);
    toast.notify('Aturan dihapus', 'success');
    load();
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-navy">Aturan Alert</h1>
          <p className="text-gray-500 text-sm">Buat threshold peringatan otomatis</p>
        </div>
        <Button onClick={openAdd}>+ Tambah Aturan</Button>
      </div>

      {loading ? (
        <p className="text-gray-500">Memuat...</p>
      ) : (
        <Card className="overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-gray-500 border-b bg-gray-50">
                <th className="py-3 px-4">Nama</th>
                <th className="px-4">Metric</th>
                <th className="px-4">Kondisi</th>
                <th className="px-4">Severity</th>
                <th className="px-4"></th>
              </tr>
            </thead>
            <tbody>
              {rules.map((r) => (
                <tr key={r.id_rule} className="border-b border-gray-50">
                  <td className="py-3 px-4 font-medium text-navy">{r.nama_rule}</td>
                  <td className="px-4">{r.metric}</td>
                  <td className="px-4">
                    {r.operator} {r.threshold}
                  </td>
                  <td className="px-4">{r.severity}</td>
                  <td className="px-4 text-right">
                    <button onClick={() => openEdit(r)} className="text-brand mr-3">
                      Edit
                    </button>
                    <button onClick={() => remove(r)} className="text-red-600">
                      Hapus
                    </button>
                  </td>
                </tr>
              ))}
              {!rules.length && (
                <tr>
                  <td colSpan={5} className="py-6 text-center text-gray-400">
                    Belum ada aturan
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </Card>
      )}

      <Modal
        open={modal}
        title={editing ? 'Edit Aturan' : 'Tambah Aturan'}
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
        <Field label="Nama Aturan">
          <input className={inputClass} value={form.nama_rule} onChange={(e) => setForm({ ...form, nama_rule: e.target.value })} />
        </Field>
        <Field label="Metric">
          <select className={inputClass} value={form.metric} onChange={(e) => setForm({ ...form, metric: e.target.value })}>
            <option value="health_mesin">health_mesin</option>
            <option value="health_station">health_station</option>
          </select>
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Operator">
            <select className={inputClass} value={form.operator} onChange={(e) => setForm({ ...form, operator: e.target.value })}>
              <option value="<">&lt;</option>
              <option value=">">&gt;</option>
              <option value="<=">≤</option>
              <option value=">=">≥</option>
            </select>
          </Field>
          <Field label="Threshold (%)">
            <input type="number" className={inputClass} value={form.threshold} onChange={(e) => setForm({ ...form, threshold: Number(e.target.value) })} />
          </Field>
        </div>
        <Field label="Severity">
          <select className={inputClass} value={form.severity} onChange={(e) => setForm({ ...form, severity: e.target.value })}>
            <option value="warning">warning</option>
            <option value="critical">critical</option>
            <option value="info">info</option>
          </select>
        </Field>
      </Modal>
    </div>
  );
}
