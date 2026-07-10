require("dotenv").config();
const mysql = require("mysql2/promise");

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

(async () => {
  try {
    await pool.query("SELECT 1");
    console.log("Berhasil koneksi ke database MySQL");
  } catch (err) {
    console.error("Gagal koneksi database:", err.message);
  }
})();

module.exports = pool;
