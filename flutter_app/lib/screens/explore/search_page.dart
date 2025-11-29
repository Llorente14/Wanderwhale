import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/destination_master_model.dart';
import '../../providers/app_providers.dart';
import '../../providers/wishlist_providers.dart';
import '../../widgets/login_required_popup.dart';
import '../destination/destination_detail.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize TextField dengan query dari provider saat page dibuka
    final currentQuery = ref.read(searchQueryProvider);
    if (currentQuery.isNotEmpty && _searchController.text != currentQuery) {
      _searchController.text = currentQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    // Update search query provider
    ref.read(searchQueryProvider.notifier).state = trimmedQuery;
    // Invalidate provider untuk memastikan search di-trigger
    ref.invalidate(destinationSearchProvider);
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResultsAsync = ref.watch(destinationSearchProvider);

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
              // Header Section with Gradient
              _SearchHeader(onBack: () => Navigator.of(context).maybePop()),
              // Search Bar and Results Section
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Search Bar Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Cari kota atau pengalaman',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppColors.gray3,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: AppColors.gray3,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          ref
                                                  .read(
                                                    searchQueryProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              '';
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: AppColors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppColors.gray1,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppColors.gray1,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              onChanged: (value) {
                                setState(
                                  () {},
                                ); // Update untuk show/hide clear button
                                // Auto-trigger search saat query >= 3 karakter
                                final trimmedValue = value.trim();
                                if (trimmedValue.length >= 3) {
                                  _handleSearch(trimmedValue);
                                } else if (trimmedValue.isEmpty) {
                                  ref.read(searchQueryProvider.notifier).state =
                                      '';
                                }
                              },
                              onSubmitted: (value) {
                                final trimmedValue = value.trim();
                                if (trimmedValue.isNotEmpty) {
                                  _handleSearch(trimmedValue);
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // Search Results Section
                      Expanded(
                        child: searchQuery.isEmpty
                            ? _buildEmptyState('Mulai eksplorasi kamu!')
                            : searchResultsAsync.when(
                                data: (destinations) {
                                  if (destinations.isEmpty) {
                                    return _buildEmptyState(
                                      'Tidak ada hasil untuk "$searchQuery"',
                                      subtitle:
                                          'Coba cari dengan kata kunci lain',
                                    );
                                  }
                                  return _buildSearchResults(
                                    destinations,
                                    searchQuery,
                                  );
                                },
                                loading: () => _buildLoadingState(),
                                error: (error, stackTrace) => _buildErrorState(
                                  error,
                                  onRetry: () {
                                    ref.invalidate(destinationSearchProvider);
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    List<DestinationMasterModel> destinations,
    String query,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            '${destinations.length} hasil ditemukan untuk "$query"',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray4,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: destinations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final destination = destinations[index];
              return _SearchResultCard(destination: destination);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _SearchResultSkeleton(),
    );
  }

  Widget _buildEmptyState(String message, {String? subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.gray3),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.gray5,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: AppColors.gray3),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat hasil pencarian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.gray5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 14, color: AppColors.gray3),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Search Result Card Component with Wishlist
class _SearchResultCard extends ConsumerStatefulWidget {
  const _SearchResultCard({required this.destination});

  final DestinationMasterModel destination;

  @override
  ConsumerState<_SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends ConsumerState<_SearchResultCard> {
  bool _isToggling = false;

  Future<void> _handleToggle() async {
    if (_isToggling) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      LoginRequiredPopup.show(
        context,
        message: 'Silakan login terlebih dahulu untuk menggunakan wishlist.',
      );
      return;
    }

    setState(() => _isToggling = true);
    final manager = ref.read(wishlistManagerProvider);
    try {
      await manager.toggle(widget.destination.destinationId);
      ref.invalidate(wishlistItemsProvider);
      ref.invalidate(wishlistStatusProvider(widget.destination.destinationId));
    } on DioException catch (error) {
      if (!mounted) return;
      final status = error.response?.statusCode;
      final message = status == 401
          ? 'Sesi kamu berakhir. Silakan login ulang.'
          : 'Gagal mengubah wishlist: ${error.message}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah wishlist: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(
      wishlistStatusProvider(widget.destination.destinationId),
    );

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                DestinationDetailPage(destination: widget.destination),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 150,
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
              Image.network(
                widget.destination.imageUrl,
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
              ),
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.destination.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.destination.rating > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.destination.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.destination.city}, ${widget.destination.country}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.destination.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.destination.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Wishlist Button
              Positioned(
                top: 10,
                right: 10,
                child: statusAsync.when(
                  data: (isWishlisted) => Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isWishlisted
                          ? const Color(0xFFFF4D6A).withOpacity(0.85)
                          : Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: isWishlisted
                            ? const Color(0xFFFF4D6A)
                            : Colors.white70,
                      ),
                    ),
                    child: IconButton(
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: _isToggling ? null : _handleToggle,
                      icon: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  loading: () => Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(color: Colors.white38),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white54),
                    ),
                    child: IconButton(
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: _isToggling ? null : _handleToggle,
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
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
}

// Header Component with Gradient
class _SearchHeader extends StatelessWidget {
  const _SearchHeader({required this.onBack});

  final VoidCallback onBack;

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
              onPressed: onBack,
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
                  'Explore Journey',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Temukan destinasi baru dan buat rencana perjalananmu',
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

// Loading Skeleton Component
class _SearchResultSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.gray1,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}
