# Dokumentasi Validasi Login/Register

## Cara Kerja Validasi Auth

### 1. **AuthWrapper Widget** (`lib/widgets/auth/auth_wrapper.dart`)
Widget ini adalah wrapper utama yang mengecek status autentikasi user menggunakan `authStateProvider`:

- **Jika user sudah login** → Menampilkan `HomeScreen`
- **Jika user belum login** → Menampilkan `WelcomeScreen`

AuthWrapper menggunakan `StreamProvider` yang mendengarkan perubahan auth state dari Firebase Auth secara real-time.

### 2. **Auth Screen Provider** (`lib/providers/auth_screen_provider.dart`)
Provider ini mengelola state screen auth (welcome/login/register) menggunakan `StateProvider`:

- `AuthScreenType.welcome` → Menampilkan WelcomeScreen
- `AuthScreenType.login` → Menampilkan LoginScreen
- `AuthScreenType.register` → Menampilkan RegisterScreen

### 3. **Flow Validasi**

#### **Login Flow:**
1. User mengisi email dan password di `LoginScreen`
2. Ketika tombol "Login" ditekan, memanggil `authController.signInWithEmail()`
3. Jika berhasil:
   - Firebase Auth state berubah (user menjadi authenticated)
   - `authStateProvider` otomatis update
   - `AuthWrapper` mendeteksi perubahan dan menampilkan `HomeScreen`
   - **TIDAK PERLU Navigator** karena menggunakan reactive state management

#### **Register Flow:**
1. User mengisi form di `RegisterScreen`
2. Ketika tombol "Sign Up" ditekan, memanggil `authController.signUpWithEmail()`
3. Jika berhasil:
   - Firebase Auth membuat user baru dan otomatis sign in
   - `authStateProvider` otomatis update
   - `AuthWrapper` mendeteksi perubahan dan menampilkan `HomeScreen`
   - **TIDAK PERLU Navigator** karena menggunakan reactive state management

#### **Navigation Between Screens:**
- **Welcome → Login/Register**: Mengubah `authScreenProvider` state
- **Login ↔ Register**: Mengubah `authScreenProvider` state
- **Login/Register → Home**: Otomatis melalui `AuthWrapper` ketika auth state berubah

### 4. **Validasi Error Handling**

#### **Login Error:**
- Jika login gagal (email/password salah, user tidak ditemukan, dll):
  - `FirebaseAuthException` ditangkap
  - Error message ditampilkan via `SnackBar`
  - User tetap di `LoginScreen`

#### **Register Error:**
- Jika register gagal (email sudah terdaftar, password terlalu lemah, dll):
  - Error ditangkap dan ditampilkan via `SnackBar`
  - User tetap di `RegisterScreen`

### 5. **Keuntungan Pendekatan Ini**

✅ **Reactive**: UI otomatis update ketika auth state berubah
✅ **No Manual Navigation**: Tidak perlu Navigator.push/pushReplacement
✅ **Type Safe**: Menggunakan enum untuk screen type
✅ **Centralized Logic**: Semua logic auth di satu tempat (AuthWrapper)
✅ **Real-time**: Auth state selalu sinkron dengan Firebase Auth

### 6. **Cara Mengecek Status Login**

Untuk mengecek apakah user sudah login di widget lain:

```dart
final authState = ref.watch(authStateProvider);

authState.when(
  data: (user) {
    if (user != null) {
      // User sudah login
    } else {
      // User belum login
    }
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### 7. **Logout**

Ketika user logout:
1. Memanggil `authController.signOut()`
2. Firebase Auth state berubah (user menjadi null)
3. `authStateProvider` otomatis update
4. `AuthWrapper` otomatis menampilkan `WelcomeScreen`

## Kesimpulan

Sistem validasi ini menggunakan **reactive state management** dengan Riverpod dan Firebase Auth. Tidak ada navigasi manual yang diperlukan karena semua perubahan screen terjadi secara otomatis berdasarkan auth state.

