// ============================================================================
// FILE: controllers/destinationController.js
// DESC: Controller untuk mengelola destinasi master (public data)
//       Digunakan untuk homepage, search, dan explore destinations
// ============================================================================

const { db } = require("../index");

// ============================================================================
// COLLECTION REFERENCE
// ============================================================================

/**
 * Reference ke collection destinations_master
 * Collection ini berisi data destinasi yang sudah di-curate (bukan user-generated)
 */
const destinationsCollection = db.collection("destinations_master");

// ============================================================================
// 1. GET POPULAR - Menampilkan Destinasi Populer
// ============================================================================
/**
 * @desc    Mendapatkan destinasi populer untuk ditampilkan di Homepage
 * @route   GET /api/destinations/popular
 * @access  Public (tidak perlu login)
 * @query   ?limit=10 - Jumlah destinasi yang ingin ditampilkan (default: 10)
 */
exports.getPopular = async (req, res) => {
  try {
    // 1. Ambil parameter limit dari query, default 10
    const limit = parseInt(req.query.limit) || 10;

    // 2. Validasi limit tidak terlalu besar (max 50)
    if (limit > 50) {
      return res.status(400).json({
        success: false,
        message: "Limit cannot exceed 50",
      });
    }

    // 3. Query destinasi yang ditandai sebagai populer
    //    Sorting di memory untuk hindari composite index requirement
    const snapshot = await destinationsCollection
      .where("isPopular", "==", true)
      .get();

    // 4. Cek jika tidak ada destinasi populer
    if (snapshot.empty) {
      return res.status(200).json({
        success: true,
        message: "No popular destinations found",
        data: [],
        count: 0,
      });
    }

    // 5. Map data dan sort by rating/views (di memory)
    const destinations = snapshot.docs
      .map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }))
      .sort((a, b) => {
        // Sort by rating (descending), kemudian by views
        if (b.rating !== a.rating) {
          return (b.rating || 0) - (a.rating || 0);
        }
        return (b.views || 0) - (a.views || 0);
      })
      .slice(0, limit); // Apply limit setelah sorting

    return res.status(200).json({
      success: true,
      message: "Popular destinations retrieved successfully",
      data: destinations,
      count: destinations.length,
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Popular destinations retrieved successfully",
    //   "data": [
    //     {
    //       "id": "dest1",
    //       "name": "Pantai Kuta",
    //       "city": "Bali",
    //       "country": "Indonesia",
    //       "description": "Pantai terkenal di Bali",
    //       "imageUrl": "https://example.com/kuta.jpg",
    //       "rating": 4.5,
    //       "views": 15000,
    //       "isPopular": true,
    //       "tags": ["pantai", "sunset", "surfing"]
    //     },
    //     {
    //       "id": "dest2",
    //       "name": "Candi Borobudur",
    //       "city": "Magelang",
    //       "country": "Indonesia",
    //       "description": "Candi Buddha terbesar di dunia",
    //       "imageUrl": "https://example.com/borobudur.jpg",
    //       "rating": 4.8,
    //       "views": 20000,
    //       "isPopular": true,
    //       "tags": ["sejarah", "budaya", "candi"]
    //     }
    //   ],
    //   "count": 2
    // }
  } catch (error) {
    console.error("Error getting popular destinations:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get popular destinations",
      error: error.message,
    });

    // Response error:
    // {
    //   "success": false,
    //   "message": "Failed to get popular destinations",
    //   "error": "Firestore error message"
    // }
  }
};

// ============================================================================
// 2. FILTER BY TAG - Filter Destinasi Berdasarkan Tag
// ============================================================================
/**
 * @desc    Filter destinasi berdasarkan tag/kategori
 * @route   GET /api/destinations/filter
 * @access  Public
 * @query   ?tag=pantai - Tag yang ingin difilter (required)
 * @query   ?limit=20 - Jumlah hasil maksimal (default: 20)
 */
exports.filterByTag = async (req, res) => {
  try {
    // 1. Ambil parameter dari query
    const { tag } = req.query;
    const limit = parseInt(req.query.limit) || 20;

    // 2. Validasi parameter tag wajib ada
    if (!tag) {
      return res.status(400).json({
        success: false,
        message: "Tag parameter is required",
      });
    }

    // 3. Validasi limit tidak terlalu besar
    if (limit > 50) {
      return res.status(400).json({
        success: false,
        message: "Limit cannot exceed 50",
      });
    }

    // 4. Query destinasi yang mengandung tag tertentu
    //    Menggunakan array-contains untuk cek tag di dalam array
    const snapshot = await destinationsCollection
      .where("tags", "array-contains", tag.toLowerCase())
      .get();

    // 5. Cek jika tidak ada hasil
    if (snapshot.empty) {
      return res.status(200).json({
        success: true,
        message: `No destinations found with tag: ${tag}`,
        data: [],
        count: 0,
        tag: tag,
      });
    }

    // 6. Map data dan sort by rating (di memory)
    const destinations = snapshot.docs
      .map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }))
      .sort((a, b) => (b.rating || 0) - (a.rating || 0)) // Sort by rating desc
      .slice(0, limit); // Apply limit

    return res.status(200).json({
      success: true,
      message: `Destinations retrieved successfully for tag: ${tag}`,
      data: destinations,
      count: destinations.length,
      tag: tag,
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Destinations retrieved successfully for tag: pantai",
    //   "data": [
    //     {
    //       "id": "dest1",
    //       "name": "Pantai Kuta",
    //       "city": "Bali",
    //       "country": "Indonesia",
    //       "tags": ["pantai", "sunset", "surfing"],
    //       "rating": 4.5
    //     },
    //     {
    //       "id": "dest3",
    //       "name": "Pantai Sanur",
    //       "city": "Bali",
    //       "country": "Indonesia",
    //       "tags": ["pantai", "sunrise"],
    //       "rating": 4.3
    //     }
    //   ],
    //   "count": 2,
    //   "tag": "pantai"
    // }
  } catch (error) {
    console.error("Error filtering by tag:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to filter destinations by tag",
      error: error.message,
    });

    // Response error:
    // {
    //   "success": false,
    //   "message": "Failed to filter destinations by tag",
    //   "error": "Firestore error message"
    // }
  }
};

// ============================================================================
// 3. SEARCH - Mencari Destinasi (Simple Implementation)
// ============================================================================
/**
 * @desc    Search destinasi berdasarkan nama, kota, atau negara
 * @route   GET /api/destinations/search
 * @access  Public
 * @query   ?query=Bali - Keyword pencarian (required)
 * @query   ?limit=20 - Jumlah hasil maksimal (default: 20)
 *
 * @note    BATASAN: Firestore tidak mendukung full-text search atau partial matching.
 *          Query ini hanya bisa exact match. Untuk search yang lebih canggih,
 *          gunakan Algolia, Typesense, atau Elasticsearch.
 *          Alternatif: Fetch semua data dan filter di memory (untuk dataset kecil)
 */
exports.search = async (req, res) => {
  try {
    // 1. Ambil parameter dari query
    const { query } = req.query;
    const limit = parseInt(req.query.limit) || 20;

    // 2. Validasi parameter query wajib ada
    if (!query) {
      return res.status(400).json({
        success: false,
        message: "Search query parameter is required",
      });
    }

    // 3. Validasi limit
    if (limit > 50) {
      return res.status(400).json({
        success: false,
        message: "Limit cannot exceed 50",
      });
    }

    // 4. OPSI A: Exact Match (Original approach)
    //    Query multiple fields secara parallel
    const searchTerm = query.trim();

    const [nameSnapshot, citySnapshot, countrySnapshot] = await Promise.all([
      destinationsCollection.where("name", "==", searchTerm).get(),
      destinationsCollection.where("city", "==", searchTerm).get(),
      destinationsCollection.where("country", "==", searchTerm).get(),
    ]);

    // 5. Gabungkan hasil menggunakan Map untuk avoid duplicates
    const resultsMap = new Map();

    nameSnapshot.forEach((doc) =>
      resultsMap.set(doc.id, { id: doc.id, ...doc.data() })
    );
    citySnapshot.forEach((doc) =>
      resultsMap.set(doc.id, { id: doc.id, ...doc.data() })
    );
    countrySnapshot.forEach((doc) =>
      resultsMap.set(doc.id, { id: doc.id, ...doc.data() })
    );

    // 6. Convert Map to Array dan sort by rating
    const destinations = Array.from(resultsMap.values())
      .sort((a, b) => (b.rating || 0) - (a.rating || 0))
      .slice(0, limit);

    // 7. Cek jika tidak ada hasil
    if (destinations.length === 0) {
      return res.status(200).json({
        success: true,
        message: `No destinations found matching: ${query}`,
        data: [],
        count: 0,
        query: query,
      });
    }

    return res.status(200).json({
      success: true,
      message: `Destinations found for query: ${query}`,
      data: destinations,
      count: destinations.length,
      query: query,
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Destinations found for query: Bali",
    //   "data": [
    //     {
    //       "id": "dest1",
    //       "name": "Pantai Kuta",
    //       "city": "Bali",
    //       "country": "Indonesia",
    //       "rating": 4.5
    //     },
    //     {
    //       "id": "dest2",
    //       "name": "Ubud",
    //       "city": "Bali",
    //       "country": "Indonesia",
    //       "rating": 4.7
    //     }
    //   ],
    //   "count": 2,
    //   "query": "Bali"
    // }
  } catch (error) {
    console.error("Error searching destinations:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to search destinations",
      error: error.message,
    });

    // Response error:
    // {
    //   "success": false,
    //   "message": "Failed to search destinations",
    //   "error": "Firestore error message"
    // }
  }
};

// ============================================================================
// 4. GET BY ID - Menampilkan Detail Satu Destinasi
// ============================================================================
/**
 * @desc    Mendapatkan detail lengkap satu destinasi berdasarkan ID
 * @route   GET /api/destinations/:id
 * @access  Public
 * @params  :id - ID destinasi
 */
exports.getById = async (req, res) => {
  try {
    // 1. Ambil ID dari parameter URL
    const { id } = req.params;

    // 2. Validasi parameter ID
    if (!id) {
      return res.status(400).json({
        success: false,
        message: "Destination ID is required",
      });
    }

    // 3. Query dokumen destinasi
    const doc = await destinationsCollection.doc(id).get();

    // 4. Cek apakah destinasi exists
    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: "Destination not found",
      });
    }

    // 5. (Optional) Increment view counter untuk analytics
    //    Fire and forget - tidak perlu await
    destinationsCollection
      .doc(id)
      .update({
        views: (doc.data().views || 0) + 1,
      })
      .catch((err) => console.error("Error updating views:", err));

    // 6. Return detail destinasi
    return res.status(200).json({
      success: true,
      message: "Destination details retrieved successfully",
      data: {
        id: doc.id,
        ...doc.data(),
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Destination details retrieved successfully",
    //   "data": {
    //     "id": "dest1",
    //     "name": "Pantai Kuta",
    //     "city": "Bali",
    //     "country": "Indonesia",
    //     "description": "Pantai terkenal di Bali dengan pemandangan sunset yang indah",
    //     "imageUrl": "https://example.com/kuta.jpg",
    //     "images": [
    //       "https://example.com/kuta1.jpg",
    //       "https://example.com/kuta2.jpg"
    //     ],
    //     "rating": 4.5,
    //     "reviews": 1250,
    //     "views": 15001,
    //     "isPopular": true,
    //     "tags": ["pantai", "sunset", "surfing"],
    //     "facilities": ["Parking", "Restaurant", "Restroom"],
    //     "coordinates": {
    //       "latitude": -8.718447,
    //       "longitude": 115.168991
    //     },
    //     "tips": [
    //       "Datang saat sunset untuk pemandangan terbaik",
    //       "Bawa sunscreen dan topi"
    //     ]
    //   }
    // }
  } catch (error) {
    console.error("Error getting destination by ID:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get destination details",
      error: error.message,
    });

    // Response error:
    // {
    //   "success": false,
    //   "message": "Failed to get destination details",
    //   "error": "Firestore error message"
    // }
  }
};

// ============================================================================
// 6. GET ALL - Menampilkan Semua Destinasi dengan Pagination
// ============================================================================
/**
 * @desc    Mendapatkan semua destinasi dengan pagination (EFFICIENT - tidak fetch semua data)
 * @route   GET /api/destinations
 * @access  Public
 * @query   ?page=1 - Halaman (default: 1)
 * @query   ?limit=10 - Jumlah per halaman (default: 10, max: 50)
 * @query   ?sortBy=rating - Sort by field (rating, name, views, createdAt)
 * @query   ?order=desc - Sort order (asc, desc)
 *
 * @note    Method ini EFISIEN karena hanya fetch data yang diperlukan per halaman.
 *          Untuk production, ini lebih hemat biaya Firestore reads daripada fetch all.
 */
exports.getAll = async (req, res) => {
  try {
    // 1. Ambil parameter dari query dengan default values
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10; // Default 10 untuk hemat reads
    const sortBy = req.query.sortBy || "rating";
    const order = req.query.order || "desc";

    // 2. Validasi limit maksimal (untuk kontrol biaya)
    if (limit > 50) {
      return res.status(400).json({
        success: false,
        message: "Limit cannot exceed 50 items per page",
      });
    }

    // 3. Validasi page minimal
    if (page < 1) {
      return res.status(400).json({
        success: false,
        message: "Page number must be greater than 0",
      });
    }

    // 4. Validasi sortBy field (hanya field yang ada di schema)
    const allowedSortFields = ["rating", "name", "views", "createdAt"];
    if (!allowedSortFields.includes(sortBy)) {
      return res.status(400).json({
        success: false,
        message: `Invalid sortBy field. Allowed: ${allowedSortFields.join(
          ", "
        )}`,
      });
    }

    // 5. Validasi order (hanya asc atau desc)
    if (!["asc", "desc"].includes(order)) {
      return res.status(400).json({
        success: false,
        message: "Order must be 'asc' or 'desc'",
      });
    }

    // 6. Hitung offset untuk pagination
    const offset = (page - 1) * limit;

    // 7. Build query dengan sorting dan pagination
    //    PENTING: orderBy + offset/limit ini akan butuh Composite Index!
    //    Tapi ini lebih efisien karena hanya fetch data yang diperlukan
    let query = destinationsCollection
      .orderBy(sortBy, order)
      .offset(offset)
      .limit(limit);

    // 8. Eksekusi query untuk data halaman ini
    const snapshot = await query.get();

    // 9. Get total count untuk pagination info
    //    count() adalah aggregation query yang SANGAT EFISIEN (tidak baca semua docs)
    const countSnapshot = await destinationsCollection.count().get();
    const totalItems = countSnapshot.data().count;
    const totalPages = Math.ceil(totalItems / limit);

    // 10. Validasi jika page yang diminta melebihi total pages
    if (page > totalPages && totalPages > 0) {
      return res.status(400).json({
        success: false,
        message: `Page ${page} exceeds total pages (${totalPages})`,
        pagination: {
          page: page,
          limit: limit,
          totalPages: totalPages,
          totalItems: totalItems,
        },
      });
    }

    // 11. Cek jika tidak ada data di halaman ini
    if (snapshot.empty) {
      return res.status(200).json({
        success: true,
        message:
          totalItems === 0
            ? "No destinations found"
            : "No destinations found on this page",
        data: [],
        count: 0,
        pagination: {
          page: page,
          limit: limit,
          totalPages: totalPages,
          totalItems: totalItems,
          hasNextPage: false,
          hasPrevPage: page > 1,
        },
      });
    }

    // 12. Map data dari snapshot
    const destinations = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // 13. Return response sukses dengan pagination info lengkap
    return res.status(200).json({
      success: true,
      message: "Destinations retrieved successfully",
      data: destinations,
      count: destinations.length,
      pagination: {
        page: page,
        limit: limit,
        totalPages: totalPages,
        totalItems: totalItems,
        hasNextPage: page < totalPages,
        hasPrevPage: page > 1,
        // Bonus info untuk UX
        nextPage: page < totalPages ? page + 1 : null,
        prevPage: page > 1 ? page - 1 : null,
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Destinations retrieved successfully",
    //   "data": [
    //     {
    //       "id": "dest1",
    //       "name": "Pantai Kuta",
    //       "city": "Bali",
    //       "country": "Indonesia",
    //       "rating": 4.8,
    //       "views": 15000,
    //       "imageUrl": "https://example.com/kuta.jpg",
    //       "tags": ["pantai", "sunset"]
    //     },
    //     // ... 9 more items (total 10 per page)
    //   ],
    //   "count": 10,
    //   "pagination": {
    //     "page": 1,
    //     "limit": 10,
    //     "totalPages": 15,
    //     "totalItems": 145,
    //     "hasNextPage": true,
    //     "hasPrevPage": false,
    //     "nextPage": 2,
    //     "prevPage": null
    //   }
    // }

    // Response jika page kosong (page melebihi total):
    // {
    //   "success": false,
    //   "message": "Page 99 exceeds total pages (15)",
    //   "pagination": {
    //     "page": 99,
    //     "limit": 10,
    //     "totalPages": 15,
    //     "totalItems": 145
    //   }
    // }
  } catch (error) {
    console.error("Error getting destinations with pagination:", error);

    // Handle specific Firestore errors
    if (error.code === 9 || error.code === "failed-precondition") {
      // Error code 9 = FAILED_PRECONDITION (butuh index)
      return res.status(500).json({
        success: false,
        message:
          "Database index required. Please create a composite index for this query.",
        error: error.message,
        hint: `Create index for collection 'destinations_master' with fields: ${sortBy} (${order})`,
      });

      // Response error (index required):
      // {
      //   "success": false,
      //   "message": "Database index required. Please create a composite index for this query.",
      //   "error": "9 FAILED_PRECONDITION: The query requires an index...",
      //   "hint": "Create index for collection 'destinations_master' with fields: rating (desc)"
      // }
    }

    // Generic error handler
    return res.status(500).json({
      success: false,
      message: "Failed to retrieve destinations",
      error: error.message,
    });

    // Response error (generic):
    // {
    //   "success": false,
    //   "message": "Failed to retrieve destinations",
    //   "error": "Network timeout error"
    // }
  }
};
