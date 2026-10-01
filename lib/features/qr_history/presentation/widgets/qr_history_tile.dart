import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/qr_item.dart';

/// Polished list tile widget displaying an individual QR history record.
class QrHistoryTile extends StatelessWidget {
  final QrItem item;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  const QrHistoryTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Small QR Thumbnail preview inside a rounded card
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: item.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: QrImageView(
                      data: item.content,
                      version: QrVersions.auto,
                      size: 44,
                      backgroundColor: item.backgroundColor,
                      eyeStyle: QrEyeStyle(
                        eyeShape: item.eyeShape,
                        color: item.foregroundColor,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: item.dataModuleShape,
                        color: item.foregroundColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Content, Payload Badge, and Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            item.payloadType.icon,
                            size: 13,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.payloadType.label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.titlePreview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.formattedDate,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),

                // Favorite Toggle Button
                IconButton(
                  icon: Icon(
                    item.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: item.isFavorite
                        ? const Color(0xFFE11D48)
                        : (isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8)),
                    size: 22,
                  ),
                  tooltip: item.isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onPressed: onToggleFavorite,
                ),

                // Trailing Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
