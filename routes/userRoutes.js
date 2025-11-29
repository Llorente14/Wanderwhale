// File: routes/userRoutes.js
const express = require("express");
const router = express.Router();
const multer = require("multer");

// 1. Import controller dan middleware
const userController = require("../controllers/userController");
const authCheck = require("../middleware/authCheck");

// 2. Setup multer untuk handle file upload (memory storage untuk sementara)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB max
  },
});

// 3. Middleware untuk handle both JSON and multipart form
const handleUpdate = (req, res, next) => {
  // Jika Content-Type adalah multipart/form-data, gunakan multer
  if (req.headers["content-type"]?.includes("multipart/form-data")) {
    return upload.single("photo")(req, res, next);
  }
  // Jika tidak, skip multer dan lanjut ke controller
  next();
};

// 4. Terapkan middleware 'authCheck' ke SEMUA rute di bawah ini
// Ini berarti tidak ada API user yang bisa diakses tanpa token
router.use(authCheck);

// 5. Definisikan Rute CRUD RESTful
//    Endpoint ini akan menjadi '/api/users/profile'
router
  .route("/profile")
  // GET /api/users/profile (Tampilkan profil)
  .get(userController.show)

  // POST /api/users/profile (Buat profil baru)
  .post(userController.store)

  // PUT /api/users/profile (Update profil - bisa dengan atau tanpa file)
  .put(handleUpdate, userController.update);

// 4. Rute Spesifik (Non-CRUD)
//    Endpoint: /api/users/profile/photo
router.patch("/profile/photo", userController.updatePhoto);

//    Endpoint: /api/users/fcm-token
router.put("/fcm-token", userController.updateFcmToken);

module.exports = router;
