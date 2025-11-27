// Daftar Fungsi:
// 1. store()          - Membuat profil user baru setelah registrasi
// 2. show()           - Menampilkan detail profil user
// 3. update()         - Memperbarui data profil user (nama, phone, dll)
// 4. updatePhoto()    - Memperbarui foto profil user
// 5. updateFcmToken() - Memperbarui token notifikasi FCM
// 6. destroy()        - Menghapus akun user (hard delete)
// ============================================================================

const { db, admin } = require("../index");
const usersCollection = db.collection("users");

// ============================================================================
// 1. CREATE - Membuat Profil User Baru
// ============================================================================
/**
 * @desc    Membuat dokumen profil user di Firestore setelah registrasi
 * @route   POST /api/users/profile
 * @access  Private (require authCheck middleware)
 * @body    { displayName, photoURL }
 */
exports.store = async (req, res) => {
  try {
    const { uid, email } = req.user;
    const { displayName, photoURL } = req.body;

    const newUserProfile = {
      uid,
      email,
      displayName: displayName || "",
      photoURL: photoURL || null,
      phoneNumber: null,
      dateOfBirth: null,
      language: "id",
      currency: "IDR",
      createdAt: new Date(),
      updatedAt: new Date(),
      fcmToken: null,
    };

    await usersCollection.doc(uid).set(newUserProfile);

    return res.status(201).json({
      success: true,
      message: "User profile created successfully",
      data: newUserProfile,
    });
  } catch (error) {
    console.error("Error creating user profile:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to create user profile",
      error: error.message,
    });
  }
};

// ============================================================================
// 2. READ - Menampilkan Profil User
// ============================================================================
/**
 * @desc    Mengambil data profil user yang sedang login
 * @route   GET /api/users/profile
 * @access  Private (require authCheck middleware)
 */
exports.show = async (req, res) => {
  try {
    const { uid } = req.user;

    const docSnapshot = await usersCollection.doc(uid).get();

    if (!docSnapshot.exists) {
      return res.status(404).json({
        success: false,
        message: "User profile not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        id: docSnapshot.id,
        ...docSnapshot.data(),
      },
    });
  } catch (error) {
    console.error("Error getting user profile:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get user profile",
      error: error.message,
    });
  }
};

// ============================================================================
// 3. UPDATE - Memperbarui Profil User (General)
// ============================================================================
/**
 * @desc    Memperbarui data profil user (nama, telepon, bahasa, dll)
 * @route   PUT /api/users/profile
 * @access  Private (require authCheck middleware)
 * @body    { displayName?, phoneNumber?, dateOfBirth?, language?, currency? }
 */
exports.update = async (req, res) => {
  try {
    const { uid } = req.user;
    const { displayName, phoneNumber, dateOfBirth, language, currency } =
      req.body;

    // Validasi: minimal ada 1 field yang di-update
    if (
      !displayName &&
      !phoneNumber &&
      !dateOfBirth &&
      !language &&
      !currency
    ) {
      return res.status(400).json({
        success: false,
        message: "At least one field must be provided for update",
      });
    }

    const updates = {
      updatedAt: new Date(),
    };

    // Hanya update field yang dikirim
    if (displayName !== undefined) updates.displayName = displayName;
    if (phoneNumber !== undefined) updates.phoneNumber = phoneNumber;
    if (dateOfBirth !== undefined) updates.dateOfBirth = new Date(dateOfBirth);
    if (language !== undefined) updates.language = language;
    if (currency !== undefined) updates.currency = currency;

    await usersCollection.doc(uid).set(updates, { merge: true });

    return res.status(200).json({
      success: true,
      message: "Profile updated successfully",
      data: updates,
    });
  } catch (error) {
    console.error("Error updating user profile:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update user profile",
      error: error.message,
    });
  }
};

// ============================================================================
// 4. UPDATE PHOTO - Memperbarui Foto Profil
// ============================================================================
/**
 * @desc    Memperbarui URL foto profil user
 * @route   PATCH /api/users/profile/photo
 * @access  Private (require authCheck middleware)
 * @body    { photoURL }
 * @note    photoURL didapat setelah upload image ke Firebase Storage
 */
exports.updatePhoto = async (req, res) => {
  try {
    const { uid } = req.user;
    const { photoURL } = req.body;

    if (!photoURL) {
      return res.status(400).json({
        success: false,
        message: "photoURL is required",
      });
    }

    await usersCollection.doc(uid).update({
      photoURL,
      updatedAt: new Date(),
    });

    return res.status(200).json({
      success: true,
      message: "Profile photo updated successfully",
      data: { photoURL },
    });
  } catch (error) {
    console.error("Error updating profile photo:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update profile photo",
      error: error.message,
    });
  }
};

// ============================================================================
// 5. UPDATE FCM TOKEN - Memperbarui Token Notifikasi
// ============================================================================
/**
 * @desc    Menyimpan/memperbarui FCM token untuk push notification
 * @route   PUT /api/users/fcm-token
 * @access  Private (require authCheck middleware)
 * @body    { fcmToken }
 * @note    Dipanggil setiap kali user login atau token di-refresh
 */
exports.updateFcmToken = async (req, res) => {
  try {
    const { uid } = req.user;
    const { fcmToken } = req.body;

    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        message: "fcmToken is required",
      });
    }

    await usersCollection.doc(uid).update({
      fcmToken,
      updatedAt: new Date(),
    });

    return res.status(200).json({
      success: true,
      message: "FCM token updated successfully",
    });
  } catch (error) {
    console.error("Error updating FCM token:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update FCM token",
      error: error.message,
    });
  }
};

// ============================================================================
// HELPER FUNCTIONS (Optional - untuk DRY principle)
// ============================================================================

/**
 * Helper: Cek apakah user profile exists
 */
const checkUserExists = async (uid) => {
  const doc = await usersCollection.doc(uid).get();
  return doc.exists;
};

/**
 * Helper: Get user profile
 */
const getUserProfile = async (uid) => {
  const doc = await usersCollection.doc(uid).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...doc.data() };
};

// Export helper jika diperlukan di controller lain
module.exports.helpers = {
  checkUserExists,
  getUserProfile,
};
