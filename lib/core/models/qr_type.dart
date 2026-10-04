import 'package:flutter/material.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';

enum QrType {
  text,
  url,
  wifi,
  contact,
  email,
  phone,
  sms;

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
    }
  }

  static QrType fromString(String val) {
    return QrType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => QrType.text,
    );
  }
}
