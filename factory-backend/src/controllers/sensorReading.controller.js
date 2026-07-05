const pool = require("../config/db");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");
const { checkAndCreateAlert, autoResolveAlerts } = require("../services/alert.service");

// Insert reading baru + otomatis jalanin pengecekan alert & auto-resolve
const create = asyncHandler(async (req, res) => {
  const { id_komponen, id_parameter, nilai } = req.body;
  if (!id_komponen || !id_parameter || nilai === undefined) {
    throw new ApiError(400, "id_komponen, id_parameter, dan nilai wajib diisi");
  }

  const [komponenRows] = await pool.query(
    "SELECT id_mesin FROM komponen WHERE id_komponen = ?",
    [id_komponen]
  );
  if (!komponenRows.length) throw new ApiError(404, "Komponen tidak ditemukan");
  const { id_mesin } = komponenRows[0];

  const [result] = await pool.query(
    "INSERT INTO sensor_reading (id_komponen, id_parameter, nilai) VALUES (?, ?, ?)",
    [id_komponen, id_parameter, nilai]
  );
  const id_reading = result.insertId;

  const alertResult = await checkAndCreateAlert({
    id_mesin,
    id_komponen,
    id_parameter,
    id_reading,
    nilai,
  });

  if (!alertResult.triggered) {
    await autoResolveAlerts({ id_komponen, id_parameter, nilai });
  }

  res.status(201).json({
    success: true,
    data: { id_reading, id_komponen, id_parameter, nilai },
    alert: alertResult,
  });
});

// Ambil histori reading, dengan filter waktu buat kebutuhan grafik/tren
const getHistory = asyncHandler(async (req, res) => {
  const { id_komponen, id_parameter, from, to, limit = 500 } = req.query;
  if (!id_komponen || !id_parameter) {
    throw new ApiError(400, "id_komponen dan id_parameter wajib diisi sebagai query param");
  }

  let query = `SELECT id_reading, nilai, recorded_at FROM sensor_reading
               WHERE id_komponen = ? AND id_parameter = ?`;
  const values = [id_komponen, id_parameter];

  if (from) {
    query += " AND recorded_at >= ?";
    values.push(from);
  }
  if (to) {
    query += " AND recorded_at <= ?";
    values.push(to);
  }
  query += " ORDER BY recorded_at DESC LIMIT ?";
  values.push(Number(limit));

  const [rows] = await pool.query(query, values);
  res.json({ success: true, data: rows });
});

// Nilai terakhir per parameter buat 1 komponen (buat dashboard "current status")
const getLatest = asyncHandler(async (req, res) => {
  const { id_komponen } = req.params;

  const [rows] = await pool.query(
    `SELECT sr.id_parameter, p.nama_parameter, p.satuan, sr.nilai, sr.recorded_at
     FROM sensor_reading sr
     JOIN parameter p ON p.id_parameter = sr.id_parameter
     INNER JOIN (
       SELECT id_parameter, MAX(recorded_at) AS max_time
       FROM sensor_reading
       WHERE id_komponen = ?
       GROUP BY id_parameter
     ) latest ON latest.id_parameter = sr.id_parameter AND latest.max_time = sr.recorded_at
     WHERE sr.id_komponen = ?`,
    [id_komponen, id_komponen]
  );

  res.json({ success: true, data: rows });
});

module.exports = { create, getHistory, getLatest };
