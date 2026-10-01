import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';

enum EmptyStateType {
  history,
  favorites,
  search,
}

/// Dynamic empty state for History, Favorites, and empty search results.
class QrHistoryEmptyState extends StatelessWidget {
  final EmptyStateType type;
  final String? searchQuery;
  final VoidCallback? onClearSearch;

  const QrHistoryEmptyState({
    super.key,
    required this.type,
    this.searchQuery,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final IconData icon;
    final String title;
    final String description;

    switch (type) {
      case EmptyStateType.history:
        icon = Icons.history_toggle_off_rounded;
        title = 'No QR History Yet';
        description =
            'QR codes you generate will appear here automatically for easy re-access, saving, and sharing.';
        break;
      case EmptyStateType.favorites:
        icon = Icons.favorite_border_rounded;
        title = 'No Favorites Saved';
        description =
            'Tap the heart icon on any generated or history QR code to pin it to your favorites list.';
        break;
      case EmptyStateType.search:
        icon = Icons.search_off_rounded;
        title = 'No Matching Results';
        description =
            'No QR records match "${searchQuery ?? ''}". Try checking for typos or clear your search query.';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : AppTheme.primaryLight.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 34,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
                height: 1.4,
              ),
            ),
            if (type == EmptyStateType.search && onClearSearch != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onClearSearch,
                icon: const Icon(Icons.clear_rounded, size: 16),
                label: const Text('Clear Search'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
