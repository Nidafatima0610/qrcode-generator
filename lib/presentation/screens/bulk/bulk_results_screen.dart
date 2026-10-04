import 'package:flutter/material.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/services/qr_sharing_service.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/presentation/screens/preview/qr_preview_screen.dart';
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
  bool _isSavedAll = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  Future<void> _saveAll() async {
    await widget.storageService.saveMultipleItems(_items);
    setState(() => _isSavedAll = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
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

  void _confirmDiscard() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Generated Codes?'),
        content: const Text(
          'Any QR codes not saved to history will be lost.',
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
              Navigator.pop(context);
            },
            child: const Text('Discard'),
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
        title: Text('Bulk Results (${_items.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Discard',
            onPressed: _confirmDiscard,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Save All Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? AppColors.darkCard : Colors.grey.shade100,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_items.length} Generated',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSavedAll ? AppColors.success : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: _isSavedAll ? null : _saveAll,
                    icon: Icon(_isSavedAll ? Icons.check_rounded : Icons.save_rounded, size: 18),
                    label: Text(_isSavedAll ? 'Saved All' : 'Save All (${_items.length})'),
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

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
                            // QR thumbnail preview
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 60,
                                height: 60,
                                color: item.customization.backgroundColor,
                                padding: const EdgeInsets.all(4),
                                child: Center(
                                  child: QrRenderView(
                                    data: item.rawPayload,
                                    customization: item.customization,
                                    size: 52,
                                    showContainer: false,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: typeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
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
                                  const SizedBox(height: 4),
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.rawPayload,
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

                            // Copy button
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              tooltip: 'Copy',
                              onPressed: () {
                                QrSharingService.copyToClipboard(
                                  context,
                                  item.rawPayload,
                                  message: 'Copied "${item.title}"',
                                );
                              },
                            ),

                            // Share text button
                            IconButton(
                              icon: const Icon(Icons.share_rounded, size: 18),
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
