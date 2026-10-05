import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';
import 'package:qrcode_generator/core/models/scan_item.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/presentation/screens/create/create_screen.dart';
import 'package:qrcode_generator/presentation/screens/preview/qr_preview_screen.dart';
import 'package:qrcode_generator/presentation/screens/scanner/scan_result_screen.dart';
import 'package:qrcode_generator/presentation/widgets/empty_state_view.dart';
import 'package:qrcode_generator/presentation/widgets/qr_card.dart';

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
    final isScans = _tabController.index == 2;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Delete $count Selected Items?'),
        content: Text(
          isScans
              ? 'Are you sure you want to delete $count selected scan records? This action cannot be undone.'
              : 'Are you sure you want to delete $count selected QR codes? This action cannot be undone.',
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
              if (isScans) {
                await widget.storageService
                    .deleteMultipleScanItems(_selectedItemIds.toList());
              } else {
                await widget.storageService
                    .deleteMultiple(_selectedItemIds.toList());
              }
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
        filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return filtered;
  }

  Map<String, List<QrItem>> _groupByDate(List<QrItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<QrItem>> groups = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    for (final item in items) {
      final itemDate = DateTime(
          item.createdAt.year, item.createdAt.month, item.createdAt.day);
      if (itemDate.isAtSameMomentAs(today) || itemDate.isAfter(today)) {
        groups['Today']!.add(item);
      } else if (itemDate.isAtSameMomentAs(yesterday)) {
        groups['Yesterday']!.add(item);
      } else {
        groups['Earlier']!.add(item);
      }
    }

    groups.removeWhere((key, list) => list.isEmpty);
    return groups;
  }

  List<ScanItem> _filterScanItems(List<ScanItem> items) {
    final query = _searchController.text.trim().toLowerCase();

    var filtered = items.where((item) {
      final matchesType = _selectedFilterType == null ||
          item.detectedType == _selectedFilterType;
      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.rawContent.toLowerCase().contains(query) ||
          item.detectedType.label.toLowerCase().contains(query);
      return matchesType && matchesSearch;
    }).toList();

    switch (_currentSort) {
      case HistorySortOption.newest:
        filtered.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
        break;
      case HistorySortOption.oldest:
        filtered.sort((a, b) => a.scannedAt.compareTo(b.scannedAt));
        break;
      case HistorySortOption.alphabetical:
        filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return filtered;
  }

  void _duplicateItem(QrItem item) async {
    final duplicate = item.copyWith(
      id: const Uuid().v4(),
      title: 'Copy of ${item.title}',
      createdAt: DateTime.now(),
      isFavorite: false,
    );
    await widget.storageService.saveItem(duplicate);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duplicated "${duplicate.title}"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _regenerateItem(QrItem item) async {
    final updated = item.copyWith(createdAt: DateTime.now());
    await widget.storageService.saveItem(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR timestamp regenerated!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _editItem(QrItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateScreen(
          storageService: widget.storageService,
          initialType: item.type,
          editingItem: item,
        ),
      ),
    );
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

        final isFavTab = _tabController.index == 1;
        final isScansTab = _tabController.index == 2;
        final List<dynamic> currentActiveItems = isScansTab
            ? scanItems
            : (isFavTab ? favoriteItems : generatedItems);

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
                  icon: Icon(_selectedItemIds.length == currentActiveItems.length
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded),
                  tooltip:
                      _selectedItemIds.length == currentActiveItems.length
                          ? 'Deselect All'
                          : 'Select All',
                  onPressed: () {
                    setState(() {
                      if (_selectedItemIds.length ==
                          currentActiveItems.length) {
                        _selectedItemIds.clear();
                      } else {
                        _selectedItemIds.addAll(
                            currentActiveItems.map((e) => e.id as String));
                      }
                    });
                  },
                ),
                // Favorite / Unfavorite selected (only on Generated and Favorites tabs)
                if (!isScansTab) ...[
                  if (!isFavTab)
                    IconButton(
                      icon: const Icon(Icons.favorite_rounded,
                          color: AppColors.error),
                      tooltip: 'Favorite Selected',
                      onPressed: _selectedItemIds.isEmpty
                          ? null
                          : () async {
                              await widget.storageService.toggleFavoritesBulk(
                                  _selectedItemIds.toList(), true);
                              setState(() {
                                _isSelectionMode = false;
                                _selectedItemIds.clear();
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Marked selected as favorites'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.favorite_border_rounded,
                          color: Colors.amber),
                      tooltip: 'Unfavorite Selected',
                      onPressed: _selectedItemIds.isEmpty
                          ? null
                          : () async {
                              await widget.storageService.toggleFavoritesBulk(
                                  _selectedItemIds.toList(), false);
                              setState(() {
                                _isSelectionMode = false;
                                _selectedItemIds.clear();
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Removed from favorites (kept in history)'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                    ),
                ],
                // Delete selected
                IconButton(
                  icon:
                      const Icon(Icons.delete_rounded, color: AppColors.error),
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
                  itemBuilder: (context) =>
                      HistorySortOption.values.map((opt) {
                    return PopupMenuItem(
                      value: opt,
                      child: Row(
                        children: [
                          Icon(
                            _currentSort == opt
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 18,
                            color:
                                _currentSort == opt ? AppColors.primary : null,
                          ),
                          const SizedBox(width: 8),
                          Text(opt.label),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                // Multi-select toggle button (for all tabs when active list is not empty)
                if (currentActiveItems.isNotEmpty)
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
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text('Generated (${generatedItems.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Favorites (${favoriteItems.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text('Scans (${scanItems.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // 1. Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: _tabController.index == 2
                        ? 'Search scanned QR codes...'
                        : 'Search titles, formats, URLs...',
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
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ),

              // 2. Format Category Filter Chips
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
                    // Tab 1: Generated QR (Date Grouped)
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

  // ================= TAB 1: GENERATED QR (DATE GROUPED) =================
  Widget _buildGeneratedTab(List<QrItem> allItems) {
    if (allItems.isEmpty) {
      return EmptyStateView(
        icon: Icons.qr_code_2_rounded,
        title: 'No Generated QR Codes',
        message:
            'Codes you create will automatically appear here. Try creating a custom code now!',
        buttonText: 'Create QR Code',
        onButtonPressed: () => widget.onNavigateToTab(1),
      );
    }

    final filtered = _filterAndSort(allItems);

    if (filtered.isEmpty) {
      return _buildSearchEmptyState();
    }

    // Date grouping: Today, Yesterday, Earlier
    final dateGroups = _groupByDate(filtered);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: dateGroups.entries.map((group) {
        final groupTitle = group.key;
        final groupItems = group.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    groupTitle == 'Today'
                        ? Icons.today_rounded
                        : (groupTitle == 'Yesterday'
                            ? Icons.history_rounded
                            : Icons.calendar_month_rounded),
                    size: 15,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$groupTitle (${groupItems.length})',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Divider()),
                ],
              ),
            ),

            // Items in group
            ...groupItems.map((item) {
              final isSelected = _selectedItemIds.contains(item.id);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: QrCard(
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
                  onEdit: () => _editItem(item),
                  onDuplicate: () => _duplicateItem(item),
                  onRegenerate: () => _regenerateItem(item),
                  onDelete: () => _confirmDeleteSingle(context, item),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QrPreviewScreen(
                          item: item,
                          storageService: widget.storageService,
                          onEdit: () => _editItem(item),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  // ================= TAB 2: FAVORITES =================
  Widget _buildFavoritesTab(List<QrItem> favorites) {
    if (favorites.isEmpty) {
      return EmptyStateView(
        icon: Icons.favorite_border_rounded,
        title: 'No Favorites Yet',
        message:
            'Tap the heart icon on any QR code in preview or history to pin your most essential codes here for instant access!',
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
          onEdit: () => _editItem(item),
          onDuplicate: () => _duplicateItem(item),
          onRegenerate: () => _regenerateItem(item),
          onDelete: () => _confirmDeleteSingle(context, item),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QrPreviewScreen(
                  item: item,
                  storageService: widget.storageService,
                  onEdit: () => _editItem(item),
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
        message:
            'Point your camera at any QR code using the Scanner to decode and save records automatically!',
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
        final isSelected = _selectedItemIds.contains(item.id);

        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              if (_isSelectionMode) {
                setState(() {
                  if (isSelected) {
                    _selectedItemIds.remove(item.id);
                  } else {
                    _selectedItemIds.add(item.id);
                  }
                });
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScanResultScreen(
                      scanItem: item,
                      storageService: widget.storageService,
                    ),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  if (_isSelectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedItemIds.add(item.id);
                          } else {
                            _selectedItemIds.remove(item.id);
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                  ],

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
                        const SizedBox(height: 6),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle.isNotEmpty
                              ? item.subtitle
                              : item.rawContent,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (!_isSelectionMode) ...[
                    // Delete Scan Record
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 19),
                      tooltip: 'Delete scan record',
                      onPressed: () async {
                        await widget.storageService.deleteScanItem(item.id);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? chipColor
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
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
    );
  }

  Widget _buildSearchEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No Matching Results',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try adjusting your search query or removing the active format filter.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
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
}
