import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';

/// Quick actions bar on the Home/Create screen for rapid navigation.
class QuickActionsBar extends StatelessWidget {
  final VoidCallback onCreateTap;
  final VoidCallback onScanTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onFavoritesTap;

  const QuickActionsBar({
    super.key,
    required this.onCreateTap,
    required this.onScanTap,
    required this.onHistoryTap,
    required this.onFavoritesTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;

          return Row(
            children: [
              _buildActionTile(
                context,
                icon: Icons.add_box_rounded,
                label: 'Create',
                color: AppTheme.primaryColor,
                isDark: isDark,
                onTap: onCreateTap,
                isPrimary: true,
                isNarrow: isNarrow,
              ),
              const SizedBox(width: 8),
              _buildActionTile(
                context,
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan QR',
                color: const Color(0xFF0D9488),
                isDark: isDark,
                onTap: onScanTap,
                isNarrow: isNarrow,
              ),
              const SizedBox(width: 8),
              _buildActionTile(
                context,
                icon: Icons.history_rounded,
                label: 'History',
                color: const Color(0xFF6366F1),
                isDark: isDark,
                onTap: onHistoryTap,
                isNarrow: isNarrow,
              ),
              const SizedBox(width: 8),
              _buildActionTile(
                context,
                icon: Icons.favorite_rounded,
                label: 'Favorites',
                color: const Color(0xFFE11D48),
                isDark: isDark,
                onTap: onFavoritesTap,
                isNarrow: isNarrow,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isNarrow = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: isNarrow ? 8 : 10,
              horizontal: 4,
            ),
            decoration: BoxDecoration(
              color: isPrimary
                  ? color.withValues(alpha: isDark ? 0.25 : 0.12)
                  : (isDark ? AppTheme.surfaceDark : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPrimary
                    ? color.withValues(alpha: 0.4)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                width: isPrimary ? 1.4 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: isNarrow ? 18 : 20, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isNarrow ? 10.5 : 11.5,
                    fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
