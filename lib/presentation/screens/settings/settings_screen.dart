import 'package:flutter/material.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/core/services/qr_sharing_service.dart';
import 'package:qrcode_generator/presentation/screens/presets/presets_screen.dart';
import 'package:qrcode_generator/presentation/screens/onboarding/onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  final StorageService storageService;

  const SettingsScreen({
    super.key,
    required this.storageService,
  });

  void _exportBackup(BuildContext context) {
    final jsonString = storageService.exportBackupJson();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Export Data Backup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your backup includes all generated codes, notes, collections, custom presets, and scan records (Schema v2).',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.black38 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonString,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy JSON'),
            onPressed: () {
              Navigator.pop(ctx);
              QrSharingService.copyToClipboard(
                context,
                jsonString,
                message: 'Backup JSON copied to clipboard!',
              );
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text('Share Backup'),
            onPressed: () {
              Navigator.pop(ctx);
              QrSharingService.shareText(
                text: jsonString,
                subject: 'QR Studio Pro Backup',
              );
            },
          ),
        ],
      ),
    );
  }

  void _restoreBackup(BuildContext context) {
    final textController = TextEditingController();
    bool replaceMode = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cloud_download_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Restore from Backup'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paste your JSON backup data below to restore your QR codes, scans, collections, and presets.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Paste backup JSON here...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Restore Mode:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setDialogState(() => replaceMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: !replaceMode
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : (Theme.of(ctx).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !replaceMode ? AppColors.primary : Colors.grey.shade300,
                              width: !replaceMode ? 1.8 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.merge_type_rounded,
                                  color: !replaceMode ? AppColors.primary : Colors.grey, size: 20),
                              const SizedBox(height: 4),
                              Text('Merge',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: !replaceMode ? FontWeight.w700 : FontWeight.w500,
                                    color: !replaceMode ? AppColors.primary : null,
                                  )),
                              const SizedBox(height: 2),
                              const Text('Keep existing',
                                  style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setDialogState(() => replaceMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: replaceMode
                                ? AppColors.error.withValues(alpha: 0.12)
                                : (Theme.of(ctx).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: replaceMode ? AppColors.error : Colors.grey.shade300,
                              width: replaceMode ? 1.8 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.swap_horiz_rounded,
                                  color: replaceMode ? AppColors.error : Colors.grey, size: 20),
                              const SizedBox(height: 4),
                              Text('Replace',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: replaceMode ? FontWeight.w700 : FontWeight.w500,
                                    color: replaceMode ? AppColors.error : null,
                                  )),
                              const SizedBox(height: 2),
                              const Text('Overwrite all',
                                  style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: replaceMode ? AppColors.error : AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final input = textController.text.trim();
                if (input.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please paste backup JSON content first.'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogCtx);
                final result = await storageService.importBackupJson(
                  input,
                  replace: replaceMode,
                );

                if (context.mounted) {
                  if (result.success) {
                    showDialog(
                      context: context,
                      builder: (resCtx) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: AppColors.success),
                            SizedBox(width: 8),
                            Text('Restore Successful'),
                          ],
                        ),
                        content: Text(
                          'Backup restored successfully!\n\n'
                          '• ${result.importedHistory} QR codes\n'
                          '• ${result.importedScans} scan records\n'
                          '• ${result.importedPresets} presets\n'
                          '• ${result.importedCollections} collections',
                          style: const TextStyle(fontSize: 13.5, height: 1.4),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(resCtx),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (errCtx) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Restore Failed'),
                          ],
                        ),
                        content: Text(
                          'The provided backup content is invalid or corrupted:\n\n${result.errorMessage}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(errCtx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              child: Text(replaceMode ? 'Replace & Restore' : 'Merge & Restore'),
            ),
          ],
        ),
      ),
    );
  }

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

  void _confirmClearFavorites(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear All Favorites?'),
        content: const Text(
          'This will unmark all favorite items. Your QR codes will remain safe in your history.',
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
              await storageService.clearFavorites();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All favorites cleared (history kept safe)'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Clear Favorites'),
          ),
        ],
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
            final defaultSize = storageService.defaultQrSize;
            final defaultEcc = storageService.defaultErrorCorrection;
            final defaultExport = storageService.defaultExportMode;

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

                // 2. Scanner Preferences (Requirement 9 & 19)
                _sectionHeader(context, 'Scanner Preferences'),
                const SizedBox(height: 8),

                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: storageService.confirmBeforeOpen,
                        activeThumbColor: AppColors.primary,
                        title: const Text(
                          'Confirm Before Opening Actions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Prompt for confirmation before launching websites, phone calls, or emails',
                          style: TextStyle(fontSize: 12),
                        ),
                        onChanged: (val) {
                          storageService.setConfirmBeforeOpen(val);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: storageService.scannerTorchDefault,
                        activeThumbColor: AppColors.primary,
                        title: const Text(
                          'Default Flashlight in Scanner',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Automatically enable flashlight when launching scanner',
                          style: TextStyle(fontSize: 12),
                        ),
                        onChanged: (val) {
                          storageService.setScannerTorchDefault(val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Default QR Preferences (Requirement)
                _sectionHeader(context, 'Default QR Preferences'),
                const SizedBox(height: 8),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Default QR Size Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Default QR Size',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${defaultSize.round()} px',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: defaultSize.clamp(160.0, 320.0),
                          min: 160.0,
                          max: 320.0,
                          divisions: 8,
                          label: '${defaultSize.round()} px',
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            storageService.setDefaultQrSize(val);
                          },
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Default Error Correction Level
                        const Text(
                          'Default Error Correction',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Higher levels allow QRs to remain readable even when partially covered or styled.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _eccOption(
                              label: 'Low',
                              sub: '7%',
                              code: 'L',
                              isSelected: defaultEcc == 'L',
                              onTap: () => storageService.setDefaultErrorCorrection('L'),
                            ),
                            const SizedBox(width: 6),
                            _eccOption(
                              label: 'Med',
                              sub: '15%',
                              code: 'M',
                              isSelected: defaultEcc == 'M',
                              onTap: () => storageService.setDefaultErrorCorrection('M'),
                            ),
                            const SizedBox(width: 6),
                            _eccOption(
                              label: 'Quartile',
                              sub: '25%',
                              code: 'Q',
                              isSelected: defaultEcc == 'Q',
                              onTap: () => storageService.setDefaultErrorCorrection('Q'),
                            ),
                            const SizedBox(width: 6),
                            _eccOption(
                              label: 'High',
                              sub: '30%',
                              code: 'H',
                              isSelected: defaultEcc == 'H',
                              onTap: () => storageService.setDefaultErrorCorrection('H'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Default Export Mode
                        const Text(
                          'Default Export Mode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Layout used when sharing or exporting generated QR graphics.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _exportModeChip(
                              label: 'QR Only',
                              value: 'qrOnly',
                              current: defaultExport,
                              onSelected: () => storageService.setDefaultExportMode('qrOnly'),
                            ),
                            _exportModeChip(
                              label: 'QR + Title',
                              value: 'titleQr',
                              current: defaultExport,
                              onSelected: () => storageService.setDefaultExportMode('titleQr'),
                            ),
                            _exportModeChip(
                              label: 'Presentation Card',
                              value: 'card',
                              current: defaultExport,
                              onSelected: () => storageService.setDefaultExportMode('card'),
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
                            color: Colors.pink.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.heart_broken_rounded,
                            color: Colors.pink,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Clear All Favorites',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.pink,
                          ),
                        ),
                        subtitle: const Text(
                          'Unmark all favorites (QR codes remain in history)',
                          style: TextStyle(fontSize: 12.5),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: favCount > 0
                            ? () => _confirmClearFavorites(context)
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
                      const Divider(),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: AppColors.accent,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Style Presets',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${storageService.presets.length} custom style configurations',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PresetsScreen(
                                storageService: storageService,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Backup & Restore (Requirement 17)
                _sectionHeader(context, 'Backup & Restore (JSON Schema v2)'),
                const SizedBox(height: 8),

                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Export Data Backup',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Export full history, scans, favorites, notes, and collections to JSON',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () => _exportBackup(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.cloud_download_outlined,
                            color: Colors.teal,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Restore from Backup',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Import JSON backup with Merge or Replace options and validation',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () => _restoreBackup(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Privacy & Security Section
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
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.school_outlined, size: 18),
                          label: const Text('View App Walkthrough'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OnboardingScreen(
                                  storageService: storageService,
                                  onFinish: () => Navigator.pop(context),
                                ),
                              ),
                            );
                          },
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

  Widget _eccOption({
    required String label,
    required String sub,
    required String code,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Text(
                code,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exportModeChip({
    required String label,
    required String value,
    required String current,
    required VoidCallback onSelected,
  }) {
    final isSelected = value == current;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : null,
      ),
      onSelected: (_) => onSelected(),
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
