// File: routes/destinationRoutes.js
const express = require("express");
const router = express.Router();

const destController = require("../controllers/destinationController");

// Kita TIDAK meletakkan 'authCheck' di sini.
// API ini bersifat PUBLIK dan bisa diakses siapa saja.

// GET /api/destinations (Untuk pagination 'view all')
router.get("/", destController.getAll);

// GET /api/destinations/popular
router.get("/popular", destController.getPopular);

// GET /api/destinations/filter?tag=pantai
router.get("/filter", destController.filterByTag);

// GET /api/destinations/search?query=Bali
router.get("/search", destController.search);

// GET /api/destinations/aBcDeFg12345
router.get("/:id", destController.getById);

module.exports = router;
