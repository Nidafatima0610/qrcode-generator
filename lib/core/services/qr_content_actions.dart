import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';
import 'package:qrcode_generator/core/services/qr_payload_builder.dart';
import 'package:qrcode_generator/core/services/qr_sharing_service.dart';

class QrContentActionItem {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const QrContentActionItem({
    required this.label,
    required this.icon,
    this.color,
    required this.onTap,
  });
}

class QrContentActions {
  /// Open external URL safely after user taps action
  static Future<bool> launchSafely(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open: $url'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to launch action ($e)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  /// Returns relevant contextual action buttons for the detected QR content
  static List<QrContentActionItem> getActionsForContent({
    required BuildContext context,
    required String rawContent,
    ParsedQrContent? parsed,
  }) {
    final info = parsed ?? QrPayloadBuilder.parse(rawContent);
    final actions = <QrContentActionItem>[];

    switch (info.type) {
      case QrType.url:
        actions.add(
          QrContentActionItem(
            label: 'Open Website',
            icon: Icons.open_in_browser_rounded,
            color: AppColors.typeUrl,
            onTap: () => launchSafely(context, info.actionUrl ?? rawContent),
          ),
        );
        actions.add(
          QrContentActionItem(
            label: 'Search Web',
            icon: Icons.search_rounded,
            onTap: () => launchSafely(
              context,
              'https://www.google.com/search?q=${Uri.encodeComponent(info.displayTitle)}',
            ),
          ),
        );
        break;

      case QrType.phone:
        final phone = info.details['Phone'] ?? rawContent.replaceAll('tel:', '');
        actions.add(
          QrContentActionItem(
            label: 'Call Number',
            icon: Icons.phone_rounded,
            color: AppColors.typePhone,
            onTap: () => launchSafely(context, 'tel:$phone'),
          ),
        );
        actions.add(
          QrContentActionItem(
            label: 'Send SMS',
            icon: Icons.sms_outlined,
            onTap: () => launchSafely(context, 'sms:$phone'),
          ),
        );
        break;

      case QrType.email:
        final email = info.details['To'] ?? rawContent.replaceAll('mailto:', '');
        actions.add(
          QrContentActionItem(
            label: 'Send Email',
            icon: Icons.mail_outline_rounded,
            color: AppColors.typeEmail,
            onTap: () => launchSafely(context, info.actionUrl ?? 'mailto:$email'),
          ),
        );
        break;

      case QrType.sms:
        final phone = info.details['Phone'] ?? '';
        actions.add(
          QrContentActionItem(
            label: 'Send SMS',
            icon: Icons.sms_outlined,
            color: AppColors.typeSms,
            onTap: () => launchSafely(context, info.actionUrl ?? rawContent),
          ),
        );
        if (phone.isNotEmpty) {
          actions.add(
            QrContentActionItem(
              label: 'Call',
              icon: Icons.phone_in_talk_rounded,
              onTap: () => launchSafely(context, 'tel:$phone'),
            ),
          );
        }
        break;

      case QrType.location:
        actions.add(
          QrContentActionItem(
            label: 'Open in Maps',
            icon: Icons.map_rounded,
            color: AppColors.typeLocation,
            onTap: () {
              final mapUrl = info.actionUrl ?? rawContent;
              launchSafely(context, mapUrl);
            },
          ),
        );
        break;

      case QrType.social:
        actions.add(
          QrContentActionItem(
            label: 'Open Profile',
            icon: Icons.open_in_new_rounded,
            color: AppColors.typeSocial,
            onTap: () => launchSafely(context, info.actionUrl ?? rawContent),
          ),
        );
        break;

      case QrType.wifi:
        final password = info.details['Password'];
        if (password != null && password != 'None' && password.isNotEmpty) {
          actions.add(
            QrContentActionItem(
              label: 'Copy Password',
              icon: Icons.key_rounded,
              color: AppColors.typeWifi,
              onTap: () => QrSharingService.copyToClipboard(
                context,
                password,
                message: 'Wi-Fi password copied!',
              ),
            ),
          );
        }
        break;

      case QrType.contact:
      case QrType.businessCard:
        final phone = info.details['Phone'];
        final email = info.details['Email'];
        final website = info.details['Website'];
        final address = info.details['Address'];

        if (phone != null && phone.isNotEmpty) {
          actions.add(
            QrContentActionItem(
              label: 'Call',
              icon: Icons.phone_rounded,
              color: AppColors.typePhone,
              onTap: () => launchSafely(context, 'tel:$phone'),
            ),
          );
        }
        if (email != null && email.isNotEmpty) {
          actions.add(
            QrContentActionItem(
              label: 'Email',
              icon: Icons.mail_outline_rounded,
              color: AppColors.typeEmail,
              onTap: () => launchSafely(context, 'mailto:$email'),
            ),
          );
        }
        if (website != null && website.isNotEmpty) {
          actions.add(
            QrContentActionItem(
              label: 'Website',
              icon: Icons.language_rounded,
              color: AppColors.typeUrl,
              onTap: () => launchSafely(
                context,
                website.startsWith('http') ? website : 'https://$website',
              ),
            ),
          );
        }
        if (address != null && address.isNotEmpty) {
          actions.add(
            QrContentActionItem(
              label: 'Map',
              icon: Icons.place_rounded,
              color: AppColors.typeLocation,
              onTap: () => launchSafely(
                context,
                'https://maps.google.com/?q=${Uri.encodeComponent(address)}',
              ),
            ),
          );
        }
        break;

      case QrType.businessInfo:
        final phone = info.details['Phone'];
        final email = info.details['Email'];
        final website = info.details['Website'];
        final address = info.details['Address'];

        if (phone != null && phone.isNotEmpty) {
          actions.add(
            QrContentActionItem(
              label: 'Call Business',
              icon: Icons.phone_rounded,
              color: AppColors.typePhone,
              onTap: () => launchSafely(context, 'tel:$phone'),
            ),
          );
        }
        if (website != null && website.isNotEmpty) {
          actions.add(
            QrContentActionItem(
              label: 'Visit Site',
              icon: Icons.storefront_rounded,
              color: AppColors.typeBusinessInfo,
              onTap: () => launchSafely(
                context,
                website.startsWith('http') ? website : 'https://$website',
              ),
            ),
          );
        }
        if (email != null && email.isNotEmpty) {
          actions.add(
            QrContentActionItem(
              label: 'Email',
              icon: Icons.email_outlined,
              color: AppColors.typeEmail,
              onTap: () => launchSafely(context, 'mailto:$email'),
            ),
          );
        }
        if (address != null && address.isNotEmpty) {
          actions.add(
            QrContentActionItem(
              label: 'Directions',
              icon: Icons.directions_rounded,
              color: AppColors.typeLocation,
              onTap: () => launchSafely(
                context,
                'https://maps.google.com/?q=${Uri.encodeComponent(address)}',
              ),
            ),
          );
        }
        break;

      case QrType.text:
        actions.add(
          QrContentActionItem(
            label: 'Search Google',
            icon: Icons.search_rounded,
            onTap: () => launchSafely(
              context,
              'https://www.google.com/search?q=${Uri.encodeComponent(rawContent)}',
            ),
          ),
        );
        break;
    }

    // Universal copy and share actions
    actions.add(
      QrContentActionItem(
        label: 'Copy Text',
        icon: Icons.copy_rounded,
        onTap: () => QrSharingService.copyToClipboard(
          context,
          rawContent,
          message: 'Content copied to clipboard',
        ),
      ),
    );

    actions.add(
      QrContentActionItem(
        label: 'Share Text',
        icon: Icons.share_rounded,
        onTap: () => QrSharingService.shareText(
          text: rawContent,
          subject: info.displayTitle,
        ),
      ),
    );

    return actions;
  }
}
