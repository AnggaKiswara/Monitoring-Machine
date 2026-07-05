const pool = require("../config/db");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");
const crudFactory = require("../utils/crudFactory");

const base = crudFactory("service_alert", "id_alert");

const acknowledge = asyncHandler(async (req, res) => {
  const [result] = await pool.query(
    "UPDATE service_alert SET status = 'acknowledged' WHERE id_alert = ? AND status = 'open'",
    [req.params.id]
  );
  if (!result.affectedRows) throw new ApiError(404, "Alert tidak ditemukan atau sudah diproses");
  res.json({ success: true, message: "Alert diacknowledge" });
});

const resolve = asyncHandler(async (req, res) => {
  const [result] = await pool.query(
    `UPDATE service_alert
     SET status = 'resolved', is_resolved = TRUE, resolved_by = ?, resolved_at = NOW()
     WHERE id_alert = ? AND status != 'resolved'`,
    [req.user.id_user, req.params.id]
  );
  if (!result.affectedRows) throw new ApiError(404, "Alert tidak ditemukan atau sudah resolved");
  res.json({ success: true, message: "Alert berhasil di-resolve" });
});

module.exports = { ...base, acknowledge, resolve };
