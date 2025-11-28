// lib/providers/wishlist_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wishlist_model.dart';
import '../services/api_service.dart';
import 'app_providers.dart';

final wishlistItemsProvider =
    FutureProvider.autoDispose<List<WishlistModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getWishlistItems();
});

final wishlistManagerProvider = Provider<WishlistManager>((ref) {
  final api = ref.watch(apiServiceProvider);
  return WishlistManager(api);
});

class WishlistManager {
  WishlistManager(this._api);

  final ApiService _api;

  Future<bool> toggle(String destinationId) {
    return _api.toggleWishlist(destinationId);
  }

  Future<void> remove(String wishlistId) {
    return _api.deleteWishlistItem(wishlistId);
  }
}

