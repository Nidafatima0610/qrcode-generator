import 'package:flutter/material.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';

enum QrType {
  text,
  url,
  wifi,
  contact,
  email,
  phone,
  sms,
  location,
  social;

  String get label {
    switch (this) {
      case QrType.text:
        return 'Plain Text';
      case QrType.url:
        return 'Website URL';
      case QrType.wifi:
        return 'Wi-Fi Network';
      case QrType.contact:
        return 'Contact (vCard)';
      case QrType.email:
        return 'Email';
      case QrType.phone:
        return 'Phone Call';
      case QrType.sms:
        return 'SMS Message';
      case QrType.location:
        return 'Location / Map';
      case QrType.social:
        return 'Social Profile';
    }
  }

  String get shortName {
    switch (this) {
      case QrType.text:
        return 'Text';
      case QrType.url:
        return 'URL';
      case QrType.wifi:
        return 'Wi-Fi';
      case QrType.contact:
        return 'Contact';
      case QrType.email:
        return 'Email';
      case QrType.phone:
        return 'Phone';
      case QrType.sms:
        return 'SMS';
      case QrType.location:
        return 'Location';
      case QrType.social:
        return 'Social';
    }
  }

  String get description {
    switch (this) {
      case QrType.text:
        return 'Notes, messages, or arbitrary text';
      case QrType.url:
        return 'Direct link to website or web app';
      case QrType.wifi:
        return 'Instant passwordless Wi-Fi connect';
      case QrType.contact:
        return 'Save contact details directly to address book';
      case QrType.email:
        return 'Compose an email with pre-filled fields';
      case QrType.phone:
        return 'Dial a telephone number instantly';
      case QrType.sms:
        return 'Send a text message with message template';
      case QrType.location:
        return 'Share coordinates or location map URL';
      case QrType.social:
        return 'Connect on social media or profile page';
    }
  }

  IconData get icon {
    switch (this) {
      case QrType.text:
        return Icons.notes_rounded;
      case QrType.url:
        return Icons.link_rounded;
      case QrType.wifi:
        return Icons.wifi_rounded;
      case QrType.contact:
        return Icons.contact_page_rounded;
      case QrType.email:
        return Icons.mail_outline_rounded;
      case QrType.phone:
        return Icons.phone_in_talk_rounded;
      case QrType.sms:
        return Icons.sms_outlined;
      case QrType.location:
        return Icons.location_on_rounded;
      case QrType.social:
        return Icons.share_rounded;
    }
  }

  Color get color {
    switch (this) {
      case QrType.text:
        return AppColors.typeText;
      case QrType.url:
        return AppColors.typeUrl;
      case QrType.wifi:
        return AppColors.typeWifi;
      case QrType.contact:
        return AppColors.typeContact;
      case QrType.email:
        return AppColors.typeEmail;
      case QrType.phone:
        return AppColors.typePhone;
      case QrType.sms:
        return AppColors.typeSms;
      case QrType.location:
        return AppColors.typeLocation;
      case QrType.social:
        return AppColors.typeSocial;
    }
  }

  static QrType fromString(String val) {
    final clean = val.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    return QrType.values.firstWhere(
      (e) => e.name.toLowerCase() == clean || (clean.contains('social') && e == QrType.social) || (clean.contains('location') && e == QrType.location),
      orElse: () => QrType.text,
    );
  }
}
