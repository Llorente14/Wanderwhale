// ============================================================================
// FILE: routes/authRoutes.js
// DESC: Routes untuk autentikasi (Register, Login, OAuth, Logout, dll)
// ============================================================================

const express = require("express");
const router = express.Router();

// ============================================================================
// 1. IMPORT CONTROLLER & MIDDLEWARE
// ============================================================================

const authController = require("../controllers/authController");
const authCheck = require("../middleware/authCheck");

// ============================================================================
// 2. PUBLIC ROUTES (Tidak perlu authentication)
// ============================================================================

/**
 * @route   POST /api/auth/register
 * @desc    Register user baru dengan email & password
 * @access  Public
 */
router.post("/register", authController.register);

/**
 * @route   POST /api/auth/login
 * @desc    Login dengan email & password
 * @access  Public
 */
router.post("/login", authController.login); // ← TAMBAHKAN INI

/**
 * @route   POST /api/auth/oauth
 * @desc    Login atau register via OAuth (Google, Facebook, Apple)
 * @access  Public
 */
router.post("/oauth", authController.verifyOAuth);

// ============================================================================
// 3. PROTECTED ROUTES (Require authentication)
// ============================================================================

/**
 * Terapkan middleware authCheck untuk semua routes di bawah ini
 * Semua endpoint setelah ini WAJIB mengirim Authorization token
 */
router.use(authCheck);

/**
 * @route   POST /api/auth/logout
 * @desc    Logout user dan hapus FCM token
 * @access  Private (require auth token)
 */
router.post("/logout", authController.logout);

/**
 * @route   POST /api/auth/refresh
 * @desc    Refresh authentication token
 * @access  Private (require auth token)
 */
router.post("/refresh", authController.refreshToken);

/**
 * @route   DELETE /api/auth/account
 * @desc    Delete account user secara permanen
 * @access  Private (require auth token)
 */
router.delete("/account", authController.deleteAccount);

// ============================================================================
// 4. EXPORT ROUTER
// ============================================================================

module.exports = router;
