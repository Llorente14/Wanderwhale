// File: routes/tripRoutes.js
const express = require("express");
const router = express.Router();

// 1. Import controllers dan middleware
const tripController = require("../controllers/tripController");
const authCheck = require("../middleware/authCheck");
const checkTripOwnership = require("../middleware/tripAuth");
const tripDestinationRoutes = require("./tripDestinationRoutes");
const tripHotelRoutes = require("./tripHotelRoutes");

// 2. Terapkan 'authCheck' ke SEMUA rute di file ini
//    Tidak ada satupun API trip yang bisa diakses tanpa login
router.use(authCheck);

// 3. Definisikan rute untuk koleksi ('/api/trips')
router
  .route("/")
  // GET /api/trips (List semua trip milik user)
  .get(tripController.index)
  // POST /api/trips (Buat trip baru)
  .post(tripController.store);

// -----------------------------------------------------------------
// PENTING: Semua rute DI BAWAH INI memiliki ':tripId'
// Kita terapkan middleware 'checkTripOwnership' di sini
// agar otomatis melindungi semua endpoint di bawah
// -----------------------------------------------------------------
router.use("/:tripId", checkTripOwnership);

// 4. Definisikan rute untuk dokumen spesifik ('/api/trips/:tripId')
router
  .route("/:tripId")
  // GET /api/trips/:tripId (Lihat detail 1 trip)
  .get(tripController.show)
  // PUT /api/trips/:tripId (Update 1 trip)
  .put(tripController.update)
  // DELETE /api/trips/:tripId (Hapus 1 trip)
  .delete(tripController.destroy);

// 5. Rute spesifik untuk update status
//    PATCH /api/trips/:tripId/status
router.patch("/:tripId/status", tripController.updateStatus);

// CRUD destinasi dari sebuah trip
router.use("/:tripId/destinations", tripDestinationRoutes);

// CRUD Hotel dari sebuah trip
router.use("/:tripId/hotels", tripHotelRoutes);

module.exports = router;
