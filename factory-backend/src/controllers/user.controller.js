const db = require("../config/db");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");

const ALLOWED_ROLES = ["admin", "staff", "teknisi"];

const getAll = asyncHandler(async (req, res) => {
  const [rows] = await db.query(
    "SELECT id_user, username, nama_lengkap, role_user, is_active, created_at FROM user_account ORDER BY id_user",
  );
  res.json({ success: true, data: rows });
});

const getOne = asyncHandler(async (req, res) => {
  const [rows] = await db.query(
    "SELECT id_user, username, nama_lengkap, role_user, is_active, created_at FROM user_account WHERE id_user = ?",
    [req.params.id],
  );
  if (!rows.length) throw new ApiError(404, "User tidak ditemukan");
  res.json({ success: true, data: rows[0] });
});

const update = asyncHandler(async (req, res) => {
  const { nama_lengkap, role_user } = req.body;
  if (role_user && !ALLOWED_ROLES.includes(role_user)) {
    throw new ApiError(400, "role_user harus admin/staff/teknisi");
  }

  const fields = [];
  const vals = [];
  if (nama_lengkap !== undefined) {
    fields.push("nama_lengkap = ?");
    vals.push(nama_lengkap);
  }
  if (role_user !== undefined) {
    fields.push("role_user = ?");
    vals.push(role_user);
  }
  if (!fields.length) throw new ApiError(400, "Tidak ada field yang diubah");

  vals.push(req.params.id);
  await db.query(
    `UPDATE user_account SET ${fields.join(", ")} WHERE id_user = ?`,
    vals,
  );

  const [rows] = await db.query(
    "SELECT id_user, username, nama_lengkap, role_user, is_active FROM user_account WHERE id_user = ?",
    [req.params.id],
  );
  res.json({ success: true, data: rows[0] });
});

const setActive = asyncHandler(async (req, res) => {
  const { is_active } = req.body;
  if (typeof is_active !== "boolean") {
    throw new ApiError(400, "is_active harus boolean");
  }
  await db.query("UPDATE user_account SET is_active = ? WHERE id_user = ?", [
    is_active,
    req.params.id,
  ]);
  res.json({ success: true, data: { id_user: req.params.id, is_active } });
});

module.exports = { getAll, getOne, update, setActive };
