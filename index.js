// File: index.js

// 1. Import library yang dibutuhkan
const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const cron = require("node-cron");
require("dotenv").config(); // Memuat variabel dari file .env

// 2. Inisialisasi Firebase Admin SDK
try {
  const serviceAccount = require(process.env.SERVICE_ACCOUNT_PATH);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log("Firebase Admin SDK terhubung.");
} catch (error) {
  console.error("Error inisialisasi Firebase Admin:", error.message);
  process.exit(1); // Hentikan aplikasi jika Firebase gagal terhubung
}

// 3. Ekspor db dan admin agar bisa dipakai di file lain (Controllers)
const db = admin.firestore();
module.exports = { db, admin };

// 4. Inisialisasi Aplikasi Express & Service lain
const app = express();
const port = process.env.PORT || 5000;
const bookingStatusService = require("./services/bookingStatusService");

// 5. Gunakan Middleware
app.use(cors()); // Mengizinkan request dari domain lain (Flutter)
app.use(express.json()); // Membaca body request sebagai JSON

// ============================================================================
// CRON JOBS (Scheduled Tasks)
// ============================================================================

// Run every hour at minute 0 (00:00, 01:00, 02:00, etc.)
cron.schedule("*/30 * * * *", async () => {
  console.log("⏰ [CRON] Running hourly booking status update...");
  await bookingStatusService.updateExpiredBookings();
});

// Run every day at 09:00 AM
cron.schedule("0 9 * * *", async () => {
  console.log("⏰ [CRON] Running daily trip reminders check...");
  await bookingStatusService.sendTripReminders();
});

console.log("✅ Cron jobs scheduled:");
console.log("   - Booking status update: Every hour");
console.log("   - Trip reminders: Daily at 09:00 AM");

// 6. Impor Rute (Routes) Anda
const userRoutes = require("./routes/userRoutes");
const tripRoutes = require("./routes/tripRoutes");
const destinationRoutes = require("./routes/destinationRoutes");
const hotelRoutes = require("./routes/hotelRoutes");
const authRoutes = require("./routes/authRoutes");
const flightRoutes = require("./routes/flightRoutes");
const notificationRoutes = require("./routes/notificationRoutes");
const wishlistRoutes = require("./routes/wishlistRoutes");

// 7. Definisikan Rute API Utama
// Memberi tahu Express untuk menggunakan file rute tersebut
app.use("/api/users", userRoutes); // Langsung /api/users
app.use("/api/trips", tripRoutes); // Langsung /api/trips
app.use("/api/destinations", destinationRoutes);
app.use("/api/hotels", hotelRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/flights", flightRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/wishlist", wishlistRoutes);

// 8. Jalankan Server
app.listen(port, () => {
  console.log(`🚀 Server API berjalan di http://localhost:${port}`);
});

//Welcome Point
app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "Travexe API is running",
    version: "1.0.0",
    features: {
      autoStatusUpdate: true,
      tripReminders: true,
      realtimeNotifications: true,
      wishlist: true,
    },
    endpoints: {
      auth: "/api/auth",
      users: "/api/users",
      trips: "/api/trips",
      destinations: "/api/destinations",
      hotels: "/api/hotels",
      flights: "/api/flights",
      notifications: "/api/notifications",
      wishlist: "/api/wishlist",
    },
  });
});

//Error Handling
// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Endpoint not found",
    path: req.path,
  });
});

// Error Handler
app.use((error, req, res, next) => {
  console.error("Unhandled error:", error);
  res.status(500).json({
    success: false,
    message: "Internal server error",
    error: error.message,
  });
});
