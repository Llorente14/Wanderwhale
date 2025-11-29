// ============================================================================
// FILE: routes/flightRoutes.js
// DESC: Routes untuk flight search dan booking
// ============================================================================

const express = require("express");
const router = express.Router();

// ============================================================================
// IMPORT CONTROLLERS & MIDDLEWARE
// ============================================================================

const flightSearchController = require("../controllers/flightSearchController");
const flightBookingController = require("../controllers/flightBookingController");
const authCheck = require("../middleware/authCheck");

// ============================================================================
// STEP 0: LOCATION SEARCH (Public)
// ============================================================================

/**
 * @route   GET /api/flights/search/locations
 * @desc    Search airports or cities by keyword
 * @access  Public
 * @example /api/flights/search/locations?keyword=jakarta&subType=CITY
 */
router.get("/search/locations", flightSearchController.searchLocations);

/**
 * @route   GET /api/flights/search/city
 * @desc    Search for cities/airports by keyword (Autocomplete)
 * @access  Public
 */
router.get("/search/city", flightSearchController.searchCity);

// ============================================================================
// STEP 1: FLIGHT OFFERS SEARCH (Public)
// ============================================================================

/**
 * @route   POST /api/flights/search
 * @desc    Search for flight offers
 * @access  Public
 */
router.post("/search", flightSearchController.searchFlightOffers);

// ============================================================================
// STEP 1.5: CONFIRM PRICING (Public) ← NEW & IMPORTANT!
// ============================================================================

/**
 * @route   POST /api/flights/pricing
 * @desc    Confirm flight offer pricing (required before seatmap)
 * @access  Public
 */
router.post("/pricing", flightSearchController.confirmFlightPricing);

// ============================================================================
// STEP 2: SEATMAP (Public)
// ============================================================================

/**
 * @route   POST /api/flights/seatmaps
 * @desc    Get seatmap for selected flight offer
 * @access  Public
 */
router.post("/seatmaps", flightSearchController.getSeatmap);

// ============================================================================
// STEP 3: FLIGHT BOOKING ROUTES (Protected - Require Authentication)
// ============================================================================

/**
 * Apply authCheck middleware untuk semua booking routes
 * Semua endpoint di bawah ini WAJIB mengirim Authorization token
 */
router.use("/bookings", authCheck);

/**
 * @route   POST /api/flights/bookings
 * @desc    Create flight booking (mock/dummy)
 * @access  Private
 */
router.post("/bookings", flightBookingController.storeFlightBooking);

/**
 * @route   GET /api/flights/bookings
 * @desc    Get all flight bookings for authenticated user
 * @access  Private
 */
router.get("/bookings", flightBookingController.getUserBookings);

/**
 * @route   GET /api/flights/bookings/:bookingId
 * @desc    Get detailed information for specific flight booking
 * @access  Private
 */
router.get("/bookings/:bookingId", flightBookingController.getBookingDetail);

/**
 * @route   DELETE /api/flights/bookings/:bookingId
 * @desc    Cancel flight booking
 * @access  Private
 */
router.delete("/bookings/:bookingId", flightBookingController.cancelBooking);

// ============================================================================
// EXPORT ROUTER
// ============================================================================

module.exports = router;
