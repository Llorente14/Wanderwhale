import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/wishlist_model.dart';
import '../../providers/wishlist_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/login_required_popup.dart';
import '../explore/search_page.dart';
import '../auth/login_screen.dart';

// ============================================================================
// ENUMS FOR SORT AND FILTER
// ============================================================================

enum SortOption { terbaru, terlama, aToZ, zToA, ratingTertinggi }

enum FilterOption { semua, rating40, rating45, indonesia, luarNegeri }

// ============================================================================
// MAIN WISHLIST SCREEN
// ============================================================================

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  String _searchQuery = '';
  SortOption _sortOption = SortOption.terbaru;
  FilterOption _filterOption = FilterOption.semua;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshWishlist() async {
    ref.invalidate(wishlistItemsProvider);
  }

  List<WishlistModel> _getFilteredAndSortedItems(List<WishlistModel> items) {
    // Apply search filter
    List<WishlistModel> filtered = items.where((item) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return item.destinationName.toLowerCase().contains(query) ||
          item.destinationCity?.toLowerCase().contains(query) == true ||
          item.destinationCountry?.toLowerCase().contains(query) == true;
    }).toList();

    // Apply filter option
    switch (_filterOption) {
      case FilterOption.semua:
        break;
      case FilterOption.rating40:
        filtered = filtered
            .where((item) => (item.destinationRating ?? 0) >= 4.0)
            .toList();
        break;
      case FilterOption.rating45:
        filtered = filtered
            .where((item) => (item.destinationRating ?? 0) >= 4.5)
            .toList();
        break;
      case FilterOption.indonesia:
        filtered = filtered
            .where((item) => item.destinationCountry == 'Indonesia')
            .toList();
        break;
      case FilterOption.luarNegeri:
        filtered = filtered
            .where((item) => item.destinationCountry != 'Indonesia')
            .toList();
        break;
    }

    // Apply sort option
    switch (_sortOption) {
      case SortOption.terbaru:
        filtered.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case SortOption.terlama:
        filtered.sort((a, b) => a.addedAt.compareTo(b.addedAt));
        break;
      case SortOption.aToZ:
        filtered.sort(
          (a, b) => a.destinationName.toLowerCase().compareTo(
            b.destinationName.toLowerCase(),
          ),
        );
        break;
      case SortOption.zToA:
        filtered.sort(
          (a, b) => b.destinationName.toLowerCase().compareTo(
            a.destinationName.toLowerCase(),
          ),
        );
        break;
      case SortOption.ratingTertinggi:
        filtered.sort((a, b) {
          final ratingA = a.destinationRating ?? 0;
          final ratingB = b.destinationRating ?? 0;
          return ratingB.compareTo(ratingA);
        });
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final wishlistAsync = ref.watch(wishlistItemsProvider);
    // Check auth state untuk menentukan apakah perlu tampilkan login required
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F6DC2), Color(0xFF0BC5EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const _WishlistHeader(),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _refreshWishlist,
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SearchBar(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _FilterSortRow(
                            sortOption: _sortOption,
                            filterOption: _filterOption,
                            onSortChanged: (option) {
                              setState(() {
                                _sortOption = option;
                              });
                            },
                            onFilterChanged: (option) {
                              setState(() {
                                _filterOption = option;
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          // Sama seperti tripsProvider, langsung watch wishlistItemsProvider
                          // API service sudah handle auth check dan return empty list jika user null
                          wishlistAsync.when(
                            data: (items) {
                              // Debug: Print items untuk troubleshooting
                              debugPrint(
                                '🔍 Wishlist items count: ${items.length}',
                              );
                              if (items.isNotEmpty) {
                                debugPrint(
                                  '🔍 First item: ${items.first.destinationName}',
                                );
                                debugPrint('🔍 Search query: "$_searchQuery"');
                                debugPrint('🔍 Filter option: $_filterOption');
                              }

                              // Jika user belum login dan items kosong, tampilkan login required
                              if (user == null && items.isEmpty) {
                                return const _LoginRequiredState();
                              }
                              // Jika user sudah login tapi items kosong, tampilkan empty state
                              if (items.isEmpty) {
                                return const _WishlistEmptyState();
                              }
                              // Tampilkan wishlist items
                              final filteredItems = _getFilteredAndSortedItems(
                                items,
                              );
                              debugPrint(
                                '🔍 Filtered items count: ${filteredItems.length}',
                              );

                              if (filteredItems.isEmpty) {
                                // Jika ada filter/search aktif, beri tahu user
                                if (_searchQuery.isNotEmpty ||
                                    _filterOption != FilterOption.semua) {
                                  return _EmptyFilterState(
                                    searchQuery: _searchQuery,
                                    filterOption: _filterOption,
                                    onClearFilter: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _searchController.clear();
                                        _filterOption = FilterOption.semua;
                                      });
                                    },
                                  );
                                }
                                return const _WishlistEmptyState();
                              }
                              return _WishlistGrid(
                                items: filteredItems,
                                onDelete: (item) async {
                                  await _handleDelete(item);
                                },
                              );
                            },
                            loading: () => const _WishlistLoadingGrid(),
                            error: (error, stack) {
                              // Jika error karena belum login (401), tampilkan login required
                              if (error is DioException &&
                                  error.response?.statusCode == 401) {
                                return const _LoginRequiredState();
                              }
                              // Jika user belum login, tampilkan login required
                              if (user == null) {
                                return const _LoginRequiredState();
                              }
                              // Error lainnya, tampilkan empty state
                              return const _WishlistEmptyState();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(WishlistModel item) async {
    // Check if user is logged in using authStateProvider
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      if (mounted) {
        LoginRequiredPopup.show(
          context,
          message: 'Silakan login terlebih dahulu untuk menggunakan wishlist.',
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus dari Wishlist'),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${item.destinationName} dari wishlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Use toggle to remove (backend delete endpoint expects destinationId)
        // Since item is in wishlist, toggle will remove it
        final manager = ref.read(wishlistManagerProvider);
        await manager.toggle(item.destinationId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil dihapus dari wishlist'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        // Refresh wishlist provider setelah delete
        ref.invalidate(wishlistItemsProvider);
        // Juga refresh untuk memastikan UI update
        await ref.read(wishlistItemsProvider.future);
      } on DioException catch (error) {
        if (mounted) {
          final message = error.response?.statusCode == 401
              ? 'Sesi berakhir. Silakan login ulang.'
              : 'Gagal menghapus: ${error.message}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppColors.error),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

// ============================================================================
// HEADER SECTION
// ============================================================================

class _WishlistHeader extends StatelessWidget {
  const _WishlistHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wishlist Saya',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Destinasi favorit yang ingin kamu kunjungi',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SEARCH BAR
// ============================================================================

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: AppColors.gray3),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Cari destinasi...',
                hintStyle: const TextStyle(color: AppColors.gray3),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: AppColors.gray3),
              onPressed: () {
                widget.controller.clear();
                widget.onChanged('');
              },
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// FILTER AND SORT ROW
// ============================================================================
class _FilterSortRow extends StatelessWidget {
  const _FilterSortRow({
    required this.sortOption,
    required this.filterOption,
    required this.onSortChanged,
    required this.onFilterChanged,
  });

  final SortOption sortOption;
  final FilterOption filterOption;
  final ValueChanged<SortOption> onSortChanged;
  final ValueChanged<FilterOption> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FilterDropdown(
            value: filterOption,
            onChanged: onFilterChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SortDropdown(value: sortOption, onChanged: onSortChanged),
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({required this.value, required this.onChanged});

  final FilterOption value;
  final ValueChanged<FilterOption> onChanged;

  String _getFilterLabel(FilterOption option) {
    switch (option) {
      case FilterOption.semua:
        return 'Semua';
      case FilterOption.rating40:
        return 'Rating ≥ 4.0';
      case FilterOption.rating45:
        return 'Rating ≥ 4.5';
      case FilterOption.indonesia:
        return 'Indonesia';
      case FilterOption.luarNegeri:
        return 'Luar Negeri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<FilterOption>(
      initialValue: value,
      onSelected: onChanged,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      color: AppColors.white,
      itemBuilder: (context) => [
        PopupMenuItem(value: FilterOption.semua, child: Text('Semua')),
        PopupMenuItem(
          value: FilterOption.rating40,
          child: Text('Rating ≥ 4.0'),
        ),
        PopupMenuItem(
          value: FilterOption.rating45,
          child: Text('Rating ≥ 4.5'),
        ),
        PopupMenuItem(value: FilterOption.indonesia, child: Text('Indonesia')),
        PopupMenuItem(
          value: FilterOption.luarNegeri,
          child: Text('Luar Negeri'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(color: AppColors.gray1.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _getFilterLabel(value),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.gray5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.gray1.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.filter_list,
                size: 18,
                color: AppColors.gray4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.value, required this.onChanged});

  final SortOption value;
  final ValueChanged<SortOption> onChanged;

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.terbaru:
        return 'Terbaru';
      case SortOption.terlama:
        return 'Terlama';
      case SortOption.aToZ:
        return 'A-Z';
      case SortOption.zToA:
        return 'Z-A';
      case SortOption.ratingTertinggi:
        return 'Rating Tertinggi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      initialValue: value,
      onSelected: onChanged,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      color: AppColors.white,
      itemBuilder: (context) => [
        PopupMenuItem(value: SortOption.terbaru, child: Text('Terbaru')),
        PopupMenuItem(value: SortOption.terlama, child: Text('Terlama')),
        PopupMenuItem(value: SortOption.aToZ, child: Text('A-Z')),
        PopupMenuItem(value: SortOption.zToA, child: Text('Z-A')),
        PopupMenuItem(
          value: SortOption.ratingTertinggi,
          child: Text('Rating Tertinggi'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(color: AppColors.gray1.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _getSortLabel(value),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.gray5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.gray1.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sort, size: 18, color: AppColors.gray4),
            ),
          ],
        ),
      ),
    );
  }
}
// ============================================================================
// WISHLIST GRID
// ============================================================================

class _WishlistGrid extends StatelessWidget {
  const _WishlistGrid({required this.items, required this.onDelete});

  final List<WishlistModel> items;
  final ValueChanged<WishlistModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _WishlistItemCard(
          item: items[index],
          onDelete: () => onDelete(items[index]),
        );
      },
    );
  }
}

// ============================================================================
// WISHLIST ITEM CARD
// ============================================================================

class _WishlistItemCard extends StatelessWidget {
  const _WishlistItemCard({required this.item, required this.onDelete});

  final WishlistModel item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (item.destinationImageUrl != null &&
                item.destinationImageUrl!.isNotEmpty)
              Image.network(
                item.destinationImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.gray1,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.gray3,
                    size: 32,
                  ),
                ),
              )
            else
              Container(
                color: AppColors.gray1,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.gray3,
                  size: 32,
                ),
              ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Rating
                  if (item.destinationRating != null &&
                      item.destinationRating! > 0)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          item.destinationRating!.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  if (item.destinationRating != null &&
                      item.destinationRating! > 0)
                    const SizedBox(height: 8),
                  // Destination name
                  Text(
                    item.destinationName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Location
                  Text(
                    '${item.destinationCity ?? '-'}, ${item.destinationCountry ?? '-'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Added date
                  Text(
                    'Ditambahkan ${DateFormat('dd MMM yyyy').format(item.addedAt)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Delete button
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.favorite,
                    color: Color(0xFFFF4D6A),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// LOADING STATE
// ============================================================================

class _WishlistLoadingGrid extends StatelessWidget {
  const _WishlistLoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.gray1,
            borderRadius: BorderRadius.circular(24),
          ),
        );
      },
    );
  }
}

// ============================================================================
// LOGIN REQUIRED STATE
// ============================================================================

class _LoginRequiredState extends StatelessWidget {
  const _LoginRequiredState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Login Diperlukan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Silakan login terlebih dahulu untuk mengakses wishlist Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.gray3),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              LoginRequiredPopup.show(
                context,
                message:
                    'Silakan login terlebih dahulu untuk mengakses wishlist Anda.',
                onLoginTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Login Sekarang',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EMPTY FILTER STATE (ketika filter/search tidak menemukan hasil)
// ============================================================================

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState({
    required this.searchQuery,
    required this.filterOption,
    required this.onClearFilter,
  });

  final String searchQuery;
  final FilterOption filterOption;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: AppColors.gray3),
          const SizedBox(height: 24),
          const Text(
            'Tidak Ada Hasil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getEmptyMessage(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.gray3),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onClearFilter,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Hapus Filter',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyMessage() {
    if (searchQuery.isNotEmpty && filterOption != FilterOption.semua) {
      return 'Tidak ada destinasi yang cocok dengan pencarian "$searchQuery" dan filter yang dipilih.';
    } else if (searchQuery.isNotEmpty) {
      return 'Tidak ada destinasi yang cocok dengan pencarian "$searchQuery".';
    } else if (filterOption != FilterOption.semua) {
      String filterText = '';
      switch (filterOption) {
        case FilterOption.rating40:
          filterText = 'Rating ≥ 4.0';
          break;
        case FilterOption.rating45:
          filterText = 'Rating ≥ 4.5';
          break;
        case FilterOption.indonesia:
          filterText = 'Indonesia';
          break;
        case FilterOption.luarNegeri:
          filterText = 'Luar Negeri';
          break;
        default:
          filterText = 'Filter yang dipilih';
      }
      return 'Tidak ada destinasi yang cocok dengan filter "$filterText".';
    }
    return 'Tidak ada hasil yang ditemukan.';
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _WishlistEmptyState extends StatelessWidget {
  const _WishlistEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 80, color: AppColors.gray3),
          const SizedBox(height: 24),
          const Text(
            'Wishlist Kosong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada destinasi yang disimpan. Mulai jelajahi dan simpan destinasi favoritmu!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.gray3),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SearchPage()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Jelajahi Destinasi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
