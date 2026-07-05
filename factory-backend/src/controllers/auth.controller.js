const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const pool = require("../config/db");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");

const register = asyncHandler(async (req, res) => {
  const { username, password, nama_lengkap, role_user } = req.body;
  if (!username || !password || !nama_lengkap) {
    throw new ApiError(400, "username, password, dan nama_lengkap wajib diisi");
  }

  const [existing] = await pool.query("SELECT id_user FROM user_account WHERE username = ?", [username]);
  if (existing.length) throw new ApiError(409, "Username sudah dipakai");

  const password_hash = await bcrypt.hash(password, 12);
  const [result] = await pool.query(
    "INSERT INTO user_account (username, password_hash, nama_lengkap, role_user) VALUES (?, ?, ?, ?)",
    [username, password_hash, nama_lengkap, role_user || "teknisi"]
  );

  res.status(201).json({
    success: true,
    data: { id_user: result.insertId, username, nama_lengkap, role_user: role_user || "teknisi" },
  });
});

const login = asyncHandler(async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) throw new ApiError(400, "username dan password wajib diisi");

  const [rows] = await pool.query(
    "SELECT * FROM user_account WHERE username = ? AND is_active = TRUE",
    [username]
  );
  if (!rows.length) throw new ApiError(401, "Username atau password salah");

  const user = rows[0];
  const match = await bcrypt.compare(password, user.password_hash);
  if (!match) throw new ApiError(401, "Username atau password salah");

  const token = jwt.sign(
    { id_user: user.id_user, username: user.username, role_user: user.role_user },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || "8h" }
  );

  res.json({
    success: true,
    data: {
      token,
      user: {
        id_user: user.id_user,
        username: user.username,
        nama_lengkap: user.nama_lengkap,
        role_user: user.role_user,
      },
    },
  });
});

const me = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    "SELECT id_user, username, nama_lengkap, role_user FROM user_account WHERE id_user = ?",
    [req.user.id_user]
  );
  if (!rows.length) throw new ApiError(404, "User tidak ditemukan");
  res.json({ success: true, data: rows[0] });
});

module.exports = { register, login, me };
