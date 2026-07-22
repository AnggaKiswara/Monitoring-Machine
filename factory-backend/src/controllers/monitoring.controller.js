const db = require("../config/db");

const SESSION_STATUS = ['Good', 'Alert', 'Danger'];

function getStatusVibration(value) {
  if (value === null || value === undefined || isNaN(value)) return 'Good';
  if (value <= 2.8) return 'Good';
  if (value >= 4.8) return 'Danger';
  return 'Alert';
}
function getStatusBearing(value) {
  if (value === null || value === undefined || isNaN(value)) return 'Good';
  if (value <= 2.0) return 'Good';
  if (value >= 4.0) return 'Danger';
  return 'Alert';
}
function getStatusTemp(value) {
  if (value === null || value === undefined || isNaN(value)) return 'Good';
  if (value <= 50) return 'Good';
  if (value >= 70) return 'Danger';
  return 'Alert';
}

const THERESHOLD = {
  vibration_horizontal: getStatusVibration,
  vibration_vertical: getStatusVibration,
  bearing_inner: getStatusBearing,
  bearing_outer: getStatusBearing,
  bearing_temp: getStatusTemp,
};

// POST create monitoring session
exports.createSession = async (req, res) => {
  try {
    const { id_mesin, hm, rpm, remarks, readings } = req.body;
    if (!id_mesin) {
      return res.status(400).json({ success: false, message: 'id_mesin wajib diisi' });
    }
    const [session] = await db.query('INSERT INTO monitoring_session (id_mesin, hm, rpm, remarks, recorded_at) VALUES (?, ?, ?, ?, NOW())', [id_mesin, hm ?? null, rpm ?? null, remarks ?? null]);
    const id_session = session.insertId;

    if (Array.isArray(readings) && readings.length > 0) {
      for (const r of readings) {
        const id_parameter = r.id_parameter;
        const nilai = parseFloat(r.nilai);
        if (!id_parameter || Number.isNaN(nilai)) continue;

        const [paramRow] = await db.query('SELECT nama_parameter FROM parameter WHERE id_parameter = ?', [id_parameter]);
        const nama = paramRow?.length ? paramRow[0].nama_parameter : '';
        const statusFn = THERESHOLD[nama] || (() => 'Good');
        const status = statusFn(nilai);

        await db.query('INSERT INTO monitoring_reading (id_session, id_parameter, nilai, status) VALUES (?, ?, ?, ?)', [id_session, id_parameter, nilai, status]);
      }
    }

    const [[createdSession]] = await db.query('SELECT * FROM monitoring_session WHERE id_session = ?', [id_session]);
    return res.status(201).json({
      success: true,
      message: 'Monitoring session disimpan',
      data: { id_session, ...createdSession },
    });
  } catch (error) {
    console.error('Error create monitoring session:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// GET latest monitoring session for machine
exports.getLatestSession = async (req, res) => {
  try {
    const { id_mesin } = req.params;
    const [[session]] = await db.query('SELECT * FROM monitoring_session WHERE id_mesin = ? ORDER BY recorded_at DESC LIMIT 1', [id_mesin]);
    if (!session) {
      return res.json({ success: true, data: null });
    }
    const [readings] = await db.query(
      'SELECT mr.id_reading, mr.id_parameter, mr.nilai, mr.status, p.nama_parameter FROM monitoring_reading mr JOIN parameter p ON mr.id_parameter = p.id_parameter WHERE mr.id_session = ?',
      [session.id_session]
    );
    return res.json({ success: true, data: { session, readings } });
  } catch (error) {
    console.error('Error get latest monitoring session:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// GET monitoring sessions history for machine
exports.getHistory = async (req, res) => {
  try {
    const { id_mesin } = req.params;
    const limit = parseInt(req.query.limit) || 20;
    const [sessions] = await db.query('SELECT * FROM monitoring_session WHERE id_mesin = ? ORDER BY recorded_at DESC LIMIT ?', [id_mesin, limit]);
    return res.json({ success: true, data: sessions });
  } catch (error) {
    console.error('Error get monitoring history:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};
