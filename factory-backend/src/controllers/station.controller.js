const crudFactory = require("../utils/crudFactory");
const db = require("../config/db");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");

const ctrl = crudFactory("station", "id_station");

// Override create: kolom lokasi_station NOT NULL tanpa default di schema,
// tapi mobile tidak mengirimkannya -> fallback agar insert tidak gagal.
ctrl.create = asyncHandler(async (req, res) => {
  const { id_factory, nama_station, lokasi_station } = req.body;
  if (!id_factory || !nama_station) {
    throw new ApiError(400, "id_factory dan nama_station wajib diisi");
  }

  const loc =
    lokasi_station && lokasi_station.toString().trim().isNotEmpty
      ? lokasi_station.toString().trim()
      : `Lokasi ${nama_station}`;

  const [result] = await db.query(
    "INSERT INTO station (id_factory, nama_station, lokasi_station) VALUES (?, ?, ?)",
    [id_factory, nama_station, loc],
  );

  const [rows] = await db.query(
    "SELECT * FROM station WHERE id_station = ?",
    [result.insertId],
  );

  res.status(201).json({ success: true, data: rows[0] });
});

module.exports = ctrl;
