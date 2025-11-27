// ============================================================================
// FILE: controllers/flightSearchController.js
// DESC: Controller untuk flight search (Location, Offers, Seatmap)
//       Semua endpoint ini menggunakan LIVE Amadeus API
// ============================================================================

const amadeusService = require("../services/amadeusService");

// ============================================================================
// STEP 0: SEARCH LOCATIONS - Pencarian Airport/City
// ============================================================================
/**
 * @desc    Search airports or cities by keyword
 * @route   GET /api/flights/search/locations
 * @access  Public
 * @query   ?keyword=jakarta - Search keyword (required)
 * @query   ?subType=CITY - Location type: AIRPORT or CITY (required)
 */
exports.searchLocations = async (req, res) => {
  try {
    // 1. Ambil parameters dari query
    const { keyword, subType } = req.query;

    // 2. Validasi parameters
    if (!keyword) {
      return res.status(400).json({
        success: false,
        message: "keyword query parameter is required",
        example: "/api/flights/search/locations?keyword=jakarta&subType=CITY",
      });
    }

    if (!subType) {
      return res.status(400).json({
        success: false,
        message: "subType query parameter is required",
        allowedValues: ["AIRPORT", "CITY"],
        example: "/api/flights/search/locations?keyword=jakarta&subType=CITY",
      });
    }

    // 3. Validasi subType value
    const validSubTypes = ["AIRPORT", "CITY"];
    if (!validSubTypes.includes(subType.toUpperCase())) {
      return res.status(400).json({
        success: false,
        message: "Invalid subType. Must be AIRPORT or CITY",
        allowedValues: validSubTypes,
      });
    }

    // 4. Call Amadeus service (LIVE API)
    const data = await amadeusService.searchFlightLocations(keyword, subType);

    // 5. Cek jika tidak ada hasil
    if (!data.data || data.data.length === 0) {
      return res.status(200).json({
        success: true,
        message: `No ${subType.toLowerCase()}s found for keyword: ${keyword}`,
        data: [],
        count: 0,
      });
    }

    // 6. Return response
    return res.status(200).json({
      success: true,
      message: "Locations retrieved successfully",
      data: data.data,
      count: data.data.length,
      meta: data.meta || {},
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Locations retrieved successfully",
    //   "data": [
    //     {
    //       "type": "location",
    //       "subType": "CITY",
    //       "name": "JAKARTA",
    //       "detailedName": "JAKARTA, INDONESIA",
    //       "iataCode": "JKT",
    //       "address": {
    //         "cityCode": "JKT",
    //         "countryCode": "ID"
    //       }
    //     },
    //     {
    //       "type": "location",
    //       "subType": "AIRPORT",
    //       "name": "SOEKARNO-HATTA INTL",
    //       "detailedName": "JAKARTA/ID:SOEKARNO-HATTA",
    //       "iataCode": "CGK",
    //       "address": {
    //         "cityCode": "JKT",
    //         "countryCode": "ID"
    //       }
    //     }
    //   ],
    //   "count": 2
    // }
  } catch (error) {
    console.error("Error searching locations:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to search locations",
      error: error.message,
    });
  }
};

// ============================================================================
// STEP 1: SEARCH FLIGHT OFFERS - Pencarian Penerbangan
// ============================================================================
/**
 * @desc    Search for flight offers
 * @route   POST /api/flights/search
 * @access  Public
 * @body    {
 *            originDestinations: array (required),
 *            travelers: array (required),
 *            sources: array (optional, default: ["GDS"]),
 *            searchCriteria: object (optional)
 *          }
 *
 * @example Body:
 * {
 *   "originDestinations": [
 *     {
 *       "id": "1",
 *       "originLocationCode": "CGK",
 *       "destinationLocationCode": "DPS",
 *       "departureDateTimeRange": {
 *         "date": "2025-12-20"
 *       }
 *     }
 *   ],
 *   "travelers": [
 *     {
 *       "id": "1",
 *       "travelerType": "ADULT"
 *     }
 *   ],
 *   "sources": ["GDS"],
 *   "searchCriteria": {
 *     "maxFlightOffers": 50
 *   }
 * }
 */
exports.searchFlightOffers = async (req, res) => {
  try {
    // 1. Ambil data dari request body
    const {
      originDestinations,
      travelers,
      sources = ["GDS"],
      searchCriteria = { maxFlightOffers: 50 },
    } = req.body;

    // 2. Validasi originDestinations
    if (
      !originDestinations ||
      !Array.isArray(originDestinations) ||
      originDestinations.length === 0
    ) {
      return res.status(400).json({
        success: false,
        message: "originDestinations array is required",
        example: {
          originDestinations: [
            {
              id: "1",
              originLocationCode: "CGK",
              destinationLocationCode: "DPS",
              departureDateTimeRange: {
                date: "2025-12-20",
              },
            },
          ],
        },
      });
    }

    // 3. Validasi travelers
    if (!travelers || !Array.isArray(travelers) || travelers.length === 0) {
      return res.status(400).json({
        success: false,
        message: "travelers array is required",
        example: {
          travelers: [
            {
              id: "1",
              travelerType: "ADULT",
            },
          ],
        },
      });
    }

    // 4. Validasi setiap originDestination
    for (let i = 0; i < originDestinations.length; i++) {
      const od = originDestinations[i];

      if (!od.originLocationCode || !od.destinationLocationCode) {
        return res.status(400).json({
          success: false,
          message: `originDestination ${
            i + 1
          }: originLocationCode and destinationLocationCode are required`,
        });
      }

      if (!od.departureDateTimeRange?.date) {
        return res.status(400).json({
          success: false,
          message: `originDestination ${
            i + 1
          }: departureDateTimeRange.date is required (format: YYYY-MM-DD)`,
        });
      }

      // Validasi format tanggal
      const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
      if (!dateRegex.test(od.departureDateTimeRange.date)) {
        return res.status(400).json({
          success: false,
          message: `originDestination ${
            i + 1
          }: Invalid date format. Use YYYY-MM-DD`,
        });
      }

      // Validasi tanggal tidak di masa lalu
      const departureDate = new Date(od.departureDateTimeRange.date);
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      if (departureDate < today) {
        return res.status(400).json({
          success: false,
          message: `originDestination ${
            i + 1
          }: Departure date cannot be in the past`,
        });
      }
    }

    // 5. Validasi travelers
    const validTravelerTypes = [
      "ADULT",
      "CHILD",
      "HELD_INFANT",
      "SEATED_INFANT",
      "SENIOR",
    ];
    for (let i = 0; i < travelers.length; i++) {
      const traveler = travelers[i];

      if (!traveler.travelerType) {
        return res.status(400).json({
          success: false,
          message: `traveler ${i + 1}: travelerType is required`,
          allowedValues: validTravelerTypes,
        });
      }

      if (!validTravelerTypes.includes(traveler.travelerType)) {
        return res.status(400).json({
          success: false,
          message: `traveler ${i + 1}: Invalid travelerType`,
          allowedValues: validTravelerTypes,
        });
      }
    }

    // 6. Call Amadeus service (LIVE API)
    const data = await amadeusService.searchFlightOffers({
      originDestinations,
      travelers,
      sources,
      searchCriteria,
    });

    // 7. Cek jika tidak ada hasil
    if (!data.data || data.data.length === 0) {
      return res.status(200).json({
        success: true,
        message: "No flight offers found for the specified criteria",
        data: [],
        count: 0,
        dictionaries: data.dictionaries || {},
      });
    }

    // 8. Return response dengan dictionaries untuk decode data
    return res.status(200).json({
      success: true,
      message: "Flight offers retrieved successfully",
      data: data.data,
      count: data.data.length,
      dictionaries: data.dictionaries || {},
      meta: data.meta || {},
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Flight offers retrieved successfully",
    //   "data": [
    //     {
    //       "type": "flight-offer",
    //       "id": "1",
    //       "source": "GDS",
    //       "instantTicketingRequired": false,
    //       "nonHomogeneous": false,
    //       "oneWay": false,
    //       "lastTicketingDate": "2025-12-20",
    //       "numberOfBookableSeats": 9,
    //       "itineraries": [...],
    //       "price": {
    //         "currency": "IDR",
    //         "total": "2500000",
    //         "base": "2200000",
    //         "grandTotal": "2500000"
    //       },
    //       "pricingOptions": {...},
    //       "validatingAirlineCodes": ["GA"],
    //       "travelerPricings": [...]
    //     }
    //   ],
    //   "count": 15,
    //   "dictionaries": {
    //     "locations": {...},
    //     "aircraft": {...},
    //     "carriers": {...}
    //   }
    // }
  } catch (error) {
    console.error("Error searching flight offers:", error);

    // Handle specific Amadeus errors
    if (error.message.includes("No flight")) {
      return res.status(404).json({
        success: false,
        message: "No flights found for the specified route and date",
      });
    }

    return res.status(500).json({
      success: false,
      message: "Failed to search flight offers",
      error: error.message,
    });
  }
};

// ============================================================================
// STEP 1.5: CONFIRM FLIGHT OFFER PRICING (Before Seatmap)
// ============================================================================
/**
 * @desc    Confirm flight offer pricing (required before seatmap or booking)
 * @route   POST /api/flights/pricing
 * @access  Public
 * @body    {
 *            data: {
 *              type: "flight-offers-pricing",
 *              flightOffers: array (required) - Flight offers from search
 *            }
 *          }
 *
 * @note    This endpoint is MANDATORY before:
 *          1. Getting seatmap
 *          2. Creating booking
 *          It validates and locks the price
 */
exports.confirmFlightPricing = async (req, res) => {
  try {
    // 1. Ambil data dari request body
    const { data } = req.body;

    // 2. Validasi data structure
    if (!data) {
      return res.status(400).json({
        success: false,
        message: "data object is required",
        example: {
          data: {
            type: "flight-offers-pricing",
            flightOffers: [
              {
                // ... flight offer object from search
              },
            ],
          },
        },
      });
    }

    // 3. Validasi type
    if (data.type !== "flight-offers-pricing") {
      return res.status(400).json({
        success: false,
        message: "data.type must be 'flight-offers-pricing'",
      });
    }

    // 4. Validasi flightOffers
    if (
      !data.flightOffers ||
      !Array.isArray(data.flightOffers) ||
      data.flightOffers.length === 0
    ) {
      return res.status(400).json({
        success: false,
        message: "data.flightOffers array is required",
        example: {
          data: {
            type: "flight-offers-pricing",
            flightOffers: [
              {
                type: "flight-offer",
                id: "1",
                // ... rest of flight offer
              },
            ],
          },
        },
      });
    }

    // 5. Call Amadeus service (LIVE API)
    const confirmedData = await amadeusService.confirmFlightOfferPricing({
      data,
    });

    // 6. Check if pricing changed
    const originalPrice = data.flightOffers[0]?.price?.total;
    const confirmedPrice = confirmedData.data?.flightOffers?.[0]?.price?.total;
    const priceChanged = originalPrice !== confirmedPrice;

    // 7. Return response
    return res.status(200).json({
      success: true,
      message: priceChanged
        ? "Flight offer pricing confirmed - Price has changed"
        : "Flight offer pricing confirmed - Price unchanged",
      data: confirmedData.data,
      meta: confirmedData.meta || {},
      priceStatus: {
        changed: priceChanged,
        originalPrice: originalPrice,
        confirmedPrice: confirmedPrice,
      },
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Flight offer pricing confirmed - Price unchanged",
    //   "data": {
    //     "type": "flight-offers-pricing",
    //     "flightOffers": [
    //       {
    //         "type": "flight-offer",
    //         "id": "1",
    //         "source": "GDS",
    //         "itineraries": [...],
    //         "price": {
    //           "currency": "EUR",
    //           "total": "125.00",
    //           "base": "95.00"
    //         },
    //         "pricingOptions": {
    //           "fareType": ["PUBLISHED"],
    //           "includedCheckedBagsOnly": true
    //         },
    //         "validatingAirlineCodes": ["BA"],
    //         "travelerPricings": [...]
    //       }
    //     ],
    //     "bookingRequirements": {
    //       "emailAddressRequired": true,
    //       "mobilePhoneNumberRequired": true,
    //       "travelerRequirements": [...]
    //     }
    //   },
    //   "priceStatus": {
    //     "changed": false,
    //     "originalPrice": "125.00",
    //     "confirmedPrice": "125.00"
    //   }
    // }
  } catch (error) {
    console.error("Error confirming flight pricing:", error);

    // Handle specific errors
    if (error.message.includes("not available")) {
      return res.status(404).json({
        success: false,
        message: "Flight offer is no longer available. Please search again.",
      });
    }

    if (error.message.includes("price")) {
      return res.status(409).json({
        success: false,
        message: "Flight price has changed. Please review the new price.",
        error: error.message,
      });
    }

    return res.status(500).json({
      success: false,
      message: "Failed to confirm flight pricing",
      error: error.message,
    });
  }
};

// ============================================================================
// STEP 2: GET SEATMAP (Updated - Now requires confirmed pricing)
// ============================================================================
/**
 * @desc    Get seatmap for confirmed flight offer
 * @route   POST /api/flights/seatmaps
 * @access  Public
 * @body    {
 *            data: array (required) - Confirmed flight offers from pricing API
 *          }
 *
 * @note    Input MUST be the result from POST /api/flights/pricing
 *          Not the original search result!
 */
exports.getSeatmap = async (req, res) => {
  try {
    // 1. Ambil confirmed flight offer data dari body
    const { data } = req.body;

    // 2. Validasi data
    if (!data || !Array.isArray(data) || data.length === 0) {
      return res.status(400).json({
        success: false,
        message:
          "data array is required (confirmed flight offers from pricing API)",
        hint: "First call POST /api/flights/pricing, then use the result here",
        example: {
          data: [
            {
              type: "flight-offer",
              id: "1",
              // ... confirmed flight offer from pricing response
            },
          ],
        },
      });
    }

    // 3. Validasi flight offer structure
    const flightOffer = data[0];
    if (!flightOffer.type || flightOffer.type !== "flight-offer") {
      return res.status(400).json({
        success: false,
        message:
          "Invalid flight offer data. Must be a confirmed flight-offer from pricing API",
      });
    }

    // 4. Call Amadeus service (LIVE API)
    const seatmapData = await amadeusService.getFlightSeatmap({ data });

    // 5. Cek jika tidak ada seatmap
    if (!seatmapData.data || seatmapData.data.length === 0) {
      return res.status(200).json({
        success: true,
        message: "No seatmap available for this flight",
        data: [],
        count: 0,
      });
    }

    // 6. Return response
    return res.status(200).json({
      success: true,
      message: "Seatmap retrieved successfully",
      data: seatmapData.data,
      count: seatmapData.data.length,
      dictionaries: seatmapData.dictionaries || {},
      meta: seatmapData.meta || {},
    });

    // Response example (same as before)
  } catch (error) {
    console.error("Error getting seatmap:", error);

    // Handle specific errors
    if (error.message.includes("not available")) {
      return res.status(404).json({
        success: false,
        message: "Seatmap not available for this flight",
      });
    }

    if (error.message.includes("mandatory")) {
      return res.status(400).json({
        success: false,
        message:
          "Missing required data. Please confirm pricing first via POST /api/flights/pricing",
        error: error.message,
      });
    }

    return res.status(500).json({
      success: false,
      message: "Failed to get seatmap",
      error: error.message,
    });
  }
};
