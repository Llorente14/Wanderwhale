// ============================================================================
// FILE: routes/hotelRoutes.js
// DESC: Routes untuk hotel search menggunakan Amadeus API
// ============================================================================

const express = require("express");
const router = express.Router();

// ============================================================================
// IMPORT CONTROLLER
// ============================================================================

const hotelSearchController = require("../controllers/hotelSearchController");
const hotelOfferController = require("../controllers/hotelOfferController");
const hotelBookingController = require("../controllers/hotelBookingController");

// ============================================================================
// IMPORT MIDDLEWARE
// ============================================================================
const authCheck = require("../middleware/authCheck");

// ============================================================================
// STEP 1: HOTEL LIST API ROUTES (Mencari Daftar Hotel Statis)
// ============================================================================

/**
 * @route   GET /api/hotels/search/by-hotels
 * @desc    Search hotels by hotel IDs
 * @access  Public
 * @example /api/hotels/search/by-hotels?hotelIds=MCLONGHM,ADPAR001
 */
router.get("/search/by-hotels", hotelSearchController.searchByHotelIds);

/**
 * @route   GET /api/hotels/search/by-city
 * @desc    Search hotels by city code (IATA)
 * @access  Public
 * @example /api/hotels/search/by-city?cityCode=PAR&radius=10
 */
router.get("/search/by-city", hotelSearchController.searchByCity);

/**
 * @route   GET /api/hotels/search/by-geocode
 * @desc    Search hotels by latitude & longitude
 * @access  Public
 * @example /api/hotels/search/by-geocode?latitude=48.8566&longitude=2.3522&radius=5
 */
router.get("/search/by-geocode", hotelSearchController.searchByGeocode);

/**
 * @route   GET /api/hotels/search/locations
 * @desc    Find locations (City/Hotel) by keyword ("translator")
 * @access  Public
 * @example /api/hotels/search/locations?keyword=Jakarta&subType=CITY
 */
router.get("/search/locations", hotelSearchController.findLocationsByKeyword);

// ============================================================================
// STEP 2: HOTEL OFFERS ROUTES (Find and Confirm Rates)
// ============================================================================

/**
 * @route   GET /api/hotels/offers
 * @desc    Get available offers with prices and room types
 * @access  Public
 */
router.get("/offers", hotelOfferController.getHotelOffers);

/**
 * @route   GET /api/hotels/offers/compare
 * @desc    Compare offers and sort by price
 * @access  Public
 */
router.get("/offers/compare", hotelOfferController.compareOffers);

/**
 * @route   GET /api/hotels/offers/:offerId
 * @desc    Confirm pricing for specific offer (before booking)
 * @access  Public
 */
router.get("/offers/:offerId", hotelOfferController.getOfferPricing);

// ============================================================================
// STEP 3: HOTEL BOOKING ROUTES (Protected - Require Authentication)
// ============================================================================

/**
 * Apply authCheck middleware untuk semua booking routes
 * Semua endpoint di bawah ini WAJIB mengirim Authorization token
 */
router.use("/bookings", authCheck);

/**
 * @route   POST /api/hotels/bookings
 * @desc    Create hotel booking
 * @access  Private
 */
router.post("/bookings", hotelBookingController.storeHotelBooking);

/**
 * @route   GET /api/hotels/bookings
 * @desc    Get all bookings for authenticated user
 * @access  Private
 */
router.get("/bookings", hotelBookingController.getUserBookings);

/**
 * @route   GET /api/hotels/bookings/:bookingId
 * @desc    Get detailed information for specific booking
 * @access  Private
 */
router.get("/bookings/:bookingId", hotelBookingController.getBookingDetail);

/**
 * @route   DELETE /api/hotels/bookings/:bookingId
 * @desc    Cancel hotel booking
 * @access  Private
 */
router.delete("/bookings/:bookingId", hotelBookingController.cancelBooking);

// ============================================================================
// EXPORT ROUTER
// ============================================================================

module.exports = router;
