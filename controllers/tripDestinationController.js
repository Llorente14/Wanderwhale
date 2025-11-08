// ============================================================================
// FILE: controllers/tripDestinationController.js
// DESC: Controller untuk mengelola destinasi dalam sebuah trip (sub-collection)
// ============================================================================

const { db, admin } = require("../index");

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Helper function untuk mendapatkan referensi sub-collection destinations
 * @param {string} tripId - ID dari trip
 * @returns {FirebaseFirestore.CollectionReference}
 */
const getDestinationsRef = (tripId) =>
  db.collection("trips").doc(tripId).collection("destinations");

// ============================================================================
// 1. CREATE - Menambahkan Destinasi Baru ke Trip
// ============================================================================
/**
 * @desc    Membuat destinasi baru di dalam trip tertentu
 * @route   POST /api/trips/:tripId/destinations
 * @access  Private (require authCheck + checkTripOwnership middleware)
 * @body    {name, location, date, order, notes, etc}
 */
exports.store = async (req, res) => {
  try {
    // 1. Ambil tripId dari parameter URL (sudah divalidasi oleh middleware)
    const { tripId } = req.params;

    // 2. Ambil data destinasi dari request body
    const destinationData = req.body;

    // 3. Validasi data minimal (opsional, bisa dipindah ke middleware)
    if (
      !destinationData.destinationName ||
      !destinationData.country ||
      !destinationData.city
    ) {
      return res.status(400).json({
        success: false,
        message: "Name and location are required",
      });
    }

    // 4. Buat dokumen baru di sub-collection destinations
    const docRef = await getDestinationsRef(tripId).add({
      ...destinationData,
      tripId: tripId, // Simpan reference ke parent trip
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 5. Update dokumen dengan ID-nya sendiri untuk kemudahan akses
    await docRef.update({
      destinationId: docRef.id,
    });

    // 6. Update counter totalDestinations di dokumen trip utama
    await db
      .collection("trips")
      .doc(tripId)
      .update({
        totalDestinations: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // 7. Ambil data destinasi yang baru dibuat
    const newDestination = await docRef.get();

    return res.status(201).json({
      success: true,
      message: "Destination added successfully",
      data: {
        id: docRef.id,
        ...newDestination.data(),
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Destination added successfully",
    //   "data": {
    //     "id": "dest123",
    //     "destinationId": "dest123",
    //     "name": "Pantai Kuta",
    //     "location": "Bali",
    //     "tripId": "trip123",
    //     "createdAt": "2025-10-26T10:30:00.000Z",
    //     "updatedAt": "2025-10-26T10:30:00.000Z"
    //   }
    // }
  } catch (error) {
    console.error("Error creating destination:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to add destination",
      error: error.message,
    });

    // Response error:
    // {
    //   "success": false,
    //   "message": "Failed to add destination",
    //   "error": "Firestore error message"
    // }
  }
};

// ============================================================================
// 2. READ ALL - Menampilkan Semua Destinasi dalam Trip
// ============================================================================
/**
 * @desc    Mendapatkan semua destinasi dari satu trip tertentu
 * @route   GET /api/trips/:tripId/destinations
 * @access  Private (require authCheck + checkTripOwnership middleware)
 * @query   ?sortBy=order (default) | createdAt
 */
exports.index = async (req, res) => {
  try {
    // 1. Ambil tripId dari parameter
    const { tripId } = req.params;
    const { sortBy = "order" } = req.query;

    // 2. Query semua destinasi, sorting di memory untuk hindari index requirement
    const snapshot = await getDestinationsRef(tripId).get();

    // 3. Cek jika tidak ada destinasi
    if (snapshot.empty) {
      return res.status(200).json({
        success: true,
        message: "No destinations found",
        data: [],
        count: 0,
      });
    }

    // 4. Map dan sort data di memory
    const destinations = snapshot.docs
      .map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }))
      .sort((a, b) => {
        // Sort berdasarkan order (ascending) atau createdAt (desc)
        if (sortBy === "createdAt") {
          const dateA = a.createdAt?.toDate?.() || new Date(0);
          const dateB = b.createdAt?.toDate?.() || new Date(0);
          return dateB - dateA; // Descending (terbaru dulu)
        }
        // Default: sort by order
        return (a.order || 0) - (b.order || 0); // Ascending
      });

    return res.status(200).json({
      success: true,
      message: "Destinations retrieved successfully",
      data: destinations,
      count: destinations.length,
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Destinations retrieved successfully",
    //   "data": [
    //     {
    //       "id": "dest1",
    //       "destinationId": "dest1",
    //       "name": "Pantai Kuta",
    //       "location": "Bali",
    //       "order": 1,
    //       "tripId": "trip123"
    //     },
    //     {
    //       "id": "dest2",
    //       "destinationId": "dest2",
    //       "name": "Tanah Lot",
    //       "location": "Bali",
    //       "order": 2,
    //       "tripId": "trip123"
    //     }
    //   ],
    //   "count": 2
    // }
  } catch (error) {
    console.error("Error getting destinations:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get destinations",
      error: error.message,
    });

    // Response error:
    // {
    //   "success": false,
    //   "message": "Failed to get destinations",
    //   "error": "Firestore error message"
    // }
  }
};

// ============================================================================
// 3. READ ONE - Menampilkan Detail Satu Destinasi
// ============================================================================
/**
 * @desc    Mendapatkan detail satu destinasi spesifik
 * @route   GET /api/trips/:tripId/destinations/:destinationId
 * @access  Private (require authCheck + checkTripOwnership middleware)
 */
exports.show = async (req, res) => {
  try {
    // 1. Ambil parameter dari URL
    const { tripId, destinationId } = req.params;

    // 2. Ambil dokumen destinasi
    const docRef = getDestinationsRef(tripId).doc(destinationId);
    const doc = await docRef.get();

    // 3. Cek apakah destinasi ada
    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: "Destination not found",
      });
    }

    // 4. Return data destinasi
    return res.status(200).json({
      success: true,
      message: "Destination retrieved successfully",
      data: {
        id: doc.id,
        ...doc.data(),
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Destination retrieved successfully",
    //   "data": {
    //     "id": "dest123",
    //     "name": "Pantai Kuta",
    //     "location": "Bali",
    //     "order": 1,
    //     "notes": "Jangan lupa bawa sunscreen",
    //     "tripId": "trip123"
    //   }
    // }
  } catch (error) {
    console.error("Error getting destination:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get destination",
      error: error.message,
    });
  }
};

// ============================================================================
// 4. UPDATE - Memperbarui Destinasi
// ============================================================================
/**
 * @desc    Memperbarui data destinasi tertentu
 * @route   PUT /api/trips/:tripId/destinations/:destinationId
 * @access  Private (require authCheck + checkTripOwnership middleware)
 * @body    {name?, location?, date?, order?, notes?, etc}
 */
exports.update = async (req, res) => {
  try {
    // 1. Ambil parameter dari URL
    const { tripId, destinationId } = req.params;

    // 2. Ambil data update dari body
    const updates = req.body;

    // 3. Validasi: pastikan tidak mengubah field system
    delete updates.destinationId; // Tidak boleh diubah
    delete updates.tripId; // Tidak boleh diubah
    delete updates.createdAt; // Tidak boleh diubah

    // 4. Cek apakah destinasi exists
    const docRef = getDestinationsRef(tripId).doc(destinationId);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: "Destination not found",
      });
    }

    // 5. Update dokumen dengan timestamp baru
    await docRef.update({
      ...updates,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 6. Update timestamp di parent trip juga
    await db.collection("trips").doc(tripId).update({
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 7. Ambil data yang sudah diupdate
    const updatedDoc = await docRef.get();

    return res.status(200).json({
      success: true,
      message: "Destination updated successfully",
      data: {
        id: updatedDoc.id,
        ...updatedDoc.data(),
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Destination updated successfully",
    //   "data": {
    //     "id": "dest123",
    //     "name": "Pantai Kuta (Updated)",
    //     "location": "Bali",
    //     "order": 1,
    //     "updatedAt": "2025-10-26T11:00:00.000Z"
    //   }
    // }
  } catch (error) {
    console.error("Error updating destination:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update destination",
      error: error.message,
    });

    // Response error:
    // {
    //   "success": false,
    //   "message": "Failed to update destination",
    //   "error": "Firestore error message"
    // }
  }
};

// ============================================================================
// 5. DELETE - Menghapus Destinasi
// ============================================================================
/**
 * @desc    Menghapus destinasi dari trip
 * @route   DELETE /api/trips/:tripId/destinations/:destinationId
 * @access  Private (require authCheck + checkTripOwnership middleware)
 */
exports.destroy = async (req, res) => {
  try {
    // 1. Ambil parameter dari URL
    const { tripId, destinationId } = req.params;

    // 2. Cek apakah destinasi exists
    const docRef = getDestinationsRef(tripId).doc(destinationId);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: "Destination not found",
      });
    }

    // 3. Hapus dokumen destinasi
    await docRef.delete();

    // 4. Update counter di dokumen trip utama
    await db
      .collection("trips")
      .doc(tripId)
      .update({
        totalDestinations: admin.firestore.FieldValue.increment(-1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return res.status(200).json({
      success: true,
      message: "Destination deleted successfully",
      data: {
        id: destinationId,
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Destination deleted successfully",
    //   "data": {
    //     "id": "dest123"
    //   }
    // }
  } catch (error) {
    console.error("Error deleting destination:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to delete destination",
      error: error.message,
    });

    // Response error:
    // {
    //   "success": false,
    //   "message": "Failed to delete destination",
    //   "error": "Firestore error message"
    // }
  }
};

// ============================================================================
// 6. BULK UPDATE - Update Urutan Destinasi (Drag & Drop)
// ============================================================================
/**
 * @desc    Update urutan multiple destinasi sekaligus (untuk drag & drop)
 * @route   PATCH /api/trips/:tripId/destinations/reorder
 * @access  Private (require authCheck + checkTripOwnership middleware)
 * @body    {destinations: [{id: "dest1", order: 1}, {id: "dest2", order: 2}]}
 */
exports.reorder = async (req, res) => {
  try {
    // 1. Ambil tripId dan data urutan baru
    const { tripId } = req.params;
    const { destinations } = req.body;

    // 2. Validasi input
    if (!Array.isArray(destinations) || destinations.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Destinations array is required",
      });
    }

    // 3. Buat batch untuk update multiple dokumen sekaligus
    const batch = db.batch();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    // 4. Loop dan tambahkan update ke batch
    destinations.forEach(({ id, order }) => {
      const docRef = getDestinationsRef(tripId).doc(id);
      batch.update(docRef, {
        order: order,
        updatedAt: timestamp,
      });
    });

    // 5. Update timestamp di parent trip
    batch.update(db.collection("trips").doc(tripId), {
      updatedAt: timestamp,
    });

    // 6. Commit semua perubahan sekaligus (atomic operation)
    await batch.commit();

    return res.status(200).json({
      success: true,
      message: "Destinations reordered successfully",
      data: {
        updated: destinations.length,
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Destinations reordered successfully",
    //   "data": {
    //     "updated": 5
    //   }
    // }
  } catch (error) {
    console.error("Error reordering destinations:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to reorder destinations",
      error: error.message,
    });
  }
};
