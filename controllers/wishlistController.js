// ============================================================================
// FILE: controllers/wishlistController.js
// DESC: Controller untuk wishlist management
// ============================================================================

const wishlistService = require("../services/wishlistService");
const notificationService = require("../services/notificationService");

// ============================================================================
// 1. ADD TO WISHLIST - Tambah Destinasi ke Wishlist
// ============================================================================
/**
 * @desc    Add destination to user's wishlist
 * @route   POST /api/wishlist
 * @access  Private (require authCheck middleware)
 * @body    { destinationId: string }
 */
exports.addToWishlist = async (req, res) => {
  try {
    // 1. Ambil userId dari middleware
    const { uid: userId } = req.user;

    // 2. Ambil destinationId dari body
    const { destinationId } = req.body;

    // 3. Validasi destinationId
    if (!destinationId) {
      return res.status(400).json({
        success: false,
        message: "destinationId is required",
        example: {
          destinationId: "dest123",
        },
      });
    }

    // 4. Add to wishlist
    const wishlist = await wishlistService.addToWishlist(userId, destinationId);

    // 5. Create notification (optional - fire and forget)
    try {
      await notificationService.createNotification({
        userId: userId,
        type: "wishlist_added",
        title: "Added to Wishlist ❤️",
        body: `${wishlist.destinationName} has been added to your wishlist!`,
        relatedType: "destination",
        relatedId: destinationId,
        actionUrl: `/destinations/${destinationId}`,
      });
    } catch (notifError) {
      console.error("Failed to create notification:", notifError.message);
    }

    // 6. Return success response
    return res.status(201).json({
      success: true,
      message: "Destination added to wishlist",
      data: wishlist,
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Destination added to wishlist",
    //   "data": {
    //     "id": "wish_abc123",
    //     "wishlistId": "wish_abc123",
    //     "userId": "user123",
    //     "destinationId": "dest456",
    //     "destinationName": "Bali",
    //     "destinationCity": "Denpasar",
    //     "destinationCountry": "Indonesia",
    //     "destinationImageUrl": "https://...",
    //     "destinationRating": 4.8,
    //     "destinationTags": ["pantai", "budaya"],
    //     "addedAt": "2025-11-02T10:30:00.000Z"
    //   }
    // }
  } catch (error) {
    console.error("Error adding to wishlist:", error);

    // Handle specific errors
    if (error.message.includes("already in wishlist")) {
      return res.status(409).json({
        success: false,
        message: "This destination is already in your wishlist",
      });
    }

    if (error.message.includes("not found")) {
      return res.status(404).json({
        success: false,
        message: "Destination not found",
      });
    }

    return res.status(500).json({
      success: false,
      message: "Failed to add to wishlist",
      error: error.message,
    });
  }
};

// ============================================================================
// 2. REMOVE FROM WISHLIST - Hapus dari Wishlist
// ============================================================================
/**
 * @desc    Remove destination from user's wishlist
 * @route   DELETE /api/wishlist/:destinationId
 * @access  Private (require authCheck middleware)
 * @params  :destinationId - Destination ID to remove
 */
exports.removeFromWishlist = async (req, res) => {
  try {
    // 1. Ambil userId dan destinationId
    const { uid: userId } = req.user;
    const { destinationId } = req.params;

    // 2. Validasi destinationId
    if (!destinationId) {
      return res.status(400).json({
        success: false,
        message: "destinationId parameter is required",
      });
    }

    // 3. Remove from wishlist
    await wishlistService.removeFromWishlist(userId, destinationId);

    // 4. Return success response
    return res.status(200).json({
      success: true,
      message: "Destination removed from wishlist",
      data: {
        destinationId: destinationId,
      },
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Destination removed from wishlist",
    //   "data": {
    //     "destinationId": "dest456"
    //   }
    // }
  } catch (error) {
    console.error("Error removing from wishlist:", error);

    if (error.message.includes("not found")) {
      return res.status(404).json({
        success: false,
        message: "Wishlist item not found",
      });
    }

    return res.status(500).json({
      success: false,
      message: "Failed to remove from wishlist",
      error: error.message,
    });
  }
};

// ============================================================================
// 3. GET USER WISHLIST - Tampilkan Semua Wishlist User
// ============================================================================
/**
 * @desc    Get all wishlist items for authenticated user
 * @route   GET /api/wishlist
 * @access  Private (require authCheck middleware)
 * @query   ?page=1 - Page number (optional, default: 1)
 * @query   ?limit=20 - Items per page (optional, default: 20, max: 50)
 */
exports.getUserWishlist = async (req, res) => {
  try {
    // 1. Ambil userId dari middleware
    const { uid: userId } = req.user;

    // 2. Ambil pagination parameters
    const { page = 1, limit = 20 } = req.query;

    // 3. Validasi pagination
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);

    if (pageNum < 1) {
      return res.status(400).json({
        success: false,
        message: "Page must be greater than 0",
      });
    }

    if (limitNum < 1 || limitNum > 50) {
      return res.status(400).json({
        success: false,
        message: "Limit must be between 1 and 50",
      });
    }

    // 4. Get wishlist
    const wishlist = await wishlistService.getUserWishlist(userId);

    // 5. Check if empty
    if (wishlist.length === 0) {
      return res.status(200).json({
        success: true,
        message: "Your wishlist is empty",
        data: [],
        count: 0,
        pagination: {
          page: pageNum,
          limit: limitNum,
          totalPages: 0,
          totalItems: 0,
          hasNextPage: false,
          hasPrevPage: false,
        },
        emptyState: {
          title: "No Saved Destinations",
          description:
            "Start exploring and save your favorite destinations to plan your next trip!",
          actionText: "Explore Destinations",
          actionUrl: "/destinations",
          imageUrl:
            "https://images.unsplash.com/photo-1488646953014-85cb44e25828",
        },
      });
    }

    // 6. Apply pagination
    const totalItems = wishlist.length;
    const totalPages = Math.ceil(totalItems / limitNum);
    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = startIndex + limitNum;
    const paginatedWishlist = wishlist.slice(startIndex, endIndex);

    // 7. Return response
    return res.status(200).json({
      success: true,
      message: "Wishlist retrieved successfully",
      data: paginatedWishlist,
      count: paginatedWishlist.length,
      pagination: {
        page: pageNum,
        limit: limitNum,
        totalPages: totalPages,
        totalItems: totalItems,
        hasNextPage: pageNum < totalPages,
        hasPrevPage: pageNum > 1,
        nextPage: pageNum < totalPages ? pageNum + 1 : null,
        prevPage: pageNum > 1 ? pageNum - 1 : null,
      },
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Wishlist retrieved successfully",
    //   "data": [
    //     {
    //       "id": "wish_abc123",
    //       "wishlistId": "wish_abc123",
    //       "userId": "user123",
    //       "destinationId": "dest456",
    //       "destinationName": "Bali",
    //       "destinationCity": "Denpasar",
    //       "destinationCountry": "Indonesia",
    //       "destinationImageUrl": "https://...",
    //       "destinationRating": 4.8,
    //       "destinationTags": ["pantai", "budaya"],
    //       "addedAt": "2025-11-02T10:30:00.000Z"
    //     }
    //   ],
    //   "count": 1,
    //   "pagination": {
    //     "page": 1,
    //     "limit": 20,
    //     "totalPages": 1,
    //     "totalItems": 1,
    //     "hasNextPage": false,
    //     "hasPrevPage": false,
    //     "nextPage": null,
    //     "prevPage": null
    //   }
    // }
  } catch (error) {
    console.error("Error getting wishlist:", error);
    console.error("Error stack:", error.stack);
    return res.status(500).json({
      success: false,
      message: "Failed to retrieve wishlist",
      error: error.message,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined,
    });
  }
};

// ============================================================================
// 4. CHECK IF IN WISHLIST - Cek Status Wishlist
// ============================================================================
/**
 * @desc    Check if destination is in user's wishlist
 * @route   GET /api/wishlist/check/:destinationId
 * @access  Private (require authCheck middleware)
 * @params  :destinationId - Destination ID to check
 */
exports.checkWishlistStatus = async (req, res) => {
  try {
    // 1. Ambil userId dan destinationId
    const { uid: userId } = req.user;
    const { destinationId } = req.params;

    // 2. Validasi destinationId
    if (!destinationId) {
      return res.status(400).json({
        success: false,
        message: "destinationId parameter is required",
      });
    }

    // 3. Check if in wishlist
    const isWishlisted = await wishlistService.isInWishlist(
      userId,
      destinationId
    );

    // 4. Return status
    return res.status(200).json({
      success: true,
      message: "Wishlist status retrieved",
      data: {
        destinationId: destinationId,
        isWishlisted: isWishlisted,
      },
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Wishlist status retrieved",
    //   "data": {
    //     "destinationId": "dest456",
    //     "isWishlisted": true
    //   }
    // }
  } catch (error) {
    console.error("Error checking wishlist status:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to check wishlist status",
      error: error.message,
    });
  }
};

// ============================================================================
// 5. GET WISHLIST COUNT - Hitung Jumlah Wishlist
// ============================================================================
/**
 * @desc    Get total count of user's wishlist items
 * @route   GET /api/wishlist/count
 * @access  Private (require authCheck middleware)
 */
exports.getWishlistCount = async (req, res) => {
  try {
    // 1. Ambil userId dari middleware
    const { uid: userId } = req.user;

    // 2. Get count
    const count = await wishlistService.getWishlistCount(userId);

    // 3. Return count
    return res.status(200).json({
      success: true,
      message: "Wishlist count retrieved",
      data: {
        count: count,
      },
    });

    // Response example:
    // {
    //   "success": true,
    //   "message": "Wishlist count retrieved",
    //   "data": {
    //     "count": 5
    //   }
    // }
  } catch (error) {
    console.error("Error getting wishlist count:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get wishlist count",
      error: error.message,
    });
  }
};

// ============================================================================
// 6. TOGGLE WISHLIST - Add/Remove dalam 1 Endpoint
// ============================================================================
/**
 * @desc    Toggle destination in wishlist (add if not exists, remove if exists)
 * @route   POST /api/wishlist/toggle
 * @access  Private (require authCheck middleware)
 * @body    { destinationId: string }
 */
exports.toggleWishlist = async (req, res) => {
  try {
    // 1. Ambil userId dan destinationId
    const { uid: userId } = req.user;
    const { destinationId } = req.body;

    // 2. Validasi destinationId
    if (!destinationId) {
      return res.status(400).json({
        success: false,
        message: "destinationId is required",
      });
    }

    // 3. Check current status
    const isWishlisted = await wishlistService.isInWishlist(
      userId,
      destinationId
    );

    // 4. Toggle action
    if (isWishlisted) {
      // Remove from wishlist
      await wishlistService.removeFromWishlist(userId, destinationId);

      return res.status(200).json({
        success: true,
        message: "Destination removed from wishlist",
        data: {
          destinationId: destinationId,
          isWishlisted: false,
          action: "removed",
        },
      });
    } else {
      // Add to wishlist
      const wishlist = await wishlistService.addToWishlist(
        userId,
        destinationId
      );

      // Create notification
      try {
        await notificationService.createNotification({
          userId: userId,
          type: "wishlist_added",
          title: "Added to Wishlist ❤️",
          body: `${wishlist.destinationName} has been added to your wishlist!`,
          relatedType: "destination",
          relatedId: destinationId,
          actionUrl: `/destinations/${destinationId}`,
        });
      } catch (notifError) {
        console.error("Failed to create notification:", notifError.message);
      }

      return res.status(200).json({
        success: true,
        message: "Destination added to wishlist",
        data: {
          ...wishlist,
          isWishlisted: true,
          action: "added",
        },
      });
    }

    // Response example (added):
    // {
    //   "success": true,
    //   "message": "Destination added to wishlist",
    //   "data": {
    //     "id": "wish_abc123",
    //     "destinationId": "dest456",
    //     "destinationName": "Bali",
    //     "isWishlisted": true,
    //     "action": "added"
    //   }
    // }

    // Response example (removed):
    // {
    //   "success": true,
    //   "message": "Destination removed from wishlist",
    //   "data": {
    //     "destinationId": "dest456",
    //     "isWishlisted": false,
    //     "action": "removed"
    //   }
    // }
  } catch (error) {
    console.error("Error toggling wishlist:", error);

    if (error.message.includes("not found")) {
      return res.status(404).json({
        success: false,
        message: "Destination not found",
      });
    }

    return res.status(500).json({
      success: false,
      message: "Failed to toggle wishlist",
      error: error.message,
    });
  }
};
