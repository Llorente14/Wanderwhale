// ============================================================================
// FILE: controllers/notificationController.js
// DESC: Controller untuk notification management (untuk Firebase SDK)
//       Flutter akan listen via onSnapshot, backend hanya handle actions
// ============================================================================

const { db, admin } = require("../index");

// ============================================================================
// COLLECTION REFERENCE
// ============================================================================

const notificationsCollection = db.collection("notifications");

// ============================================================================
// INFO: Flutter akan listen notifications via Firebase SDK onSnapshot
// Backend hanya menyediakan action endpoints (mark read, delete, dll)
// ============================================================================

// ============================================================================
// 0. GET NOTIFICATIONS - Ambil List Notifikasi User
// ============================================================================
/**
 * @desc    Get all notifications for the authenticated user
 * @route   GET /api/notifications
 * @access  Private (require authCheck middleware)
 * @query   unreadOnly (optional) - if true, only return unread notifications
 */
exports.getNotifications = async (req, res) => {
  try {
    // 1. Ambil userId dari middleware
    const { uid: userId } = req.user;

    // 2. Ambil query parameter unreadOnly
    const unreadOnly = req.query.unreadOnly === "true";

    // 3. Build query - tanpa orderBy untuk menghindari index requirement
    // Kita akan sort di memory
    let query = notificationsCollection.where("userId", "==", userId);

    // 4. Filter by unread if requested
    if (unreadOnly) {
      query = query.where("isRead", "==", false);
    }

    // 5. Execute query (tanpa orderBy)
    const snapshot = await query.get();

    // 7. Map documents to array
    const notifications = snapshot.docs.map((doc) => {
      const data = doc.data();
      
      // Helper function to convert Firestore timestamp to ISO string
      const toISOString = (timestamp) => {
        if (!timestamp) return null;
        // If it's a Firestore Timestamp object
        if (timestamp.toDate && typeof timestamp.toDate === 'function') {
          return timestamp.toDate().toISOString();
        }
        // If it's already a Date object
        if (timestamp instanceof Date) {
          return timestamp.toISOString();
        }
        // If it's already a string
        if (typeof timestamp === 'string') {
          return timestamp;
        }
        // If it's a Map with _seconds (serialized timestamp)
        if (timestamp._seconds) {
          return new Date(timestamp._seconds * 1000).toISOString();
        }
        return null;
      };
      
      return {
        id: doc.id,
        userId: data.userId || "",
        type: data.type || "general",
        title: data.title || "",
        body: data.body || "",
        isRead: data.isRead || false,
        createdAt: toISOString(data.createdAt) || new Date().toISOString(),
        referenceId: data.relatedId || data.referenceId || null,
        imageUrl: data.imageUrl || null,
        actionUrl: data.actionUrl || null,
      };
    });

    // 8. Sort by createdAt descending (newest first) in memory
    notifications.sort((a, b) => {
      const dateA = new Date(a.createdAt || 0);
      const dateB = new Date(b.createdAt || 0);
      return dateB - dateA; // Descending order
    });

    // 9. Return success response
    return res.status(200).json({
      success: true,
      message: "Notifications retrieved successfully",
      data: notifications,
      count: notifications.length,
    });
  } catch (error) {
    console.error("Error getting notifications:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get notifications",
      error: error.message,
    });
  }
};

// ============================================================================
// 1. MARK AS READ - Tandai Satu Notifikasi Sudah Dibaca
// ============================================================================
/**
 * @desc    Mark single notification as read
 * @route   PATCH /api/notifications/:notificationId/read
 * @access  Private (require authCheck middleware)
 */
exports.markAsRead = async (req, res) => {
  try {
    // 1. Ambil userId dan notificationId
    const { uid: userId } = req.user;
    const { notificationId } = req.params;

    // 2. Validasi notificationId
    if (!notificationId) {
      return res.status(400).json({
        success: false,
        message: "notificationId parameter is required",
      });
    }

    // 3. Get notification document
    const notifDoc = await notificationsCollection.doc(notificationId).get();

    // 4. Check if exists
    if (!notifDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Notification not found",
      });
    }

    // 5. Check ownership
    const notifData = notifDoc.data();
    if (notifData.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: "You don't have permission to update this notification",
      });
    }

    // 6. Check if already read
    if (notifData.isRead) {
      return res.status(200).json({
        success: true,
        message: "Notification already marked as read",
        data: {
          notificationId: notificationId,
          isRead: true,
        },
      });
    }

    // 7. Update to read
    await notificationsCollection.doc(notificationId).update({
      isRead: true,
      readAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 8. Return success response
    return res.status(200).json({
      success: true,
      message: "Notification marked as read",
      data: {
        notificationId: notificationId,
        isRead: true,
        readAt: new Date().toISOString(),
      },
    });
  } catch (error) {
    console.error("Error marking notification as read:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to mark notification as read",
      error: error.message,
    });
  }
};

// ============================================================================
// 2. MARK ALL AS READ - Tandai Semua Notifikasi Sudah Dibaca
// ============================================================================
/**
 * @desc    Mark all notifications as read
 * @route   PATCH /api/notifications/read-all
 * @access  Private (require authCheck middleware)
 */
exports.markAllAsRead = async (req, res) => {
  try {
    // 1. Ambil userId dari middleware
    const { uid: userId } = req.user;

    // 2. Get all unread notifications
    const snapshot = await notificationsCollection
      .where("userId", "==", userId)
      .where("isRead", "==", false)
      .get();

    // 3. Check if empty
    if (snapshot.empty) {
      return res.status(200).json({
        success: true,
        message: "No unread notifications to mark",
        data: {
          updatedCount: 0,
        },
      });
    }

    // 4. Batch update
    const batch = db.batch();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    snapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        isRead: true,
        readAt: timestamp,
      });
    });

    await batch.commit();

    // 5. Return success response
    return res.status(200).json({
      success: true,
      message: "All notifications marked as read",
      data: {
        updatedCount: snapshot.size,
      },
    });
  } catch (error) {
    console.error("Error marking all as read:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to mark all as read",
      error: error.message,
    });
  }
};

// ============================================================================
// 3. DELETE NOTIFICATION - Hapus Satu Notifikasi
// ============================================================================
/**
 * @desc    Delete single notification
 * @route   DELETE /api/notifications/:notificationId
 * @access  Private (require authCheck middleware)
 */
exports.deleteNotification = async (req, res) => {
  try {
    // 1. Ambil userId dan notificationId
    const { uid: userId } = req.user;
    const { notificationId } = req.params;

    // 2. Get notification document
    const notifDoc = await notificationsCollection.doc(notificationId).get();

    // 3. Check if exists
    if (!notifDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Notification not found",
      });
    }

    // 4. Check ownership
    const notifData = notifDoc.data();
    if (notifData.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: "You don't have permission to delete this notification",
      });
    }

    // 5. Delete notification
    await notificationsCollection.doc(notificationId).delete();

    // 6. Return success response
    return res.status(200).json({
      success: true,
      message: "Notification deleted successfully",
      data: {
        notificationId: notificationId,
      },
    });
  } catch (error) {
    console.error("Error deleting notification:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to delete notification",
      error: error.message,
    });
  }
};

// ============================================================================
// 4. CLEAR ALL READ - Hapus Semua Notifikasi yang Sudah Dibaca
// ============================================================================
/**
 * @desc    Clear all read notifications
 * @route   DELETE /api/notifications/clear-all
 * @access  Private (require authCheck middleware)
 */
exports.clearAllRead = async (req, res) => {
  try {
    // 1. Ambil userId dari middleware
    const { uid: userId } = req.user;

    // 2. Get all read notifications
    const snapshot = await notificationsCollection
      .where("userId", "==", userId)
      .where("isRead", "==", true)
      .get();

    // 3. Check if empty
    if (snapshot.empty) {
      return res.status(200).json({
        success: true,
        message: "No read notifications to clear",
        data: {
          deletedCount: 0,
        },
      });
    }

    // 4. Batch delete
    const batch = db.batch();

    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    // 5. Return success response
    return res.status(200).json({
      success: true,
      message: "All read notifications cleared",
      data: {
        deletedCount: snapshot.size,
      },
    });
  } catch (error) {
    console.error("Error clearing read notifications:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to clear notifications",
      error: error.message,
    });
  }
};
