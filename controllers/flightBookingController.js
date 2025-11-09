// ============================================================================
// FILE: controllers/flightBookingController.js
// DESC: Controller untuk flight booking (MOCK MODE - Dummy Booking)
//       Semua booking disimpan langsung ke Firestore tanpa call Amadeus
// ============================================================================

const { db, admin } = require("../index");

// ============================================================================
// COLLECTION REFERENCES
// ============================================================================

const bookingsCollection = db.collection("bookings");
const tripsCollection = db.collection("trips");
const notificationService = require("../services/notificationService");
// Mock mode flag
const MOCK_AMADEUS_FLIGHT_BOOKING =
  process.env.MOCK_AMADEUS_FLIGHT_BOOKING === "true";

// ============================================================================
// STEP 3: CREATE FLIGHT BOOKING - Booking Penerbangan (MOCK)
// ============================================================================
/**
 * @desc    Create flight booking (dummy/mock booking)
 * @route   POST /api/flights/bookings
 * @access  Private (require authCheck middleware)
 * @body    {
 *            tripId: string (required),
 *            flightOffer: object (required) - Entire flight offer from Step 1,
 *            passengers: array (required) - Passenger information,
 *            selectedSeats: array (optional) - Seat numbers if selected,
 *            paymentMethod: string (required)
 *          }
 */
exports.storeFlightBooking = async (req, res) => {
  try {
    // 1. Ambil userId dari middleware authCheck
    const { uid: userId } = req.user;

    // 2. Ambil data dari request body
    const { tripId, flightOffer, passengers, selectedSeats, paymentMethod } =
      req.body;

    // 3. Validasi parameter wajib
    if (!tripId) {
      return res.status(400).json({
        success: false,
        message: "tripId is required",
      });
    }

    if (!flightOffer || !flightOffer.id) {
      return res.status(400).json({
        success: false,
        message: "flightOffer object is required (from Step 1 search results)",
        example: {
          flightOffer: {
            id: "1",
            type: "flight-offer",
            // ... rest of flight offer
          },
        },
      });
    }

    if (!passengers || !Array.isArray(passengers) || passengers.length === 0) {
      return res.status(400).json({
        success: false,
        message: "At least one passenger is required",
        example: {
          passengers: [
            {
              type: "ADULT",
              firstName: "John",
              lastName: "Doe",
              dateOfBirth: "1990-01-15",
              email: "john@example.com",
              phone: "+628123456789",
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
          "bca_va",
          "mandiri_va",
          "bni_va",
          "bri_va",
          "e_wallet",
        ],
      });
    }

    // 4. Validasi passenger data
    for (let i = 0; i < passengers.length; i++) {
      const passenger = passengers[i];

      if (!passenger.firstName || !passenger.lastName) {
        return res.status(400).json({
          success: false,
          message: `Passenger ${i + 1}: firstName and lastName are required`,
        });
      }

      if (!passenger.dateOfBirth) {
        return res.status(400).json({
          success: false,
          message: `Passenger ${
            i + 1
          }: dateOfBirth is required (format: YYYY-MM-DD)`,
        });
      }

      if (!passenger.email) {
        return res.status(400).json({
          success: false,
          message: `Passenger ${i + 1}: email is required`,
        });
      }

      // Validasi email format
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(passenger.email)) {
        return res.status(400).json({
          success: false,
          message: `Passenger ${i + 1}: invalid email format`,
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

    // 6. Generate mock confirmation number
    console.log("⚠️  MOCK MODE: Creating dummy flight booking");
    const mockConfirmationNumber = `FLIGHT_${Date.now()}_${Math.random()
      .toString(36)
      .substring(2, 8)
      .toUpperCase()}`;

    // 7. Extract flight details dari flightOffer
    const itinerary = flightOffer.itineraries?.[0] || {};
    const segments = itinerary.segments || [];
    const firstSegment = segments[0] || {};
    const lastSegment = segments[segments.length - 1] || {};
    const price = flightOffer.price || {};

    // 8. Prepare booking data untuk Firestore
    const bookingData = {
      // User & Trip Info
      userId: userId,
      tripId: tripId,
      bookingType: "flight",

      // Booking Status
      confirmationNumber: mockConfirmationNumber,
      bookingStatus: "CONFIRMED",
      isMockBooking: MOCK_AMADEUS_FLIGHT_BOOKING,

      // Flight Offer Info (Store entire offer for reference)
      flightOfferId: flightOffer.id,
      flightOffer: flightOffer, // Entire offer object

      // Flight Route Info
      origin: firstSegment.departure?.iataCode || null,
      destination: lastSegment.arrival?.iataCode || null,
      originCity: firstSegment.departure?.cityCode || null,
      destinationCity: lastSegment.arrival?.cityCode || null,

      // Flight Dates
      departureDate: firstSegment.departure?.at || null,
      arrivalDate: lastSegment.arrival?.at || null,

      // Flight Details
      airline: firstSegment.carrierCode || null,
      flightNumber: firstSegment.number || null,
      numberOfStops: segments.length - 1,
      cabin:
        flightOffer.travelerPricings?.[0]?.fareDetailsBySegment?.[0]?.cabin ||
        null,

      // Passenger Info
      passengers: passengers.map((p) => ({
        type: p.type || "ADULT",
        firstName: p.firstName,
        lastName: p.lastName,
        dateOfBirth: p.dateOfBirth,
        email: p.email,
        phone: p.phone || null,
        gender: p.gender || null,
        nationality: p.nationality || null,
        documentType: p.documentType || null,
        documentNumber: p.documentNumber || null,
      })),
      primaryPassengerName: `${passengers[0].firstName} ${passengers[0].lastName}`,
      primaryPassengerEmail: passengers[0].email,
      primaryPassengerPhone: passengers[0].phone || null,
      numberOfPassengers: passengers.length,

      // Seat Selection
      selectedSeats: selectedSeats || null,
      hasSeatsSelected: (selectedSeats && selectedSeats.length > 0) ?? false,

      // Price Info
      currency: price.currency || "IDR",
      totalPrice: parseFloat(price.total || price.grandTotal || 0),
      basePrice: parseFloat(price.base || 0),
      taxes: price.taxes || [],

      // Payment Info
      paymentMethod: paymentMethod,
      paymentStatus: "paid", // Dummy
      paidAt: admin.firestore.FieldValue.serverTimestamp(),

      // Timestamps
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      bookedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // 9. Simpan booking ke Firestore
    const bookingRef = await bookingsCollection.add(bookingData);
    const bookingId = bookingRef.id;

    // 10. Update bookingId di dokumen
    await bookingRef.update({ bookingId: bookingId });

    // 11. Get complete booking data
    const savedBooking = await bookingRef.get();

    try {
      await notificationService.notifyBookingSuccess(userId, {
        bookingId: bookingId,
        bookingType: "flight",
        origin: firstSegment.departure?.iataCode || "Unknown",
        destination: lastSegment.arrival?.iataCode || "Unknown",
        confirmationNumber: mockConfirmationNumber,
      });
      console.log("✅ Flight booking success notification created");
    } catch (notifError) {
      console.error("⚠️ Failed to create notification:", notifError.message);
    }

    // 12. Return success response
    return res.status(201).json({
      success: true,
      message: MOCK_AMADEUS_FLIGHT_BOOKING
        ? "Flight booking created successfully (Mock Mode)"
        : "Flight booking created successfully",
      data: {
        bookingId: bookingId,
        confirmationNumber: mockConfirmationNumber,
        bookingStatus: "CONFIRMED",
        isMockBooking: MOCK_AMADEUS_FLIGHT_BOOKING,
        ...savedBooking.data(),
      },
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Flight booking created successfully (Mock Mode)",
    //   "data": {
    //     "bookingId": "flight_abc123",
    //     "confirmationNumber": "FLIGHT_1730534567_A8F3G2",
    //     "bookingStatus": "CONFIRMED",
    //     "isMockBooking": true,
    //     "userId": "user123",
    //     "tripId": "trip456",
    //     "bookingType": "flight",
    //     "origin": "CGK",
    //     "destination": "DPS",
    //     "departureDate": "2025-12-20T07:00:00",
    //     "arrivalDate": "2025-12-20T09:30:00",
    //     "airline": "GA",
    //     "flightNumber": "123",
    //     "primaryPassengerName": "John Doe",
    //     "primaryPassengerEmail": "john@example.com",
    //     "numberOfPassengers": 1,
    //     "totalPrice": 2500000,
    //     "currency": "IDR",
    //     "paymentMethod": "bca_va",
    //     "paymentStatus": "paid"
    //   }
    // }
  } catch (error) {
    console.error("Error creating flight booking:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to create flight booking",
      error: error.message,
    });
  }
};

// ============================================================================
// GET USER BOOKINGS - Tampilkan Semua Flight Booking User
// ============================================================================
/**
 * @desc    Get all flight bookings for authenticated user
 * @route   GET /api/flights/bookings
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
      .where("bookingType", "==", "flight");

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
        message: "No flight bookings found",
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
      message: "Flight bookings retrieved successfully",
      data: bookings,
      count: bookings.length,
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Flight bookings retrieved successfully",
    //   "data": [
    //     {
    //       "id": "flight_abc123",
    //       "confirmationNumber": "FLIGHT_1730534567_A8F3G2",
    //       "bookingStatus": "CONFIRMED",
    //       "origin": "CGK",
    //       "destination": "DPS",
    //       "departureDate": "2025-12-20T07:00:00",
    //       "airline": "GA",
    //       "flightNumber": "123",
    //       "totalPrice": 2500000,
    //       "currency": "IDR",
    //       "numberOfPassengers": 1,
    //       "bookedAt": "2025-11-02T10:30:00.000Z"
    //     }
    //   ],
    //   "count": 1
    // }
  } catch (error) {
    console.error("Error getting user flight bookings:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to retrieve flight bookings",
      error: error.message,
    });
  }
};

// ============================================================================
// GET BOOKING DETAIL - Tampilkan Detail Satu Flight Booking
// ============================================================================
/**
 * @desc    Get detailed information for specific flight booking
 * @route   GET /api/flights/bookings/:bookingId
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
        message: "Flight booking not found",
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
      message: "Flight booking details retrieved successfully",
      data: {
        id: bookingDoc.id,
        ...bookingData,
        trip: tripInfo,
      },
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Flight booking details retrieved successfully",
    //   "data": {
    //     "id": "flight_abc123",
    //     "bookingId": "flight_abc123",
    //     "confirmationNumber": "FLIGHT_1730534567_A8F3G2",
    //     "bookingStatus": "CONFIRMED",
    //     "isMockBooking": true,
    //     "origin": "CGK",
    //     "destination": "DPS",
    //     "departureDate": "2025-12-20T07:00:00",
    //     "arrivalDate": "2025-12-20T09:30:00",
    //     "airline": "GA",
    //     "flightNumber": "123",
    //     "cabin": "ECONOMY",
    //     "passengers": [...],
    //     "selectedSeats": ["20D"],
    //     "totalPrice": 2500000,
    //     "currency": "IDR",
    //     "paymentMethod": "bca_va",
    //     "flightOffer": {...},
    //     "trip": {
    //       "tripId": "trip456",
    //       "tripName": "Bali Holiday",
    //       "startDate": "2025-12-20",
    //       "endDate": "2025-12-27"
    //     }
    //   }
    // }
  } catch (error) {
    console.error("Error getting flight booking detail:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to retrieve flight booking details",
      error: error.message,
    });
  }
};

// ============================================================================
// CANCEL BOOKING - Cancel Flight Booking (Soft Delete)
// ============================================================================
/**
 * @desc    Cancel flight booking
 * @route   DELETE /api/flights/bookings/:bookingId
 * @access  Private (require authCheck middleware)
 * @params  :bookingId - Booking ID
 *
 * @note    This is a soft delete. Booking status will be changed to CANCELLED
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
        message: "Flight booking not found",
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

    // 6. Check if departure date has passed
    if (bookingData.departureDate) {
      const departureDate = new Date(bookingData.departureDate);
      const now = new Date();

      if (departureDate < now) {
        return res.status(400).json({
          success: false,
          message: "Cannot cancel booking. Departure date has passed.",
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

    try {
      await notificationService.notifyBookingCancelled(userId, {
        bookingId: bookingId,
        bookingType: "flight",
        origin: bookingData.origin,
        destination: bookingData.destination,
      });
      console.log("✅ Flight cancellation notification created");
    } catch (notifError) {
      console.error("⚠️ Failed to create notification:", notifError.message);
    }

    // 8. Return success response
    return res.status(200).json({
      success: true,
      message: "Flight booking cancelled successfully",
      data: {
        bookingId: bookingId,
        bookingStatus: "CANCELLED",
        cancelledAt: new Date().toISOString(),
      },
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Flight booking cancelled successfully",
    //   "data": {
    //     "bookingId": "flight_abc123",
    //     "bookingStatus": "CANCELLED",
    //     "cancelledAt": "2025-11-02T10:30:00.000Z"
    //   }
    // }
  } catch (error) {
    console.error("Error cancelling flight booking:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to cancel flight booking",
      error: error.message,
    });
  }
};
