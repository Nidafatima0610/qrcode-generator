import 'package:flutter/material.dart';

/// Supported types of content that can be encoded into a QR code.
enum QrPayloadType {
  text(
    label: 'Text',
    icon: Icons.text_fields_rounded,
    hintText: 'Enter any text, notes, or message...',
    keyboardType: TextInputType.multiline,
    helperText: 'Free-form text content encoded as UTF-8.',
  ),
  url(
    label: 'Website',
    icon: Icons.link_rounded,
    hintText: 'https://example.com',
    keyboardType: TextInputType.url,
    helperText: 'Links will open directly in the browser when scanned.',
  ),
  email(
    label: 'Email',
    icon: Icons.alternate_email_rounded,
    hintText: 'user@example.com or mailto:user@domain.com',
    keyboardType: TextInputType.emailAddress,
    helperText: 'Prompts to send an email to this address.',
  ),
  phone(
    label: 'Phone',
    icon: Icons.phone_rounded,
    hintText: '+1 234 567 8900',
    keyboardType: TextInputType.phone,
    helperText: 'Prompts scanner to dial this phone number.',
  ),
  wifi(
    label: 'Wi-Fi',
    icon: Icons.wifi_rounded,
    hintText: 'WIFI:S:NetworkName;T:WPA;P:secretPassword;;',
    keyboardType: TextInputType.text,
    helperText: 'Format: WIFI:S:SSID;T:WPA;P:password;;',
  ),
  sms(
    label: 'SMS',
    icon: Icons.sms_outlined,
    hintText: 'smsto:+123456789:Hello there',
    keyboardType: TextInputType.text,
    helperText: 'Prompts to compose an SMS message.',
  );

  const QrPayloadType({
    required this.label,
    required this.icon,
    required this.hintText,
    required this.keyboardType,
    required this.helperText,
  });

  final String label;
  final IconData icon;
  final String hintText;
  final TextInputType keyboardType;
  final String helperText;
}
