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

// POST - Update HM
exports.updateHM = async (req, res) => {
  try {
    const { id } = req.params;
    const { hm_current } = req.body;
    const teknisi_id = req.user?.id_user;

    if (!hm_current || hm_current < 0) {
      return res.status(400).json({
        success: false,
        message: "HM value harus lebih dari 0",
      });
    }

    // Get current machine data
    const [machines] = await db.query("SELECT * FROM machine WHERE id_mesin = ?", [id]);
    if (machines.length === 0) {
      return res.status(404).json({ success: false, message: "Machine not found" });
    }

    const machine = machines[0];

    // Update HM
    await db.query("UPDATE machine SET hm_current = ?, updated_at = NOW() WHERE id_mesin = ?", [hm_current, id]);

    // Insert to service history
    await db.query(
      "INSERT INTO service_history (id_mesin, service_type, hm_value, tanggal_service, teknisi_id, keterangan) VALUES (?, ?, ?, NOW(), ?, ?)",
      [id, "HM", hm_current, teknisi_id, `HM updated to ${hm_current}`],
    );

    // Check if PM is needed
    const hoursSinceLastService = hm_current - machine.hm_last_service;
    const needPM = hoursSinceLastService >= machine.pm_interval;

    res.json({
      success: true,
      message: "HM berhasil diupdate",
      data: {
        hm_current,
        need_pm: needPM,
        hours_until_pm: machine.pm_interval - hoursSinceLastService,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST - Record PM
exports.recordPM = async (req, res) => {
  try {
    const { id } = req.params;
    const { tanggal_service, keterangan } = req.body;
    const teknisi_id = req.user?.id_user;

    // Get current machine data
    const [machines] = await db.query("SELECT * FROM machine WHERE id_mesin = ?", [id]);
    if (machines.length === 0) {
      return res.status(404).json({ success: false, message: "Machine not found" });
    }

    const machine = machines[0];

    // Update PM data
    await db.query("UPDATE machine SET hm_last_service = hm_current, last_pm_date = ?, updated_at = NOW() WHERE id_mesin = ?", [
      tanggal_service || new Date(),
      id,
    ]);

    // Insert to service history
    await db.query(
      "INSERT INTO service_history (id_mesin, service_type, hm_value, tanggal_service, teknisi_id, keterangan) VALUES (?, ?, ?, ?, ?, ?)",
      [id, "PM", machine.hm_current, tanggal_service || new Date(), teknisi_id, keterangan || "Preventive Maintenance"],
    );

    res.json({
      success: true,
      message: "PM berhasil dicatat",
      data: {
        last_pm_date: tanggal_service || new Date(),
        next_pm_hm: machine.hm_current + machine.pm_interval,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET - Get service history
exports.getServiceHistory = async (req, res) => {
  try {
    const { id } = req.params;
    const { limit = 10, offset = 0 } = req.query;

    const query = `
      SELECT 
        sh.id_service,
        sh.service_type,
        sh.hm_value,
        sh.tanggal_service,
        sh.keterangan,
        u.nama_lengkap as teknisi_name
      FROM service_history sh
      LEFT JOIN user_account u ON sh.teknisi_id = u.id_user
      WHERE sh.id_mesin = ?
      ORDER BY sh.tanggal_service DESC
      LIMIT ? OFFSET ?
    `;

    const [history] = await db.query(query, [id, parseInt(limit), parseInt(offset)]);

    res.json({
      success: true,
      data: history,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET - Get PM status
exports.getPMStatus = async (req, res) => {
  try {
    const { id } = req.params;

    const [machines] = await db.query("SELECT * FROM machine WHERE id_mesin = ?", [id]);
    if (machines.length === 0) {
      return res.status(404).json({ success: false, message: "Machine not found" });
    }

    const machine = machines[0];
    const hoursSinceLastService = machine.hm_current - machine.hm_last_service;
    const hoursUntilPM = machine.pm_interval - hoursSinceLastService;
    const needPM = hoursUntilPM <= 0;

    // Calculate days until PM (estimate based on average usage)
    const daysUntilPM = Math.ceil(hoursUntilPM / 8); // Asumsi 8 jam/hari

    res.json({
      success: true,
      data: {
        hm_current: machine.hm_current,
        hm_last_service: machine.hm_last_service,
        pm_interval: machine.pm_interval,
        hours_since_last_service: hoursSinceLastService,
        hours_until_pm: hoursUntilPM,
        days_until_pm: daysUntilPM,
        need_pm: needPM,
        last_pm_date: machine.last_pm_date,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
