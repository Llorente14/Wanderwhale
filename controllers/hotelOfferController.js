// ============================================================================
// FILE: controllers/hotelOfferController.js
// DESC: Controller untuk "Step 2" - Find and Confirm Rates
//       Mencari harga hotel dan konfirmasi penawaran sebelum booking
// ============================================================================

const amadeusService = require("../services/amadeusService");

// ============================================================================
// 1. GET HOTEL OFFERS - Mencari Harga & Kamar Tersedia
// ============================================================================
/**
 * @desc    Search for available offers (prices, rooms, deals) for specific hotels
 * @route   GET /api/hotels/offers
 * @access  Public
 * @query   ?hotelIds=MCLONGHM,ADPAR001 - Comma-separated hotel IDs (required)
 * @query   ?checkInDate=2025-12-20 - Check-in date YYYY-MM-DD (required)
 * @query   ?checkOutDate=2025-12-22 - Check-out date YYYY-MM-DD (required)
 * @query   ?adults=2 - Number of adults (required, 1-9)
 * @query   ?roomQuantity=1 - Number of rooms (optional, default: 1)
 * @query   ?currency=EUR - Currency code (optional, default: EUR)
 * @query   ?paymentPolicy=NONE - Payment policy: NONE, GUARANTEE, DEPOSIT (optional)
 * @query   ?boardType=BREAKFAST - Meal plan: ROOM_ONLY, BREAKFAST, etc. (optional)
 * @query   ?bestRateOnly=true - Show only best rate per hotel (optional)
 */
exports.getHotelOffers = async (req, res) => {
  try {
    // 1. Ambil semua parameter dari query
    const {
      hotelIds,
      checkInDate,
      checkOutDate,
      adults,
      roomQuantity = 1,
      currency = "EUR",
      paymentPolicy = "NONE",
      boardType,
      priceRange,
      ratings,
      bestRateOnly,
    } = req.query;

    // 2. Validasi parameter wajib
    if (!hotelIds || !checkInDate || !checkOutDate || !adults) {
      return res.status(400).json({
        success: false,
        message: "hotelIds, checkInDate, checkOutDate, and adults are required",
        example:
          "/api/hotels/offers?hotelIds=MCLONGHM,ADPAR001&checkInDate=2025-12-20&checkOutDate=2025-12-22&adults=2",
      });
    }

    // 3. Validasi format tanggal
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateRegex.test(checkInDate) || !dateRegex.test(checkOutDate)) {
      return res.status(400).json({
        success: false,
        message: "Date format must be YYYY-MM-DD",
        example: "checkInDate=2025-12-20&checkOutDate=2025-12-22",
      });
    }

    // 4. Validasi logical date (check-out > check-in)
    const checkIn = new Date(checkInDate);
    const checkOut = new Date(checkOutDate);

    if (checkOut <= checkIn) {
      return res.status(400).json({
        success: false,
        message: "Check-out date must be after check-in date",
      });
    }

    // 5. Validasi check-in date tidak di masa lalu
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (checkIn < today) {
      return res.status(400).json({
        success: false,
        message: "Check-in date cannot be in the past",
      });
    }

    // 6. Validasi number of adults
    const adultsNum = parseInt(adults);
    if (isNaN(adultsNum) || adultsNum < 1 || adultsNum > 9) {
      return res.status(400).json({
        success: false,
        message: "Number of adults must be between 1 and 9",
      });
    }

    // 7. Validasi room quantity
    const roomNum = parseInt(roomQuantity);
    if (isNaN(roomNum) || roomNum < 1) {
      return res.status(400).json({
        success: false,
        message: "Room quantity must be at least 1",
      });
    }

    // 8. Parse hotel IDs (comma-separated string to array)
    const hotelIdsArray = hotelIds
      .split(",")
      .map((id) => id.trim())
      .filter((id) => id.length > 0);

    if (hotelIdsArray.length === 0) {
      return res.status(400).json({
        success: false,
        message: "At least one hotel ID is required",
      });
    }

    if (hotelIdsArray.length > 200) {
      return res.status(400).json({
        success: false,
        message: "Maximum 200 hotel IDs per request",
      });
    }

    // 9. Call Amadeus service
    const data = await amadeusService.searchHotelOffers({
      hotelIds: hotelIdsArray,
      checkInDate,
      checkOutDate,
      adults: adultsNum,
      roomQuantity: roomNum,
      currency,
      paymentPolicy,
      boardType,
      priceRange,
      ratings,
      bestRateOnly: bestRateOnly === "true",
    });

    // 10. Calculate nights
    const nights = Math.ceil((checkOut - checkIn) / (1000 * 60 * 60 * 24));

    // 11. Return response dengan enriched data
    return res.status(200).json({
      success: true,
      message: "Hotel offers retrieved successfully",
      data: data.data || [],
      count: data.data?.length || 0,
      meta: data.meta || {},
      searchParams: {
        hotelIds: hotelIdsArray,
        checkInDate,
        checkOutDate,
        nights,
        adults: adultsNum,
        rooms: roomNum,
        currency,
      },
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Hotel offers retrieved successfully",
    //   "data": [
    //     {
    //       "type": "hotel-offers",
    //       "hotel": {
    //         "type": "hotel",
    //         "hotelId": "MCLONGHM",
    //         "chainCode": "MC",
    //         "name": "MELIA WHITE HOUSE",
    //         "cityCode": "LON"
    //       },
    //       "available": true,
    //       "offers": [
    //         {
    //           "id": "OFFER123ABC",
    //           "checkInDate": "2025-12-20",
    //           "checkOutDate": "2025-12-22",
    //           "room": {
    //             "type": "A1K",
    //             "typeEstimated": {
    //               "category": "SUPERIOR_ROOM",
    //               "beds": 1,
    //               "bedType": "KING"
    //             },
    //             "description": {
    //               "text": "Deluxe King Room with City View"
    //             }
    //           },
    //           "guests": {
    //             "adults": 2
    //           },
    //           "price": {
    //             "currency": "EUR",
    //             "base": "250.00",
    //             "total": "285.50",
    //             "variations": {
    //               "average": {
    //                 "base": "125.00"
    //               }
    //             }
    //           },
    //           "policies": {
    //             "paymentType": "guarantee",
    //             "cancellation": {
    //               "deadline": "2025-12-18T23:59:00.000+00:00"
    //             }
    //           }
    //         }
    //       ]
    //     }
    //   ],
    //   "count": 1,
    //   "searchParams": {
    //     "hotelIds": ["MCLONGHM"],
    //     "checkInDate": "2025-12-20",
    //     "checkOutDate": "2025-12-22",
    //     "nights": 2,
    //     "adults": 2,
    //     "rooms": 1,
    //     "currency": "EUR"
    //   }
    // }
  } catch (error) {
    console.error("Error getting hotel offers:", error);

    // Handle specific Amadeus errors
    if (error.message.includes("No hotels found")) {
      return res.status(404).json({
        success: false,
        message: "No offers found for the specified criteria",
      });
    }

    if (error.message.includes("Date")) {
      return res.status(400).json({
        success: false,
        message: error.message,
      });
    }

    return res.status(500).json({
      success: false,
      message: "Failed to retrieve hotel offers",
      error: error.message,
    });
  }
};

// ============================================================================
// 2. GET OFFER PRICING - Konfirmasi Harga Spesifik (Pre-Booking)
// ============================================================================
/**
 * @desc    Confirm the final price of a specific offer before booking
 * @route   GET /api/hotels/offers/:offerId
 * @access  Public
 * @params  :offerId - Offer ID from /api/hotels/offers response
 *
 * @note    Use this endpoint to:
 *          1. Confirm price before payment (might have changed)
 *          2. Get detailed cancellation policies
 *          3. Verify room availability one more time
 */
exports.getOfferPricing = async (req, res) => {
  try {
    // 1. Ambil offerId dari URL parameter
    const { offerId } = req.params;

    // 2. Validasi offerId
    if (!offerId) {
      return res.status(400).json({
        success: false,
        message: "offerId parameter is required",
        example: "/api/hotels/offers/OFFER123ABC",
      });
    }

    // 3. Validasi format offerId (basic check)
    if (offerId.length < 5) {
      return res.status(400).json({
        success: false,
        message: "Invalid offer ID format",
      });
    }

    // 4. Call Amadeus service untuk confirm pricing
    const data = await amadeusService.confirmOfferPricing(offerId);

    // 5. Cek apakah offer masih available
    if (!data.data) {
      return res.status(404).json({
        success: false,
        message: "Offer not found or no longer available",
      });
    }

    // 6. Extract key info untuk response
    const offer = data.data;
    const priceChanged = offer.price?.changes || false;

    // 7. Return response dengan status info
    return res.status(200).json({
      success: true,
      message: priceChanged
        ? "Offer pricing confirmed - Price has changed"
        : "Offer pricing confirmed - Price unchanged",
      data: offer,
      meta: data.meta || {},
      priceStatus: {
        changed: priceChanged,
        available: offer.available !== false,
        offerId: offerId,
      },
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Offer pricing confirmed - Price unchanged",
    //   "data": {
    //     "type": "hotel-offers",
    //     "hotel": {
    //       "hotelId": "MCLONGHM",
    //       "name": "MELIA WHITE HOUSE"
    //     },
    //     "available": true,
    //     "offers": [
    //       {
    //         "id": "OFFER123ABC",
    //         "checkInDate": "2025-12-20",
    //         "checkOutDate": "2025-12-22",
    //         "room": {
    //           "type": "A1K",
    //           "typeEstimated": {
    //             "category": "SUPERIOR_ROOM"
    //           }
    //         },
    //         "price": {
    //           "currency": "EUR",
    //           "base": "250.00",
    //           "total": "285.50"
    //         },
    //         "policies": {
    //           "paymentType": "guarantee",
    //           "cancellation": {
    //             "type": "FULL_STAY",
    //             "deadline": "2025-12-18T23:59:00.000+00:00",
    //             "amount": "285.50"
    //           }
    //         }
    //       }
    //     ]
    //   },
    //   "priceStatus": {
    //     "changed": false,
    //     "available": true,
    //     "offerId": "OFFER123ABC"
    //   }
    // }
  } catch (error) {
    console.error("Error confirming offer pricing:", error);

    // Handle specific errors
    if (error.message.includes("not found") || error.message.includes("404")) {
      return res.status(404).json({
        success: false,
        message: "Offer not found or has expired. Please search again.",
        hint: "Offers are typically valid for 15-30 minutes",
      });
    }

    if (error.message.includes("400")) {
      return res.status(400).json({
        success: false,
        message: "Invalid offer ID",
      });
    }

    return res.status(500).json({
      success: false,
      message: "Failed to confirm offer pricing",
      error: error.message,
    });
  }
};

// ============================================================================
// 3. (BONUS) COMPARE OFFERS - Bandingkan Penawaran dari Multiple Hotels
// ============================================================================
/**
 * @desc    Compare offers and find the best deal
 * @route   GET /api/hotels/offers/compare
 * @access  Public
 * @query   Same as /api/hotels/offers but returns sorted by price
 */
exports.compareOffers = async (req, res) => {
  try {
    // Reuse getHotelOffers logic
    const offersResult = await new Promise((resolve, reject) => {
      const mockRes = {
        status: (code) => ({
          json: (data) => {
            if (code === 200) resolve(data);
            else reject(data);
          },
        }),
      };
      exports.getHotelOffers(req, mockRes);
    });

    // Sort offers by price (cheapest first)
    const sortedData = offersResult.data.map((hotelOffer) => {
      // Sort offers within each hotel
      if (hotelOffer.offers) {
        hotelOffer.offers.sort((a, b) => {
          const priceA = parseFloat(a.price?.total || 0);
          const priceB = parseFloat(b.price?.total || 0);
          return priceA - priceB;
        });
      }
      return hotelOffer;
    });

    // Sort hotels by their cheapest offer
    sortedData.sort((a, b) => {
      const cheapestA = a.offers?.[0]?.price?.total || Infinity;
      const cheapestB = b.offers?.[0]?.price?.total || Infinity;
      return parseFloat(cheapestA) - parseFloat(cheapestB);
    });

    // Find overall best deal
    const bestDeal = sortedData[0]?.offers?.[0] || null;

    return res.status(200).json({
      success: true,
      message: "Offers compared and sorted by price",
      data: sortedData,
      count: sortedData.length,
      bestDeal: bestDeal
        ? {
            offerId: bestDeal.id,
            hotelId: sortedData[0].hotel.hotelId,
            hotelName: sortedData[0].hotel.name,
            price: bestDeal.price,
            roomType: bestDeal.room?.typeEstimated?.category,
          }
        : null,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to compare offers",
      error: error.message,
    });
  }
};
