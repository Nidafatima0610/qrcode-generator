import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/core/utils/qr_image_exporter.dart';
import 'package:qr_code_generator/core/utils/snackbar_helper.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../controllers/qr_history_controller.dart';
import '../../models/qr_item.dart';
import '../widgets/delete_confirmation_dialog.dart';

/// Detail screen displaying full QR code preview, complete content, and export actions.
class QrDetailScreen extends StatefulWidget {
  final QrItem item;

  const QrDetailScreen({
    super.key,
    required this.item,
  });

  @override
  State<QrDetailScreen> createState() => _QrDetailScreenState();
}

class _QrDetailScreenState extends State<QrDetailScreen> {
  final GlobalKey _detailRepaintKey = GlobalKey();
  bool _isExporting = false;
  String? _exportStatus;

  Future<void> _handleSave(QrItem item) async {
    setState(() {
      _isExporting = true;
      _exportStatus = 'Saving QR image...';
    });

    try {
      final Uint8List bytes =
          await QrImageExporter.capturePng(_detailRepaintKey);
      final message = await QrImageExporter.saveImage(bytes);
      if (mounted) {
        SnackBarHelper.showSuccess(context, message);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
            context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportStatus = null;
        });
      }
    }
  }

  Future<void> _handleShare(QrItem item) async {
    setState(() {
      _isExporting = true;
      _exportStatus = 'Preparing share...';
    });

    try {
      final Uint8List bytes =
          await QrImageExporter.capturePng(_detailRepaintKey);
      await QrImageExporter.shareQrCode(
        bytes: bytes,
        content: item.content,
      );
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
            context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportStatus = null;
        });
      }
    }
  }

  Future<void> _handleDelete(QrItem item) async {
    final confirmed = await DeleteConfirmationDialog.confirmDeleteItem(
      context,
      title: item.content,
    );

    if (confirmed && mounted) {
      await QrHistoryController.instance.deleteItem(item.id);
      if (mounted) {
        SnackBarHelper.showInfo(context, 'QR code deleted from history.');
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleCopy(String content) async {
    await QrImageExporter.copyToClipboard(content);
    if (mounted) {
      SnackBarHelper.showInfo(context, 'Content copied to clipboard!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: QrHistoryController.instance,
      builder: (context, _) {
        // Find latest version of this item from controller
        final currentItem = QrHistoryController.instance.allItems.firstWhere(
          (i) => i.id == widget.item.id,
          orElse: () => widget.item,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('QR Details'),
            actions: [
              IconButton(
                icon: Icon(
                  currentItem.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: currentItem.isFavorite
                      ? const Color(0xFFE11D48)
                      : null,
                ),
                tooltip: currentItem.isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                onPressed: () =>
                    QrHistoryController.instance.toggleFavorite(currentItem.id),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete record',
                onPressed: () => _handleDelete(currentItem),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      // Prominent QR Canvas inside RepaintBoundary
                      RepaintBoundary(
                        key: _detailRepaintKey,
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: currentItem.backgroundColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: currentItem.content,
                            version: QrVersions.auto,
                            size: 230,
                            backgroundColor: currentItem.backgroundColor,
                            errorCorrectionLevel:
                                currentItem.errorCorrectionLevel,
                            eyeStyle: QrEyeStyle(
                              eyeShape: currentItem.eyeShape,
                              color: currentItem.foregroundColor,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: currentItem.dataModuleShape,
                              color: currentItem.foregroundColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Metadata & Complete Content Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131B2E) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.borderDark
                                : AppTheme.borderLight,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row: Type & Date
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        currentItem.payloadType.icon,
                                        size: 14,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        currentItem.payloadType.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? const Color(0xFFA5B4FC)
                                              : AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currentItem.formattedDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Content Box
                            Text(
                              'ENCODED CONTENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.borderDark
                                      : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: SelectableText(
                                currentItem.content,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.45,
                                  fontFamily: 'monospace',
                                  color: isDark
                                      ? AppTheme.textPrimaryDark
                                      : AppTheme.textPrimaryLight,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${currentItem.content.length} characters',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Export & Action Buttons
                      if (_isExporting) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryColor),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _exportStatus ?? 'Processing...',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handleSave(currentItem),
                                icon: const Icon(Icons.download_rounded,
                                    size: 18),
                                label: const Text('Save Image'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _handleShare(currentItem),
                                icon:
                                    const Icon(Icons.share_rounded, size: 18),
                                label: const Text('Share QR'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.borderDark
                                      : AppTheme.borderLight,
                                  width: 1.2,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 19),
                                tooltip: 'Copy content to clipboard',
                                onPressed: () =>
                                    _handleCopy(currentItem.content),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Load back in Generator button
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop(currentItem);
                            },
                            icon: const Icon(Icons.edit_note_rounded,
                                size: 18),
                            label: const Text('Open in Generator'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
