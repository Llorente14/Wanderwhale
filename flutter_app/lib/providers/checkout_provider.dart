// lib/providers/checkout_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Checkout State (untuk menyimpan data checkout sementara)
// ---------------------------------------------------------------------------

@immutable
class CheckoutState {
  const CheckoutState({
    this.paymentMethod,
    this.promoCode,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
    this.discountAmount = 0.0,
  });

  final String? paymentMethod;
  final String? promoCode;
  final String? contactName;
  final String? contactEmail;
  final String? contactPhone;
  final double discountAmount; // Jumlah diskon dalam currency

  // Helper untuk menghitung harga setelah diskon
  double getDiscountedPrice(double originalPrice) {
    if (discountAmount <= 0) return originalPrice;
    final discounted = originalPrice - discountAmount;
    return discounted > 0 ? discounted : 0;
  }

  // Helper untuk mendapatkan persentase diskon (untuk display)
  double getDiscountPercentage(double originalPrice) {
    if (originalPrice <= 0 || discountAmount <= 0) return 0;
    return (discountAmount / originalPrice) * 100;
  }

  CheckoutState copyWith({
    String? paymentMethod,
    String? promoCode,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    double? discountAmount,
  }) {
    return CheckoutState(
      paymentMethod: paymentMethod ?? this.paymentMethod,
      promoCode: promoCode ?? this.promoCode,
      contactName: contactName ?? this.contactName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  void reset() {
    // Reset akan dilakukan melalui notifier
  }
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier() : super(const CheckoutState());

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setPromoCode(String? code) {
    state = state.copyWith(promoCode: code);
  }

  /// Set discount amount (dipanggil dari screen dengan harga asli)
  /// Method ini akan membaca promoCode dari state saat ini
  void setDiscountAmount(double originalPrice) {
    if (state.promoCode == null || state.promoCode!.isEmpty) {
      // Jika tidak ada promo code, reset discount
      state = state.copyWith(discountAmount: 0.0);
      return;
    }

    // Generate random discount antara 5% - 25%
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final discountPercentage = 5.0 + (random / 100.0 * 20.0); // 5% - 25%
    final discountAmount = originalPrice * (discountPercentage / 100.0);
    
    state = state.copyWith(discountAmount: discountAmount);
  }

  /// Apply promo code dan generate discount dalam satu operasi
  /// Ini memastikan promoCode dan discountAmount di-set secara atomik
  void applyPromoCode(String code, double originalPrice) {
    if (code.isEmpty) {
      state = state.copyWith(promoCode: null, discountAmount: 0.0);
      return;
    }

    // Generate random discount antara 5% - 25%
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final discountPercentage = 5.0 + (random / 100.0 * 20.0); // 5% - 25%
    final discountAmount = originalPrice * (discountPercentage / 100.0);
    
    state = state.copyWith(
      promoCode: code,
      discountAmount: discountAmount,
    );
  }

  /// Clear discount (ketika promo code dihapus)
  void clearDiscount() {
    state = state.copyWith(discountAmount: 0.0, promoCode: null);
  }

  void setContactInfo({
    String? name,
    String? email,
    String? phone,
  }) {
    state = state.copyWith(
      contactName: name ?? state.contactName,
      contactEmail: email ?? state.contactEmail,
      contactPhone: phone ?? state.contactPhone,
    );
  }

  void reset() {
    state = const CheckoutState();
  }
}

final checkoutProvider =
    StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier();
});

// ---------------------------------------------------------------------------
// Transaction History (untuk menyimpan semua transaksi yang sudah selesai)
// ---------------------------------------------------------------------------

@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.type, // 'flight' or 'hotel'
    required this.title,
    required this.totalPrice,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.description,
  });

  final String id;
  final String type;
  final String title;
  final double totalPrice;
  final String currency;
  final String paymentMethod;
  final String status; // 'pending', 'completed', 'cancelled'
  final DateTime createdAt;
  final String? description;

  Transaction copyWith({
    String? id,
    String? type,
    String? title,
    double? totalPrice,
    String? currency,
    String? paymentMethod,
    String? status,
    DateTime? createdAt,
    String? description,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      totalPrice: totalPrice ?? this.totalPrice,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
    );
  }
}

@immutable
class TransactionHistoryState {
  const TransactionHistoryState({
    this.transactions = const [],
  });

  final List<Transaction> transactions;

  TransactionHistoryState copyWith({
    List<Transaction>? transactions,
  }) {
    return TransactionHistoryState(
      transactions: transactions ?? this.transactions,
    );
  }
}

class TransactionHistoryNotifier
    extends StateNotifier<TransactionHistoryState> {
  TransactionHistoryNotifier() : super(const TransactionHistoryState());

  void addTransaction(Transaction transaction) {
    final updated = [transaction, ...state.transactions];
    state = state.copyWith(transactions: updated);
  }

  void updateTransactionStatus(String id, String status) {
    final updated = state.transactions.map((t) {
      if (t.id == id) {
        return t.copyWith(status: status);
      }
      return t;
    }).toList();
    state = state.copyWith(transactions: updated);
  }

  List<Transaction> getTransactionsByType(String type) {
    return state.transactions.where((t) => t.type == type).toList();
  }

  void clear() {
    state = const TransactionHistoryState();
  }
}

final transactionHistoryProvider =
    StateNotifierProvider<TransactionHistoryNotifier, TransactionHistoryState>(
  (ref) => TransactionHistoryNotifier(),
);

