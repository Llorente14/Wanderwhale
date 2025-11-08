// File: routes/userRoutes.js
const express = require("express");
const router = express.Router();

// 1. Import controller dan middleware
const userController = require("../controllers/userController");
const authCheck = require("../middleware/authCheck");

// 2. Terapkan middleware 'authCheck' ke SEMUA rute di bawah ini
// Ini berarti tidak ada API user yang bisa diakses tanpa token
router.use(authCheck);

// 3. Definisikan Rute CRUD RESTful
//    Endpoint ini akan menjadi '/api/users/profile'
router
  .route("/profile")
  // GET /api/users/profile (Tampilkan profil)
  .get(userController.show)

  // POST /api/users/profile (Buat profil baru)
  .post(userController.store)

  // PUT /api/users/profile (Update profil)
  .put(userController.update);

// 4. Rute Spesifik (Non-CRUD)
//    Endpoint: /api/users/profile/photo
router.patch("/profile/photo", userController.updatePhoto);

//    Endpoint: /api/users/fcm-token
router.put("/fcm-token", userController.updateFcmToken);

module.exports = router;
