// File: routes/tripDestinationRoutes.js
const express = require("express");

// Ini agar router ini bisa "mewarisi" :tripId dari router induknya
const router = express.Router({ mergeParams: true });

const destController = require("../controllers/tripDestinationController");
// Kita TIDAK perlu authCheck atau tripAuth di sini
// karena mereka sudah dipasang di 'tripRoutes.js' (induknya)

// Rute ini sudah otomatis diawali /api/trips/:tripId/destinations

router
  .route("/")
  // POST /api/trips/:tripId/destinations
  .post(destController.store)
  // GET /api/trips/:tripId/destinations
  .get(destController.index);

router
  .route("/:destinationId")
  // PUT /api/trips/:tripId/destinations/:destinationId
  .put(destController.update)
  // DELETE /api/trips/:tripId/destinations/:destinationId
  .delete(destController.destroy);

module.exports = router;
