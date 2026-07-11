const db = require("../config/db");

// POST - Insert sensor reading baru
exports.create = async (req, res) => {
  try {
    const { id_komponen, id_parameter, nilai } = req.body;

    // Validasi input
    if (!id_komponen || !id_parameter || nilai === undefined) {
      return res.status(400).json({
        success: false,
        message: "id_komponen, id_parameter, dan nilai wajib diisi",
      });
    }

    // Cek apakah komponen dan parameter valid
    const [komponenCheck] = await db.query("SELECT * FROM komponen WHERE id_komponen = ?", [id_komponen]);

    if (komponenCheck.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Komponen tidak ditemukan",
      });
    }

    // Cek apakah parameter ter-mapping ke komponen
    const [mappingCheck] = await db.query("SELECT * FROM komponen_parameter WHERE id_komponen = ? AND id_parameter = ?", [id_komponen, id_parameter]);

    if (mappingCheck.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Parameter tidak valid untuk komponen ini",
      });
    }

    // Insert sensor reading
    const [result] = await db.query("INSERT INTO sensor_reading (id_komponen, id_parameter, nilai, recorded_at) VALUES (?, ?, ?, NOW())", [
      id_komponen,
      id_parameter,
      nilai,
    ]);

    res.status(201).json({
      success: true,
      message: "Sensor reading berhasil disimpan",
      data: {
        id_reading: result.insertId,
        id_komponen,
        id_parameter,
        nilai,
        recorded_at: new Date(),
      },
    });
  } catch (error) {
    console.error("Error creating sensor reading:", error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// GET - Ambil parameter yang relevan dengan komponen tertentu
exports.getParametersByKomponen = async (req, res) => {
  try {
    const { id_komponen } = req.params;

    const query = `
      SELECT 
        p.id_parameter,
        p.nama_parameter,
        p.satuan,
        p.nilai_min,
        p.nilai_max,
        kp.nilai_min_override,
        kp.nilai_max_override
      FROM parameter p
      JOIN komponen_parameter kp ON p.id_parameter = kp.id_parameter
      WHERE kp.id_komponen = ? AND kp.is_active = 1
      ORDER BY p.nama_parameter
    `;

    const [parameters] = await db.query(query, [id_komponen]);

    res.json({
      success: true,
      data: parameters,
    });
  } catch (error) {
    console.error("Error fetching parameters:", error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// GET - Ambil history sensor reading untuk komponen tertentu
exports.getHistory = async (req, res) => {
  try {
    const { id_komponen } = req.params;
    const { limit = 10, offset = 0 } = req.query;

    const query = `
      SELECT 
        sr.id_reading,
        sr.id_komponen,
        sr.id_parameter,
        sr.nilai,
        sr.recorded_at,
        p.nama_parameter,
        p.satuan
      FROM sensor_reading sr
      JOIN parameter p ON sr.id_parameter = p.id_parameter
      WHERE sr.id_komponen = ?
      ORDER BY sr.recorded_at DESC
      LIMIT ? OFFSET ?
    `;

    const [readings] = await db.query(query, [id_komponen, parseInt(limit), parseInt(offset)]);

    res.json({
      success: true,
      data: readings,
      total: readings.length,
    });
  } catch (error) {
    console.error("Error fetching history:", error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// GET - Ambil sensor reading terbaru untuk komponen
exports.getLatest = async (req, res) => {
  try {
    const { id_komponen } = req.params;

    const query = `
      SELECT 
        sr.id_reading,
        sr.id_komponen,
        sr.id_parameter,
        sr.nilai,
        sr.recorded_at,
        p.nama_parameter,
        p.satuan
      FROM sensor_reading sr
      JOIN parameter p ON sr.id_parameter = p.id_parameter
      WHERE sr.id_komponen = ?
      ORDER BY sr.recorded_at DESC
      LIMIT 1
    `;

    const [readings] = await db.query(query, [id_komponen]);

    if (readings.length === 0) {
      return res.json({
        success: true,
        data: null,
        message: "Belum ada data sensor reading",
      });
    }

    res.json({
      success: true,
      data: readings[0],
    });
  } catch (error) {
    console.error("Error fetching latest reading:", error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
