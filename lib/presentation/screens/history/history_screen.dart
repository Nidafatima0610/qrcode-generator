import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';
import 'package:qrcode_generator/core/models/scan_item.dart';
import 'package:qrcode_generator/core/services/qr_sharing_service.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/presentation/widgets/qr_card.dart';
import 'package:qrcode_generator/presentation/widgets/empty_state_view.dart';
import 'package:qrcode_generator/presentation/screens/preview/qr_preview_screen.dart';
import 'package:qrcode_generator/presentation/screens/scanner/scan_result_screen.dart';

enum HistorySortOption {
  newest,
  oldest,
  alphabetical;

  String get label {
    switch (this) {
      case HistorySortOption.newest:
        return 'Newest First';
      case HistorySortOption.oldest:
        return 'Oldest First';
      case HistorySortOption.alphabetical:
        return 'Alphabetical (A-Z)';
    }
  }
}

class HistoryScreen extends StatefulWidget {
  final StorageService storageService;
  final Function(int tabIndex, [QrType? initialType]) onNavigateToTab;
  final int initialSubTab; // 0 = Generated, 1 = Favorites, 2 = Scans

  const HistoryScreen({
    super.key,
    required this.storageService,
    required this.onNavigateToTab,
    this.initialSubTab = 0,
  });

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  QrType? _selectedFilterType;
  HistorySortOption _currentSort = HistorySortOption.newest;

  // Multi-select state
  bool _isSelectionMode = false;
  final Set<String> _selectedItemIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialSubTab,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging && _isSelectionMode) {
        setState(() {
          _isSelectionMode = false;
          _selectedItemIds.clear();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSubTab != widget.initialSubTab) {
      _tabController.animateTo(widget.initialSubTab);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void switchTab(int index) {
    if (index >= 0 && index < 3) {
      _tabController.animateTo(index);
    }
  }

  void _confirmDeleteSingle(BuildContext context, QrItem item) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete QR Code?'),
        content: Text(
          'Are you sure you want to permanently delete "${item.title}" from your history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await widget.storageService.deleteItem(item.id);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${item.title}"'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelected(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final count = _selectedItemIds.length;
    if (count == 0) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Delete $count Selected Items?'),
        content: Text(
          'Are you sure you want to delete $count selected QR codes? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await widget.storageService.deleteMultiple(_selectedItemIds.toList());
              setState(() {
                _isSelectionMode = false;
                _selectedItemIds.clear();
              });
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Deleted $count items'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete Selected'),
          ),
        ],
      ),
    );
  }

  void _confirmClearGeneratedHistory(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    bool keepFavorites = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Clear QR History?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will remove generated QR codes from your history.',
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: keepFavorites,
                activeColor: AppColors.primary,
                title: const Text(
                  'Keep favorite QR codes safe',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Favorite QR codes will not be deleted',
                  style: TextStyle(fontSize: 11.5),
                ),
                onChanged: (val) {
                  setDialogState(() => keepFavorites = val ?? true);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await widget.storageService.clearHistory(
                  preserveFavorites: keepFavorites,
                );
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(keepFavorites
                          ? 'History cleared (favorites preserved)'
                          : 'All QR history cleared'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Clear History'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearScanHistory(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear Scan History?'),
        content: const Text(
          'Are you sure you want to permanently delete all scanned QR codes? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await widget.storageService.clearScanHistory();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Scan history cleared'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Clear All Scans'),
          ),
        ],
      ),
    );
  }

  List<QrItem> _filterAndSort(List<QrItem> items) {
    final query = _searchController.text.trim().toLowerCase();

    var filtered = items.where((item) {
      final matchesType =
          _selectedFilterType == null || item.type == _selectedFilterType;
      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.rawPayload.toLowerCase().contains(query) ||
          item.type.label.toLowerCase().contains(query);
      return matchesType && matchesSearch;
    }).toList();

    switch (_currentSort) {
      case HistorySortOption.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case HistorySortOption.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case HistorySortOption.alphabetical:
        filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return filtered;
  }

  List<ScanItem> _filterScanItems(List<ScanItem> items) {
    final query = _searchController.text.trim().toLowerCase();

    return items.where((item) {
      final matchesType =
          _selectedFilterType == null || item.detectedType == _selectedFilterType;
      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.rawContent.toLowerCase().contains(query) ||
          item.detectedType.label.toLowerCase().contains(query);
      return matchesType && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.storageService,
      builder: (context, _) {
        final generatedItems = widget.storageService.history;
        final favoriteItems = widget.storageService.favorites;
        final scanItems = widget.storageService.scanHistory;

        return Scaffold(
          appBar: AppBar(
            title: Text(_isSelectionMode
                ? '${_selectedItemIds.length} Selected'
                : 'QR Management'),
            leading: _isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedItemIds.clear();
                      });
                    },
                  )
                : null,
            actions: [
              if (_isSelectionMode) ...[
                // Select All / Deselect All
                IconButton(
                  icon: Icon(_selectedItemIds.length == generatedItems.length
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded),
                  tooltip: _selectedItemIds.length == generatedItems.length
                      ? 'Deselect All'
                      : 'Select All',
                  onPressed: () {
                    setState(() {
                      if (_selectedItemIds.length == generatedItems.length) {
                        _selectedItemIds.clear();
                      } else {
                        _selectedItemIds.addAll(generatedItems.map((e) => e.id));
                      }
                    });
                  },
                ),
                // Delete selected
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: AppColors.error),
                  tooltip: 'Delete Selected',
                  onPressed: _selectedItemIds.isEmpty
                      ? null
                      : () => _confirmDeleteSelected(context),
                ),
              ] else ...[
                // Sort Menu
                PopupMenuButton<HistorySortOption>(
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'Sort List',
                  onSelected: (val) => setState(() => _currentSort = val),
                  itemBuilder: (context) => HistorySortOption.values.map((opt) {
                    return PopupMenuItem(
                      value: opt,
                      child: Row(
                        children: [
                          Icon(
                            _currentSort == opt
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 18,
                            color: _currentSort == opt ? AppColors.primary : null,
                          ),
                          const SizedBox(width: 8),
                          Text(opt.label),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                // Multi-select toggle button (for Generated tab)
                if (_tabController.index == 0 && generatedItems.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.checklist_rounded),
                    tooltip: 'Select Multiple',
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = true;
                      });
                    },
                  ),

                // Clear History Button
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  tooltip: 'Clear History',
                  onPressed: () {
                    if (_tabController.index == 2) {
                      if (scanItems.isNotEmpty) {
                        _confirmClearScanHistory(context);
                      }
                    } else {
                      if (generatedItems.isNotEmpty) {
                        _confirmClearGeneratedHistory(context);
                      }
                    }
                  },
                ),
              ],
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              tabs: [
                Tab(
                  text: 'Generated (${generatedItems.length})',
                  icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                ),
                Tab(
                  text: 'Favorites (${favoriteItems.length})',
                  icon: const Icon(Icons.favorite_rounded, size: 20),
                ),
                Tab(
                  text: 'Scans (${scanItems.length})',
                  icon: const Icon(Icons.camera_alt_rounded, size: 20),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // 1. Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by title, URL, type, or text...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // 2. Filter Chips
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip(
                      label: 'All Formats',
                      isSelected: _selectedFilterType == null,
                      onTap: () => setState(() => _selectedFilterType = null),
                    ),
                    ...QrType.values.map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _buildFilterChip(
                          label: type.shortName,
                          isSelected: _selectedFilterType == type,
                          color: type.color,
                          onTap: () => setState(() {
                            _selectedFilterType =
                                _selectedFilterType == type ? null : type;
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 3. Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Generated QR
                    _buildGeneratedTab(generatedItems),

                    // Tab 2: Favorites
                    _buildFavoritesTab(favoriteItems),

                    // Tab 3: Scanned QR
                    _buildScansTab(scanItems),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= TAB 1: GENERATED QR =================
  Widget _buildGeneratedTab(List<QrItem> allItems) {
    if (allItems.isEmpty) {
      return EmptyStateView(
        icon: Icons.qr_code_2_rounded,
        title: 'No Generated QR Codes',
        message: 'Codes you create will automatically appear here. Try creating a custom code now!',
        buttonText: 'Create QR Code',
        onButtonPressed: () => widget.onNavigateToTab(1),
      );
    }

    final filtered = _filterAndSort(allItems);

    if (filtered.isEmpty) {
      return _buildSearchEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = filtered[index];
        final isSelected = _selectedItemIds.contains(item.id);

        return QrCard(
          item: item,
          showDelete: true,
          isSelectionMode: _isSelectionMode,
          isSelected: isSelected,
          onSelectChanged: (val) {
            setState(() {
              if (val == true) {
                _selectedItemIds.add(item.id);
              } else {
                _selectedItemIds.remove(item.id);
              }
            });
          },
          onFavoriteToggle: () async {
            await widget.storageService.toggleFavorite(item.id);
          },
          onEdit: () {
            widget.onNavigateToTab(1, item.type);
          },
          onDelete: () => _confirmDeleteSingle(context, item),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QrPreviewScreen(
                  item: item,
                  storageService: widget.storageService,
                  onEdit: () => widget.onNavigateToTab(1, item.type),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= TAB 2: FAVORITES =================
  Widget _buildFavoritesTab(List<QrItem> favorites) {
    if (favorites.isEmpty) {
      return EmptyStateView(
        icon: Icons.favorite_border_rounded,
        title: 'No Favorites Yet',
        message: 'Tap the heart icon on any QR code in preview or history to pin your most essential codes here for instant access!',
        buttonText: 'Create a QR Code',
        onButtonPressed: () => widget.onNavigateToTab(1),
      );
    }

    final filtered = _filterAndSort(favorites);

    if (filtered.isEmpty) {
      return _buildSearchEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = filtered[index];

        return QrCard(
          item: item,
          showDelete: true,
          onFavoriteToggle: () async {
            await widget.storageService.toggleFavorite(item.id);
          },
          onEdit: () {
            widget.onNavigateToTab(1, item.type);
          },
          onDelete: () => _confirmDeleteSingle(context, item),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QrPreviewScreen(
                  item: item,
                  storageService: widget.storageService,
                  onEdit: () => widget.onNavigateToTab(1, item.type),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= TAB 3: SCANS =================
  Widget _buildScansTab(List<ScanItem> scanItems) {
    if (scanItems.isEmpty) {
      return EmptyStateView(
        icon: Icons.qr_code_scanner_rounded,
        title: 'No Scanned QR Codes',
        message: 'Point your camera at any QR code using the Scanner to decode and save records automatically!',
        buttonText: 'Open Scanner',
        onButtonPressed: () => widget.onNavigateToTab(3),
      );
    }

    final filtered = _filterScanItems(scanItems);

    if (filtered.isEmpty) {
      return _buildSearchEmptyState();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = filtered[index];
        final typeColor = item.detectedType.color;
        final formattedDate =
            DateFormat('MMM d, y • h:mm a').format(item.scannedAt);

        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScanResultScreen(
                    scanItem: item,
                    storageService: widget.storageService,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Type Icon Container
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.detectedType.icon,
                        color: typeColor, size: 22),
                  ),
                  const SizedBox(width: 14),

                  // Metadata & Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.detectedType.shortName,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: typeColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.rawContent,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    onSelected: (val) async {
                      if (val == 'view') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScanResultScreen(
                              scanItem: item,
                              storageService: widget.storageService,
                            ),
                          ),
                        );
                      } else if (val == 'copy') {
                        QrSharingService.copyToClipboard(
                          context,
                          item.rawContent,
                          message: 'Scanned content copied!',
                        );
                      } else if (val == 'share') {
                        QrSharingService.shareText(
                          text: item.rawContent,
                          subject: item.title,
                        );
                      } else if (val == 'delete') {
                        await widget.storageService.deleteScanItem(item.id);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Copy Content'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Share Content'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 14),
            const Text(
              'No Matching Results',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing your search terms or clearing the format filter.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _selectedFilterType = null);
              },
              child: const Text('Reset Search & Filter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = color ?? AppColors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
