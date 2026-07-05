const pool = require("../config/db");

/**
 * Evaluasi 1 nilai terhadap 1 rule. Return true kalau nilai dianggap anomali.
 */
function evaluateRule(operator, nilai, batas1, batas2) {
  switch (operator) {
    case ">":
      return nilai > batas1;
    case "<":
      return nilai < batas1;
    case ">=":
      return nilai >= batas1;
    case "<=":
      return nilai <= batas1;
    case "between":
      // anomali kalau nilai JUSTRU masuk rentang ini (rentang "bahaya")
      return nilai >= batas1 && nilai <= batas2;
    case "outside":
      // anomali kalau nilai di LUAR rentang normal
      return nilai < batas1 || nilai > batas2;
    default:
      throw new Error(`Operator tidak dikenal: ${operator}`);
  }
}

/**
 * Dipanggil setiap kali ada sensor_reading baru masuk.
 * Alur:
 * 1. Ambil semua alert_rule aktif untuk parameter ini (prioritas rule spesifik komponen > general)
 * 2. Evaluasi tiap rule terhadap nilai yang baru masuk
 * 3. Kalau kena, cek dulu apakah masih ada alert 'open' utk kombinasi id_komponen+id_rule yang sama
 *    - Kalau ada -> update nilai_terdeteksi & updated_at (hindari alert dobel)
 *    - Kalau belum ada -> insert alert baru
 */
async function checkAndCreateAlert({ id_mesin, id_komponen, id_parameter, id_reading, nilai }) {
  const [rules] = await pool.query(
    `SELECT id_rule, operator, nilai_batas_1, nilai_batas_2, severity, pesan_custom
     FROM alert_rule
     WHERE id_parameter = ?
       AND is_active = TRUE
       AND (id_komponen = ? OR id_komponen IS NULL)
     ORDER BY id_komponen IS NULL ASC`,
    [id_parameter, id_komponen]
  );

  for (const rule of rules) {
    const isAnomaly = evaluateRule(rule.operator, nilai, rule.nilai_batas_1, rule.nilai_batas_2);
    if (!isAnomaly) continue;

    const [existing] = await pool.query(
      `SELECT id_alert FROM service_alert
       WHERE id_komponen = ? AND id_rule = ? AND status = 'open'
       LIMIT 1`,
      [id_komponen, rule.id_rule]
    );

    if (existing.length) {
      await pool.query(
        `UPDATE service_alert SET nilai_terdeteksi = ?, id_reading = ?, updated_at = NOW()
         WHERE id_alert = ?`,
        [nilai, id_reading, existing[0].id_alert]
      );
      return { triggered: true, alert_id: existing[0].id_alert, deduped: true };
    }

    const [result] = await pool.query(
      `INSERT INTO service_alert
        (id_mesin, id_komponen, id_rule, id_reading, description, status, nilai_terdeteksi, severity, is_resolved)
       VALUES (?, ?, ?, ?, ?, 'open', ?, ?, FALSE)`,
      [
        id_mesin,
        id_komponen,
        rule.id_rule,
        id_reading,
        rule.pesan_custom || "Nilai parameter anomali",
        nilai,
        rule.severity,
      ]
    );

    return { triggered: true, alert_id: result.insertId, deduped: false };
  }

  return { triggered: false };
}

/**
 * Auto-resolve alert kalau nilai terbaru udah balik normal.
 * Dipanggil juga tiap ada reading baru, setelah checkAndCreateAlert.
 */
async function autoResolveAlerts({ id_komponen, id_parameter, nilai }) {
  const [openAlerts] = await pool.query(
    `SELECT sa.id_alert, ar.operator, ar.nilai_batas_1, ar.nilai_batas_2
     FROM service_alert sa
     JOIN alert_rule ar ON ar.id_rule = sa.id_rule
     WHERE sa.id_komponen = ? AND sa.status = 'open' AND ar.id_parameter = ?`,
    [id_komponen, id_parameter]
  );

  for (const alert of openAlerts) {
    const stillAnomaly = evaluateRule(alert.operator, nilai, alert.nilai_batas_1, alert.nilai_batas_2);
    if (!stillAnomaly) {
      await pool.query(
        `UPDATE service_alert SET status = 'resolved', is_resolved = TRUE, resolved_at = NOW()
         WHERE id_alert = ?`,
        [alert.id_alert]
      );
    }
  }
}

module.exports = { evaluateRule, checkAndCreateAlert, autoResolveAlerts };
