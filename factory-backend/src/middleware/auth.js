const jwt = require("jsonwebtoken");
const ApiError = require("../utils/ApiError");

// Verifikasi JWT token, dipasang di route yang butuh login
const authenticate = (req, res, next) => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    return next(new ApiError(401, "Token tidak ditemukan"));
  }

  const token = header.split(" ")[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // { id_user, username, role_user }
    next();
  } catch (err) {
    next(new ApiError(401, "Token tidak valid atau kadaluarsa"));
  }
};

// Batasi akses berdasarkan role, contoh: authorize('admin')
const authorize = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.role_user)) {
    return next(new ApiError(403, "Tidak punya akses untuk aksi ini"));
  }
  next();
};

module.exports = { authenticate, authorize };
