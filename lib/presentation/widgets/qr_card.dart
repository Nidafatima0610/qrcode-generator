import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/services/qr_sharing_service.dart';
import 'package:qrcode_generator/presentation/widgets/qr_render_view.dart';

class QrCard extends StatelessWidget {
  final QrItem item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onFavoriteToggle;
  final bool showDelete;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;

  const QrCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onDelete,
    this.onEdit,
    this.onFavoriteToggle,
    this.showDelete = false,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectChanged,
  });

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = item.type.color;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isSelectionMode
            ? () {
                onSelectChanged?.call(!isSelected);
              }
            : onTap,
        onLongPress: onSelectChanged != null
            ? () {
                onSelectChanged?.call(!isSelected);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Selection Checkbox
              if (isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: onSelectChanged,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 4),
              ],

              // QR Thumbnail Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 58,
                  height: 58,
                  color: item.customization.backgroundColor,
                  padding: const EdgeInsets.all(4),
                  child: Center(
                    child: QrRenderView(
                      data: item.rawPayload,
                      customization: item.customization,
                      size: 50,
                      showContainer: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info & Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Type Badge & Date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.type.icon,
                                size: 12,
                                color: typeColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.type.shortName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: typeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(item.createdAt),
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

                    // Title
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Subtitle / Summary
                    Text(
                      item.subtitle.isNotEmpty
                          ? item.subtitle
                          : item.rawPayload,
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

              // Favorite Heart Icon Button
              if (!isSelectionMode && onFavoriteToggle != null) ...[
                IconButton(
                  icon: Icon(
                    item.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: item.isFavorite
                        ? AppColors.error
                        : (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted),
                  ),
                  tooltip: item.isFavorite
                      ? 'Remove from Favorites'
                      : 'Add to Favorites',
                  onPressed: onFavoriteToggle,
                ),
              ],

              // Action Popup Menu Button
              if (!isSelectionMode) ...[
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'view') {
                      onTap();
                    } else if (value == 'edit' && onEdit != null) {
                      onEdit!();
                    } else if (value == 'favorite' && onFavoriteToggle != null) {
                      onFavoriteToggle!();
                    } else if (value == 'copy') {
                      QrSharingService.copyToClipboard(
                        context,
                        item.rawPayload,
                        message: 'Copied "${item.title}" to clipboard',
                      );
                    } else if (value == 'share') {
                      QrSharingService.shareText(
                        text: item.rawPayload,
                        subject: item.title,
                      );
                    } else if (value == 'delete' && onDelete != null) {
                      onDelete!();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('Open Preview'),
                        ],
                      ),
                    ),
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_note_rounded, size: 18),
                            SizedBox(width: 10),
                            Text('Edit / Re-generate'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'favorite',
                      child: Row(
                        children: [
                          Icon(
                            item.isFavorite
                                ? Icons.favorite_border_rounded
                                : Icons.favorite_rounded,
                            size: 18,
                            color: item.isFavorite ? null : AppColors.error,
                          ),
                          const SizedBox(width: 10),
                          Text(item.isFavorite
                              ? 'Remove Favorite'
                              : 'Add to Favorites'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Copy Payload'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('Share Text'),
                        ],
                      ),
                    ),
                    if (showDelete && onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: AppColors.error),
                            SizedBox(width: 10),
                            Text('Delete',
                                style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
