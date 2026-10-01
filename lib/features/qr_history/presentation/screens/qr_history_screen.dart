import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/core/utils/snackbar_helper.dart';
import '../../controllers/qr_history_controller.dart';
import '../../models/qr_item.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/qr_history_empty_state.dart';
import '../widgets/qr_history_tile.dart';
import 'qr_detail_screen.dart';

/// Screen providing browsable, searchable QR code history and favorites.
class QrHistoryScreen extends StatefulWidget {
  final int initialTabIndex;

  const QrHistoryScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<QrHistoryScreen> createState() => _QrHistoryScreenState();
}

class _QrHistoryScreenState extends State<QrHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _searchController.addListener(() {
      QrHistoryController.instance.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    QrHistoryController.instance.clearSearch();
    super.dispose();
  }

  Future<void> _openDetail(QrItem item) async {
    final result = await Navigator.of(context).push<QrItem>(
      MaterialPageRoute(
        builder: (_) => QrDetailScreen(item: item),
      ),
    );

    // If user tapped "Open in Generator", pass it back to main screen
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _handleDeleteItem(QrItem item) async {
    final confirmed = await DeleteConfirmationDialog.confirmDeleteItem(
      context,
      title: item.content,
    );

    if (confirmed && mounted) {
      await QrHistoryController.instance.deleteItem(item.id);
      if (mounted) {
        SnackBarHelper.showInfo(context, 'Record deleted.');
      }
    }
  }

  Future<void> _handleClearHistory() async {
    final controller = QrHistoryController.instance;
    final totalCount = controller.allItems.length;
    final favCount = controller.favoriteItems.length;

    if (totalCount == 0) {
      SnackBarHelper.showInfo(context, 'History is already empty.');
      return;
    }

    final preserveFavorites =
        await DeleteConfirmationDialog.confirmClearHistory(
      context,
      totalCount: totalCount,
      favoriteCount: favCount,
    );

    if (preserveFavorites != null && mounted) {
      await controller.clearHistory(preserveFavorites: preserveFavorites);
      if (mounted) {
        if (preserveFavorites) {
          SnackBarHelper.showSuccess(
            context,
            'Non-favorite history records cleared.',
          );
        } else {
          SnackBarHelper.showSuccess(context, 'All history records cleared.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: QrHistoryController.instance,
      builder: (context, _) {
        final controller = QrHistoryController.instance;
        final allItems = controller.allItems;
        final favItems = controller.favoriteItems;
        final filteredAll = controller.filteredHistoryItems;
        final filteredFavs = controller.filteredFavoriteItems;
        final isSearching = controller.isSearching;

        return Scaffold(
          appBar: AppBar(
            title: const Text('History & Favorites'),
            actions: [
              if (allItems.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  tooltip: 'Clear history',
                  onPressed: _handleClearHistory,
                ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                  indicatorColor: AppTheme.primaryColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text('All (${allItems.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite_rounded,
                              size: 18, color: Color(0xFFE11D48)),
                          const SizedBox(width: 8),
                          Text('Favorites (${favItems.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search records by content...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: isSearching
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    controller.clearSearch();
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF131B2E)
                              : Colors.white,
                        ),
                      ),
                    ),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 0: All History
                          _buildListTab(
                            items: filteredAll,
                            emptyType: EmptyStateType.history,
                            isSearching: isSearching,
                            searchQuery: controller.searchQuery,
                            onClearSearch: () {
                              _searchController.clear();
                              controller.clearSearch();
                            },
                          ),

                          // Tab 1: Favorites
                          _buildListTab(
                            items: filteredFavs,
                            emptyType: EmptyStateType.favorites,
                            isSearching: isSearching,
                            searchQuery: controller.searchQuery,
                            onClearSearch: () {
                              _searchController.clear();
                              controller.clearSearch();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListTab({
    required List<QrItem> items,
    required EmptyStateType emptyType,
    required bool isSearching,
    required String searchQuery,
    required VoidCallback onClearSearch,
  }) {
    if (items.isEmpty) {
      if (isSearching) {
        return QrHistoryEmptyState(
          type: EmptyStateType.search,
          searchQuery: searchQuery,
          onClearSearch: onClearSearch,
        );
      }
      return QrHistoryEmptyState(type: emptyType);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return QrHistoryTile(
          key: ValueKey(item.id),
          item: item,
          onTap: () => _openDetail(item),
          onToggleFavorite: () =>
              QrHistoryController.instance.toggleFavorite(item.id),
          onDelete: () => _handleDeleteItem(item),
        );
      },
    );
  }
}
