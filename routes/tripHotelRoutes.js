// File: routes/tripHotelRoutes.js
const express = require("express");

// PENTING: { mergeParams: true }
// Ini agar router ini bisa "mewarisi" :tripId dari router induknya
const router = express.Router({ mergeParams: true });

const hotelController = require("../controllers/tripHotelController");
// Kita TIDAK perlu authCheck atau tripAuth di sini
// karena mereka sudah dipasang di 'tripRoutes.js' (induknya)

// Rute ini sudah otomatis diawali /api/trips/:tripId/hotels

router
  .route("/")
  // POST /api/trips/:tripId/hotels
  .post(hotelController.store)
  // GET /api/trips/:tripId/hotels
  .get(hotelController.index);

router
  .route("/:hotelId")
  // PUT /api/trips/:tripId/hotels/:hotelId
  .put(hotelController.update)
  // DELETE /api/trips/:tripId/hotels/:hotelId
  .delete(hotelController.destroy);

module.exports = router;
