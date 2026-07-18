const crudFactory = require("../utils/crudFactory");
const db = require("../config/db");

const ctrl = crudFactory("service_history", "id_service");

// GET /service-history/global - semua inspeksi dari semua pabrik (join factory/station/machine)
ctrl.getGlobal = async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;

    const query = `
      SELECT
        sh.id_service,
        sh.service_type,
        sh.description,
        sh.health_mesin_before,
        sh.health_mesin_after,
        DATE_FORMAT(sh.service_date, '%Y-%m-%d') as service_date,
        DATE_FORMAT(sh.next_service_date, '%Y-%m-%d') as next_service_date,
        u.nama_lengkap as teknisi_name,
        f.id_factory,
        f.nama_factory,
        st.id_station,
        st.nama_station,
        m.id_mesin,
        m.nama_mesin as nama_lori,
        m.kode_mesin
      FROM service_history sh
      LEFT JOIN user_account u ON sh.id_user = u.id_user
      LEFT JOIN machine m ON sh.id_mesin = m.id_mesin
      LEFT JOIN station st ON m.id_station = st.id_station
      LEFT JOIN factory f ON st.id_factory = f.id_factory
      WHERE sh.service_type = 'inspection'
      ORDER BY sh.created_at DESC, sh.id_service DESC
      LIMIT ? OFFSET ?
    `;

    const [history] = await db.query(query, [
      parseInt(limit),
      parseInt(offset),
    ]);

    res.json({ success: true, data: history });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = ctrl;
