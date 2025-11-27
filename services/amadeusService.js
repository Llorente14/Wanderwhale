// ============================================================================
// FILE: services/amadeusService.js
// DESC: Service untuk integrasi dengan Amadeus Hotel Search API
//       Mendukung 3 jenis pencarian: by-hotels, by-city, by-geocode
// ============================================================================

const fetch = require("node-fetch"); // Install: npm install node-fetch@2

// ============================================================================
// CONFIGURATION
// ============================================================================

const AMADEUS_CONFIG = {
  baseUrl: process.env.AMADEUS_BASE_URL || "https://test.api.amadeus.com",
  clientId: process.env.AMADEUS_CLIENT_ID,
  clientSecret: process.env.AMADEUS_CLIENT_SECRET,
  tokenUrl: "/v1/security/oauth2/token",
  // Hotel Search Endpoints
  endpoints: {
    byHotels: "/v1/reference-data/locations/hotels/by-hotels",
    byCity: "/v1/reference-data/locations/hotels/by-city",
    byGeocode: "/v1/reference-data/locations/hotels/by-geocode",
    locations: "/v1/reference-data/locations",
    flightOffers: "/v2/shopping/flight-offers",
    flightOffersPrice: "/v2/shopping/flight-offers/pricing",
    flightSeatmaps: "/v1/shopping/seatmaps",
    flightOrders: "/v1/booking/flight-orders",
  },
};

// Token cache untuk avoid multiple token requests
let cachedToken = null;
let tokenExpiresAt = null;

// ============================================================================
// PRIVATE FUNCTIONS
// ============================================================================

/**
 * Get access token dari Amadeus OAuth2
 * Menggunakan cache untuk efisiensi
 */
async function getAccessToken() {
  // 1. Cek apakah token masih valid
  if (cachedToken && tokenExpiresAt && Date.now() < tokenExpiresAt) {
    console.log("✅ Using cached Amadeus token");
    return cachedToken;
  }

  // 2. Validasi credentials
  if (!AMADEUS_CONFIG.clientId || !AMADEUS_CONFIG.clientSecret) {
    throw new Error(
      "Amadeus credentials not configured. Please set AMADEUS_CLIENT_ID and AMADEUS_CLIENT_SECRET in .env"
    );
  }

  console.log("🔄 Fetching new Amadeus token...");

  try {
    // 3. Request token ke Amadeus OAuth2 endpoint
    const response = await fetch(
      `${AMADEUS_CONFIG.baseUrl}${AMADEUS_CONFIG.tokenUrl}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          grant_type: "client_credentials",
          client_id: AMADEUS_CONFIG.clientId,
          client_secret: AMADEUS_CONFIG.clientSecret,
        }),
      }
    );

    // 4. Parse response
    const data = await response.json();

    if (!response.ok) {
      throw new Error(
        `Amadeus OAuth2 failed: ${data.error_description || data.error}`
      );
    }

    // 5. Cache token dengan expiry time (biasanya 1799 seconds = ~30 menit)
    cachedToken = data.access_token;
    const expiresIn = data.expires_in || 1799; // default 30 menit
    tokenExpiresAt = Date.now() + expiresIn * 1000 - 60000; // Minus 1 menit untuk buffer

    console.log(`✅ Amadeus token obtained, expires in ${expiresIn}s`);

    return cachedToken;
  } catch (error) {
    console.error("❌ Error getting Amadeus token:", error.message);
    throw new Error(`Failed to authenticate with Amadeus: ${error.message}`);
  }
}

/**
 * Generic function untuk call Amadeus API dengan authentication
 */
async function callAmadeusAPI(endpoint, queryParams = {}) {
  try {
    // 1. Get access token
    const accessToken = await getAccessToken();

    // 2. Build URL dengan query parameters
    const url = new URL(`${AMADEUS_CONFIG.baseUrl}${endpoint}`);
    Object.keys(queryParams).forEach((key) => {
      if (queryParams[key] !== undefined && queryParams[key] !== null) {
        url.searchParams.append(key, queryParams[key]);
      }
    });

    console.log(`🌐 Calling Amadeus API: ${url.pathname}${url.search}`);

    // 3. Call Amadeus API
    const response = await fetch(url.toString(), {
      method: "GET",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
    });

    // 4. Parse response
    const data = await response.json();

    // 5. Handle errors
    if (!response.ok) {
      console.error("❌ Amadeus API Error:", data);
      throw new Error(
        data.errors?.[0]?.detail ||
          data.error_description ||
          "Amadeus API request failed"
      );
    }

    console.log(
      `✅ Amadeus API success: ${data.data?.length || 0} results found`
    );

    return data;
  } catch (error) {
    console.error("❌ Error calling Amadeus API:", error.message);
    throw error;
  }
}

// ============================================================================
// PUBLIC FUNCTIONS - HOTEL SEARCH
// ============================================================================

/**
 * Search hotels by hotel IDs
 * @param {string[]} hotelIds - Array of Amadeus hotel IDs (e.g., ["MCLONGHM", "ADPAR001"])
 * @returns {Promise<Object>} Hotel data
 *
 * @example
 * const hotels = await searchHotelsByHotelIds(["MCLONGHM", "ADPAR001"]);
 */
async function searchHotelsByHotelIds(hotelIds) {
  if (!hotelIds || hotelIds.length === 0) {
    throw new Error("hotelIds parameter is required");
  }

  // Amadeus expects comma-separated hotel IDs
  const hotelIdsString = Array.isArray(hotelIds)
    ? hotelIds.join(",")
    : hotelIds;

  return await callAmadeusAPI(AMADEUS_CONFIG.endpoints.byHotels, {
    hotelIds: hotelIdsString,
  });
}

/**
 * Search hotels by city code (IATA code)
 * @param {string} cityCode - IATA city code (e.g., "PAR" for Paris, "LON" for London)
 * @param {number} radius - Search radius in KM (default: 5, max: 300)
 * @param {string} radiusUnit - Unit: KM or MILE (default: KM)
 * @param {string} amenities - Filter by amenities (e.g., "SWIMMING_POOL,SPA,FITNESS_CENTER")
 * @param {string} ratings - Filter by ratings (e.g., "1,2,3,4,5")
 * @param {string} hotelSource - Hotel source (default: ALL)
 * @returns {Promise<Object>} Hotel data
 *
 * @example
 * const hotels = await searchHotelsByCity("PAR", 10, "KM");
 */
async function searchHotelsByCity(
  cityCode,
  radius = 5,
  radiusUnit = "KM",
  amenities = null,
  ratings = null,
  hotelSource = "ALL"
) {
  if (!cityCode) {
    throw new Error("cityCode parameter is required");
  }

  const params = {
    cityCode: cityCode.toUpperCase(),
    radius: radius,
    radiusUnit: radiusUnit,
    hotelSource: hotelSource,
  };

  // Optional filters
  if (amenities) params.amenities = amenities;
  if (ratings) params.ratings = ratings;

  return await callAmadeusAPI(AMADEUS_CONFIG.endpoints.byCity, params);
}

/**
 * Search hotels by geocode (latitude & longitude)
 * @param {number} latitude - Latitude coordinate (e.g., 48.8566 for Paris)
 * @param {number} longitude - Longitude coordinate (e.g., 2.3522 for Paris)
 * @param {number} radius - Search radius in KM (default: 5, max: 300)
 * @param {string} radiusUnit - Unit: KM or MILE (default: KM)
 * @param {string} amenities - Filter by amenities
 * @param {string} ratings - Filter by ratings
 * @param {string} hotelSource - Hotel source (default: ALL)
 * @returns {Promise<Object>} Hotel data
 *
 * @example
 * const hotels = await searchHotelsByGeocode(48.8566, 2.3522, 5, "KM");
 */
async function searchHotelsByGeocode(
  latitude,
  longitude,
  radius = 5,
  radiusUnit = "KM",
  amenities = null,
  ratings = null,
  hotelSource = "ALL"
) {
  if (!latitude || !longitude) {
    throw new Error("latitude and longitude parameters are required");
  }

  const params = {
    latitude: latitude,
    longitude: longitude,
    radius: radius,
    radiusUnit: radiusUnit,
    hotelSource: hotelSource,
  };

  // Optional filters
  if (amenities) params.amenities = amenities;
  if (ratings) params.ratings = ratings;

  return await callAmadeusAPI(AMADEUS_CONFIG.endpoints.byGeocode, params);
}

//Input User Converter
/**
 * Mencari lokasi (Kota atau Hotel) berdasarkan keyword (teks bebas).
 * Ini adalah "Penerjemah" Anda.
 *
 * @param {string} keyword - Teks pencarian user (mis: "Jakarta" or "Marriott")
 * @param {string} subType - Tipe yang dicari ('CITY', 'HOTEL', atau 'AIRPORT')
 * @returns {Promise<Object>} Data lokasi dari Amadeus
 *
 * @example
 * // Mencari kode kota "Jakarta"
 * const city = await searchLocationsByKeyword("Jakarta", "CITY");
 * const cityCode = city.data[0].iataCode; // "JKT"
 *
 * @example
 * // Mencari hotel "Marriott"
 * const hotels = await searchLocationsByKeyword("Marriott", "HOTEL");
 */
async function searchLocationsByKeyword(keyword, subType) {
  if (!keyword || !subType) {
    throw new Error("keyword and subType parameters are required");
  }

  const params = {
    keyword: keyword,
    subType: subType.toUpperCase(),
    "page[limit]": 10, // Ambil 10 hasil teratas
  };

  // Asumsi Anda punya AMADEUS_CONFIG.endpoints.locations
  // Jika tidak, endpoint-nya adalah "/v1/reference-data/locations"
  const endpoint =
    AMADEUS_CONFIG.endpoints.locations || "/v1/reference-data/locations";

  return await callAmadeusAPI(endpoint, params);
}

// ============================================================================
// PUBLIC FUNCTIONS - HOTEL OFFERS (Step 2: Find Rates)
// ============================================================================

/**
 * Search for hotel offers (prices, room types, availability)
 * @param {Object} params - Search parameters
 * @param {string[]} params.hotelIds - Array of hotel IDs (max 200)
 * @param {string} params.checkInDate - Check-in date (YYYY-MM-DD)
 * @param {string} params.checkOutDate - Check-out date (YYYY-MM-DD)
 * @param {number} params.adults - Number of adults (1-9)
 * @param {number} params.roomQuantity - Number of rooms (default: 1)
 * @param {string} params.currency - Currency code (default: EUR)
 * @param {string} params.paymentPolicy - NONE, GUARANTEE, DEPOSIT (default: NONE)
 * @param {string} params.boardType - Meal plan: ROOM_ONLY, BREAKFAST, etc. (optional)
 * @returns {Promise<Object>} Hotel offers data
 *
 * @example
 * const offers = await searchHotelOffers({
 *   hotelIds: ["MCLONGHM", "ADPAR001"],
 *   checkInDate: "2025-12-20",
 *   checkOutDate: "2025-12-22",
 *   adults: 2,
 *   roomQuantity: 1
 * });
 */
async function searchHotelOffers(params) {
  const {
    hotelIds,
    checkInDate,
    checkOutDate,
    adults,
    roomQuantity = 1,
    currency = "EUR",
    paymentPolicy = "NONE",
    boardType = null,
    priceRange = null,
    ratings = null,
    bestRateOnly = false,
  } = params;

  // Validasi parameters
  if (!hotelIds || hotelIds.length === 0) {
    throw new Error("hotelIds parameter is required");
  }

  if (!checkInDate || !checkOutDate || !adults) {
    throw new Error("checkInDate, checkOutDate, and adults are required");
  }

  // Validasi format tanggal
  const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
  if (!dateRegex.test(checkInDate) || !dateRegex.test(checkOutDate)) {
    throw new Error("Date format must be YYYY-MM-DD");
  }

  // Validasi check-out date > check-in date
  const checkIn = new Date(checkInDate);
  const checkOut = new Date(checkOutDate);
  if (checkOut <= checkIn) {
    throw new Error("Check-out date must be after check-in date");
  }

  // Validasi adults range
  if (adults < 1 || adults > 9) {
    throw new Error("Number of adults must be between 1 and 9");
  }

  // Validasi max hotel IDs (Amadeus limit: 200)
  if (hotelIds.length > 200) {
    throw new Error("Maximum 200 hotel IDs per request");
  }

  // Build query parameters
  const queryParams = {
    hotelIds: Array.isArray(hotelIds) ? hotelIds.join(",") : hotelIds,
    checkInDate: checkInDate,
    checkOutDate: checkOutDate,
    adults: adults,
    roomQuantity: roomQuantity,
    currency: currency,
    paymentPolicy: paymentPolicy,
  };

  // Optional parameters
  if (boardType) queryParams.boardType = boardType;
  if (priceRange) queryParams.priceRange = priceRange;
  if (ratings) queryParams.ratings = ratings;
  if (bestRateOnly) queryParams.bestRateOnly = bestRateOnly;

  // Call Amadeus API
  return await callAmadeusAPI("/v3/shopping/hotel-offers", queryParams);
}

/**
 * Confirm pricing for a specific offer (before booking)
 * @param {string} offerId - Offer ID from hotel-offers response
 * @returns {Promise<Object>} Confirmed offer with final pricing
 *
 * @example
 * const confirmedOffer = await confirmOfferPricing("OFFER123ABC");
 */
async function confirmOfferPricing(offerId) {
  if (!offerId) {
    throw new Error("offerId parameter is required");
  }

  // Call Amadeus API
  // Note: This is a GET request to a specific offer ID
  return await callAmadeusAPI(`/v3/shopping/hotel-offers/${offerId}`);
}

// ============================================================================
// PUBLIC FUNCTIONS - HOTEL BOOKING (Step 3: Book Rooms)
// ============================================================================

/**
 * Create hotel booking (hotel order)
 * @param {Object} bookingData - Booking data
 * @param {string} bookingData.offerId - Offer ID from hotel-offers
 * @param {Object[]} bookingData.guests - Array of guest information
 * @param {Object} bookingData.payments - Payment information
 * @returns {Promise<Object>} Booking confirmation data
 *
 * @example
 * const booking = await createHotelBooking({
 *   offerId: "OFFER123ABC",
 *   guests: [
 *     {
 *       name: {
 *         title: "MR",
 *         firstName: "JOHN",
 *         lastName: "DOE"
 *       },
 *       contact: {
 *         phone: "+33600000000",
 *         email: "john.doe@example.com"
 *       }
 *     }
 *   ],
 *   payments: [
 *     {
 *       method: "creditCard",
 *       card: {
 *         vendorCode: "VI",
 *         cardNumber: "4111111111111111",
 *         expiryDate: "2025-12"
 *       }
 *     }
 *   ]
 * });
 */
async function createHotelBooking(bookingData) {
  const { offerId, guests, payments } = bookingData;

  // Validasi parameters
  if (!offerId) {
    throw new Error("offerId is required");
  }

  if (!guests || !Array.isArray(guests) || guests.length === 0) {
    throw new Error("At least one guest is required");
  }

  // Validasi guest data
  for (let i = 0; i < guests.length; i++) {
    const guest = guests[i];

    if (!guest.name?.firstName || !guest.name?.lastName) {
      throw new Error(`Guest ${i + 1}: firstName and lastName are required`);
    }

    if (!guest.contact?.email) {
      throw new Error(`Guest ${i + 1}: email is required`);
    }

    if (!guest.contact?.phone) {
      throw new Error(`Guest ${i + 1}: phone is required`);
    }
  }

  // Build request body sesuai Amadeus API format
  const requestBody = {
    data: {
      type: "hotel-order", // ← TAMBAHKAN INI (PENTING!)
      guests: guests.map((guest, index) => ({
        tid: index + 1, // ← Guest ID (1, 2, 3, ...)
        title: guest.name.title?.toUpperCase() || "MR",
        firstName: guest.name.firstName.toUpperCase(),
        lastName: guest.name.lastName.toUpperCase(),
        phone: guest.contact.phone,
        email: guest.contact.email.toLowerCase(),
      })),
      payments: payments || [
        {
          method: "creditCard",
          card: {
            vendorCode: "VI", // Visa
            cardNumber: "4111111111111111", // Test card
            expiryDate: "2025-12",
          },
        },
      ],
      rooms: [
        {
          offerId: offerId,
          guests: guests.map((_, index) => ({
            tid: index + 1, // Reference to guest tid
          })),
        },
      ],
    },
  };

  try {
    // Get access token
    const accessToken = await getAccessToken();

    // Call Amadeus Hotel Booking API
    const url = `${AMADEUS_CONFIG.baseUrl}/v1/booking/hotel-orders`;

    console.log(`🌐 Creating hotel booking with offerId: ${offerId}`);
    console.log("📤 Request Body:", JSON.stringify(requestBody, null, 2));

    const response = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(requestBody),
    });

    const data = await response.json();

    console.log("📥 Response Status:", response.status);
    console.log("📥 Response Data:", JSON.stringify(data, null, 2));

    // Handle errors
    if (!response.ok) {
      console.error("❌ Amadeus Booking Error:", data);

      // Extract error message
      const errorMessage =
        data.errors?.[0]?.detail ||
        data.errors?.[0]?.title ||
        data.error_description ||
        "Booking failed";

      throw new Error(errorMessage);
    }

    console.log(`✅ Hotel booking created successfully`);

    return data;
  } catch (error) {
    console.error("❌ Error creating hotel booking:", error.message);
    throw error;
  }
}

// ============================================================================
// PUBLIC FUNCTIONS - FLIGHT SEARCH & BOOKING
// ============================================================================

/**
 * Search locations (airports/cities) by keyword
 * @param {string} keyword - Search keyword (e.g., "Jakarta", "CGK")
 * @param {string} subType - Location type: AIRPORT, CITY
 * @returns {Promise<Object>} Location data
 *
 * @example
 * const locations = await searchFlightLocations("jakarta", "CITY");
 */
async function searchFlightLocations(keyword, subType) {
  if (!keyword) {
    throw new Error("keyword parameter is required");
  }

  if (!subType) {
    throw new Error("subType parameter is required (AIRPORT or CITY)");
  }

  const params = {
    keyword: keyword,
    subType: subType.toUpperCase(),
    "page[limit]": 10,
  };

  return await callAmadeusAPI("/v1/reference-data/locations", params);
}

/**
 * Search flight offers
 * @param {Object} searchParams - Flight search parameters
 * @returns {Promise<Object>} Flight offers data
 *
 * @example
 * const offers = await searchFlightOffers({
 *   originDestinations: [...],
 *   travelers: [...],
 *   sources: ["GDS"],
 *   searchCriteria: { maxFlightOffers: 50 }
 * });
 */
async function searchFlightOffers(searchParams) {
  const {
    originDestinations,
    travelers,
    sources = ["GDS"],
    searchCriteria = { maxFlightOffers: 50 },
  } = searchParams;

  // Validasi parameters
  if (!originDestinations || originDestinations.length === 0) {
    throw new Error("originDestinations is required");
  }

  if (!travelers || travelers.length === 0) {
    throw new Error("travelers is required");
  }

  // Build request body
  const requestBody = {
    originDestinations,
    travelers,
    sources,
    searchCriteria,
  };

  try {
    const accessToken = await getAccessToken();
    const url = `${AMADEUS_CONFIG.baseUrl}/v2/shopping/flight-offers`;

    console.log(`🌐 Searching flight offers...`);
    console.log("📤 Request Body:", JSON.stringify(requestBody, null, 2));

    const response = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(requestBody),
    });

    const data = await response.json();

    console.log("📥 Response Status:", response.status);

    if (!response.ok) {
      console.error("❌ Amadeus Flight Search Error:", data);
      throw new Error(data.errors?.[0]?.detail || "Flight search failed");
    }

    console.log(`✅ Found ${data.data?.length || 0} flight offers`);
    return data;
  } catch (error) {
    console.error("❌ Error searching flight offers:", error.message);
    throw error;
  }
}

/**
 * Confirm flight offer pricing before booking or getting seatmap
 * @param {Object} flightOfferData - Flight offer object(s) to confirm
 * @returns {Promise<Object>} Confirmed pricing data
 *
 * @note This is MANDATORY before calling seatmap API
 *       Amadeus needs to validate and lock the price first
 *
 * @example
 * const confirmedOffer = await confirmFlightOfferPricing({
 *   data: {
 *     type: "flight-offers-pricing",
 *     flightOffers: [{ ...flightOfferObject... }]
 *   }
 * });
 */
async function confirmFlightOfferPricing(flightOfferData) {
  if (!flightOfferData || !flightOfferData.data) {
    throw new Error("Flight offer data is required");
  }

  try {
    const accessToken = await getAccessToken();
    const url = `${AMADEUS_CONFIG.baseUrl}/v1/shopping/flight-offers/pricing`;

    console.log(`🌐 Confirming flight offer pricing...`);

    const response = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(flightOfferData),
    });

    const data = await response.json();

    if (!response.ok) {
      console.error("❌ Amadeus Pricing Error:", data);
      throw new Error(
        data.errors?.[0]?.detail || "Failed to confirm flight offer pricing"
      );
    }

    console.log(`✅ Flight offer pricing confirmed successfully`);
    return data;
  } catch (error) {
    console.error("❌ Error confirming flight offer pricing:", error.message);
    throw error;
  }
}

/**
 * Get seatmap for flight offer (MUST confirm pricing first)
 * @param {Object} confirmedFlightOfferData - CONFIRMED flight offer from pricing API
 * @returns {Promise<Object>} Seatmap data
 *
 * @note Input MUST be result from confirmFlightOfferPricing()
 *
 * @example
 * // Step 1: Confirm pricing first
 * const confirmed = await confirmFlightOfferPricing({
 *   data: {
 *     type: "flight-offers-pricing",
 *     flightOffers: [flightOffer]
 *   }
 * });
 *
 * // Step 2: Get seatmap with confirmed offer
 * const seatmap = await getFlightSeatmap({
 *   data: confirmed.data.flightOffers
 * });
 */
async function getFlightSeatmap(confirmedFlightOfferData) {
  if (!confirmedFlightOfferData || !confirmedFlightOfferData.data) {
    throw new Error("Confirmed flight offer data is required");
  }

  try {
    const accessToken = await getAccessToken();
    const url = `${AMADEUS_CONFIG.baseUrl}/v1/shopping/seatmaps`;

    console.log(`🌐 Getting seatmap...`);

    const response = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(confirmedFlightOfferData),
    });

    const data = await response.json();

    if (!response.ok) {
      console.error("❌ Amadeus Seatmap Error:", data);
      throw new Error(data.errors?.[0]?.detail || "Failed to get seatmap");
    }

    console.log(`✅ Seatmap retrieved successfully`);
    return data;
  } catch (error) {
    console.error("❌ Error getting seatmap:", error.message);
    throw error;
  }
}

/**
 * Get seatmap for flight offer
 * @param {Object} flightOfferData - Flight offer object(s)
 * @returns {Promise<Object>} Seatmap data
 *
 * @note DECISION: Kirim entire flightOffer dari Flutter
 *       Alasan: Lebih efisien, avoid double API call
 *       Trade-off: Request body lebih besar, tapi Firebase quota lebih hemat
 *
 * @example
 * const seatmap = await getFlightSeatmap({
 *   data: [{ ...flightOfferObject... }]
 * });
 */
async function getFlightSeatmap(flightOfferData) {
  if (!flightOfferData || !flightOfferData.data) {
    throw new Error("Flight offer data is required");
  }

  try {
    const accessToken = await getAccessToken();
    const url = `${AMADEUS_CONFIG.baseUrl}/v1/shopping/seatmaps`;

    console.log(`🌐 Getting seatmap...`);

    const response = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(flightOfferData),
    });

    const data = await response.json();

    if (!response.ok) {
      console.error("❌ Amadeus Seatmap Error:", data);
      throw new Error(data.errors?.[0]?.detail || "Failed to get seatmap");
    }

    console.log(`✅ Seatmap retrieved successfully`);
    return data;
  } catch (error) {
    console.error("❌ Error getting seatmap:", error.message);
    throw error;
  }
}

// ============================================================================
// EXPORTS
// ============================================================================

module.exports = {
  searchHotelsByHotelIds,
  searchHotelsByCity,
  searchHotelsByGeocode,
  searchLocationsByKeyword,
  searchHotelOffers,
  confirmOfferPricing,
  createHotelBooking,
  searchFlightLocations,
  searchFlightOffers,
  confirmFlightOfferPricing,
  getFlightSeatmap,
  getAccessToken,
};
