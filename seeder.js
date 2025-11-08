// File: seeder.js
const admin = require("firebase-admin");

// 1. Ambil data JSON lokal Anda
const data = require("./seeder-data.json");

// 2. Ambil kunci admin Anda (SAMA seperti di index.js)
const serviceAccount = require("./serviceAccountKey.json");

// 3. Inisialisasi Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// 4. Dapatkan referensi ke Firestore
const db = admin.firestore();
const collectionRef = db.collection("destinations_master");

/**
 * Fungsi untuk meng-upload data
 */
const seedDatabase = async () => {
  console.log("Mulai proses seeding...");

  // 5. Loop setiap data di file JSON
  for (const item of data) {
    try {
      // 6. Tambahkan data ke koleksi
      await collectionRef.add(item);
      console.log(`Berhasil menambahkan: ${item.name}`);
    } catch (error) {
      console.error(`Gagal menambahkan: ${item.name}`, error);
    }
  }

  console.log("Proses seeding selesai.");
  process.exit(0); // Keluar dari script
};

// 7. Jalankan fungsi
seedDatabase();
