// ============================================================================
// FILE: controllers/authController.js
// DESC: Controller untuk autentikasi user (Register, Login OAuth, Logout)
//       Terintegrasi dengan Firebase Authentication & Firestore
// ============================================================================

const { db, admin } = require("../index");
const notificationService = require("../services/notificationService");
// ============================================================================
// COLLECTION REFERENCE
// ============================================================================

/**
 * Reference ke collection users
 * Collection ini menyimpan profile lengkap user yang sudah terautentikasi
 */
const usersCollection = db.collection("users");

// ============================================================================
// 1. REGISTER - Membuat User Baru (Email/Password)
// ============================================================================
/**
 * @desc    Mendaftarkan user baru dengan email & password
 * @route   POST /api/auth/register
 * @access  Public (tidak perlu login)
 * @body    {
 *            email: string (required),
 *            password: string (required, min 6 chars),
 *            displayName: string (optional),
 *            photoURL: string (optional)
 *          }
 */
exports.register = async (req, res) => {
  try {
    // 1. Ambil data dari request body
    const { email, password, displayName, photoURL } = req.body;

    // 2. Validasi input wajib
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required",
      });
    }

    // 3. Validasi format email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: "Invalid email format",
      });
    }

    // 4. Validasi password minimal 6 karakter (Firebase requirement)
    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: "Password must be at least 6 characters long",
      });
    }

    // 5. Buat user baru di Firebase Authentication
    const userRecord = await admin.auth().createUser({
      email: email.toLowerCase().trim(), // Normalize email
      password: password,
      displayName: displayName || null,
      photoURL: photoURL || null,
      emailVerified: false, // Email belum terverifikasi
    });

    // 6. Buat profil user di Firestore dengan data default
    const newUserProfile = {
      uid: userRecord.uid,
      email: userRecord.email,
      displayName: displayName || "",
      photoURL: photoURL || null,
      phoneNumber: null,
      dateOfBirth: null,
      bio: "",
      language: "id", // Default bahasa Indonesia
      currency: "IDR", // Default mata uang Rupiah
      emailVerified: false,
      provider: "email", // Auth provider type
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      fcmToken: null, // Will be set saat login
    };

    await usersCollection.doc(userRecord.uid).set(newUserProfile);

    // 7. (Optional) Kirim email verifikasi
    //    Uncomment jika ingin implementasi email verification
    // const link = await admin.auth().generateEmailVerificationLink(email);
    // await sendVerificationEmail(email, link);

    try {
      await notificationService.notifyWelcome(
        userRecord.uid,
        displayName || "Traveler"
      );
      console.log("✅ Welcome notification created");
    } catch (notifError) {
      console.error("⚠️ Failed to create notification:", notifError.message);
    }
    // 8. Return response sukses
    //    NOTE: Tidak kirim token, user harus login untuk mendapat token
    return res.status(201).json({
      success: true,
      message: "Registration successful. Please login to continue.",
      data: {
        uid: userRecord.uid,
        email: userRecord.email,
        displayName: displayName || "",
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Registration successful. Please login to continue.",
    //   "data": {
    //     "uid": "abc123xyz",
    //     "email": "user@example.com",
    //     "displayName": "John Doe"
    //   }
    // }
  } catch (error) {
    console.error("Error registering user:", error);

    // Handle specific Firebase Auth errors
    if (error.code === "auth/email-already-exists") {
      return res.status(409).json({
        success: false,
        message: "Email already registered. Please login instead.",
      });
      // Response error (email exists):
      // {
      //   "success": false,
      //   "message": "Email already registered. Please login instead."
      // }
    }

    if (error.code === "auth/invalid-email") {
      return res.status(400).json({
        success: false,
        message: "Invalid email address",
      });
    }

    if (error.code === "auth/weak-password") {
      return res.status(400).json({
        success: false,
        message: "Password is too weak. Use at least 6 characters.",
      });
    }

    // Generic error
    return res.status(500).json({
      success: false,
      message: "Failed to register user",
      error: error.message,
    });

    // Response error (generic):
    // {
    //   "success": false,
    //   "message": "Failed to register user",
    //   "error": "Internal server error"
    // }
  }
};

// ============================================================================
// 1.5. LOGIN - Login dengan Email & Password
// ============================================================================
/**
 * @desc    Login user dengan email & password
 * @route   POST /api/auth/login
 * @access  Public
 * @body    {
 *            email: string (required),
 *            password: string (required),
 *            fcmToken: string (optional) - untuk push notifications
 *          }
 *
 * @note    Firebase Admin SDK tidak bisa verify password secara langsung.
 *          Ada 2 cara implementasi:
 *          A. Client-side: Firebase Client SDK verify credentials → kirim ID token ke backend
 *          B. Server-side: Gunakan Firebase Auth REST API
 *
 *          Implementasi di bawah menggunakan cara B (REST API)
 */
exports.login = async (req, res) => {
  try {
    // 1. Ambil credentials dari request body
    const { email, password, fcmToken } = req.body;

    // 2. Validasi input wajib
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required",
      });
    }

    // 3. Validasi format email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: "Invalid email format",
      });
    }

    // 4. Verify credentials menggunakan Firebase Auth REST API
    //    API Key harus ada di environment variables
    const firebaseApiKey = process.env.FIREBASE_API_KEY;

    if (!firebaseApiKey) {
      throw new Error("FIREBASE_API_KEY not configured in environment");
    }

    const authUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${firebaseApiKey}`;

    const response = await fetch(authUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: email.toLowerCase().trim(),
        password: password,
        returnSecureToken: true,
      }),
    });

    const authData = await response.json();

    // 5. Cek jika login gagal (credentials salah)
    if (!response.ok) {
      // Handle specific Firebase Auth errors
      if (authData.error) {
        const errorMessage = authData.error.message;

        if (
          errorMessage.includes("INVALID_LOGIN_CREDENTIALS") ||
          errorMessage.includes("EMAIL_NOT_FOUND") ||
          errorMessage.includes("INVALID_PASSWORD")
        ) {
          return res.status(401).json({
            success: false,
            message: "Invalid email or password",
          });
        }

        if (errorMessage.includes("USER_DISABLED")) {
          return res.status(403).json({
            success: false,
            message: "This account has been disabled",
          });
        }

        if (errorMessage.includes("TOO_MANY_ATTEMPTS_TRY_LATER")) {
          return res.status(429).json({
            success: false,
            message: "Too many failed login attempts. Please try again later.",
          });
        }
      }

      // Generic login error
      return res.status(401).json({
        success: false,
        message: "Login failed. Please check your credentials.",
      });
    }

    // 6. Extract user info dari response
    const {
      idToken, // ID Token untuk authentication
      refreshToken, // Refresh token untuk renew session
      localId: uid, // User ID
      email: userEmail,
      displayName,
      photoUrl,
      expiresIn,
    } = authData;

    // 7. Update atau create user profile di Firestore
    const userDocRef = usersCollection.doc(uid);
    const userDoc = await userDocRef.get();

    let userProfile;

    if (userDoc.exists) {
      // User exists - update login info
      const existingData = userDoc.data();

      const updates = {
        fcmToken: fcmToken || existingData.fcmToken,
        lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await userDocRef.update(updates);

      userProfile = {
        ...existingData,
        ...updates,
      };
    } else {
      // User doesn't exist in Firestore (shouldn't happen after register, but handle it)
      userProfile = {
        uid: uid,
        email: userEmail,
        displayName: displayName || "",
        photoURL: photoUrl || null,
        phoneNumber: null,
        dateOfBirth: null,
        bio: "",
        language: "id",
        currency: "IDR",
        emailVerified: false,
        provider: "email",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
        fcmToken: fcmToken || null,
      };

      await userDocRef.set(userProfile);
    }

    // 8. Return response sukses dengan tokens
    return res.status(200).json({
      success: true,
      message: "Login successful",
      data: {
        user: {
          uid: uid,
          email: userProfile.email,
          displayName: userProfile.displayName,
          photoURL: userProfile.photoURL,
        },
        tokens: {
          idToken: idToken, // Client simpan ini untuk authentication
          refreshToken: refreshToken, // Client simpan ini untuk refresh session
          expiresIn: expiresIn, // Token valid selama (dalam detik, biasanya 3600 = 1 jam)
        },
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Login successful",
    //   "data": {
    //     "user": {
    //       "uid": "abc123xyz",
    //       "email": "user@example.com",
    //       "displayName": "John Doe",
    //       "photoURL": null
    //     },
    //     "tokens": {
    //       "idToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    //       "refreshToken": "AGEhc0D-RtHd...",
    //       "expiresIn": "3600"
    //     }
    //   }
    // }
  } catch (error) {
    console.error("Error during login:", error);

    // Handle network errors
    if (error.code === "ENOTFOUND" || error.code === "ECONNREFUSED") {
      return res.status(503).json({
        success: false,
        message: "Unable to connect to authentication service",
      });
    }

    // Generic error
    return res.status(500).json({
      success: false,
      message: "Login failed. Please try again.",
      error: error.message,
    });

    // Response error (wrong credentials):
    // {
    //   "success": false,
    //   "message": "Invalid email or password"
    // }

    // Response error (account disabled):
    // {
    //   "success": false,
    //   "message": "This account has been disabled"
    // }

    // Response error (too many attempts):
    // {
    //   "success": false,
    //   "message": "Too many failed login attempts. Please try again later."
    // }
  }
};

// ============================================================================
// 2. OAUTH LOGIN - Login atau Register via OAuth Provider
// ============================================================================
/**
 * @desc    Login atau auto-register user via OAuth (Google, Facebook, Apple, etc.)
 * @route   POST /api/auth/oauth
 * @access  Public
 * @body    {
 *            idToken: string (required) - Firebase ID Token dari client SDK,
 *            fcmToken: string (optional) - FCM token untuk push notifications
 *          }
 *
 * @flow    Client Flow:
 *          1. User tap "Login with Google" di app
 *          2. Firebase Client SDK handle OAuth flow
 *          3. Client dapat ID Token dari Firebase
 *          4. Client kirim ID Token ke endpoint ini
 *          5. Backend verify token & sync data ke Firestore
 */
exports.verifyOAuth = async (req, res) => {
  try {
    // 1. Ambil ID Token dan FCM Token dari request body
    const { idToken, fcmToken } = req.body;

    // 2. Validasi ID Token wajib ada
    if (!idToken) {
      return res.status(400).json({
        success: false,
        message: "ID Token is required",
      });
    }

    // 3. Verifikasi ID Token dengan Firebase Admin SDK
    //    Ini memastikan token valid dan tidak expired
    const decodedToken = await admin.auth().verifyIdToken(idToken);

    // 4. Extract user info dari decoded token
    const { uid, email, name, picture, firebase } = decodedToken;

    // 5. Detect provider type (google.com, facebook.com, apple.com, etc)
    const provider = firebase.sign_in_provider || "unknown";

    // 6. Cek apakah user sudah terdaftar di Firestore
    const userDocRef = usersCollection.doc(uid);
    const docSnapshot = await userDocRef.get();

    let userProfile;
    let isNewUser = false;

    if (docSnapshot.exists) {
      // 7a. USER EXISTING - Update data yang perlu di-refresh
      const existingData = docSnapshot.data();

      const updates = {
        // Update info yang mungkin berubah dari OAuth provider
        displayName: name || existingData.displayName,
        photoURL: picture || existingData.photoURL,
        email: email || existingData.email,
        // Update FCM token untuk push notifications
        fcmToken: fcmToken || existingData.fcmToken,
        // Update timestamp
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        // Track last login
        lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await userDocRef.update(updates);

      userProfile = {
        ...existingData,
        ...updates,
      };
    } else {
      // 7b. USER BARU - Auto-register via OAuth
      isNewUser = true;

      userProfile = {
        uid: uid,
        email: email || null,
        displayName: name || "",
        photoURL: picture || null,
        phoneNumber: null,
        dateOfBirth: null,
        bio: "",
        language: "id",
        currency: "IDR",
        emailVerified: email ? true : false, // OAuth emails usually verified
        provider: provider, // google.com, facebook.com, etc
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
        fcmToken: fcmToken || null,
      };

      await userDocRef.set(userProfile);
    }

    // 8. Return response sukses
    return res.status(200).json({
      success: true,
      message: isNewUser
        ? "Account created successfully via OAuth"
        : "Login successful",
      data: {
        uid: uid,
        email: userProfile.email,
        displayName: userProfile.displayName,
        photoURL: userProfile.photoURL,
        provider: provider,
        isNewUser: isNewUser,
      },
    });

    // Response sukses (existing user):
    // {
    //   "success": true,
    //   "message": "Login successful",
    //   "data": {
    //     "uid": "google_abc123",
    //     "email": "user@gmail.com",
    //     "displayName": "John Doe",
    //     "photoURL": "https://lh3.googleusercontent.com/...",
    //     "provider": "google.com",
    //     "isNewUser": false
    //   }
    // }

    // Response sukses (new user):
    // {
    //   "success": true,
    //   "message": "Account created successfully via OAuth",
    //   "data": {
    //     "uid": "google_xyz789",
    //     "email": "newuser@gmail.com",
    //     "displayName": "Jane Smith",
    //     "photoURL": "https://lh3.googleusercontent.com/...",
    //     "provider": "google.com",
    //     "isNewUser": true
    //   }
    // }
  } catch (error) {
    console.error("Error verifying OAuth token:", error);

    // Handle specific Firebase Auth errors
    if (error.code === "auth/id-token-expired") {
      return res.status(401).json({
        success: false,
        message: "Authentication token has expired. Please login again.",
      });
      // Response error (token expired):
      // {
      //   "success": false,
      //   "message": "Authentication token has expired. Please login again."
      // }
    }

    if (error.code === "auth/invalid-id-token") {
      return res.status(401).json({
        success: false,
        message: "Invalid authentication token",
      });
    }

    if (error.code === "auth/argument-error") {
      return res.status(400).json({
        success: false,
        message: "Invalid token format",
      });
    }

    // Generic error
    return res.status(500).json({
      success: false,
      message: "Failed to process OAuth login",
      error: error.message,
    });

    // Response error (generic):
    // {
    //   "success": false,
    //   "message": "Failed to process OAuth login",
    //   "error": "Network error"
    // }
  }
};

// ============================================================================
// 3. LOGOUT - Menghapus Sesi User dan FCM Token
// ============================================================================
/**
 * @desc    Logout user dengan menghapus FCM token
 * @route   POST /api/auth/logout
 * @access  Private (require authCheck middleware)
 * @body    {} - Tidak perlu body, UID diambil dari req.user (middleware)
 *
 * @note    Logout di Firebase adalah client-side action.
 *          Endpoint ini hanya untuk cleanup FCM token agar user tidak
 *          menerima push notifications setelah logout.
 */
exports.logout = async (req, res) => {
  try {
    // 1. Ambil UID dari middleware authCheck
    //    Middleware sudah memverifikasi token dan attach user info
    const { uid } = req.user;

    // 2. Validasi UID ada (double check)
    if (!uid) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized. User not authenticated.",
      });
    }

    // 3. Update user profile: hapus FCM token
    //    Ini mencegah user menerima push notifications
    const updates = {
      fcmToken: null,
      lastLogoutAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await usersCollection.doc(uid).update(updates);

    // 4. (Optional) Revoke refresh tokens untuk extra security
    //    Uncomment jika ingin force logout dari semua devices
    // await admin.auth().revokeRefreshTokens(uid);

    // 5. Return response sukses
    return res.status(200).json({
      success: true,
      message: "Logout successful. Push notifications disabled.",
      data: {
        uid: uid,
        loggedOutAt: new Date().toISOString(),
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Logout successful. Push notifications disabled.",
    //   "data": {
    //     "uid": "abc123xyz",
    //     "loggedOutAt": "2025-11-01T10:30:00.000Z"
    //   }
    // }
  } catch (error) {
    console.error("Error during logout:", error);

    // Handle specific Firestore errors
    if (error.code === 5) {
      // NOT_FOUND
      return res.status(404).json({
        success: false,
        message: "User profile not found",
      });
      // Response error (user not found):
      // {
      //   "success": false,
      //   "message": "User profile not found"
      // }
    }

    // Generic error
    return res.status(500).json({
      success: false,
      message: "Failed to logout. Please try again.",
      error: error.message,
    });

    // Response error (generic):
    // {
    //   "success": false,
    //   "message": "Failed to logout. Please try again.",
    //   "error": "Firestore connection error"
    // }
  }
};

// ============================================================================
// 4. REFRESH TOKEN - Mendapatkan Custom Token Baru (Optional)
// ============================================================================
/**
 * @desc    Generate custom token untuk refresh authentication
 * @route   POST /api/auth/refresh
 * @access  Private (require authCheck middleware)
 * @body    {} - Tidak perlu body
 *
 * @note    Endpoint ini opsional. Biasanya Firebase Client SDK
 *          handle token refresh secara otomatis.
 */
exports.refreshToken = async (req, res) => {
  try {
    // 1. Ambil UID dari middleware
    const { uid } = req.user;

    // 2. Validasi user masih ada di Firestore
    const userDoc = await usersCollection.doc(uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // 3. Generate custom token baru
    const customToken = await admin.auth().createCustomToken(uid);

    // 4. Update last activity timestamp
    await usersCollection.doc(uid).update({
      lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 5. Return token baru
    return res.status(200).json({
      success: true,
      message: "Token refreshed successfully",
      data: {
        customToken: customToken,
        uid: uid,
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Token refreshed successfully",
    //   "data": {
    //     "customToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    //     "uid": "abc123xyz"
    //   }
    // }
  } catch (error) {
    console.error("Error refreshing token:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to refresh token",
      error: error.message,
    });
  }
};

// ============================================================================
// 5. DELETE ACCOUNT - Menghapus Akun User (Optional)
// ============================================================================
/**
 * @desc    Menghapus akun user secara permanen
 * @route   DELETE /api/auth/account
 * @access  Private (require authCheck middleware)
 * @body    { password: string } - Required untuk email/password users
 *
 * @note    Ini akan menghapus:
 *          1. User dari Firebase Authentication
 *          2. User profile dari Firestore
 *          3. (Optional) Semua data terkait user (trips, dll)
 */
exports.deleteAccount = async (req, res) => {
  try {
    // 1. Ambil UID dari middleware
    const { uid, email } = req.user;
    const { password } = req.body;

    // 2. Get user data untuk validasi provider
    const userDoc = await usersCollection.doc(uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const userData = userDoc.data();

    // 3. Validasi password untuk email/password users
    if (userData.provider === "email" || userData.provider === "password") {
      if (!password) {
        return res.status(400).json({
          success: false,
          message: "Password is required to delete account",
        });
      }

      // NOTE: Firebase Admin SDK tidak bisa verify password
      // Client harus re-authenticate sebelum delete account
      // Atau implementasi custom password verification
    }

    // 4. Delete user dari Firebase Authentication
    await admin.auth().deleteUser(uid);

    // 5. Delete user profile dari Firestore
    await usersCollection.doc(uid).delete();

    // 6. (Optional) Delete semua data terkait user
    //    Uncomment jika ingin cascade delete
    // const batch = db.batch();
    // const userTrips = await db.collection("trips").where("userId", "==", uid).get();
    // userTrips.forEach(doc => batch.delete(doc.ref));
    // await batch.commit();

    // 7. Return success response
    return res.status(200).json({
      success: true,
      message: "Account deleted successfully",
      data: {
        uid: uid,
        deletedAt: new Date().toISOString(),
      },
    });

    // Response sukses:
    // {
    //   "success": true,
    //   "message": "Account deleted successfully",
    //   "data": {
    //     "uid": "abc123xyz",
    //     "deletedAt": "2025-11-01T10:30:00.000Z"
    //   }
    // }
  } catch (error) {
    console.error("Error deleting account:", error);

    if (error.code === "auth/user-not-found") {
      return res.status(404).json({
        success: false,
        message: "User account not found",
      });
    }

    return res.status(500).json({
      success: false,
      message: "Failed to delete account",
      error: error.message,
    });
  }
};
