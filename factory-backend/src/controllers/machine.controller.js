const crudFactory = require("../utils/crudFactory");
const db = require("../config/db");
const multer = require("multer");
const path = require("path");

// Multer config untuk upload foto inspeksi
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, "..", "..", "uploads", "inspections"));
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, `inspection-${uniqueSuffix}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // Max 10MB
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|webp/;
    const extOk = allowed.test(path.extname(file.originalname).toLowerCase());
    const mimeOk = allowed.test(file.mimetype);
    // Android sering kirim content-URI tanpa ekstensi → andalkan mimetype
    if (mimeOk || extOk) cb(null, true);
    else cb(new Error("Hanya file gambar (jpg, png, webp) yang diizinkan"));
  },
});

// Export multer middleware agar bisa dipakai di routes
const uploadMiddleware = upload.array("photos", 10); // max 10 foto

// Simpan hasil crudFactory ke variable
const crud = crudFactory("machine", "id_mesin");

// Export method dari crudFactory
module.exports = {
  getAll: crud.getAll,
  getOne: crud.getOne,
  update: crud.update,
  remove: crud.remove,
  uploadMiddleware, // ← dipakai di machine.routes.js (upload foto inspeksi)
};

// Template komponen default untuk setiap Lori baru
const DEFAULT_KOMPONEN = [
  { nama: "Body", jenis: "Structural" },
  { nama: "Siku", jenis: "Structural" },
  { nama: "Steam Spreader", jenis: "Mechanical" },
  { nama: "Chasis", jenis: "Structural" },
  { nama: "Hook", jenis: "Mechanical" },
  { nama: "Cover Roda", jenis: "Mechanical" },
  { nama: "Roda", jenis: "Mechanical" },
  { nama: "Lantai", jenis: "Structural" },
];

// POST - Create machine baru + auto-create komponen default
module.exports.create = async (req, res) => {
  const connection = await db.getConnection();

  try {
    const { id_station, kode_mesin, nama_mesin, health_mesin } = req.body;

    await connection.beginTransaction();

    // 1. Create machine
    const [result] = await connection.query(
      "INSERT INTO machine (id_station, kode_mesin, nama_mesin, health_mesin, created_at) VALUES (?, ?, ?, ?, NOW())",
      [id_station, kode_mesin || null, nama_mesin, health_mesin || 0]
    );

    const newMachineId = result.insertId;

    // 2. Pastikan parameter "kondisi" ada
    let kondisiParamId;
    const [existingParam] = await connection.query(
      "SELECT id_parameter FROM parameter WHERE nama_parameter = 'kondisi'"
    );

    if (existingParam.length > 0) {
      kondisiParamId = existingParam[0].id_parameter;
    } else {
      const [newParam] = await connection.query(
        "INSERT INTO parameter (nama_parameter, satuan, nilai_min, nilai_max) VALUES ('kondisi', '%', 0, 100)"
      );
      kondisiParamId = newParam.insertId;
    }

    // 3. Auto-create komponen default + mapping parameter
    for (const komp of DEFAULT_KOMPONEN) {
      const [kompResult] = await connection.query(
        "INSERT INTO komponen (id_mesin, nama_komponen, jenis_komponen, avg_health_all_parameter, created_at) VALUES (?, ?, ?, 0, NOW())",
        [newMachineId, komp.nama, komp.jenis]
      );

      // Mapping komponen ke parameter "kondisi"
      await connection.query(
        "INSERT INTO komponen_parameter (id_komponen, id_parameter, is_active) VALUES (?, ?, 1)",
        [kompResult.insertId, kondisiParamId]
      );
    }

    await connection.commit();

    res.status(201).json({
      success: true,
      message: `Machine berhasil dibuat dengan ${DEFAULT_KOMPONEN.length} komponen default`,
      data: {
        id_mesin: newMachineId,
        id_station,
        kode_mesin,
        nama_mesin,
        health_mesin: health_mesin || 0,
        komponen_count: DEFAULT_KOMPONEN.length,
      },
    });
  } catch (error) {
    await connection.rollback();
    res.status(500).json({
      success: false,
      message: error.message,
    });
  } finally {
    connection.release();
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
    const [result] = await db.query(
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
        id_service: result.insertId, // ← dibutuhkan mobile utk upload foto
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
        DATE_FORMAT(sh.service_date, '%Y-%m-%d') as service_date,
        DATE_FORMAT(sh.next_service_date, '%Y-%m-%d') as next_service_date,
        u.nama_lengkap as teknisi_name
      FROM service_history sh
      LEFT JOIN user_account u ON sh.id_user = u.id_user
      WHERE sh.id_mesin = ?
      ORDER BY sh.created_at DESC, sh.id_service DESC
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

// GET - Get inspection detail (service_history + komponen readings)
module.exports.getInspectionDetail = async (req, res) => {
  try {
    const { id, serviceId } = req.params;

    // 1. Get service_history record
    const [services] = await db.query(
      `SELECT 
        sh.id_service,
        sh.service_type,
        sh.description,
        sh.health_mesin_before,
        sh.health_mesin_after,
        DATE_FORMAT(sh.service_date, '%Y-%m-%d') as service_date,
        DATE_FORMAT(sh.next_service_date, '%Y-%m-%d') as next_service_date,
        DATE_FORMAT(sh.created_at, '%Y-%m-%d %H:%i:%s') as created_at,
        u.nama_lengkap as teknisi_name
      FROM service_history sh
      LEFT JOIN user_account u ON sh.id_user = u.id_user
      WHERE sh.id_service = ? AND sh.id_mesin = ?`,
      [serviceId, id]
    );

    if (services.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Data inspeksi tidak ditemukan",
      });
    }

    const service = services[0];

    // 2. Get semua komponen machine + sensor_reading yang TERIKAT ke inspeksi ini
    const [komponenReadings] = await db.query(
      `SELECT 
        k.id_komponen,
        k.nama_komponen,
        k.jenis_komponen,
        sr.nilai,
        sr.recorded_at,
        p.nama_parameter
      FROM komponen k
      LEFT JOIN sensor_reading sr ON k.id_komponen = sr.id_komponen
        AND sr.id_service = ?
      LEFT JOIN parameter p ON sr.id_parameter = p.id_parameter
      WHERE k.id_mesin = ?
      ORDER BY k.id_komponen, p.nama_parameter`,
      [serviceId, id]
    );

    // 3. Group by komponen - ambil nilai rata-rata per komponen
    const komponenMap = {};
    for (const row of komponenReadings) {
      const key = row.id_komponen;
      if (!komponenMap[key]) {
        komponenMap[key] = {
          id_komponen: row.id_komponen,
          nama_komponen: row.nama_komponen,
          jenis_komponen: row.jenis_komponen,
          nilai: row.nilai,
          kondisi: null,
          parameters: [],
        };
      }
      if (row.nama_parameter && row.nilai !== null) {
        komponenMap[key].parameters.push({
          nama_parameter: row.nama_parameter,
          nilai: row.nilai,
        });
      }
    }

    // 4. Determine kondisi from nilai
    const komponenList = Object.values(komponenMap).map((k) => {
      // Ambil nilai dari parameter pertama (semua parameter memiliki nilai yang sama dari inspeksi)
      const nilai = k.parameters.length > 0 ? k.parameters[0].nilai : null;
      let kondisi = "-";

      if (nilai !== null) {
        if (nilai >= 95) kondisi = "Sangat Baik";
        else if (nilai >= 80) kondisi = "Baik";
        else if (nilai >= 60) kondisi = "Perlu Maintenance";
        else if (nilai >= 30) kondisi = "Rusak";
        else kondisi = "Tidak Ada";
      }

      return {
        id_komponen: k.id_komponen,
        nama_komponen: k.nama_komponen,
        jenis_komponen: k.jenis_komponen,
        nilai: nilai,
        kondisi: kondisi,
      };
    });

    // 5. Ambil foto inspeksi
    const [photos] = await db.query(
      `SELECT id_photo, id_komponen, photo_path, caption, 
        DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s') as created_at
      FROM inspection_photo 
      WHERE id_service = ?
      ORDER BY id_photo`,
      [serviceId]
    );

    res.json({
      success: true,
      data: {
        ...service,
        komponen: komponenList,
        photos: photos,
      },
    });
  } catch (error) {
    console.error("Error fetching inspection detail:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST - Upload foto inspeksi
module.exports.uploadInspectionPhotos = async (req, res) => {
  try {
    const { serviceId } = req.params;
    const { id_komponen, caption } = req.body;

    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Tidak ada file yang diupload",
      });
    }

    // Verify service exists
    const [services] = await db.query(
      "SELECT id_service FROM service_history WHERE id_service = ?",
      [serviceId]
    );
    if (services.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Data inspeksi tidak ditemukan",
      });
    }

    const insertedPhotos = [];

    for (const file of req.files) {
      const photoPath = `uploads/inspections/${file.filename}`;

      const [result] = await db.query(
        `INSERT INTO inspection_photo (id_service, id_komponen, photo_path, caption)
         VALUES (?, ?, ?, ?)`,
        [serviceId, id_komponen || null, caption || null, photoPath]
      );

      insertedPhotos.push({
        id_photo: result.insertId,
        photo_path: photoPath,
        caption: caption || null,
      });
    }

    res.status(201).json({
      success: true,
      message: `${insertedPhotos.length} foto berhasil diupload`,
      data: insertedPhotos,
    });
  } catch (error) {
    console.error("Error uploading photos:", error);
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

    // 2. Hitung health baru dari input komponen (tanpa insert dulu)
    let totalNilai = 0;
    let komponenCount = 0;
    const readingsToInsert = []; // kumpulkan (id_komponen, id_parameter, nilai)

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

      if (parameters.length > 0) {
        for (const param of parameters) {
          readingsToInsert.push([id_komponen, param.id_parameter, nilai]);
        }
      } else {
        // Jika belum ada mapping komponen_parameter, cari/buat parameter default "kondisi"
        let defaultParamId;

        const [existingParam] = await connection.query(
          `SELECT id_parameter FROM parameter WHERE nama_parameter = 'kondisi'`
        );

        if (existingParam.length > 0) {
          defaultParamId = existingParam[0].id_parameter;
        } else {
          const [newParam] = await connection.query(
            `INSERT INTO parameter (nama_parameter, satuan, nilai_min, nilai_max) VALUES ('kondisi', '%', 0, 100)`
          );
          defaultParamId = newParam.insertId;
        }

        await connection.query(
          `INSERT IGNORE INTO komponen_parameter (id_komponen, id_parameter, is_active) VALUES (?, ?, 1)`,
          [id_komponen, defaultParamId]
        );

        readingsToInsert.push([id_komponen, defaultParamId, nilai]);
        console.log(`Auto-created parameter mapping for komponen ${id_komponen}`);
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

    // 6. Insert service_history dulu → dapat id_service
    const [historyResult] = await connection.query(
      `INSERT INTO service_history
       (id_user, id_station, id_mesin, service_type, description,
        health_mesin_before, health_mesin_after, service_date, next_service_date, created_at)
       VALUES (?, ?, ?, 'inspection', ?, ?, ?, ?, ?, NOW())`,
      [id_user || null, machine.id_station, id, description, healthBefore, healthAfter, serviceDate, nextServiceDate]
    );
    const serviceId = historyResult.insertId;

    // 6b. Insert sensor_reading terikat ke id_service ini
    for (const [id_komponen, id_parameter, nilai] of readingsToInsert) {
      await connection.query(
        `INSERT INTO sensor_reading (id_komponen, id_parameter, nilai, recorded_at, id_service)
         VALUES (?, ?, ?, ?, ?)`,
        [id_komponen, id_parameter, nilai, serviceDate, serviceId]
      );
    }

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
