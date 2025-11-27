// ============================================================================
// TRIP CONTROLLER - Travel App
// ============================================================================
//
// Daftar Fungsi:
// 1. store()        - Membuat trip baru (status: draft)
// 2. index()        - Menampilkan semua trip milik user
// 3. show()         - Menampilkan detail satu trip
// 4. update()       - Memperbarui data trip (nama, tanggal, budget, dll)
// 5. destroy()      - Menghapus trip (beserta subcollections)
// 6. updateStatus() - Memperbarui status trip (draft/active/completed/cancelled)
// ============================================================================

const { db, admin } = require("../index");
const tripsCollection = db.collection("trips");
const notificationService = require("../services/notificationService");
// ============================================================================
// 1. CREATE - Membuat Trip Baru
// ============================================================================
/**
 * @desc    Membuat trip baru dengan status default 'draft'
 * @route   POST /api/trips
 * @access  Private (require authCheck middleware)
 * @body    { tripName, startDate, endDate, budget?, currency?, coverImage? }
 */
exports.store = async (req, res) => {
  try {
    const { uid } = req.user;
    const { tripName, startDate, endDate, budget, currency, coverImage } =
      req.body;

    // Validasi field wajib
    if (!tripName || !startDate || !endDate) {
      return res.status(400).json({
        success: false,
        message: "tripName, startDate, and endDate are required",
      });
    }

    // Validasi tanggal
    const start = new Date(startDate);
    const end = new Date(endDate);
    if (start >= end) {
      return res.status(400).json({
        success: false,
        message: "endDate must be after startDate",
      });
    }

    const newTrip = {
      userId: uid,
      tripName,
      startDate: start,
      endDate: end,
      budget: Number(budget) || 0,
      currency: currency || "IDR",
      status: "draft",
      coverImage: coverImage || null,
      totalDestinations: 0,
      totalHotels: 0,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    // Simpan ke Firestore
    const docRef = await tripsCollection.add(newTrip);

    // Update dokumen dengan tripId-nya sendiri
    await docRef.update({ tripId: docRef.id });

    try {
      await notificationService.notifyTripCreated(uid, {
        tripId: docRef.id,
        tripName: tripData.tripName,
      });
      console.log("✅ Trip created notification sent");
    } catch (notifError) {
      console.error("⚠️ Failed to create notification:", notifError.message);
    }

    return res.status(201).json({
      success: true,
      message: "Trip created successfully",
      data: {
        tripId: docRef.id,
        ...newTrip,
        tripId: docRef.id, // Include tripId in data
      },
    });
  } catch (error) {
    console.error("Error creating trip:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to create trip",
      error: error.message,
    });
  }
};

// ============================================================================
// 2. READ ALL - Menampilkan Semua Trip Milik User
// ============================================================================
/**
 * @desc    Mendapatkan semua trip yang dibuat oleh user yang sedang login
 * @route   GET /api/trips
 * @access  Private (require authCheck middleware)
 * @query   ?status={status} - Filter berdasarkan status (optional)
 */
exports.index = async (req, res) => {
  try {
    const { uid } = req.user;
    const { status } = req.query;

    // Query dasar: filter by userId
    let query = tripsCollection.where("userId", "==", uid);

    // Filter tambahan by status jika ada
    if (status) {
      query = query.where("status", "==", status);
    }

    const snapshot = await query.get();

    if (snapshot.empty) {
      return res.status(200).json({
        success: true,
        message: "No trips found",
        data: [],
      });
    }

    // Sorting dilakukan di memory
    const trips = snapshot.docs
      .map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }))
      .sort((a, b) => {
        // Sort descending by createdAt (terbaru dulu)
        const dateA = a.createdAt?.toDate?.() || new Date(0);
        const dateB = b.createdAt?.toDate?.() || new Date(0);
        return dateB - dateA;
      });

    return res.status(200).json({
      success: true,
      message: "Trips retrieved successfully",
      data: trips,
      count: trips.length,
    });
  } catch (error) {
    console.error("Error getting trips:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get trips",
      error: error.message,
    });
  }
};

// ============================================================================
// 3. READ ONE - Menampilkan Detail Satu Trip
// ============================================================================
/**
 * @desc    Mendapatkan detail dari satu trip spesifik
 * @route   GET /api/trips/:tripId
 * @access  Private (require authCheck + tripAuth middleware)
 * @note    Middleware tripAuth sudah memastikan user adalah pemilik trip
 */
exports.show = async (req, res) => {
  try {
    const tripRef = req.tripRef; // Dari middleware tripAuth
    const tripDoc = await tripRef.get();

    if (!tripDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Trip not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        id: tripDoc.id,
        ...tripDoc.data(),
      },
    });
  } catch (error) {
    console.error("Error getting trip details:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get trip details",
      error: error.message,
    });
  }
};

// ============================================================================
// 4. UPDATE - Memperbarui Data Trip
// ============================================================================
/**
 * @desc    Memperbarui informasi trip (nama, tanggal, budget, dll)
 * @route   PUT /api/trips/:tripId
 * @access  Private (require authCheck + tripAuth middleware)
 * @body    { tripName?, startDate?, endDate?, budget?, currency?, coverImage? }
 */
exports.update = async (req, res) => {
  try {
    const tripRef = req.tripRef; // Dari middleware tripAuth
    const { tripName, startDate, endDate, budget, currency, coverImage } =
      req.body;

    // Validasi: minimal ada 1 field yang di-update
    if (
      !tripName &&
      !startDate &&
      !endDate &&
      !budget &&
      !currency &&
      !coverImage
    ) {
      return res.status(400).json({
        success: false,
        message: "At least one field must be provided for update",
      });
    }

    const updates = {
      updatedAt: new Date(),
    };

    // Update hanya field yang dikirim
    if (tripName !== undefined) updates.tripName = tripName;
    if (startDate !== undefined) updates.startDate = new Date(startDate);
    if (endDate !== undefined) updates.endDate = new Date(endDate);
    if (budget !== undefined) updates.budget = Number(budget);
    if (currency !== undefined) updates.currency = currency;
    if (coverImage !== undefined) updates.coverImage = coverImage;

    // Validasi tanggal jika keduanya di-update
    if (
      updates.startDate &&
      updates.endDate &&
      updates.startDate >= updates.endDate
    ) {
      return res.status(400).json({
        success: false,
        message: "endDate must be after startDate",
      });
    }

    await tripRef.update(updates);

    return res.status(200).json({
      success: true,
      message: "Trip updated successfully",
      data: updates,
    });
  } catch (error) {
    console.error("Error updating trip:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update trip",
      error: error.message,
    });
  }
};

// ============================================================================
// 5. DELETE - Menghapus Trip
// ============================================================================
/**
 * @desc    Menghapus trip beserta semua subcollections (destinations & hotels)
 * @route   DELETE /api/trips/:tripId
 * @access  Private (require authCheck + tripAuth middleware)
 * @warning Hard delete! Data akan hilang permanen
 */
exports.destroy = async (req, res) => {
  try {
    const tripRef = req.tripRef; // Dari middleware tripAuth
    const tripId = req.params.tripId;

    // Hapus subcollection: destinations
    await deleteSubcollection(tripRef, "destinations");

    // Hapus subcollection: hotels
    await deleteSubcollection(tripRef, "hotels");

    // Hapus dokumen trip utama
    await tripRef.delete();

    // TODO: Hapus juga data terkait di collection lain:
    // - bookings (where tripId == tripId)
    // - flights (where tripId == tripId)

    return res.status(200).json({
      success: true,
      message: "Trip and all related data deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting trip:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to delete trip",
      error: error.message,
    });
  }
};

// ============================================================================
// 6. UPDATE STATUS - Memperbarui Status Trip
// ============================================================================
/**
 * @desc    Memperbarui status trip (draft, active, completed, cancelled)
 * @route   PATCH /api/trips/:tripId/status
 * @access  Private (require authCheck + tripAuth middleware)
 * @body    { status }
 */
exports.updateStatus = async (req, res) => {
  try {
    const tripRef = req.tripRef; // Dari middleware tripAuth
    const { status } = req.body;

    // Validasi input
    if (!status) {
      return res.status(400).json({
        success: false,
        message: "Status is required",
      });
    }

    // Validasi nilai status
    const validStatuses = ["draft", "active", "completed", "cancelled"];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Must be one of: ${validStatuses.join(", ")}`,
      });
    }

    await tripRef.update({
      status,
      updatedAt: new Date(),
    });

    return res.status(200).json({
      success: true,
      message: "Trip status updated successfully",
      data: { status },
    });
  } catch (error) {
    console.error("Error updating trip status:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update trip status",
      error: error.message,
    });
  }
};

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Helper: Menghapus semua dokumen di subcollection
 * @param {DocumentReference} parentRef - Reference ke dokumen parent
 * @param {string} subcollectionName - Nama subcollection yang akan dihapus
 */
const deleteSubcollection = async (parentRef, subcollectionName) => {
  const subcollectionRef = parentRef.collection(subcollectionName);
  const snapshot = await subcollectionRef.get();

  // Firestore memiliki batasan 500 operasi per batch
  const batchSize = 500;
  const batches = [];
  let batch = db.batch();
  let operationCount = 0;

  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
    operationCount++;

    if (operationCount === batchSize) {
      batches.push(batch.commit());
      batch = db.batch();
      operationCount = 0;
    }
  });

  // Commit batch terakhir jika ada
  if (operationCount > 0) {
    batches.push(batch.commit());
  }

  await Promise.all(batches);
};

/**
 * Helper: Validasi format tanggal
 */
const isValidDate = (dateString) => {
  const date = new Date(dateString);
  return date instanceof Date && !isNaN(date);
};

/**
 * Helper: Hitung durasi trip dalam hari
 */
const calculateTripDuration = (startDate, endDate) => {
  const start = new Date(startDate);
  const end = new Date(endDate);
  const diffTime = Math.abs(end - start);
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  return diffDays;
};

// Export helpers jika diperlukan di controller lain
module.exports.helpers = {
  deleteSubcollection,
  isValidDate,
  calculateTripDuration,
};

//Dokumentasi
/*
### 📁 Alur Penjelasan: store (Create Trip)

1.  **Tujuan:** Membuat dokumen perjalanan baru di koleksi `trips`.
2.  **Middleware:** Memerlukan `authCheck` (untuk tahu siapa yang membuat).
3.  **Proses:**
    * Flutter mengirim `POST /api/trips` dengan **Token** dan data trip (nama, tanggal) di `body`.
    * `authCheck` memverifikasi token dan menyisipkan `req.user`.
    * `store` mengambil `req.user.uid` sebagai `userId` (pemilik trip).
    * Ia membuat object `newTrip` lengkap dengan nilai default (status: "draft", totalDestinations: 0).
    * `await tripsCollection.add(...)`: Menyimpan data ke Firestore. Firestore akan membuat ID dokumen acak (unik).
    * `await docRef.update(...)`: Memperbarui dokumen yang baru saja dibuat untuk menambahkan `tripId` di dalam field-nya sendiri, agar mudah di-query.
    * Server membalas dengan `201 (Created)` dan `tripId` baru.
*/
/*
### 📁 Alur Penjelasan: index (Get All My Trips)

1.  **Tujuan:** Menampilkan daftar semua perjalanan yang dibuat oleh user.
2.  **Middleware:** Memerlukan `authCheck`.
3.  **Proses:**
    * Flutter mengirim `GET /api/trips` dengan **Token**.
    * `authCheck` memverifikasi token.
    * `index` mengambil `req.user.uid` sebagai `userId`.
    * `tripsCollection.where("userId", "==", userId).get()`: Ini adalah *query* Firestore. Ia memfilter koleksi dan hanya mengembalikan dokumen yang `userId`-nya cocok.
    * Server membalas dengan array berisi semua data trip.
*/
/*
### 📁 Alur Penjelasan: show (Get One Trip)

1.  **Tujuan:** Menampilkan detail dari satu perjalanan.
2.  **Middleware:** Memerlukan `authCheck` DAN `tripAuth`.
3.  **Proses:**
    * Flutter mengirim `GET /api/trips/abc-123` dengan **Token**.
    * `authCheck` memverifikasi token.
    * `tripAuth` (middleware kedua) berjalan. Ia mengambil `tripId` (abc-123) dari URL, mengambil data trip dari Firestore, dan **memastikan user ini adalah pemiliknya**.
    * `tripAuth` juga menyisipkan `req.tripRef` (referensi ke dokumen) untuk efisiensi.
    * Fungsi `show` hanya perlu mengambil data dari `req.tripRef` dan mengirimkannya.
*/
/*
### 📁 Alur Penjelasan: update (Update One Trip)

1.  **Tujuan:** Mengedit detail dari satu perjalanan (ganti nama, tanggal, dll).
2.  **Middleware:** Memerlukan `authCheck` DAN `tripAuth`.
3.  **Proses:**
    * Flutter mengirim `PUT /api/trips/abc-123` dengan **Token** dan **data baru** di `body`.
    * `authCheck` dan `tripAuth` berjalan (memastikan user adalah pemilik).
    * `update` mengambil data baru dari `req.body`.
    * `await req.tripRef.update(updates)`: Memperbarui dokumen di Firestore.
    * Server membalas dengan `200 (OK)`.
*/
/*
### 📁 Alur Penjelasan: destroy (Delete One Trip)

1.  **Tujuan:** Menghapus satu perjalanan.
2.  **Middleware:** Memerlukan `authCheck` DAN `tripAuth`.
3.  **Proses:**
    * Flutter mengirim `DELETE /api/trips/abc-123` dengan **Token**.
    * `authCheck` dan `tripAuth` berjalan (memastikan user adalah pemilik).
    * `await req.tripRef.delete()`: Menghapus dokumen dari Firestore.
    * Server membalas dengan `200 (OK)`.
*/
/*
### 📁 Alur Penjelasan: updateStatus

1.  **Tujuan:** Mengganti status trip (misal dari "draft" ke "active").
2.  **Middleware:** Memerlukan `authCheck` DAN `tripAuth`.
3.  **Proses:**
    * Flutter mengirim `PATCH /api/trips/abc-123/status` dengan **Token** dan `{"status": "active"}` di `body`.
    * `authCheck` dan `tripAuth` berjalan.
    * `updateStatus` hanya memperbarui satu field: `status`.
    * Server membalas dengan `200 (OK)`.
*/

//Dokumentasi Hasil
// api/trips (GET)
/*
{
  "success": true,
  "message": "Trips retrieved successfully",
  "data": [
    {
      "id": "XhsQb3DmtrDG3Ib7nDXq",
      "userId": "GS5J6BDhDfW4zNFwOKvn6inFJ932",
      "tripName": "Liburan ke Bali",
      "startDate": {
        "_seconds": 1765360800,
        "_nanoseconds": 0
      },
      "endDate": {
        "_seconds": 1765792800,
        "_nanoseconds": 0
      },
      "budget": 5000000,
      "currency": "IDR",
      "status": "draft",
      "coverImage": "http://example.com/bali.png",
      "totalDestinations": 0,
      "totalHotels": 0,
      "createdAt": {
        "_seconds": 1761448011,
        "_nanoseconds": 220000000
      },
      "updatedAt": {
        "_seconds": 1761448011,
        "_nanoseconds": 220000000
      },
      "tripId": "XhsQb3DmtrDG3Ib7nDXq"
    }
  ],
  "count": 1
}


// api/trips/:idtrips
{
  "success": true,
  "data": {
    "id": "XhsQb3DmtrDG3Ib7nDXq",
    "userId": "GS5J6BDhDfW4zNFwOKvn6inFJ932",
    "tripName": "Liburan ke Bali",
    "startDate": {
      "_seconds": 1765360800,
      "_nanoseconds": 0
    },
    "endDate": {
      "_seconds": 1765792800,
      "_nanoseconds": 0
    },
    "budget": 5000000,
    "currency": "IDR",
    "status": "draft",
    "coverImage": "http://example.com/bali.png",
    "totalDestinations": 0,
    "totalHotels": 0,
    "createdAt": {
      "_seconds": 1761448011,
      "_nanoseconds": 220000000
    },
    "updatedAt": {
      "_seconds": 1761448011,
      "_nanoseconds": 220000000
    },
    "tripId": "XhsQb3DmtrDG3Ib7nDXq"
  }
}
*/
