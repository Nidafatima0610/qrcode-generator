import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/core/utils/snackbar_helper.dart';
import 'package:qr_code_generator/features/qr_generator/controllers/qr_generator_controller.dart';

/// Row of primary export actions: Save, Share, and Copy.
class QrActionButtons extends StatelessWidget {
  final QrGeneratorController controller;

  const QrActionButtons({
    super.key,
    required this.controller,
  });

  Future<void> _handleSave(BuildContext context) async {
    try {
      final message = await controller.saveQrImage();
      if (context.mounted) {
        SnackBarHelper.showSuccess(context, message);
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(
            context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    try {
      await controller.shareQrCode();
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(
            context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _handleCopy(BuildContext context) async {
    try {
      await controller.copyEncodedText();
      if (context.mounted) {
        SnackBarHelper.showInfo(
            context, 'Encoded content copied to clipboard!');
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(context, 'Failed to copy to clipboard.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (controller.isExporting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppTheme.primaryLight,
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
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              controller.exportStatusMessage ?? 'Processing...',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.primaryDark,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        return Row(
          children: [
            // Save Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleSave(context),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  isCompact ? 'Save' : 'Save Image',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Share Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleShare(context),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text(
                  isCompact ? 'Share' : 'Share QR',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Quick Copy Icon Button
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  width: 1.2,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.copy_rounded, size: 19),
                tooltip: 'Copy text to clipboard',
                color: isDark ? Colors.white70 : AppTheme.textPrimaryLight,
                onPressed: () => _handleCopy(context),
              ),
            ),
          ],
        );
      },
    );
  }
}
