// ============================================================================
// FILE: controllers/hotelSearchController.js
// DESC: Controller untuk hotel search menggunakan Amadeus API
//       Support 3 jenis pencarian: by hotel IDs, by city, by geocode
//       + 1 "Translator" untuk mencari lokasi by keyword
// ============================================================================

const amadeusService = require("../services/amadeusService");

// ============================================================================
// 1. SEARCH BY HOTEL IDs (TIDAK BERUBAH)
// ============================================================================
/**
 * @desc    Search hotels by hotel IDs
 * @route   GET /api/hotels/search/by-hotels
 * @access  Public
 * @query   ?hotelIds=MCLONGHM,ADPAR001 - Comma-separated hotel IDs (required)
 */
exports.searchByHotelIds = async (req, res) => {
  try {
    // 1. Ambil hotel IDs dari query parameter
    const { hotelIds } = req.query;

    // 2. Validasi parameter
    if (!hotelIds) {
      return res.status(400).json({
        success: false,
        message: "hotelIds query parameter is required",
        example: "/api/hotels/search/by-hotels?hotelIds=MCLONGHM,ADPAR001",
      });
    }

    // 3. Convert comma-separated string to array
    const hotelIdsArray = hotelIds.split(",").map((id) => id.trim());

    if (hotelIdsArray.length === 0) {
      return res.status(400).json({
        success: false,
        message: "At least one hotel ID is required",
      });
    }

    // 4. Call Amadeus service
    // (Asumsi Anda punya 'searchHotelsByHotelIds' di service Anda)
    const data = await amadeusService.searchHotelsByHotelIds(hotelIdsArray);

    // 5. Return response
    return res.status(200).json({
      success: true,
      message: "Hotels retrieved successfully",
      data: data.data || [],
      count: data.data?.length || 0,
      meta: data.meta || {},
    });
  } catch (error) {
    console.error("Error searching hotels by IDs:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to search hotels",
      error: error.message,
    });
  }
};

// ============================================================================
// 2. SEARCH BY CITY CODE (TIDAK BERUBAH)
// ============================================================================
/**
 * @desc    Search hotels by city code (IATA)
 * @route   GET /api/hotels/search/by-city
 * @access  Public
 * @query   ?cityCode=PAR - IATA city code (required)
 */
exports.searchByCity = async (req, res) => {
  try {
    // 1. Ambil parameters dari query
    const {
      cityCode,
      radius = 5,
      radiusUnit = "KM",
      amenities,
      ratings,
      hotelSource = "ALL",
    } = req.query;

    // 2. Validasi parameter wajib
    if (!cityCode) {
      return res.status(400).json({
        success: false,
        message: "cityCode query parameter is required",
        example: "/api/hotels/search/by-city?cityCode=PAR&radius=10",
      });
    }

    // 3. Validasi city code format (3 letters)
    if (!/^[A-Z]{3}$/i.test(cityCode)) {
      return res.status(400).json({
        success: false,
        message: "cityCode must be a 3-letter IATA code (e.g., PAR, LON, NYC)",
      });
    }

    // 4. Validasi radius
    const radiusNum = parseInt(radius);
    if (isNaN(radiusNum) || radiusNum < 0 || radiusNum > 300) {
      return res.status(400).json({
        success: false,
        message: "radius must be between 0 and 300",
      });
    }

    // 5. Call Amadeus service
    // (Asumsi Anda punya 'searchHotelsByCity' di service Anda)
    const data = await amadeusService.searchHotelsByCity(
      cityCode,
      radiusNum,
      radiusUnit,
      amenities,
      ratings,
      hotelSource
    );

    // 6. Return response
    return res.status(200).json({
      success: true,
      message: `Hotels found in ${cityCode.toUpperCase()} within ${radiusNum}${radiusUnit}`,
      data: data.data || [],
      count: data.data?.length || 0,
      meta: data.meta || {},
      filters: {
        cityCode: cityCode.toUpperCase(),
        radius: radiusNum,
        radiusUnit: radiusUnit,
        amenities: amenities || null,
        ratings: ratings || null,
      },
    });
  } catch (error) {
    console.error("Error searching hotels by city:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to search hotels",
      error: error.message,
    });
  }
};

// ============================================================================
// 3. SEARCH BY GEOCODE (Latitude & Longitude) (TIDAK BERUBAH)
// ============================================================================
/**
 * @desc    Search hotels by geographic coordinates
 * @route   GET /api/hotels/search/by-geocode
 * @access  Public
 * @query   ?latitude=48.8566 - Latitude (required)
 */
exports.searchByGeocode = async (req, res) => {
  try {
    // 1. Ambil parameters dari query
    const {
      latitude,
      longitude,
      radius = 5,
      radiusUnit = "KM",
      amenities,
      ratings,
      hotelSource = "ALL",
    } = req.query;

    // 2. Validasi parameters wajib
    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: "latitude and longitude query parameters are required",
        example:
          "/api/hotels/search/by-geocode?latitude=48.8566&longitude=2.3522&radius=10",
      });
    }

    // 3. Validasi coordinate format
    const lat = parseFloat(latitude);
    const lon = parseFloat(longitude);

    if (isNaN(lat) || lat < -90 || lat > 90) {
      return res.status(400).json({
        success: false,
        message: "latitude must be between -90 and 90",
      });
    }

    if (isNaN(lon) || lon < -180 || lon > 180) {
      return res.status(400).json({
        success: false,
        message: "longitude must be between -180 and 180",
      });
    }

    // 4. Validasi radius
    const radiusNum = parseInt(radius);
    if (isNaN(radiusNum) || radiusNum < 0 || radiusNum > 300) {
      return res.status(400).json({
        success: false,
        message: "radius must be between 0 and 300",
      });
    }

    // 5. Call Amadeus service
    // (Asumsi Anda punya 'searchHotelsByGeocode' di service Anda)
    const data = await amadeusService.searchHotelsByGeocode(
      lat,
      lon,
      radiusNum,
      radiusUnit,
      amenities,
      ratings,
      hotelSource
    );

    // 6. Return response
    return res.status(200).json({
      success: true,
      message: `Hotels found near coordinates (${lat}, ${lon}) within ${radiusNum}${radiusUnit}`,
      data: data.data || [],
      count: data.data?.length || 0,
      meta: data.meta || {},
      filters: {
        latitude: lat,
        longitude: lon,
        radius: radiusNum,
        radiusUnit: radiusUnit,
        amenities: amenities || null,
        ratings: ratings || null,
      },
    });
  } catch (error) {
    console.error("Error searching hotels by geocode:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to search hotels",
      error: error.message,
    });
  }
};

// ============================================================================
// 4. (BARU) SEARCH LOCATIONS BY KEYWORD (THE "TRANSLATOR")
// ============================================================================
/**
 * @desc    Find locations (City, Hotel) by keyword. Ini adalah "penerjemah".
 * @route   GET /api/hotels/search/locations
 * @access  Public
 * @query   ?keyword=Jakarta - Teks pencarian (required)
 * @query   ?subType=CITY - Tipe: CITY atau HOTEL (required)
 */
exports.findLocationsByKeyword = async (req, res) => {
  try {
    // 1. Ambil parameters dari query
    const { keyword, subType } = req.query;

    // 2. Validasi parameters wajib
    if (!keyword || !subType) {
      return res.status(400).json({
        success: false,
        message: "keyword and subType query parameters are required",
        example: "/api/hotels/search/locations?keyword=Jakarta&subType=CITY",
      });
    }

    // 3. Call Amadeus service
    // (Pastikan Anda sudah menambahkan 'searchLocationsByKeyword' ke amadeusService)
    const data = await amadeusService.searchLocationsByKeyword(
      keyword,
      subType
    );

    // 4. Return response
    return res.status(200).json({
      success: true,
      message: `Locations found for keyword '${keyword}' with subType '${subType}'`,
      data: data.data || [],
      count: data.data?.length || 0,
      meta: data.meta || {},
    });
  } catch (error) {
    console.error("Error finding locations by keyword:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to find locations",
      error: error.message,
    });
  }
};
