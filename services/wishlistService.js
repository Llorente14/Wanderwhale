// ============================================================================
// FILE: services/wishlistService.js
// DESC: Service helper untuk wishlist operations
// ============================================================================

const { db, admin } = require("../index");

const wishlistsCollection = db.collection("wishlists");
const destinationsCollection = db.collection("destinations_master");

// ============================================================================
// WISHLIST OPERATIONS
// ============================================================================

/**
 * Add destination to user's wishlist
 * @param {string} userId - User ID
 * @param {string} destinationId - Destination ID
 * @returns {Promise<Object>} Wishlist document
 */
async function addToWishlist(userId, destinationId) {
  // 1. Check if already in wishlist
  const existing = await wishlistsCollection
    .where("userId", "==", userId)
    .where("destinationId", "==", destinationId)
    .get();

  if (!existing.empty) {
    throw new Error("Destination already in wishlist");
  }

  // 2. Get destination info for denormalization
  const destDoc = await destinationsCollection.doc(destinationId).get();

  if (!destDoc.exists) {
    throw new Error("Destination not found");
  }

  const destData = destDoc.data();

  // 3. Create wishlist entry
  const wishlistData = {
    userId: userId,
    destinationId: destinationId,

    // Denormalized data (avoid extra reads in Flutter)
    destinationName: destData.name || "Unknown",
    destinationCity: destData.city || "",
    destinationCountry: destData.country || "",
    destinationImageUrl: destData.imageUrl || "",
    destinationRating: destData.rating || 0,
    destinationTags: destData.tags || [],

    addedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const docRef = await wishlistsCollection.add(wishlistData);
  await docRef.update({ wishlistId: docRef.id });

  console.log(
    `✅ Added destination ${destinationId} to wishlist for user ${userId}`
  );

  return {
    id: docRef.id,
    ...wishlistData,
  };
}

/**
 * Remove destination from user's wishlist
 * @param {string} userId - User ID
 * @param {string} destinationId - Destination ID
 * @returns {Promise<boolean>} Success status
 */
async function removeFromWishlist(userId, destinationId) {
  const snapshot = await wishlistsCollection
    .where("userId", "==", userId)
    .where("destinationId", "==", destinationId)
    .get();

  if (snapshot.empty) {
    throw new Error("Wishlist item not found");
  }

  // Delete all matching documents (should only be 1)
  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });
  await batch.commit();

  console.log(
    `✅ Removed destination ${destinationId} from wishlist for user ${userId}`
  );

  return true;
}

/**
 * Get user's wishlist
 * @param {string} userId - User ID
 * @returns {Promise<Array>} Wishlist items
 */
async function getUserWishlist(userId) {
  const snapshot = await wishlistsCollection
    .where("userId", "==", userId)
    .orderBy("addedAt", "desc")
    .get();

  if (snapshot.empty) {
    return [];
  }

  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
}

/**
 * Check if destination is in user's wishlist
 * @param {string} userId - User ID
 * @param {string} destinationId - Destination ID
 * @returns {Promise<boolean>} Is wishlisted
 */
async function isInWishlist(userId, destinationId) {
  const snapshot = await wishlistsCollection
    .where("userId", "==", userId)
    .where("destinationId", "==", destinationId)
    .limit(1)
    .get();

  return !snapshot.empty;
}

/**
 * Get wishlist count for user
 * @param {string} userId - User ID
 * @returns {Promise<number>} Count
 */
async function getWishlistCount(userId) {
  const snapshot = await wishlistsCollection
    .where("userId", "==", userId)
    .count()
    .get();

  return snapshot.data().count;
}

// ============================================================================
// EXPORTS
// ============================================================================

module.exports = {
  addToWishlist,
  removeFromWishlist,
  getUserWishlist,
  isInWishlist,
  getWishlistCount,
};
