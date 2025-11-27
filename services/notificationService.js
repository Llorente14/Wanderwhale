// ============================================================================
// FILE: services/notificationService.js
// DESC: Service helper untuk create notifications
// ============================================================================

const { db, admin } = require("../index");
const notificationsCollection = db.collection("notifications");

// ============================================================================
// NOTIFICATION TYPES
// ============================================================================

const NOTIFICATION_TYPES = {
  BOOKING_SUCCESS: "booking_success",
  BOOKING_CANCELLED: "booking_cancelled",
  TRIP_CREATED: "trip_created",
  DESTINATION_ADDED: "destination_added",
  HOTEL_ADDED: "hotel_added",
  REMINDER: "reminder",
  WELCOME: "welcome",
  WISHLIST_ADDED: "wishlist_added",
};

// ============================================================================
// CREATE NOTIFICATION FUNCTION
// ============================================================================

/**
 * Create a new notification
 * @param {Object} notificationData - Notification data
 * @returns {Promise<string>} Notification ID
 */
async function createNotification(notificationData) {
  const {
    userId,
    type,
    title,
    body,
    relatedType = null,
    relatedId = null,
    actionUrl = null,
  } = notificationData;

  // Validasi
  if (!userId || !type || !title || !body) {
    throw new Error("userId, type, title, and body are required");
  }

  // Create notification document
  const notificationDoc = {
    userId: userId,
    type: type,
    title: title,
    body: body,
    relatedType: relatedType,
    relatedId: relatedId,
    actionUrl: actionUrl,
    isRead: false,
    readAt: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const docRef = await notificationsCollection.add(notificationDoc);
  await docRef.update({ notificationId: docRef.id });

  console.log(`✅ Notification created: ${docRef.id} for user ${userId}`);

  return docRef.id;
}

// ============================================================================
// PRESET NOTIFICATION TEMPLATES
// ============================================================================

/**
 * Create booking success notification
 */
async function notifyBookingSuccess(userId, bookingData) {
  const {
    bookingId,
    bookingType,
    hotelName,
    origin,
    destination,
    confirmationNumber,
  } = bookingData;

  const title =
    bookingType === "hotel"
      ? "Hotel Booking Confirmed! 🎉"
      : "Flight Booking Confirmed! ✈️";

  const body =
    bookingType === "hotel"
      ? `Your booking at ${hotelName} has been confirmed. Confirmation: ${confirmationNumber}`
      : `Your flight from ${origin} to ${destination} has been confirmed. Confirmation: ${confirmationNumber}`;

  return await createNotification({
    userId,
    type: NOTIFICATION_TYPES.BOOKING_SUCCESS,
    title,
    body,
    relatedType: "booking",
    relatedId: bookingId,
    actionUrl:
      bookingType === "hotel"
        ? `/hotels/bookings/${bookingId}`
        : `/flights/bookings/${bookingId}`,
  });
}

/**
 * Create booking cancelled notification
 */
async function notifyBookingCancelled(userId, bookingData) {
  const { bookingId, bookingType, hotelName, origin, destination } =
    bookingData;

  const title = "Booking Cancelled";

  const body =
    bookingType === "hotel"
      ? `Your booking at ${hotelName} has been cancelled successfully.`
      : `Your flight from ${origin} to ${destination} has been cancelled.`;

  return await createNotification({
    userId,
    type: NOTIFICATION_TYPES.BOOKING_CANCELLED,
    title,
    body,
    relatedType: "booking",
    relatedId: bookingId,
    actionUrl:
      bookingType === "hotel"
        ? `/hotels/bookings/${bookingId}`
        : `/flights/bookings/${bookingId}`,
  });
}

/**
 * Create trip created notification
 */
async function notifyTripCreated(userId, tripData) {
  const { tripId, tripName } = tripData;

  return await createNotification({
    userId,
    type: NOTIFICATION_TYPES.TRIP_CREATED,
    title: "New Trip Created! 🗺️",
    body: `Your trip "${tripName}" has been created. Start planning your adventure!`,
    relatedType: "trip",
    relatedId: tripId,
    actionUrl: `/trips/${tripId}`,
  });
}

/**
 * Create destination added notification
 */
async function notifyDestinationAdded(userId, destinationData) {
  const { tripId, destinationName } = destinationData;

  return await createNotification({
    userId,
    type: NOTIFICATION_TYPES.DESTINATION_ADDED,
    title: "Destination Added! 📍",
    body: `${destinationName} has been added to your trip itinerary.`,
    relatedType: "trip",
    relatedId: tripId,
    actionUrl: `/trips/${tripId}`,
  });
}

/**
 * Create hotel added notification
 */
async function notifyHotelAdded(userId, hotelData) {
  const { tripId, hotelName } = hotelData;

  return await createNotification({
    userId,
    type: NOTIFICATION_TYPES.HOTEL_ADDED,
    title: "Hotel Added! 🏨",
    body: `${hotelName} has been added to your trip.`,
    relatedType: "trip",
    relatedId: tripId,
    actionUrl: `/trips/${tripId}`,
  });
}

/**
 * Create welcome notification
 */
async function notifyWelcome(userId, userName) {
  return await createNotification({
    userId,
    type: NOTIFICATION_TYPES.WELCOME,
    title: `Welcome to Travexe, ${userName}! 🎉`,
    body: "Start planning your dream vacation today. Explore destinations, book hotels and flights!",
    relatedType: null,
    relatedId: null,
    actionUrl: "/destinations",
  });
}

/**
 * Create reminder notification
 */
async function notifyReminder(userId, reminderData) {
  const { tripId, tripName, daysUntilDeparture } = reminderData;

  return await createNotification({
    userId,
    type: NOTIFICATION_TYPES.REMINDER,
    title: `Trip Reminder: ${tripName} 📅`,
    body: `Your trip starts in ${daysUntilDeparture} days! Don't forget to prepare.`,
    relatedType: "trip",
    relatedId: tripId,
    actionUrl: `/trips/${tripId}`,
  });
}

// ============================================================================
// EXPORTS
// ============================================================================

module.exports = {
  NOTIFICATION_TYPES,
  createNotification,
  notifyBookingSuccess,
  notifyBookingCancelled,
  notifyTripCreated,
  notifyDestinationAdded,
  notifyHotelAdded,
  notifyWelcome,
  notifyReminder,
};
