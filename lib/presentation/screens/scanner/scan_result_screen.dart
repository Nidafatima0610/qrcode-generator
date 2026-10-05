import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';
import 'package:qrcode_generator/core/models/scan_item.dart';
import 'package:qrcode_generator/core/services/qr_payload_builder.dart';
import 'package:qrcode_generator/core/services/qr_sharing_service.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';

class ScanResultScreen extends StatelessWidget {
  final ScanItem scanItem;
  final StorageService storageService;
  final VoidCallback? onScanAgain;

  const ScanResultScreen({
    super.key,
    required this.scanItem,
    required this.storageService,
    this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parsed = QrPayloadBuilder.parse(scanItem.rawContent);
    final typeColor = parsed.type.color;
    final formattedDate =
        DateFormat('MMM d, y • h:mm a').format(scanItem.scannedAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Content',
            onPressed: () {
              QrSharingService.shareText(
                text: scanItem.rawContent,
                subject: parsed.displayTitle,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy Payload',
            onPressed: () {
              QrSharingService.copyToClipboard(
                context,
                scanItem.rawContent,
                message: 'Scanned content copied to clipboard!',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Detected Type Pill & Scan Timestamp
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: typeColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(parsed.type.icon, size: 16, color: typeColor),
                        const SizedBox(width: 6),
                        Text(
                          parsed.type.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: typeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Display Title & Summary
              Text(
                parsed.displayTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                parsed.displaySubtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // 3. Primary Smart Action Buttons (Requirement 12)
              _buildSmartAction(context, parsed, typeColor),
              const SizedBox(height: 20),

              // 4. Structured Details Card (for Wi-Fi, Contact, Location, etc.)
              if (parsed.details.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Content Details',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...parsed.details.entries.map((entry) {
                          final isPassword = entry.key.toLowerCase().contains('pass');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: SelectableText(
                                    entry.value,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isPassword)
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.copy_rounded, size: 16),
                                    tooltip: 'Copy Password',
                                    onPressed: () {
                                      QrSharingService.copyToClipboard(
                                        context,
                                        entry.value,
                                        message: 'Wi-Fi password copied!',
                                      );
                                    },
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 5. Raw Payload Box
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Raw Scanned Payload',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(60, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 15),
                            label: const Text('Copy', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              QrSharingService.copyToClipboard(
                                context,
                                scanItem.rawContent,
                                message: 'Raw payload copied!',
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: SelectableText(
                          scanItem.rawContent,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.4,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 6. Secondary Management Actions
              Row(
                children: [
                  // Save to QR Generator history
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final qrItem = QrItem(
                          id: const Uuid().v4(),
                          type: parsed.type,
                          title: parsed.displayTitle,
                          subtitle: parsed.displaySubtitle,
                          rawPayload: scanItem.rawContent,
                          createdAt: DateTime.now(),
                        );
                        await storageService.saveItem(qrItem);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saved to your QR Generator history!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                      label: const Text('Save to QR History'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Scan Again button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onScanAgain?.call();
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                  label: const Text('Scan Another Code'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndLaunch(
    BuildContext context, {
    required String title,
    required String actionLabel,
    required String targetDescription,
    required String url,
    required IconData icon,
    Color? iconColor,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 17))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to proceed with this external action?',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? Colors.black26
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(ctx).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
              ),
              child: SelectableText(
                targetDescription,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor ?? AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await QrSharingService.launchExternalUrl(url);
    }
  }

  Widget _buildSmartAction(
      BuildContext context, ParsedQrContent parsed, Color typeColor) {
    void copyDefault() {
      QrSharingService.copyToClipboard(
        context,
        scanItem.rawContent,
        message: 'Content copied to clipboard!',
      );
    }

    void shareDefault() {
      QrSharingService.shareText(
        text: scanItem.rawContent,
        subject: parsed.displayTitle,
      );
    }

    Widget actionWithCopyShare(Widget primaryAction,
        {VoidCallback? onCopy, VoidCallback? onShare}) {
      return Column(
        children: [
          primaryAction,
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy ?? copyDefault,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShare ?? shareDefault,
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    switch (parsed.type) {
      case QrType.url:
      case QrType.social:
        final url = parsed.actionUrl ?? parsed.rawPayload;
        return actionWithCopyShare(
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: typeColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _confirmAndLaunch(
                  context,
                  title: 'Open Website?',
                  actionLabel: 'Open in Browser',
                  targetDescription: url,
                  url: url,
                  icon: Icons.open_in_browser_rounded,
                  iconColor: typeColor,
                );
              },
              icon: const Icon(Icons.open_in_browser_rounded, size: 20),
              label: const Text(
                'Open Website in Browser',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );

      case QrType.phone:
        final phoneUrl = parsed.actionUrl ?? 'tel:${parsed.rawPayload}';
        return actionWithCopyShare(
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: typeColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _confirmAndLaunch(
                  context,
                  title: 'Place Phone Call?',
                  actionLabel: 'Call Number',
                  targetDescription: parsed.rawPayload,
                  url: phoneUrl,
                  icon: Icons.phone_in_talk_rounded,
                  iconColor: typeColor,
                );
              },
              icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
              label: const Text(
                'Call Number',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );

      case QrType.email:
        final emailUrl = parsed.actionUrl ?? 'mailto:${parsed.rawPayload}';
        return actionWithCopyShare(
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: typeColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _confirmAndLaunch(
                  context,
                  title: 'Compose Email?',
                  actionLabel: 'Open Email App',
                  targetDescription: parsed.rawPayload,
                  url: emailUrl,
                  icon: Icons.mail_outline_rounded,
                  iconColor: typeColor,
                );
              },
              icon: const Icon(Icons.mail_outline_rounded, size: 20),
              label: const Text(
                'Compose Email',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );

      case QrType.sms:
        final smsUrl = parsed.actionUrl ?? 'smsto:${parsed.rawPayload}';
        return actionWithCopyShare(
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: typeColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _confirmAndLaunch(
                  context,
                  title: 'Send SMS Message?',
                  actionLabel: 'Open Messages App',
                  targetDescription: parsed.rawPayload,
                  url: smsUrl,
                  icon: Icons.sms_outlined,
                  iconColor: typeColor,
                );
              },
              icon: const Icon(Icons.sms_outlined, size: 20),
              label: const Text(
                'Send SMS Message',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );

      case QrType.location:
        final mapUrl = parsed.actionUrl ?? parsed.rawPayload;
        return actionWithCopyShare(
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: typeColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _confirmAndLaunch(
                  context,
                  title: 'Open in Maps?',
                  actionLabel: 'Launch Maps',
                  targetDescription: parsed.rawPayload,
                  url: mapUrl,
                  icon: Icons.map_rounded,
                  iconColor: typeColor,
                );
              },
              icon: const Icon(Icons.map_rounded, size: 20),
              label: const Text(
                'Open Location in Maps',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );

      case QrType.contact:
        final phone = parsed.details['Phone'];
        return actionWithCopyShare(
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: typeColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (phone != null && phone.isNotEmpty) {
                  _confirmAndLaunch(
                    context,
                    title: 'Call Contact?',
                    actionLabel: 'Call $phone',
                    targetDescription:
                        '${parsed.displayTitle}\nPhone: $phone',
                    url: 'tel:$phone',
                    icon: Icons.phone_in_talk_rounded,
                    iconColor: typeColor,
                  );
                } else {
                  copyDefault();
                }
              },
              icon: const Icon(Icons.contact_phone_rounded, size: 20),
              label: Text(
                phone != null && phone.isNotEmpty
                    ? 'Call Contact ($phone)'
                    : 'Copy Contact Details',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );

      case QrType.businessCard:
        final phone = parsed.details['Phone'];
        final website = parsed.details['Website'];
        return actionWithCopyShare(
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: typeColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (phone != null && phone.isNotEmpty) {
                  _confirmAndLaunch(
                    context,
                    title: 'Call Business?',
                    actionLabel: 'Call $phone',
                    targetDescription:
                        '${parsed.displayTitle}\nPhone: $phone',
                    url: 'tel:$phone',
                    icon: Icons.phone_in_talk_rounded,
                    iconColor: typeColor,
                  );
                } else if (website != null && website.isNotEmpty) {
                  final webUrl = website.startsWith('http')
                      ? website
                      : 'https://$website';
                  _confirmAndLaunch(
                    context,
                    title: 'Visit Business Website?',
                    actionLabel: 'Open Website',
                    targetDescription: webUrl,
                    url: webUrl,
                    icon: Icons.open_in_browser_rounded,
                    iconColor: typeColor,
                  );
                } else {
                  copyDefault();
                }
              },
              icon: const Icon(Icons.badge_rounded, size: 20),
              label: Text(
                phone != null && phone.isNotEmpty
                    ? 'Call ($phone)'
                    : 'Open Business Card',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );

      case QrType.businessInfo:
        final phone = parsed.details['Phone'];
        final website = parsed.details['Website'];
        return actionWithCopyShare(
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: typeColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (phone != null && phone.isNotEmpty) {
                  _confirmAndLaunch(
                    context,
                    title: 'Contact Business?',
                    actionLabel: 'Call $phone',
                    targetDescription:
                        '${parsed.displayTitle}\nPhone: $phone',
                    url: 'tel:$phone',
                    icon: Icons.phone_in_talk_rounded,
                    iconColor: typeColor,
                  );
                } else if (website != null && website.isNotEmpty) {
                  final webUrl = website.startsWith('http')
                      ? website
                      : 'https://$website';
                  _confirmAndLaunch(
                    context,
                    title: 'Visit Business Website?',
                    actionLabel: 'Open Website',
                    targetDescription: webUrl,
                    url: webUrl,
                    icon: Icons.open_in_browser_rounded,
                    iconColor: typeColor,
                  );
                } else {
                  copyDefault();
                }
              },
              icon: const Icon(Icons.storefront_rounded, size: 20),
              label: Text(
                phone != null && phone.isNotEmpty
                    ? 'Contact Business ($phone)'
                    : 'View Business Info',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );

      case QrType.wifi:
        final pass = parsed.details['Password'] ?? '';
        return actionWithCopyShare(
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: typeColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                QrSharingService.copyToClipboard(
                  context,
                  pass.isNotEmpty ? pass : parsed.rawPayload,
                  message: pass.isNotEmpty
                      ? 'Wi-Fi Password copied to clipboard!'
                      : 'Wi-Fi details copied!',
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 20),
              label: Text(
                pass.isNotEmpty ? 'Copy Wi-Fi Password' : 'Copy Network Info',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          onCopy: () {
            QrSharingService.copyToClipboard(
              context,
              pass.isNotEmpty ? pass : parsed.rawPayload,
              message: pass.isNotEmpty
                  ? 'Wi-Fi Password copied!'
                  : 'Wi-Fi network details copied!',
            );
          },
        );

      case QrType.text:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: copyDefault,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text(
                  'Copy Plain Text',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: shareDefault,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text(
                  'Share Text',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
    }
  }
}
