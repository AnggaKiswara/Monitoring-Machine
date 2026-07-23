// One-time seed: replace existing vibration machines' komponen (4 -> 5)
// sesuai tabel: Horizontal, Vertikal, Bearing Dalam, Bearing Luar, Temp (bobot 20 each)
const db = require('../src/config/db');

const VIB = [
  { nama: "Vibration Fan - Horizontal", jenis: "Vibration", bobot: 20, satuan: "mm/s" },
  { nama: "Vibration Fan - Vertikal", jenis: "Vibration", bobot: 20, satuan: "mm/s" },
  { nama: "Bearing - Bagian Dalam", jenis: "Bearing", bobot: 20, satuan: "gE" },
  { nama: "Bearing - Bagian Luar", jenis: "Bearing", bobot: 20, satuan: "gE" },
  { nama: "Bearing Temperature", jenis: "Temperature", bobot: 20, satuan: "°C" },
];

(async () => {
  try {
    const [machines] = await db.query(
      `SELECT id_mesin, nama_mesin FROM machine WHERE jenis = 'vibration' ORDER BY id_mesin`
    );
    console.log('Vibration machines found:', machines.length);

    for (const m of machines) {
      // hapus komponen lama (cascade ke komponen_parameter & sensor_reading via FK)
      await db.query(`DELETE FROM komponen WHERE id_mesin = ?`, [m.id_mesin]);

      for (const k of VIB) {
        const [r] = await db.query(
          `INSERT INTO komponen (id_mesin, nama_komponen, jenis_komponen, bobot, satuan, avg_health_all_parameter, created_at)
           VALUES (?, ?, ?, ?, ?, 0, NOW())`,
          [m.id_mesin, k.nama, k.jenis, k.bobot, k.satuan]
        );
        const idK = r.insertId;
        // map ke parameter 'kondisi' (id_parameter 1 dari seed awal)
        await db.query(
          `INSERT IGNORE INTO komponen_parameter (id_komponen, id_parameter, is_active) VALUES (?, 1, 1)`,
          [idK]
        );
      }
      console.log(`  -> ${m.nama_mesin}: 5 komponen seeded`);
    }
    console.log('SEED DONE');
    process.exit(0);
  } catch (e) {
    console.error('SEED ERROR:', e.message);
    process.exit(1);
  }
})();
