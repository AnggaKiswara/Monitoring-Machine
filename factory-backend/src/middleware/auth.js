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

// Coba baca & verifikasi token kalau ada, tapi gak error kalau gak ada/invalid.
// Dipakai di endpoint yang perilakunya beda tergantung ada login atau nggak (misal register).
const optionalAuthenticate = (req, res, next) => {
  const header = req.headers.authorization;
  if (header && header.startsWith("Bearer ")) {
    const token = header.split(" ")[1];
    try {
      req.user = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      // token invalid, biarin req.user tetap undefined, jangan block request
    }
  }
  next();
};

// Batasi akses berdasarkan role, contoh: authorize('admin')
const authorize = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.role_user)) {
    return next(new ApiError(403, "Tidak punya akses untuk aksi ini"));
  }
  next();
};

module.exports = { authenticate, optionalAuthenticate, authorize };
