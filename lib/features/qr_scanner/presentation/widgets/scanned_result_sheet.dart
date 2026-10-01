import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/core/utils/snackbar_helper.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_config.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_payload_type.dart';
import 'package:qr_code_generator/features/qr_history/controllers/qr_history_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modal bottom sheet displaying detected QR code content and context-aware actions.
class ScannedResultSheet extends StatefulWidget {
  final String rawContent;
  final VoidCallback onScanAgain;

  const ScannedResultSheet({
    super.key,
    required this.rawContent,
    required this.onScanAgain,
  });

  static Future<void> show(
    BuildContext context, {
    required String rawContent,
    required VoidCallback onScanAgain,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScannedResultSheet(
        rawContent: rawContent,
        onScanAgain: onScanAgain,
      ),
    );
  }

  @override
  State<ScannedResultSheet> createState() => _ScannedResultSheetState();
}

class _ScannedResultSheetState extends State<ScannedResultSheet> {
  bool _isSaved = false;

  QrPayloadType _detectType(String content) {
    final lower = content.trim().toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return QrPayloadType.url;
    }
    if (lower.startsWith('wifi:')) {
      return QrPayloadType.wifi;
    }
    if (lower.startsWith('mailto:') || RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(content.trim())) {
      return QrPayloadType.email;
    }
    if (lower.startsWith('tel:') || (RegExp(r'^\+?[\d\s-]{6,}$').hasMatch(content.trim()) && !content.contains('\n'))) {
      return QrPayloadType.phone;
    }
    if (lower.startsWith('smsto:')) {
      return QrPayloadType.sms;
    }
    if (lower.contains('begin:vcard')) {
      return QrPayloadType.contact;
    }
    return QrPayloadType.text;
  }

  Future<void> _handleUrlLaunch(BuildContext context, String url) async {
    // Safety confirmation dialog for external URLs
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Open External Link?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You are about to visit an external website. Ensure you recognize and trust this source:',
              style: TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                url,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Continue to Website'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final uri = Uri.parse(url);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          SnackBarHelper.showError(context, 'Could not open URL: $url');
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarHelper.showError(context, 'Failed to launch URL: $e');
        }
      }
    }
  }

  Future<void> _handleTelLaunch(BuildContext context, String phone) async {
    final clean = phone.replaceFirst('tel:', '').trim();
    try {
      final uri = Uri(scheme: 'tel', path: clean);
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        SnackBarHelper.showError(context, 'Could not dial phone number.');
      }
    }
  }

  Future<void> _handleSmsLaunch(BuildContext context, String raw) async {
    final clean = raw.replaceFirst('smsto:', '').trim();
    final parts = clean.split(':');
    final phone = parts.first;
    final body = parts.length > 1 ? parts.sublist(1).join(':') : null;

    try {
      final uri = Uri(
        scheme: 'sms',
        path: phone,
        queryParameters: body != null && body.isNotEmpty ? {'body': body} : null,
      );
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        SnackBarHelper.showError(context, 'Could not draft SMS message.');
      }
    }
  }

  Future<void> _handleEmailLaunch(BuildContext context, String raw) async {
    try {
      final clean = raw.startsWith('mailto:') ? raw : 'mailto:$raw';
      final uri = Uri.parse(clean);
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        SnackBarHelper.showError(context, 'Could not compose email.');
      }
    }
  }

  Future<void> _saveToHistory(BuildContext context, QrPayloadType type) async {
    await QrHistoryController.instance.addOrUpdate(
      QrConfig(
        content: widget.rawContent,
        payloadType: type,
      ),
    );
    setState(() => _isSaved = true);
    if (context.mounted) {
      SnackBarHelper.showSuccess(context, 'Saved to history successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final detectedType = _detectType(widget.rawContent);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  detectedType.icon,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QR Code Detected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      detectedType.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: SelectableText(
              widget.rawContent,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                fontFamily: detectedType == QrPayloadType.url ? 'monospace' : null,
              ),
              maxLines: 6,
            ),
          ),
          const SizedBox(height: 20),

          // Contextual Action Buttons
          if (detectedType == QrPayloadType.url) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _handleUrlLaunch(context, widget.rawContent.trim()),
                icon: const Icon(Icons.open_in_browser_rounded),
                label: const Text('Visit Website (Safe Open)'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ] else if (detectedType == QrPayloadType.phone) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _handleTelLaunch(context, widget.rawContent),
                    icon: const Icon(Icons.call_rounded),
                    label: const Text('Call Number'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleSmsLaunch(context, widget.rawContent),
                    icon: const Icon(Icons.sms_rounded),
                    label: const Text('Send SMS'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ] else if (detectedType == QrPayloadType.email) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _handleEmailLaunch(context, widget.rawContent),
                icon: const Icon(Icons.mail_rounded),
                label: const Text('Compose Email'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ] else if (detectedType == QrPayloadType.sms) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _handleSmsLaunch(context, widget.rawContent),
                icon: const Icon(Icons.sms_rounded),
                label: const Text('Draft SMS Message'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Secondary Universal Actions
          Row(
            children: [
              // Copy Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.rawContent));
                    SnackBarHelper.showSuccess(context, 'Copied to clipboard!');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Share Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text: widget.rawContent,
                        subject: 'Scanned QR Code',
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Save to History Button
              IconButton.filledTonal(
                onPressed: _isSaved ? null : () => _saveToHistory(context, detectedType),
                icon: Icon(
                  _isSaved ? Icons.check_circle_rounded : Icons.bookmark_add_outlined,
                  color: _isSaved ? const Color(0xFF10B981) : AppTheme.primaryColor,
                ),
                tooltip: _isSaved ? 'Saved to History' : 'Save to History',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Scan Again Button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onScanAgain();
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Scan Another Code'),
            ),
          ),
        ],
      ),
    );
  }
}
