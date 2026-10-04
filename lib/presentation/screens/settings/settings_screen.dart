import 'package:flutter/material.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  final StorageService storageService;

  const SettingsScreen({
    super.key,
    required this.storageService,
  });

  void _confirmClearHistory(BuildContext context) {
    bool keepFavorites = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Clear QR Generation History?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will remove generated QR codes from this device.',
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
                  'Favorite items will remain in your favorites',
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
                await storageService.clearHistory(
                  preserveFavorites: keepFavorites,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(keepFavorites
                          ? 'History cleared (favorites kept)'
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

  void _confirmClearScans(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear Scanned QR History?'),
        content: const Text(
          'This will permanently delete all scanned QR codes from your scan history. Are you sure you want to proceed?',
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
              await storageService.clearScanHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All scan history cleared successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Clear Scans'),
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
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: storageService,
          builder: (context, _) {
            final currentMode = storageService.themeMode;
            final historyCount = storageService.history.length;
            final favCount = storageService.favorites.length;
            final scanCount = storageService.scanHistory.length;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              children: [
                // 1. Appearance Section Header
                _sectionHeader(context, 'Appearance & Theme'),
                const SizedBox(height: 8),

                // Theme Mode Selector Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Theme Mode',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose your preferred visual appearance. Persists across restarts.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Segmented Theme Selector
                        Row(
                          children: [
                            _themeOption(
                              context: context,
                              title: 'System',
                              icon: Icons.brightness_auto_rounded,
                              isSelected: currentMode == ThemeMode.system,
                              onTap: () =>
                                  storageService.setThemeMode(ThemeMode.system),
                            ),
                            const SizedBox(width: 8),
                            _themeOption(
                              context: context,
                              title: 'Light',
                              icon: Icons.light_mode_rounded,
                              isSelected: currentMode == ThemeMode.light,
                              onTap: () =>
                                  storageService.setThemeMode(ThemeMode.light),
                            ),
                            const SizedBox(width: 8),
                            _themeOption(
                              context: context,
                              title: 'Dark',
                              icon: Icons.dark_mode_rounded,
                              isSelected: currentMode == ThemeMode.dark,
                              onTap: () =>
                                  storageService.setThemeMode(ThemeMode.dark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Data & Storage Section
                _sectionHeader(context, 'Data & Storage'),
                const SizedBox(height: 8),

                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Generated QR Codes',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '$historyCount code${historyCount == 1 ? '' : 's'} ($favCount favorite${favCount == 1 ? '' : 's'})',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        trailing: Text(
                          '$historyCount',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Scanned QR Records',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '$scanCount scan record${scanCount == 1 ? '' : 's'} stored',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        trailing: Text(
                          '$scanCount',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_sweep_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Clear QR History',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                        subtitle: const Text(
                          'Clear generated history with safe favorites option',
                          style: TextStyle(fontSize: 12.5),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: historyCount > 0
                            ? () => _confirmClearHistory(context)
                            : null,
                      ),
                      const Divider(),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Clear Scan History',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                        subtitle: const Text(
                          'Remove all saved camera scans',
                          style: TextStyle(fontSize: 12.5),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: scanCount > 0
                            ? () => _confirmClearScans(context)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Privacy & Security Section
                _sectionHeader(context, 'Privacy & Security'),
                const SizedBox(height: 8),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: AppColors.success,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '100% Offline & Private',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'All QR codes and scans are generated and stored locally on your device. No data is ever sent to external cloud servers.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. About App Section
                _sectionHeader(context, 'About QR Studio Pro'),
                const SizedBox(height: 8),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.secondary],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.qr_code_2_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'QR Studio Pro',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Version 2.0.0 (Build 2026)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'A complete, private QR utility for generating, styling, exporting, scanning, and managing QR codes across all essential formats.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
      ),
    );
  }

  Widget _themeOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 6),
              Text(
                title,
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
            ],
          ),
        ),
      ),
    );
  }
}
