import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/core/theme/theme_controller.dart';
import 'package:qr_code_generator/core/utils/snackbar_helper.dart';
import 'package:qr_code_generator/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:qr_code_generator/features/qr_history/controllers/qr_history_controller.dart';
import 'package:qr_code_generator/features/qr_history/presentation/widgets/delete_confirmation_dialog.dart';
import 'package:share_plus/share_plus.dart';

/// Application settings screen managing theme mode, storage, privacy, and app information.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    QrHistoryController.instance.addListener(_onStateChange);
    ThemeController.instance.addListener(_onStateChange);
  }

  @override
  void dispose() {
    QrHistoryController.instance.removeListener(_onStateChange);
    ThemeController.instance.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Privacy Policy'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '100% Offline & Private',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'QR Code Generator is built with strict user privacy in mind:\n\n'
                '• No Cloud Servers: Every QR code created or scanned is processed locally on your device.\n'
                '• No Tracking or Telemetry: We do not collect analytics, logs, or personal identifiers.\n'
                '• Local Storage: Your history and favorites are stored exclusively in your device\'s local storage.\n'
                '• Camera Security: Camera feed is processed in real time and no images are stored or transmitted without your explicit action.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('About App'),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'QR Code Generator',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: isDark ? Colors.white : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0 (Build 1)',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'A modern, professional QR utility built with Flutter and Dart. Features multi-type QR generation, dynamic forms, real-time camera and gallery scanning, offline persistence, and customizable styling.',
              style: TextStyle(fontSize: 13, height: 1.45),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    int selectedStars = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Rate QR Code Generator'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enjoying the app? Your rating and feedback help us make it even better!',
                style: TextStyle(fontSize: 13.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    onPressed: () {
                      setDialogState(() => selectedStars = starIndex);
                    },
                    icon: Icon(
                      starIndex <= selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                SnackBarHelper.showSuccess(context, 'Thank you for your rating!');
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTheme = ThemeController.instance.themeMode;
    final historyCount = QrHistoryController.instance.allItems.length;
    final favoritesCount = QrHistoryController.instance.favoriteItems.length;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Section: Appearance
          _buildSectionHeader('Appearance', isDark),
          Card(
            elevation: 0,
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.palette_outlined, size: 20, color: AppTheme.primaryColor),
                      const SizedBox(width: 10),
                      Text(
                        'Theme Mode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_rounded, size: 16),
                      ),
                    ],
                    selected: {currentTheme},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      ThemeController.instance.setThemeMode(newSelection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppTheme.primaryColor,
                      selectedForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section: Data & Storage
          _buildSectionHeader('History & Storage', isDark),
          Card(
            elevation: 0,
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_outlined, color: AppTheme.primaryColor),
                  title: const Text('Saved QR Codes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('$historyCount total ($favoritesCount favorites)'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFEF4444)),
                  title: const Text(
                    'Clear History',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
                  ),
                  subtitle: const Text('Remove saved scans & generated codes'),
                  onTap: historyCount == 0
                      ? null
                      : () async {
                          final preserveFavorites =
                              await DeleteConfirmationDialog.confirmClearHistory(
                            context,
                            totalCount: historyCount,
                            favoriteCount: favoritesCount,
                          );
                          if (preserveFavorites != null && context.mounted) {
                            await QrHistoryController.instance
                                .clearHistory(preserveFavorites: preserveFavorites);
                            if (context.mounted) {
                              SnackBarHelper.showSuccess(context, 'History cleared.');
                            }
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: General & App Info
          _buildSectionHeader('About & Support', isDark),
          Card(
            elevation: 0,
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
                  title: const Text('About App', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () => _showAboutDialog(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: AppTheme.primaryColor),
                  title: const Text('Privacy Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () => _showPrivacyPolicyDialog(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.school_outlined, color: AppTheme.primaryColor),
                  title: const Text('View Walkthrough', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Revisit app onboarding'),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OnboardingScreen(
                          onFinish: () => Navigator.of(context).pop(),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.share_outlined, color: AppTheme.primaryColor),
                  title: const Text('Share App', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text: 'Check out this modern offline QR Code Generator and Scanner for Flutter!',
                        subject: 'QR Code Generator App',
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.star_outline_rounded, color: AppTheme.primaryColor),
                  title: const Text('Rate App', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () => _showRatingDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Version Footer
          Center(
            child: Text(
              'QR Code Generator • v1.0.0 (Build 1)',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
        ),
      ),
    );
  }
}
