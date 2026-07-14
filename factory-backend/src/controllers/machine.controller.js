const crudFactory = require("../utils/crudFactory");
const db = require("../config/db");

// Simpan hasil crudFactory ke variable
const crud = crudFactory("machine", "id_mesin");

// Export method dari crudFactory
module.exports = {
  getAll: crud.getAll,
  getOne: crud.getOne,
  update: crud.update,
  remove: crud.remove,
};

// POST - Create machine baru
module.exports.create = async (req, res) => {
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
module.exports.updateHM = async (req, res) => {
  try {
    const { id } = req.params;
    const { hm_current } = req.body;
    const id_user = req.user?.id_user;

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

    // Insert to service history (sesuai struktur tabel yang ada)
    await db.query(
      `INSERT INTO service_history 
       (id_user, id_station, id_mesin, service_type, description, health_mesin_before, health_mesin_after, service_date, next_service_date) 
       VALUES (?, ?, ?, 'inspection', ?, ?, ?, NOW(), ?)`,
      [
        id_user,
        machine.id_station,
        id,
        `HM updated to ${hm_current}`,
        machine.health_mesin,
        machine.health_mesin,
        new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // Next service 7 hari
      ],
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
module.exports.recordPM = async (req, res) => {
  try {
    const { id } = req.params;
    const { tanggal_service, keterangan } = req.body;
    const id_user = req.user?.id_user;

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

    // Hitung next service date (7 hari setelah tanggal PM)
    const nextServiceDate = new Date(new Date(tanggal_service).getTime() + 7 * 24 * 60 * 60 * 1000);

    // Insert to service history (sesuai struktur tabel yang ada)
    await db.query(
      `INSERT INTO service_history 
       (id_user, id_station, id_mesin, service_type, description, health_mesin_before, health_mesin_after, service_date, next_service_date) 
       VALUES (?, ?, ?, 'preventive', ?, ?, ?, ?, ?)`,
      [
        id_user,
        machine.id_station,
        id,
        keterangan || "Preventive Maintenance",
        machine.health_mesin,
        machine.health_mesin,
        tanggal_service || new Date(),
        nextServiceDate,
      ],
    );

    res.json({
      success: true,
      message: "PM berhasil dicatat",
      data: {
        last_pm_date: tanggal_service || new Date(),
        next_pm_date: nextServiceDate,
        next_pm_hm: machine.hm_current + machine.pm_interval,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET - Get service history
module.exports.getServiceHistory = async (req, res) => {
  try {
    const { id } = req.params;
    const { limit = 10, offset = 0 } = req.query;

    const query = `
      SELECT 
        sh.id_service,
        sh.service_type,
        sh.description,
        sh.health_mesin_before,
        sh.health_mesin_after,
        sh.service_date,
        sh.next_service_date,
        u.nama_lengkap as teknisi_name
      FROM service_history sh
      LEFT JOIN user_account u ON sh.id_user = u.id_user
      WHERE sh.id_mesin = ?
      ORDER BY sh.service_date DESC
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
module.exports.getPMStatus = async (req, res) => {
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

// POST - Submit Inspection (simpan inspeksi lengkap dalam 1 transaksi)
module.exports.submitInspection = async (req, res) => {
  const connection = await db.getConnection();

  try {
    const { id } = req.params;
    const { tanggal_inspeksi, pic, keterangan, komponen_conditions } = req.body;
    const id_user = req.user?.id_user;

    // Validasi input
    if (!pic || !pic.trim()) {
      connection.release();
      return res.status(400).json({
        success: false,
        message: "PIC wajib diisi",
      });
    }

    if (!komponen_conditions || komponen_conditions.length === 0) {
      connection.release();
      return res.status(400).json({
        success: false,
        message: "Minimal 1 komponen harus dinilai",
      });
    }

    await connection.beginTransaction();

    // 1. Get current machine data
    const [machines] = await connection.query("SELECT * FROM machine WHERE id_mesin = ?", [id]);

    if (machines.length === 0) {
      await connection.rollback();
      connection.release();
      return res.status(404).json({
        success: false,
        message: "Machine tidak ditemukan",
      });
    }

    const machine = machines[0];
    const healthBefore = machine.health_mesin || 0;
    const serviceDate = tanggal_inspeksi || new Date().toISOString().split("T")[0];

    // 2. Process setiap komponen
    let totalNilai = 0;
    let komponenCount = 0;

    for (const item of komponen_conditions) {
      const { id_komponen, kondisi, nilai } = item;

      // Ambil parameter yang terkait dengan komponen ini
      const [parameters] = await connection.query(
        `SELECT p.id_parameter
         FROM parameter p
         JOIN komponen_parameter kp ON p.id_parameter = kp.id_parameter
         WHERE kp.id_komponen = ? AND kp.is_active = 1`,
        [id_komponen]
      );

      // Insert sensor_reading untuk setiap parameter
      for (const param of parameters) {
        await connection.query(
          `INSERT INTO sensor_reading (id_komponen, id_parameter, nilai, recorded_at)
           VALUES (?, ?, ?, ?)`,
          [id_komponen, param.id_parameter, nilai, serviceDate]
        );
      }

      // Update kesehatan komponen
      await connection.query(
        `UPDATE komponen SET avg_health_all_parameter = ?, last_service = ?, updated_at = NOW()
         WHERE id_komponen = ?`,
        [nilai, serviceDate, id_komponen]
      );

      totalNilai += nilai;
      komponenCount++;
    }

    // 3. Hitung health baru (rata-rata semua komponen)
    const healthAfter = komponenCount > 0 ? Math.round((totalNilai / komponenCount) * 100) / 100 : healthBefore;

    // 4. Next service date (+7 hari)
    const nextServiceDate = new Date(new Date(serviceDate).getTime() + 7 * 24 * 60 * 60 * 1000);

    // 5. Build description: "PIC: nama - keterangan"
    const description = "PIC: " + pic.trim() + (keterangan ? " - " + keterangan.trim() : "");

    // 6. Insert service_history
    const [historyResult] = await connection.query(
      `INSERT INTO service_history
       (id_user, id_station, id_mesin, service_type, description,
        health_mesin_before, health_mesin_after, service_date, next_service_date, created_at)
       VALUES (?, ?, ?, 'inspection', ?, ?, ?, ?, ?, NOW())`,
      [id_user || null, machine.id_station, id, description, healthBefore, healthAfter, serviceDate, nextServiceDate]
    );

    // 7. Update machine health & service dates
    await connection.query(
      `UPDATE machine
       SET health_mesin = ?, last_service = ?, next_service = ?, updated_at = NOW()
       WHERE id_mesin = ?`,
      [healthAfter, serviceDate, nextServiceDate, id]
    );

    await connection.commit();

    res.status(201).json({
      success: true,
      message: "Inspeksi berhasil disimpan",
      data: {
        id_service: historyResult.insertId,
        health_before: healthBefore,
        health_after: healthAfter,
        service_date: serviceDate,
        next_service_date: nextServiceDate,
        komponen_count: komponenCount,
        description: description,
      },
    });
  } catch (error) {
    await connection.rollback();
    console.error("Error submitting inspection:", error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  } finally {
    connection.release();
  }
};
