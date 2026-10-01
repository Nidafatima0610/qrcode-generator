import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';

/// Dialog helper for confirming individual item deletion and bulk history clear.
class DeleteConfirmationDialog {
  /// Confirms deletion of a single history item.
  static Future<bool> confirmDeleteItem(
    BuildContext context, {
    required String title,
  }) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF131B2E) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.errorColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Delete Record?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this QR code from your history? This action cannot be undone.',
              style: TextStyle(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                title.length > 60 ? '${title.substring(0, 57)}...' : title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Confirms bulk clear of history with explicit choice to preserve favorites.
  static Future<bool?> confirmClearHistory(
    BuildContext context, {
    required int totalCount,
    required int favoriteCount,
  }) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    bool preserveFavorites = favoriteCount > 0;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: isDark ? const Color(0xFF131B2E) : Colors.white,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_sweep_rounded,
                      color: AppTheme.errorColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Clear History',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will clear $totalCount recorded QR code(s) from your device.',
                    style: const TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                  if (favoriteCount > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : AppTheme.primaryLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFC7D2FE),
                          width: 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        title: Text(
                          'Keep favorites ($favoriteCount saved)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Recommended to preserve your pinned codes',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: preserveFavorites,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) {
                          setState(() {
                            preserveFavorites = val ?? true;
                          });
                        },
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(preserveFavorites),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    preserveFavorites
                        ? 'Clear Non-Favorites'
                        : 'Clear All History',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
