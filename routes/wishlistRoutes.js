// ============================================================================
// FILE: routes/wishlistRoutes.js
// DESC: Routes untuk wishlist management
// ============================================================================

const express = require("express");
const router = express.Router();

// ============================================================================
// IMPORT CONTROLLER & MIDDLEWARE
// ============================================================================

const wishlistController = require("../controllers/wishlistController");
const authCheck = require("../middleware/authCheck");

// ============================================================================
// ALL ROUTES ARE PROTECTED (Require Authentication)
// ============================================================================

router.use(authCheck);

// ============================================================================
// WISHLIST ROUTES
// ============================================================================

/**
 * @route   GET /api/wishlist
 * @desc    Get all wishlist items for user
 * @access  Private
 */
router.get("/", wishlistController.getUserWishlist);

/**
 * @route   GET /api/wishlist/count
 * @desc    Get wishlist count
 * @access  Private
 */
router.get("/count", wishlistController.getWishlistCount);

/**
 * @route   GET /api/wishlist/check/:destinationId
 * @desc    Check if destination is in wishlist
 * @access  Private
 */
router.get("/check/:destinationId", wishlistController.checkWishlistStatus);

/**
 * @route   POST /api/wishlist
 * @desc    Add destination to wishlist
 * @access  Private
 */
router.post("/", wishlistController.addToWishlist);

/**
 * @route   POST /api/wishlist/toggle
 * @desc    Toggle destination in wishlist
 * @access  Private
 */
router.post("/toggle", wishlistController.toggleWishlist);

/**
 * @route   DELETE /api/wishlist/:destinationId
 * @desc    Remove destination from wishlist
 * @access  Private
 */
router.delete("/:destinationId", wishlistController.removeFromWishlist);

// ============================================================================
// EXPORT ROUTER
// ============================================================================

module.exports = router;
