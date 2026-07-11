const crudFactory = require("../utils/crudFactory");

module.exports = crudFactory("machine", "id_mesin");

// POST - Create machine baru
exports.create = async (req, res) => {
  try {
    const { id_station, kode_mesin, nama_mesin, health_mesin } = req.body;

    const [result] = await db.query("INSERT INTO machine (id_station, kode_mesin, nama_mesin, health_mesin, created_at) VALUES (?, ?, ?, ?, NOW())", [
      id_station,
      kode_mesin || null,
      nama_mesin,
      health_mesin || 0,
    ]);

    res.status(201).json({
      success: true,
      data: {
        id_mesin: result.insertId,
        id_station,
        kode_mesin,
        nama_mesin,
        health_mesin: health_mesin || 0,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
