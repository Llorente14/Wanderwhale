// ============================================================================
// FILE: controllers/hotelBookingController.js
// DESC: Controller untuk "Step 3" - Book Rooms
//       Handle hotel booking dan simpan ke Firestore
// ============================================================================

const { db, admin } = require("../index");
const amadeusService = require("../services/amadeusService");
const notificationService = require("../services/notificationService");
// ============================================================================
// COLLECTION REFERENCES
// ============================================================================

const bookingsCollection = db.collection("bookings");
const tripsCollection = db.collection("trips");

const MOCK_AMADEUS_BOOKING = process.env.MOCK_AMADEUS_BOOKING === "true";
// ============================================================================
// 1. CREATE HOTEL BOOKING - Book Hotel Room
// ============================================================================
/**
 * @desc    Create hotel booking (finalize reservation)
 * @route   POST /api/hotels/bookings
 * @access  Private (require authCheck middleware)
 * @body    {
 *            offerId: string (required) - Offer ID from /api/hotels/offers,
 *            tripId: string (required) - Trip ID to associate booking with,
 *            guests: array (required) - Guest information,
 *            paymentMethod: string (required) - Payment method: credit_card, debit_card, etc,
 *            payments: array (optional) - Payment details for Amadeus
 *          }
 */

exports.storeHotelBooking = async (req, res) => {
  try {
    // 1. Ambil userId dari middleware authCheck
    const { uid: userId } = req.user;

    // 2. Ambil data dari request body
    const { offerId, tripId, guests, paymentMethod, payments } = req.body;

    // 3. Validasi parameter wajib
    if (!offerId) {
      return res.status(400).json({
        success: false,
        message: "offerId is required",
      });
    }

    if (!tripId) {
      return res.status(400).json({
        success: false,
        message: "tripId is required",
      });
    }

    if (!guests || !Array.isArray(guests) || guests.length === 0) {
      return res.status(400).json({
        success: false,
        message: "At least one guest is required",
        example: {
          guests: [
            {
              name: {
                title: "MR",
                firstName: "John",
                lastName: "Doe",
              },
              contact: {
                phone: "+33600000000",
                email: "john.doe@example.com",
              },
            },
          ],
        },
      });
    }

    if (!paymentMethod) {
      return res.status(400).json({
        success: false,
        message: "paymentMethod is required",
        allowedValues: [
          "credit_card",
          "debit_card",
          "bank_transfer",
          "e_wallet",
        ],
      });
    }

    // 4. Validasi guest data structure
    for (let i = 0; i < guests.length; i++) {
      const guest = guests[i];

      if (!guest.name?.firstName || !guest.name?.lastName) {
        return res.status(400).json({
          success: false,
          message: `Guest ${i + 1}: firstName and lastName are required`,
        });
      }

      if (!guest.contact?.email) {
        return res.status(400).json({
          success: false,
          message: `Guest ${i + 1}: email is required`,
        });
      }

      if (!guest.contact?.phone) {
        return res.status(400).json({
          success: false,
          message: `Guest ${i + 1}: phone number is required`,
        });
      }

      // Validasi email format
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(guest.contact.email)) {
        return res.status(400).json({
          success: false,
          message: `Guest ${i + 1}: invalid email format`,
        });
      }
    }

    // 5. Validasi tripId exists dan belongs to user
    const tripDoc = await tripsCollection.doc(tripId).get();

    if (!tripDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Trip not found",
      });
    }

    const tripData = tripDoc.data();
    if (tripData.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: "You don't have permission to add booking to this trip",
      });
    }

    // 6. Call Amadeus API atau use Mock
    let amadeusBooking;
    let amadeusData;

    if (MOCK_AMADEUS_BOOKING) {
      // ==================== MOCK MODE ====================
      console.log("⚠️  MOCK MODE: Simulating Amadeus booking response");

      // Generate mock confirmation number
      const mockConfirmationNumber = `MOCK_${Date.now()}_${Math.random()
        .toString(36)
        .substring(2, 8)
        .toUpperCase()}`;

      amadeusBooking = {
        data: [
          {
            type: "hotel-order",
            id: mockConfirmationNumber,
            bookingStatus: "CONFIRMED",
            providerConfirmationId: mockConfirmationNumber,
            associatedRecords: [
              {
                reference: mockConfirmationNumber,
                originSystemCode: "MOCK",
              },
            ],
            hotel: {
              hotelId: "MOCKHOTEL001",
              name: "Mock Hotel for Testing",
              chainCode: "MC",
              cityCode: "LON",
              latitude: 51.50988,
              longitude: -0.15509,
            },
            room: {
              type: "AP7",
              typeEstimated: {
                category: "SUPERIOR_ROOM",
                beds: 1,
                bedType: "KING",
              },
              description: {
                text: "Superior King Room - Mock Booking for Testing",
              },
            },
            guests: guests.map((g, idx) => ({
              tid: idx + 1,
              title: g.name.title || "MR",
              firstName: g.name.firstName,
              lastName: g.name.lastName,
              phone: g.contact.phone,
              email: g.contact.email,
            })),
            checkInDate: "2025-12-20",
            checkOutDate: "2025-12-22",
            price: {
              currency: "GBP",
              total: "907.20",
              base: "864.00",
              taxes: [
                {
                  amount: "43.20",
                  currency: "GBP",
                  code: "VAT",
                  included: true,
                },
              ],
            },
            policies: {
              cancellation: {
                deadline: "2025-12-18T23:59:00.000Z",
                type: "FULL_STAY",
              },
              paymentType: "deposit",
            },
          },
        ],
      };

      amadeusData = amadeusBooking.data[0];
      console.log("✅ Mock booking created:", mockConfirmationNumber);
    } else {
      // ==================== REAL MODE ====================
      console.log(`📝 Creating real hotel booking with offerId: ${offerId}`);

      try {
        amadeusBooking = await amadeusService.createHotelBooking({
          offerId: offerId,
          guests: guests,
          payments: payments,
        });

        amadeusData = amadeusBooking.data?.[0] || amadeusBooking.data || {};
      } catch (amadeusError) {
        console.error("❌ Amadeus API Error:", amadeusError.message);

        // Handle specific Amadeus errors
        if (amadeusError.message.includes("not found")) {
          return res.status(404).json({
            success: false,
            message:
              "Offer not found or has expired. Please search for offers again.",
            hint: "Offers typically expire within 15-30 minutes",
          });
        }

        if (amadeusError.message.includes("not available")) {
          return res.status(409).json({
            success: false,
            message:
              "Room is no longer available. Please select another offer.",
          });
        }

        throw amadeusError;
      }
    }

    // 7. Extract booking data dari Amadeus response
    const bookingStatus = amadeusData.bookingStatus || "CONFIRMED";
    const providerConfirmationId =
      amadeusData.providerConfirmationId ||
      amadeusData.associatedRecords?.[0]?.reference ||
      amadeusData.id ||
      null;

    // 8. Check jika booking gagal
    if (bookingStatus !== "CONFIRMED" && bookingStatus !== "PENDING") {
      return res.status(400).json({
        success: false,
        message: "Booking failed. Please try again or contact support.",
        bookingStatus: bookingStatus,
      });
    }

    // 9. Prepare data untuk Firestore
    const hotelInfo = amadeusData.hotel || {};
    const roomInfo = amadeusData.room || {};
    const priceInfo = amadeusData.price || {};

    const bookingData = {
      // User & Trip Info
      userId: userId,
      tripId: tripId,
      bookingType: "hotel",

      // Amadeus Booking Info
      offerId: offerId,
      confirmationNumber: providerConfirmationId,
      bookingStatus: bookingStatus,
      providerConfirmationId: providerConfirmationId,

      // Mock Mode Flag
      isMockBooking: MOCK_AMADEUS_BOOKING,

      // Hotel Info
      hotelId: hotelInfo.hotelId || null,
      hotelName: hotelInfo.name || "Unknown Hotel",
      hotelChainCode: hotelInfo.chainCode || null,
      hotelCityCode: hotelInfo.cityCode || null,
      hotelLatitude: hotelInfo.latitude || null,
      hotelLongitude: hotelInfo.longitude || null,

      // Room Info
      roomType: roomInfo.type || null,
      roomDescription:
        roomInfo.description?.text || roomInfo.typeEstimated?.category || null,
      roomCategory: roomInfo.typeEstimated?.category || null,
      roomBeds: roomInfo.typeEstimated?.beds || null,
      roomBedType: roomInfo.typeEstimated?.bedType || null,

      // Guest Info
      guests: guests.map((g) => ({
        title: g.name.title || "MR",
        firstName: g.name.firstName,
        lastName: g.name.lastName,
        email: g.contact.email,
        phone: g.contact.phone,
      })),
      primaryGuestName: `${guests[0].name.firstName} ${guests[0].name.lastName}`,
      primaryGuestEmail: guests[0].contact.email,
      primaryGuestPhone: guests[0].contact.phone,
      numberOfGuests: guests.length,

      // Booking Dates
      checkInDate: amadeusData.checkInDate || null,
      checkOutDate: amadeusData.checkOutDate || null,

      // Price Info
      currency: priceInfo.currency || "EUR",
      totalPrice: parseFloat(priceInfo.total || 0),
      basePrice: parseFloat(priceInfo.base || 0),
      taxes: priceInfo.taxes || [],

      // Payment Info
      paymentMethod: paymentMethod,
      paymentStatus: "paid", // Dummy for now
      paidAt: admin.firestore.FieldValue.serverTimestamp(),

      // Timestamps
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      bookedAt: admin.firestore.FieldValue.serverTimestamp(),

      // Additional Info
      policies: amadeusData.policies || null,
      cancellationDeadline:
        amadeusData.policies?.cancellation?.deadline || null,
    };

    // 10. Simpan booking ke Firestore
    const bookingRef = await bookingsCollection.add(bookingData);
    const bookingId = bookingRef.id;

    // 11. Update bookingId di dokumen
    await bookingRef.update({ bookingId: bookingId });

    // 12. Get complete booking data
    const savedBooking = await bookingRef.get();

    try {
      await notificationService.notifyBookingSuccess(userId, {
        bookingId: bookingId,
        bookingType: "hotel",
        hotelName: hotelInfo.name || "Unknown Hotel",
        confirmationNumber: providerConfirmationId,
      });
      console.log("✅ Booking success notification created");
    } catch (notifError) {
      // Don't fail booking if notification fails
      console.error("⚠️ Failed to create notification:", notifError.message);
    }

    // 13. Return success response
    return res.status(201).json({
      success: true,
      message: MOCK_AMADEUS_BOOKING
        ? "Hotel booking created successfully"
        : "Hotel booking created successfully",
      data: {
        bookingId: bookingId,
        confirmationNumber: providerConfirmationId,
        bookingStatus: bookingStatus,
        isMockBooking: MOCK_AMADEUS_BOOKING,
        ...savedBooking.data(),
      },
    });
  } catch (error) {
    console.error("Error creating hotel booking:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to create hotel booking",
      error: error.message,
    });
  }
};

// ... (getUserBookings, getBookingDetail, cancelBooking tetap sama)

// ============================================================================
// 2. GET USER BOOKINGS - Tampilkan Semua Booking User
// ============================================================================
/**
 * @desc    Get all bookings for authenticated user
 * @route   GET /api/hotels/bookings
 * @access  Private (require authCheck middleware)
 * @query   ?tripId=trip123 - Filter by trip (optional)
 * @query   ?status=CONFIRMED - Filter by booking status (optional)
 */
exports.getUserBookings = async (req, res) => {
  try {
    // 1. Ambil userId dari middleware
    const { uid: userId } = req.user;

    // 2. Ambil filter dari query
    const { tripId, status } = req.query;

    // 3. Build query
    let query = bookingsCollection
      .where("userId", "==", userId)
      .where("bookingType", "==", "hotel");

    // Apply filters
    if (tripId) {
      query = query.where("tripId", "==", tripId);
    }

    if (status) {
      query = query.where("bookingStatus", "==", status.toUpperCase());
    }

    // 4. Execute query
    const snapshot = await query.get();

    // 5. Check if empty
    if (snapshot.empty) {
      return res.status(200).json({
        success: true,
        message: "No hotel bookings found",
        data: [],
        count: 0,
      });
    }

    // 6. Map data and sort by booking date (newest first)
    const bookings = snapshot.docs
      .map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }))
      .sort((a, b) => {
        const dateA = a.bookedAt?.toDate?.() || new Date(0);
        const dateB = b.bookedAt?.toDate?.() || new Date(0);
        return dateB - dateA;
      });

    // 7. Return response
    return res.status(200).json({
      success: true,
      message: "Hotel bookings retrieved successfully",
      data: bookings,
      count: bookings.length,
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Hotel bookings retrieved successfully",
    //   "data": [
    //     {
    //       "id": "booking123",
    //       "confirmationNumber": "AMADEUS123456",
    //       "hotelName": "MELIA WHITE HOUSE",
    //       "checkInDate": "2025-12-20",
    //       "checkOutDate": "2025-12-22",
    //       "totalPrice": 285.50,
    //       "bookingStatus": "CONFIRMED"
    //     }
    //   ],
    //   "count": 1
    // }
  } catch (error) {
    console.error("Error getting user bookings:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to retrieve bookings",
      error: error.message,
    });
  }
};

// ============================================================================
// 3. GET BOOKING DETAIL - Tampilkan Detail Satu Booking
// ============================================================================
/**
 * @desc    Get detailed information for specific booking
 * @route   GET /api/hotels/bookings/:bookingId
 * @access  Private (require authCheck middleware)
 * @params  :bookingId - Booking ID
 */
exports.getBookingDetail = async (req, res) => {
  try {
    // 1. Ambil userId dan bookingId
    const { uid: userId } = req.user;
    const { bookingId } = req.params;

    // 2. Validasi bookingId
    if (!bookingId) {
      return res.status(400).json({
        success: false,
        message: "bookingId parameter is required",
      });
    }

    // 3. Get booking document
    const bookingDoc = await bookingsCollection.doc(bookingId).get();

    // 4. Check if exists
    if (!bookingDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Booking not found",
      });
    }

    // 5. Check ownership
    const bookingData = bookingDoc.data();
    if (bookingData.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: "You don't have permission to view this booking",
      });
    }

    // 6. Get associated trip info (optional enrichment)
    let tripInfo = null;
    if (bookingData.tripId) {
      const tripDoc = await tripsCollection.doc(bookingData.tripId).get();
      if (tripDoc.exists) {
        tripInfo = {
          tripId: tripDoc.id,
          tripName: tripDoc.data().tripName,
          startDate: tripDoc.data().startDate,
          endDate: tripDoc.data().endDate,
        };
      }
    }

    // 7. Return response
    return res.status(200).json({
      success: true,
      message: "Booking details retrieved successfully",
      data: {
        id: bookingDoc.id,
        ...bookingData,
        trip: tripInfo,
      },
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Booking details retrieved successfully",
    //   "data": {
    //     "id": "booking123",
    //     "bookingId": "booking123",
    //     "confirmationNumber": "AMADEUS123456",
    //     "bookingStatus": "CONFIRMED",
    //     "hotelName": "MELIA WHITE HOUSE",
    //     "hotelCityCode": "LON",
    //     "checkInDate": "2025-12-20",
    //     "checkOutDate": "2025-12-22",
    //     "guests": [...],
    //     "totalPrice": 285.50,
    //     "currency": "EUR",
    //     "paymentMethod": "credit_card",
    //     "trip": {
    //       "tripId": "trip456",
    //       "tripName": "London Holiday",
    //       "startDate": "2025-12-20",
    //       "endDate": "2025-12-25"
    //     }
    //   }
    // }
  } catch (error) {
    console.error("Error getting booking detail:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to retrieve booking details",
      error: error.message,
    });
  }
};

// ============================================================================
// 4. CANCEL BOOKING - Cancel Hotel Booking (Optional)
// ============================================================================
/**
 * @desc    Cancel hotel booking
 * @route   DELETE /api/hotels/bookings/:bookingId
 * @access  Private (require authCheck middleware)
 * @params  :bookingId - Booking ID
 *
 * @note    This is a soft delete. Booking status will be changed to CANCELLED
 *          Real cancellation with Amadeus would require additional API call
 */
exports.cancelBooking = async (req, res) => {
  try {
    // 1. Ambil userId dan bookingId
    const { uid: userId } = req.user;
    const { bookingId } = req.params;

    // 2. Get booking document
    const bookingDoc = await bookingsCollection.doc(bookingId).get();

    // 3. Check if exists
    if (!bookingDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Booking not found",
      });
    }

    // 4. Check ownership
    const bookingData = bookingDoc.data();
    if (bookingData.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: "You don't have permission to cancel this booking",
      });
    }

    // 5. Check if already cancelled
    if (bookingData.bookingStatus === "CANCELLED") {
      return res.status(400).json({
        success: false,
        message: "Booking is already cancelled",
      });
    }

    // 6. Check cancellation deadline
    if (bookingData.cancellationDeadline) {
      const deadline = new Date(bookingData.cancellationDeadline);
      const now = new Date();

      if (now > deadline) {
        return res.status(400).json({
          success: false,
          message: "Cancellation deadline has passed",
          cancellationDeadline: bookingData.cancellationDeadline,
        });
      }
    }

    // 7. Update booking status to CANCELLED
    await bookingsCollection.doc(bookingId).update({
      bookingStatus: "CANCELLED",
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      paymentStatus: "refunded", // Dummy
    });

    // 8. (Optional) Call Amadeus cancellation API
    //    Uncomment jika implement real cancellation
    // await amadeusService.cancelHotelBooking(bookingData.confirmationNumber);

    try {
      await notificationService.notifyBookingCancelled(userId, {
        bookingId: bookingId,
        bookingType: "hotel",
        hotelName: bookingData.hotelName,
      });
      console.log("✅ Booking cancellation notification created");
    } catch (notifError) {
      console.error("⚠️ Failed to create notification:", notifError.message);
    }

    // 9. Return success response
    return res.status(200).json({
      success: true,
      message: "Booking cancelled successfully",
      data: {
        bookingId: bookingId,
        bookingStatus: "CANCELLED",
        cancelledAt: new Date().toISOString(),
      },
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Booking cancelled successfully",
    //   "data": {
    //     "bookingId": "booking123",
    //     "bookingStatus": "CANCELLED",
    //     "cancelledAt": "2025-11-02T10:30:00.000Z"
    //   }
    // }
  } catch (error) {
    console.error("Error cancelling booking:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to cancel booking",
      error: error.message,
    });
  }
};
