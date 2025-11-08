// File: middleware/tripAuth.js
const { db } = require("../index"); // Ambil 'db' (Firestore) dari index.js

/**
 * Middleware untuk memeriksa apakah user yang login (dari authCheck)
 * adalah PEMILIK dari trip yang ingin diakses.
 */
const checkTripOwnership = async (req, res, next) => {
  try {
    // Ambil tripId dari parameter URL (contoh: /api/trips/abc-123)
    const { tripId } = req.params;

    // Ambil userId dari 'req.user' yang sudah disisipkan oleh authCheck
    const userId = req.user.uid;

    if (!tripId) {
      return res.status(400).send({ message: "Trip ID is required" });
    }

    // 1. Ambil dokumen trip dari Firestore
    const tripRef = db.collection("trips").doc(tripId);
    const doc = await tripRef.get();

    if (!doc.exists) {
      return res.status(404).send({ message: "Trip not found" });
    }

    const tripData = doc.data();

    // 2. Validasi Keamanan Utama:
    // Apakah 'userId' di dokumen trip SAMA DENGAN 'userId' dari token?
    if (tripData.userId !== userId) {
      return res
        .status(403)
        .send({
          message: "Forbidden: You do not have access to this resource",
        });
    }

    // 3. (Opsional) Lampirkan referensi dokumen ke request
    //    Ini adalah optimasi agar controller tidak perlu query lagi
    req.tripRef = tripRef;

    // 4. Lanjutkan ke controller jika user adalah pemilik
    next();
  } catch (error) {
    console.error("Error checking trip ownership:", error);
    res.status(500).send({ message: "Internal Server Error" });
  }
};

module.exports = checkTripOwnership;
