// ============================================================================
// FILE: routes/notificationRoutes.js
// DESC: Routes untuk notification actions (untuk Firebase SDK realtime)
// ============================================================================

const express = require("express");
const router = express.Router();

// ============================================================================
// IMPORT CONTROLLER & MIDDLEWARE
// ============================================================================

const notificationController = require("../controllers/notificationController");
const authCheck = require("../middleware/authCheck");

// ============================================================================
// ALL ROUTES ARE PROTECTED
// ============================================================================

router.use(authCheck);

// ============================================================================
// NOTIFICATION ACTION ROUTES
// ============================================================================

/**
 * @route   PATCH /api/notifications/read-all
 * @desc    Mark all notifications as read
 * @access  Private
 */
router.patch("/read-all", notificationController.markAllAsRead);

/**
 * @route   DELETE /api/notifications/clear-all
 * @desc    Clear all read notifications
 * @access  Private
 */
router.delete("/clear-all", notificationController.clearAllRead);

/**
 * @route   PATCH /api/notifications/:notificationId/read
 * @desc    Mark single notification as read
 * @access  Private
 */
router.patch("/:notificationId/read", notificationController.markAsRead);

/**
 * @route   DELETE /api/notifications/:notificationId
 * @desc    Delete single notification
 * @access  Private
 */
router.delete("/:notificationId", notificationController.deleteNotification);

// ============================================================================
// EXPORT ROUTER
// ============================================================================

module.exports = router;
