// ============================================================================
// FILE: services/bookingStatusService.js
// DESC: Service untuk auto-update booking status
// ============================================================================

const { db, admin } = require("../index");
const notificationService = require("./notificationService");

const bookingsCollection = db.collection("bookings");

// ============================================================================
// AUTO UPDATE BOOKING STATUS TO COMPLETED
// ============================================================================

/**
 * Update bookings yang sudah lewat tanggal check-out/arrival
 * Status CONFIRMED → COMPLETED
 */
async function updateExpiredBookings() {
  try {
    console.log("🔄 Running auto-update booking status...");

    const now = new Date();
    const nowISO = now.toISOString();

    // ========== UPDATE HOTEL BOOKINGS ==========

    // Get all CONFIRMED hotel bookings
    const hotelSnapshot = await bookingsCollection
      .where("bookingType", "==", "hotel")
      .where("bookingStatus", "==", "CONFIRMED")
      .get();

    let hotelUpdatedCount = 0;

    if (!hotelSnapshot.empty) {
      const batch = db.batch();

      hotelSnapshot.docs.forEach((doc) => {
        const booking = doc.data();
        const checkOutDate = new Date(booking.checkOutDate);

        // Jika check-out date sudah lewat
        if (checkOutDate < now) {
          batch.update(doc.ref, {
            bookingStatus: "COMPLETED",
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          hotelUpdatedCount++;

          // Create notification (fire and forget)
          notificationService
            .createNotification({
              userId: booking.userId,
              type: "booking_completed",
              title: "Booking Completed 🎉",
              body: `Your stay at ${booking.hotelName} has been completed. We hope you enjoyed your trip!`,
              relatedType: "booking",
              relatedId: doc.id,
              actionUrl: `/hotels/bookings/${doc.id}`,
            })
            .catch((err) =>
              console.error("Failed to create notification:", err)
            );
        }
      });

      if (hotelUpdatedCount > 0) {
        await batch.commit();
        console.log(
          `✅ Updated ${hotelUpdatedCount} hotel bookings to COMPLETED`
        );
      }
    }

    // ========== UPDATE FLIGHT BOOKINGS ==========

    // Get all CONFIRMED flight bookings
    const flightSnapshot = await bookingsCollection
      .where("bookingType", "==", "flight")
      .where("bookingStatus", "==", "CONFIRMED")
      .get();

    let flightUpdatedCount = 0;

    if (!flightSnapshot.empty) {
      const batch = db.batch();

      flightSnapshot.docs.forEach((doc) => {
        const booking = doc.data();
        const arrivalDate = new Date(booking.arrivalDate);

        // Jika arrival date sudah lewat
        if (arrivalDate < now) {
          batch.update(doc.ref, {
            bookingStatus: "COMPLETED",
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          flightUpdatedCount++;

          // Create notification (fire and forget)
          notificationService
            .createNotification({
              userId: booking.userId,
              type: "booking_completed",
              title: "Flight Completed ✈️",
              body: `Your flight from ${booking.origin} to ${booking.destination} has been completed. Safe travels!`,
              relatedType: "booking",
              relatedId: doc.id,
              actionUrl: `/flights/bookings/${doc.id}`,
            })
            .catch((err) =>
              console.error("Failed to create notification:", err)
            );
        }
      });

      if (flightUpdatedCount > 0) {
        await batch.commit();
        console.log(
          `✅ Updated ${flightUpdatedCount} flight bookings to COMPLETED`
        );
      }
    }

    const totalUpdated = hotelUpdatedCount + flightUpdatedCount;

    if (totalUpdated === 0) {
      console.log("ℹ️  No bookings to update");
    }

    return {
      success: true,
      hotelUpdated: hotelUpdatedCount,
      flightUpdated: flightUpdatedCount,
      totalUpdated: totalUpdated,
    };
  } catch (error) {
    console.error("❌ Error updating booking status:", error);
    return {
      success: false,
      error: error.message,
    };
  }
}

// ============================================================================
// SEND TRIP REMINDERS (H-3)
// ============================================================================

/**
 * Send reminder notification 3 days before trip starts
 */
async function sendTripReminders() {
  try {
    console.log("🔔 Checking for trip reminders...");

    const now = new Date();
    const threeDaysFromNow = new Date(now);
    threeDaysFromNow.setDate(now.getDate() + 3);
    threeDaysFromNow.setHours(0, 0, 0, 0);

    const fourDaysFromNow = new Date(now);
    fourDaysFromNow.setDate(now.getDate() + 4);
    fourDaysFromNow.setHours(0, 0, 0, 0);

    // Get bookings dengan departure/check-in 3 hari dari sekarang
    const hotelSnapshot = await bookingsCollection
      .where("bookingType", "==", "hotel")
      .where("bookingStatus", "==", "CONFIRMED")
      .get();

    const flightSnapshot = await bookingsCollection
      .where("bookingType", "==", "flight")
      .where("bookingStatus", "==", "CONFIRMED")
      .get();

    let remindersSent = 0;

    // Process hotel bookings
    for (const doc of hotelSnapshot.docs) {
      const booking = doc.data();
      const checkInDate = new Date(booking.checkInDate);
      checkInDate.setHours(0, 0, 0, 0);

      // Jika check-in 3 hari lagi dan belum dikirim reminder
      if (
        checkInDate.getTime() === threeDaysFromNow.getTime() &&
        !booking.reminderSent
      ) {
        await notificationService.createNotification({
          userId: booking.userId,
          type: "reminder",
          title: "Upcoming Hotel Stay 🏨",
          body: `Reminder: Your check-in at ${booking.hotelName} is in 3 days! Don't forget to prepare.`,
          relatedType: "booking",
          relatedId: doc.id,
          actionUrl: `/hotels/bookings/${doc.id}`,
        });

        // Mark reminder as sent
        await doc.ref.update({
          reminderSent: true,
          reminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        remindersSent++;
      }
    }

    // Process flight bookings
    for (const doc of flightSnapshot.docs) {
      const booking = doc.data();
      const departureDate = new Date(booking.departureDate);
      departureDate.setHours(0, 0, 0, 0);

      if (
        departureDate.getTime() === threeDaysFromNow.getTime() &&
        !booking.reminderSent
      ) {
        await notificationService.createNotification({
          userId: booking.userId,
          type: "reminder",
          title: "Upcoming Flight ✈️",
          body: `Reminder: Your flight from ${booking.origin} to ${booking.destination} is in 3 days! Check your documents.`,
          relatedType: "booking",
          relatedId: doc.id,
          actionUrl: `/flights/bookings/${doc.id}`,
        });

        await doc.ref.update({
          reminderSent: true,
          reminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        remindersSent++;
      }
    }

    console.log(`✅ Sent ${remindersSent} trip reminders`);

    return {
      success: true,
      remindersSent: remindersSent,
    };
  } catch (error) {
    console.error("❌ Error sending trip reminders:", error);
    return {
      success: false,
      error: error.message,
    };
  }
}

// ============================================================================
// EXPORTS
// ============================================================================

module.exports = {
  updateExpiredBookings,
  sendTripReminders,
};
