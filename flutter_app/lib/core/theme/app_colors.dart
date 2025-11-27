import 'package:flutter/material.dart';

// Kelas ini memegang semua palet warna untuk aplikasi
class AppColors {
  // --- WARNA UTAMA (PRIMARY) ---
  // (Sesuai Hex yang Anda berikan)
  static const Color primaryLight3 = Color(0xFFF5FDFF);
  static const Color primaryLight2 = Color(0xFF7FC7E1);
  static const Color primaryLight1 = Color(0xFF47C0ED);
  static const Color primary = Color(0xFF05B3F3); // Ini akan jadi warna utama
  static const Color primaryDark1 = Color(0xFF068ABA);
  static const Color primaryDark2 = Color(0xFF00597A);

  // --- WARNA NETRAL (Grayscale) ---
  // (Ini adalah palet grayscale yang saya sarankan,
  // bagus untuk teks, background, dan border)
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static const Color gray0 = Color(0xFFF8F9FA); // Untuk background
  static const Color gray1 = Color(0xFFE9ECEF); // Untuk border/divider
  static const Color gray2 = Color(0xFFADB5BD); // Untuk teks/ikon non-aktif
  static const Color gray3 = Color(0xFF6C757D); // Untuk sub-teks
  static const Color gray4 = Color(0xFF495057); // Untuk teks bodi
  static const Color gray5 = Color(0xFF212529); // Untuk judul

  // --- WARNA LAINNYA (Opsional) ---
  static const Color error = Color(0xFFD90429);
  static const Color success = Color(0xFF00A562);
  static const Color warning = Color(0xFFE89005);
}
