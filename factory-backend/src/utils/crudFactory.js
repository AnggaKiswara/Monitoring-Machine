const pool = require("../config/db");
const asyncHandler = require("./asyncHandler");
const ApiError = require("./ApiError");

/**
 * Factory buat generate handler CRUD standar (getAll, getOne, create, update, remove)
 * untuk tabel yang gak punya logic khusus. Tabel yang butuh logic tambahan
 * (misal sensor_reading yang trigger alert check) tetap punya controller sendiri.
 */
function crudFactory(table, primaryKey) {
  const getAll = asyncHandler(async (req, res) => {
    const { limit = 50, offset = 0, ...filters } = req.query;

    let query = `SELECT * FROM ${table}`;
    const values = [];
    const whereClauses = Object.keys(filters).map((key) => {
      values.push(filters[key]);
      return `${key} = ?`;
    });

    if (whereClauses.length) {
      query += ` WHERE ${whereClauses.join(" AND ")}`;
    }
    query += ` ORDER BY ${primaryKey} DESC LIMIT ? OFFSET ?`;
    values.push(Number(limit), Number(offset));

    const [rows] = await pool.query(query, values);
    res.json({ success: true, data: rows });
  });

  const getOne = asyncHandler(async (req, res) => {
    const [rows] = await pool.query(
      `SELECT * FROM ${table} WHERE ${primaryKey} = ?`,
      [req.params.id]
    );
    if (!rows.length) throw new ApiError(404, `${table} tidak ditemukan`);
    res.json({ success: true, data: rows[0] });
  });

  const create = asyncHandler(async (req, res) => {
    const [result] = await pool.query(`INSERT INTO ${table} SET ?`, [req.body]);
    const [rows] = await pool.query(
      `SELECT * FROM ${table} WHERE ${primaryKey} = ?`,
      [result.insertId]
    );
    res.status(201).json({ success: true, data: rows[0] });
  });

  const update = asyncHandler(async (req, res) => {
    const [result] = await pool.query(
      `UPDATE ${table} SET ? WHERE ${primaryKey} = ?`,
      [req.body, req.params.id]
    );
    if (!result.affectedRows) throw new ApiError(404, `${table} tidak ditemukan`);
    const [rows] = await pool.query(
      `SELECT * FROM ${table} WHERE ${primaryKey} = ?`,
      [req.params.id]
    );
    res.json({ success: true, data: rows[0] });
  });

  const remove = asyncHandler(async (req, res) => {
    const [result] = await pool.query(
      `DELETE FROM ${table} WHERE ${primaryKey} = ?`,
      [req.params.id]
    );
    if (!result.affectedRows) throw new ApiError(404, `${table} tidak ditemukan`);
    res.json({ success: true, message: `${table} berhasil dihapus` });
  });

  return { getAll, getOne, create, update, remove };
}

module.exports = crudFactory;
