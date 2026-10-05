import 'package:flutter/material.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/services/qr_sharing_service.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/presentation/screens/preview/qr_preview_screen.dart';
import 'package:qrcode_generator/presentation/widgets/empty_state_view.dart';
import 'package:qrcode_generator/presentation/widgets/qr_render_view.dart';

class BulkResultsScreen extends StatefulWidget {
  final List<QrItem> items;
  final StorageService storageService;

  const BulkResultsScreen({
    super.key,
    required this.items,
    required this.storageService,
  });

  @override
  State<BulkResultsScreen> createState() => _BulkResultsScreenState();
}

class _BulkResultsScreenState extends State<BulkResultsScreen> {
  late List<QrItem> _items;
  final Set<String> _selectedIds = {};
  final Set<String> _savedIds = {};

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void dispose() {
    _selectedIds.clear();
    super.dispose();
  }

  bool get _isAllSelected =>
      _items.isNotEmpty && _selectedIds.length == _items.length;

  void _toggleSelectAll() {
    setState(() {
      if (_isAllSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(_items.map((e) => e.id));
      }
    });
  }

  Future<void> _saveAll() async {
    await widget.storageService.saveMultipleItems(_items);
    setState(() {
      _savedIds.addAll(_items.map((e) => e.id));
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Saved all ${_items.length} QR codes to history!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveSelected() async {
    final toSave = _items.where((e) => _selectedIds.contains(e.id)).toList();
    if (toSave.isEmpty) return;

    await widget.storageService.saveMultipleItems(toSave);
    setState(() {
      _savedIds.addAll(toSave.map((e) => e.id));
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Saved ${toSave.length} selected QR codes to history!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _favoriteSelected() async {
    final toSave = _items
        .where((e) => _selectedIds.contains(e.id))
        .map((e) => e.copyWith(isFavorite: true))
        .toList();

    if (toSave.isEmpty) return;

    await widget.storageService.saveMultipleItems(toSave);

    // Update local copies as favorite
    setState(() {
      for (int i = 0; i < _items.length; i++) {
        if (_selectedIds.contains(_items[i].id)) {
          _items[i] = _items[i].copyWith(isFavorite: true);
          _savedIds.add(_items[i].id);
        }
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.favorite_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Favorited & saved ${toSave.length} QR codes to history!'),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _discardSelected() {
    final count = _selectedIds.length;
    if (count == 0) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Discard $count Selected QR Codes?'),
        content: const Text(
          'This will remove the selected codes from this view. Any codes already saved to history will remain safe in your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _items.removeWhere((e) => _selectedIds.contains(e.id));
                _selectedIds.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed $count entries from current view'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Discard Selected'),
          ),
        ],
      ),
    );
  }

  void _confirmDiscardAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard All Generated Codes?'),
        content: const Text(
          'Any QR codes not yet saved to history will be lost. Previously saved codes remain untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Viewing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _selectedIds.clear();
              Navigator.pop(context);
            },
            child: const Text('Discard All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAllSaved = _items.isNotEmpty && _savedIds.length >= _items.length;
    final selectedCount = _selectedIds.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bulk Results (${_items.length})'),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Discard All',
              onPressed: _confirmDiscardAll,
            ),
        ],
      ),
      body: SafeArea(
        child: _items.isEmpty
            ? Center(
                child: EmptyStateView(
                  icon: Icons.qr_code_2_rounded,
                  title: 'No Bulk QR Codes Remaining',
                  message:
                      'All generated codes have either been saved to your history or discarded.',
                  buttonText: 'Back to Bulk Creator',
                  onButtonPressed: () => Navigator.pop(context),
                ),
              )
            : Column(
                children: [
                  // Multi-select & Status Control Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Select All Checkbox / Toggle
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _toggleSelectAll,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  _isAllSelected
                                      ? Icons.check_box_rounded
                                      : (_selectedIds.isNotEmpty
                                          ? Icons.indeterminate_check_box_rounded
                                          : Icons.check_box_outline_blank_rounded),
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isAllSelected ? 'Deselect' : 'Select All',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Count chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$selectedCount of ${_items.length} selected',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Save All Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAllSaved
                                ? AppColors.success
                                : AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: const Size(0, 32),
                          ),
                          onPressed: isAllSaved ? null : _saveAll,
                          icon: Icon(
                            isAllSaved
                                ? Icons.check_rounded
                                : Icons.save_rounded,
                            size: 16,
                          ),
                          label: Text(
                            isAllSaved ? 'Saved' : 'Save All',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Selection Action Bar (when 1 or more items selected)
                  if (selectedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$selectedCount Selected:',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          // Save Selected
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: const Size(0, 28),
                            ),
                            icon: const Icon(Icons.bookmark_add_outlined,
                                size: 16),
                            label: const Text('Save',
                                style: TextStyle(fontSize: 12)),
                            onPressed: _saveSelected,
                          ),
                          const SizedBox(width: 4),
                          // Favorite Selected
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: const Size(0, 28),
                              foregroundColor: AppColors.error,
                            ),
                            icon: const Icon(Icons.favorite_rounded,
                                size: 16, color: AppColors.error),
                            label: const Text('Favorite',
                                style: TextStyle(fontSize: 12)),
                            onPressed: _favoriteSelected,
                          ),
                          const SizedBox(width: 4),
                          // Discard Selected
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: const Size(0, 28),
                              foregroundColor: AppColors.error,
                            ),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 16, color: AppColors.error),
                            label: const Text('Discard',
                                style: TextStyle(fontSize: 12)),
                            onPressed: _discardSelected,
                          ),
                        ],
                      ),
                    ),

                  // Scrollable List of Generated QR Cards
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final typeColor = item.type.color;
                        final isSelected = _selectedIds.contains(item.id);
                        final isSaved = _savedIds.contains(item.id);

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QrPreviewScreen(
                                    item: item,
                                    storageService: widget.storageService,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Selection Checkbox
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedIds.add(item.id);
                                        } else {
                                          _selectedIds.remove(item.id);
                                        }
                                      });
                                    },
                                  ),

                                  // QR thumbnail preview
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 54,
                                      height: 54,
                                      color:
                                          item.customization.backgroundColor,
                                      padding: const EdgeInsets.all(4),
                                      child: Center(
                                        child: QrRenderView(
                                          data: item.rawPayload,
                                          customization: item.customization,
                                          size: 46,
                                          showContainer: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: typeColor.withValues(
                                                    alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.type.shortName,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: typeColor,
                                                ),
                                              ),
                                            ),
                                            if (isSaved) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.success
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.check_rounded,
                                                      size: 10,
                                                      color: AppColors.success,
                                                    ),
                                                    SizedBox(width: 2),
                                                    Text(
                                                      'Saved',
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            AppColors.success,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.rawPayload,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Individual Favorite Button
                                  IconButton(
                                    icon: Icon(
                                      item.isFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 18,
                                      color: item.isFavorite
                                          ? AppColors.error
                                          : Colors.grey,
                                    ),
                                    tooltip: item.isFavorite
                                        ? 'Favorited'
                                        : 'Favorite',
                                    onPressed: () async {
                                      final updated = item.copyWith(
                                          isFavorite: !item.isFavorite);
                                      await widget.storageService
                                          .saveItem(updated);
                                      setState(() {
                                        _items[index] = updated;
                                        _savedIds.add(updated.id);
                                      });
                                    },
                                  ),

                                  // Individual Share button
                                  IconButton(
                                    icon: const Icon(Icons.share_rounded,
                                        size: 18),
                                    tooltip: 'Share',
                                    onPressed: () {
                                      QrSharingService.shareText(
                                        text: item.rawPayload,
                                        subject: item.title,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
