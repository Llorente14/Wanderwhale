// lib/core/utils/formatters.dart

import 'package:intl/intl.dart';

class Formatters {
  // Cara Klasik: Formatters.formatRupiah(50000)
  static String formatRupiah(num number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }
}

// Cara Pakai: myPrice.toIDR()
extension CurrencyExtension on num {
  String toIDR() {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(this);
  }
}
