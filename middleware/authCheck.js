// File: middleware/authCheck.js
const { admin } = require("../index"); // Ambil 'admin' yang diekspor dari index.js

/**
 * Middleware untuk memverifikasi Firebase ID Token
 * yang dikirim dari aplikasi Flutter.
 */
const authCheck = async (req, res, next) => {
  // 1. Cek apakah header 'Authorization' ada dan dimulai dengan 'Bearer '
  if (
    !req.headers.authorization ||
    !req.headers.authorization.startsWith("Bearer ")
  ) {
    return res.status(401).send({ message: "Unauthorized: No token provided" });
  }

  // 2. Ambil token-nya (setelah "Bearer ")
  const idToken = req.headers.authorization.split("Bearer ")[1];

  try {
    // 3. Verifikasi token menggunakan Firebase Admin
    const decodedToken = await admin.auth().verifyIdToken(idToken);

    // 4. Jika token valid, simpan data user (seperti uid, email)
    //    ke dalam object 'req' agar bisa dipakai oleh controller
    req.user = decodedToken;

    // 5. Lanjutkan ke fungsi selanjutnya (yaitu controller)
    next();
  } catch (error) {
    // 6. Jika token tidak valid atau kedaluwarsa
    console.error("Error verifying token:", error.message);
    return res.status(401).send({ message: "Unauthorized: Invalid token" });
  }
};

module.exports = authCheck;
