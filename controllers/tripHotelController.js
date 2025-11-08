// ============================================================================
// FILE: controllers/tripHotelController.js
// DESC: Controller untuk mengelola hotel dalam sebuah trip (sub-collection)
// ============================================================================

const { db, admin } = require("../index");

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Helper function untuk mendapatkan referensi sub-collection hotels
 * @param {string} tripId - ID dari trip
 * @returns {FirebaseFirestore.CollectionReference}
 */
const getHotelsRef = (tripId) =>
  db.collection("trips").doc(tripId).collection("hotels");

// ============================================================================
// 1. CREATE - Menambahkan Hotel Baru ke Trip
// ============================================================================
/**
 * @desc    Menambahkan hotel baru ke dalam trip tertentu
 * @route   POST /api/trips/:tripId/hotels
 * @access  Private (require authCheck + checkTripOwnership middleware)
 * @body    {hotelName, address, checkInDate, checkOutDate, price, roomType, etc}
 */
exports.store = async (req, res) => {
  try {
    // 1. Ambil tripId dari parameter URL (sudah divalidasi oleh middleware)
    const { tripId } = req.params;

    // 2. Ambil data hotel dari request body
    const hotelData = req.body;

    // 3. Validasi data minimal yang diperlukan
    if (!hotelData.hotelName || !hotelData.checkInDate) {
      return res.status(400).json({
        success: false,
        message: "Hotel name and check-in date are required",
      });
    }

    // 4. Validasi format tanggal (opsional tapi recommended)
    if (!hotelData.checkOutDate) {
      return res.status(400).json({
        success: false,
        message: "Check-out date is required",
      });
    }

    // 5. Buat dokumen baru di sub-collection hotels
    const docRef = await getHotelsRef(tripId).add({
      ...hotelData,
      tripId: tripId, // Simpan reference ke parent trip
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 6. Update dokumen dengan ID-nya sendiri untuk kemudahan akses
    await docRef.update({
      hotelId: docRef.id,
    });

    // 7. Update counter totalHotels di dokumen trip utama
    await db
      .collection("trips")
      .doc(tripId)
      .update({
        totalHotels: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // 8. Ambil data hotel yang baru dibuat
    const newHotel = await docRef.get();

    return res.status(201).json({
      success: true,
      message: "Hotel added successfully",
      data: {
        id: docRef.id,
        ...newHotel.data(),
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Hotel added successfully",
    //   "data": {
    //     "id": "hotel123",
    //     "hotelId": "hotel123",
    //     "hotelName": "Grand Hyatt Bali",
    //     "address": "Nusa Dua, Bali",
    //     "checkInDate": "2025-12-10",
    //     "checkOutDate": "2025-12-12",
    //     "price": 1500000,
    //     "roomType": "Deluxe Room",
    //     "tripId": "trip123",
    //     "createdAt": "2025-10-26T10:30:00.000Z",
    //     "updatedAt": "2025-10-26T10:30:00.000Z"
    //   }
    // }
  } catch (error) {
    console.error("Error creating hotel:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to add hotel",
      error: error.message,
    });

    // Response error:
    // {
    //   "success": false,
    //   "message": "Failed to add hotel",
    //   "error": "Firestore error message"
    // }
  }
};

// ============================================================================
// 2. READ ALL - Menampilkan Semua Hotel dalam Trip
// ============================================================================
/**
 * @desc    Mendapatkan semua hotel dari satu trip tertentu
 * @route   GET /api/trips/:tripId/hotels
 * @access  Private (require authCheck + checkTripOwnership middleware)
 * @query   ?sortBy=checkInDate (default) | price | createdAt
 */
exports.index = async (req, res) => {
  try {
    // 1. Ambil tripId dari parameter
    const { tripId } = req.params;
    const { sortBy = "checkInDate" } = req.query;

    // 2. Query semua hotel, sorting di memory untuk hindari index requirement
    const snapshot = await getHotelsRef(tripId).get();

    // 3. Cek jika tidak ada hotel
    if (snapshot.empty) {
      return res.status(200).json({
        success: true,
        message: "No hotels found for this trip",
        data: [],
        count: 0,
      });
    }

    // 4. Map dan sort data di memory
    const hotels = snapshot.docs
      .map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }))
      .sort((a, b) => {
        // Sort berdasarkan parameter yang dipilih
        switch (sortBy) {
          case "price":
            return (a.price || 0) - (b.price || 0); // Ascending (termurah dulu)

          case "createdAt":
            const dateA = a.createdAt?.toDate?.() || new Date(0);
            const dateB = b.createdAt?.toDate?.() || new Date(0);
            return dateB - dateA; // Descending (terbaru dulu)

          case "checkInDate":
          default:
            // Sort by checkInDate (ascending - check-in terdekat dulu)
            const checkInA = new Date(a.checkInDate || 0);
            const checkInB = new Date(b.checkInDate || 0);
            return checkInA - checkInB;
        }
      });

    return res.status(200).json({
      success: true,
      message: "Hotels retrieved successfully",
      data: hotels,
      count: hotels.length,
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Hotels retrieved successfully",
    //   "data": [
    //     {
    //       "id": "hotel1",
    //       "hotelId": "hotel1",
    //       "hotelName": "Grand Hyatt Bali",
    //       "address": "Nusa Dua, Bali",
    //       "checkInDate": "2025-12-10",
    //       "checkOutDate": "2025-12-12",
    //       "price": 1500000,
    //       "roomType": "Deluxe Room",
    //       "tripId": "trip123"
    //     },
    //     {
    //       "id": "hotel2",
    //       "hotelId": "hotel2",
    //       "hotelName": "Ayana Resort",
    //       "address": "Jimbaran, Bali",
    //       "checkInDate": "2025-12-12",
    //       "checkOutDate": "2025-12-15",
    //       "price": 2000000,
    //       "roomType": "Ocean View Suite",
    //       "tripId": "trip123"
    //     }
    //   ],
    //   "count": 2
    // }
  } catch (error) {
    console.error("Error getting hotels:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get hotels",
      error: error.message,
    });

    // Response error:
    // {
    //   "success": false,
    //   "message": "Failed to get hotels",
    //   "error": "Firestore error message"
    // }
  }
};

// ============================================================================
// 3. READ ONE - Menampilkan Detail Satu Hotel
// ============================================================================
/**
 * @desc    Mendapatkan detail satu hotel spesifik
 * @route   GET /api/trips/:tripId/hotels/:hotelId
 * @access  Private (require authCheck + checkTripOwnership middleware)
 */
exports.show = async (req, res) => {
  try {
    // 1. Ambil parameter dari URL
    const { tripId, hotelId } = req.params;

    // 2. Ambil dokumen hotel
    const docRef = getHotelsRef(tripId).doc(hotelId);
    const doc = await docRef.get();

    // 3. Cek apakah hotel ada
    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: "Hotel not found",
      });
    }

    // 4. Return data hotel
    return res.status(200).json({
      success: true,
      message: "Hotel retrieved successfully",
      data: {
        id: doc.id,
        ...doc.data(),
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Hotel retrieved successfully",
    //   "data": {
    //     "id": "hotel123",
    //     "hotelName": "Grand Hyatt Bali",
    //     "address": "Nusa Dua, Bali",
    //     "checkInDate": "2025-12-10",
    //     "checkOutDate": "2025-12-12",
    //     "price": 1500000,
    //     "roomType": "Deluxe Room",
    //     "facilities": ["Pool", "WiFi", "Gym"],
    //     "contact": "+62-361-1234567",
    //     "tripId": "trip123"
    //   }
    // }
  } catch (error) {
    console.error("Error getting hotel:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get hotel",
      error: error.message,
    });

    // Response error (404):
    // {
    //   "success": false,
    //   "message": "Hotel not found"
    // }
  }
};

// ============================================================================
// 4. UPDATE - Memperbarui Hotel
// ============================================================================
/**
 * @desc    Memperbarui data hotel tertentu
 * @route   PUT /api/trips/:tripId/hotels/:hotelId
 * @access  Private (require authCheck + checkTripOwnership middleware)
 * @body    {hotelName?, address?, checkInDate?, checkOutDate?, price?, etc}
 */
exports.update = async (req, res) => {
  try {
    // 1. Ambil parameter dari URL
    const { tripId, hotelId } = req.params;

    // 2. Ambil data update dari body
    const updates = req.body;

    // 3. Validasi: pastikan tidak mengubah field system
    delete updates.hotelId; // Tidak boleh diubah
    delete updates.tripId; // Tidak boleh diubah
    delete updates.createdAt; // Tidak boleh diubah

    // 4. Validasi: jika ada perubahan tanggal, pastikan checkOut > checkIn
    if (updates.checkInDate && updates.checkOutDate) {
      const checkIn = new Date(updates.checkInDate);
      const checkOut = new Date(updates.checkOutDate);

      if (checkOut <= checkIn) {
        return res.status(400).json({
          success: false,
          message: "Check-out date must be after check-in date",
        });
      }
    }

    // 5. Cek apakah hotel exists
    const docRef = getHotelsRef(tripId).doc(hotelId);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: "Hotel not found",
      });
    }

    // 6. Update dokumen dengan timestamp baru
    await docRef.update({
      ...updates,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 7. Update timestamp di parent trip juga
    await db.collection("trips").doc(tripId).update({
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 8. Ambil data yang sudah diupdate
    const updatedDoc = await docRef.get();

    return res.status(200).json({
      success: true,
      message: "Hotel updated successfully",
      data: {
        id: updatedDoc.id,
        ...updatedDoc.data(),
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Hotel updated successfully",
    //   "data": {
    //     "id": "hotel123",
    //     "hotelName": "Grand Hyatt Bali (Updated)",
    //     "address": "Nusa Dua, Bali",
    //     "checkInDate": "2025-12-10",
    //     "checkOutDate": "2025-12-13",
    //     "price": 1750000,
    //     "roomType": "Suite Room",
    //     "updatedAt": "2025-10-26T11:00:00.000Z"
    //   }
    // }
  } catch (error) {
    console.error("Error updating hotel:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update hotel",
      error: error.message,
    });

    // Response error:
    // {
    //   "success": false,
    //   "message": "Failed to update hotel",
    //   "error": "Firestore error message"
    // }
  }
};

// ============================================================================
// 5. DELETE - Menghapus Hotel
// ============================================================================
/**
 * @desc    Menghapus hotel dari trip
 * @route   DELETE /api/trips/:tripId/hotels/:hotelId
 * @access  Private (require authCheck + checkTripOwnership middleware)
 */
exports.destroy = async (req, res) => {
  try {
    // 1. Ambil parameter dari URL
    const { tripId, hotelId } = req.params;

    // 2. Cek apakah hotel exists
    const docRef = getHotelsRef(tripId).doc(hotelId);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: "Hotel not found",
      });
    }

    // 3. Hapus dokumen hotel
    await docRef.delete();

    // 4. Update counter di dokumen trip utama
    await db
      .collection("trips")
      .doc(tripId)
      .update({
        totalHotels: admin.firestore.FieldValue.increment(-1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return res.status(200).json({
      success: true,
      message: "Hotel deleted successfully",
      data: {
        id: hotelId,
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Hotel deleted successfully",
    //   "data": {
    //     "id": "hotel123"
    //   }
    // }
  } catch (error) {
    console.error("Error deleting hotel:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to delete hotel",
      error: error.message,
    });

    // Response error:
    // {
    //   "success": false,
    //   "message": "Failed to delete hotel",
    //   "error": "Firestore error message"
    // }
  }
};

// ============================================================================
// 6. CALCULATE TOTAL COST - Menghitung Total Biaya Hotel
// ============================================================================
/**
 * @desc    Menghitung total biaya semua hotel dalam trip
 * @route   GET /api/trips/:tripId/hotels/total-cost
 * @access  Private (require authCheck + checkTripOwnership middleware)
 */
exports.getTotalCost = async (req, res) => {
  try {
    // 1. Ambil tripId dari parameter
    const { tripId } = req.params;

    // 2. Query semua hotel dalam trip
    const snapshot = await getHotelsRef(tripId).get();

    // 3. Cek jika tidak ada hotel
    if (snapshot.empty) {
      return res.status(200).json({
        success: true,
        message: "No hotels found",
        data: {
          totalCost: 0,
          totalHotels: 0,
          averageCost: 0,
        },
      });
    }

    // 4. Hitung total cost dari semua hotel
    let totalCost = 0;
    const hotels = [];

    snapshot.docs.forEach((doc) => {
      const hotelData = doc.data();
      const price = hotelData.price || 0;
      totalCost += price;

      hotels.push({
        id: doc.id,
        hotelName: hotelData.hotelName,
        price: price,
      });
    });

    // 5. Hitung rata-rata
    const averageCost =
      snapshot.docs.length > 0 ? totalCost / snapshot.docs.length : 0;

    return res.status(200).json({
      success: true,
      message: "Total hotel cost calculated successfully",
      data: {
        totalCost: totalCost,
        totalHotels: snapshot.docs.length,
        averageCost: Math.round(averageCost),
        hotels: hotels,
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Total hotel cost calculated successfully",
    //   "data": {
    //     "totalCost": 3500000,
    //     "totalHotels": 2,
    //     "averageCost": 1750000,
    //     "hotels": [
    //       {
    //         "id": "hotel1",
    //         "hotelName": "Grand Hyatt Bali",
    //         "price": 1500000
    //       },
    //       {
    //         "id": "hotel2",
    //         "hotelName": "Ayana Resort",
    //         "price": 2000000
    //       }
    //     ]
    //   }
    // }
  } catch (error) {
    console.error("Error calculating total cost:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to calculate total cost",
      error: error.message,
    });
  }
};
