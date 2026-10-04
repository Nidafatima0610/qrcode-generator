import 'package:flutter/material.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/presentation/widgets/qr_card.dart';
import 'package:qrcode_generator/presentation/widgets/empty_state_view.dart';
import 'package:qrcode_generator/presentation/screens/preview/qr_preview_screen.dart';

class HistoryScreen extends StatefulWidget {
  final StorageService storageService;
  final Function(int tabIndex, [QrType? initialType]) onNavigateToTab;

  const HistoryScreen({
    super.key,
    required this.storageService,
    required this.onNavigateToTab,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  QrType? _selectedFilterType; // null means 'All'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, QrItem item) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete QR Code?'),
        content: Text(
          'Are you sure you want to permanently remove "${item.title}" from your generation history?',
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

  void _confirmClearAll(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text(
          'This will permanently delete all generated and saved QR codes from this device. This action cannot be undone.',
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
              await widget.storageService.clearHistory();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('All history cleared'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR History'),
        actions: [
          ListenableBuilder(
            listenable: widget.storageService,
            builder: (context, _) {
              if (widget.storageService.history.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                tooltip: 'Clear All History',
                onPressed: () => _confirmClearAll(context),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.storageService,
          builder: (context, _) {
            final allItems = widget.storageService.history;

            if (allItems.isEmpty) {
              return EmptyStateView(
                icon: Icons.history_rounded,
                title: 'No History Found',
                message:
                    'QR codes you generate or save will automatically appear here. Start creating your first code!',
                buttonText: 'Create QR Code',
                onButtonPressed: () => widget.onNavigateToTab(1),
              );
            }

            // Apply search & type filters
            final searchQuery = _searchController.text.trim().toLowerCase();
            final filteredItems = allItems.where((item) {
              final matchesType = _selectedFilterType == null ||
                  item.type == _selectedFilterType;
              final matchesSearch = searchQuery.isEmpty ||
                  item.title.toLowerCase().contains(searchQuery) ||
                  item.subtitle.toLowerCase().contains(searchQuery) ||
                  item.rawPayload.toLowerCase().contains(searchQuery);
              return matchesType && matchesSearch;
            }).toList();

            return Column(
              children: [
                // 1. Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search history by title, URL or text...',
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

                // 2. Type Filter Chips
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    children: [
                      _buildFilterChip(
                        label: 'All (${allItems.length})',
                        isSelected: _selectedFilterType == null,
                        onTap: () => setState(() => _selectedFilterType = null),
                      ),
                      ...QrType.values.map((type) {
                        final count =
                            allItems.where((e) => e.type == type).length;
                        if (count == 0 && _selectedFilterType != type) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildFilterChip(
                            label: '${type.shortName} ($count)',
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
                const SizedBox(height: 10),

                // 3. Filtered Results or Search Empty State
                Expanded(
                  child: filteredItems.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No matching QR codes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Try adjusting your search query or clear the type filter.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _selectedFilterType = null;
                                    });
                                  },
                                  child: const Text('Reset Search & Filter'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return QrCard(
                              item: item,
                              showDelete: true,
                              onDelete: () => _confirmDelete(context, item),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QrPreviewScreen(
                                      item: item,
                                      storageService: widget.storageService,
                                      onEdit: () {
                                        widget.onNavigateToTab(1, item.type);
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
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
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
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
              fontSize: 12.5,
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
