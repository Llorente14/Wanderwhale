// File: index.js

// 1. Import library yang dibutuhkan
const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
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

// 4. Inisialisasi Aplikasi Express
const app = express();
const port = process.env.PORT || 5000;

// 5. Gunakan Middleware
app.use(cors()); // Mengizinkan request dari domain lain (Flutter)
app.use(express.json()); // Membaca body request sebagai JSON

// 6. Impor Rute (Routes) Anda
const userRoutes = require("./routes/userRoutes");
const tripRoutes = require("./routes/tripRoutes");
const destinationRoutes = require("./routes/destinationRoutes");
const hotelRoutes = require("./routes/hotelRoutes");
const authRoutes = require("./routes/authRoutes");

// 7. Definisikan Rute API Utama
// Memberi tahu Express untuk menggunakan file rute tersebut
app.use("/api/users", userRoutes); // Langsung /api/users
app.use("/api/trips", tripRoutes); // Langsung /api/trips
app.use("/api/destinations", destinationRoutes);
app.use("/api/hotels", hotelRoutes);
app.use("/api/auth", authRoutes);

// 8. Jalankan Server
app.listen(port, () => {
  console.log(`🚀 Server API berjalan di http://localhost:${port}`);
});
