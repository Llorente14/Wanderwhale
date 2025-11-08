## ✨ Fitur Utama (Key Features)

- **Autentikasi Pengguna:** Login, register, dan manajemen profil pengguna (termasuk OAuth).
- **Perencanaan Perjalanan (Internal):** Fitur CRUD untuk membuat rencana perjalanan (`trips`), menambahkan destinasi, dan menyimpan daftar hotel ke dalam trip pribadi.
- **Pencarian Hotel (LIVE):** Terhubung langsung ke **Amadeus API** untuk:
  - Mencari daftar hotel (berdasarkan kota, geocode, atau ID).
  - Mencari harga dan ketersediaan kamar (`hotel-offers`).
  - Mengonfirmasi harga satu penawaran (`hotel-offers/{offerId}`).
- **Pencarian Penerbangan (LIVE):** Terhubung langsung ke **Amadeus API** untuk:
  - Mencari kode bandara (`city-search`).
  - Mencari penawaran penerbangan (`flight-offers`).
  - Mendapatkan _layout_ peta kursi (`seatmaps`).
- **Simulasi Booking (Dummy):** Alur _booking_ dan _payment_ palsu. API **tidak** memanggil Amadeus `Create Orders`, melainkan langsung menyimpan pesanan (hotel & pesawat) ke database internal Firestore dengan status _confirmed_.

---

## 🛠️ Tech Stack

| Kategori              | Teknologi                                          |
| :-------------------- | :------------------------------------------------- |
| **Frontend (Mobile)** | Flutter & Dart                                     |
| **Backend**           | Node.js, Express.js                                |
| **Database**          | Google Firestore                                   |
| **Autentikasi**       | Firebase Authentication                            |
| **API Eksternal**     | Amadeus Self-Service API (Live Mode)               |
| **Runtime**           | Node.js                                            |
| **Lain-lain**         | `axios` (untuk panggilan API), `dotenv`, `nodemon` |

---

## 🚀 Cara Menjalankan Proyek

Proyek ini terdiri dari dua bagian: `backend` (Node.js) dan `frontend` (Flutter).

### 🖥️ Backend (Node.js & Firebase)

1.  **Clone Repositori:**

    ```bash
    git clone [https://github.com/Llorente14/Wanderwhale.git](https://github.com/Llorente14/Wanderwhale.git)
    cd wanderwhale
    ```

2.  **Install Dependencies:**

    ```bash
    npm install
    ```

3.  **Setup Firebase Admin:**

    - Pergi ke Firebase Console > Project Settings > Service accounts.
    - Generate _private key_ baru dan simpan sebagai `serviceAccountKey.json` di dalam folder _Wanderwwhale_.

4.  **Setup Environment Variables (.env):**

    - Buat file `.env` di folder _Wanderwwhale_ dan isi dengan variabel berikut:

    ```env
    # Port Server
    PORT=5000

    # Path ke Kunci Firebase
    SERVICE_ACCOUNT_PATH="./serviceAccountKey.json"

    # Amadeus API Credentials (Ganti dengan Client ID & Secret Anda)
    AMADEUS_CLIENT_ID="YOUR_AMADEUS_CLIENT_ID"
    AMADEUS_CLIENT_SECRET="YOUR_AMADEUS_CLIENT_SECRET"
    AMADEUS_BASE_URL="[https://test.api.amadeus.com](https://test.api.amadeus.com)"
    ```

5.  **Jalankan Server:**
    ```bash
    npm run dev
    ```
    Server akan berjalan di `http://localhost:5000`.

---

### 📱 Frontend (Flutter)

1.  **Navigasi ke Folder Flutter:**

    ```bash
    cd ../flutter_app
    ```

2.  **Setup Firebase untuk Flutter:**

    - Ikuti instruksi di [Firebase Console](https://console.firebase.google.com/) untuk menambahkan aplikasi Android dan iOS.
    - Download `google-services.json` (untuk Android) dan letakkan di `android/app/`.
    - Download `GoogleService-Info.plist` (untuk iOS) dan letakkan di `ios/Runner/`.

3.  **Konfigurasi Alamat API:**

    - Di dalam kode Flutter (misal, di `lib/core/api_client.dart` atau `lib/constants.dart`), pastikan alamat API menunjuk ke server backend Anda:
    - Untuk **Emulator Android**: `String baseUrl = "http://10.0.2.2:5000/api";`
    - Untuk **Emulator iOS / Device Fisik**: `String baseUrl = "http://localhost:5000/api";` (atau IP lokal Anda jika menggunakan _device_ fisik).

4.  **Install Packages:**

    ```bash
    flutter pub get
    ```

5.  **Jalankan Aplikasi:**
    ```bash
    flutter run
    ```

---

## 🌊 Alur Inti Aplikasi (Hotel & Flight)

Aplikasi ini mengimplementasikan alur pencarian dan pemesanan _hybrid_ (live search, dummy booking):

1.  **Step 1: Pencarian (LIVE)**

    - Pengguna mencari hotel/penerbangan (misal: berdasarkan kota atau geocode).
    - `GET /api/hotels/search/...` atau `GET /api/flights/search/locations`
    - Backend memanggil **Amadeus API (Live)** untuk mendapatkan daftar hotel statis atau bandara (IATA code).

2.  **Step 2: Penawaran & Kursi (LIVE)**

    - Pengguna memilih item dan memasukkan tanggal/tamu.
    - `GET /api/hotels/offers` atau `POST /api/flights/search` (untuk _flight offers_) dan `POST /api/flights/seatmaps` (untuk _kursi_).
    - Backend memanggil **Amadeus API (Live)** untuk mendapatkan harga, ketersediaan kamar, dan _layout_ kursi.

3.  **Step 3: Booking (DUMMY)**
    - Pengguna mengonfirmasi pesanan (setelah memilih kamar/kursi) dan memilih metode pembayaran (palsu).
    - `POST /api/bookings/hotels` atau `POST /api/flights/bookings`
    - Backend **TIDAK** memanggil Amadeus `Create Orders` atau _payment gateway_.
    - Backend **langsung menyimpan** data pesanan ke koleksi `bookings` di **Firestore** dengan status `CONFIRMED` dan `paymentStatus: "paid (dummy)"`.
