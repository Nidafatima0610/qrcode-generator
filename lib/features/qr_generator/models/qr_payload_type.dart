import 'package:flutter/material.dart';

/// Supported types of content that can be encoded into a QR code.
enum QrPayloadType {
  text(
    label: 'Plain Text',
    icon: Icons.text_fields_rounded,
    hintText: 'Enter text, notes, or messages...',
    keyboardType: TextInputType.multiline,
    helperText: 'Standard plain text encoded directly as UTF-8.',
  ),
  url(
    label: 'Website / URL',
    icon: Icons.language_rounded,
    hintText: 'https://example.com',
    keyboardType: TextInputType.url,
    helperText: 'Opens the webpage in the default browser when scanned.',
  ),
  wifi(
    label: 'Wi-Fi',
    icon: Icons.wifi_rounded,
    hintText: 'MyHomeNetwork',
    keyboardType: TextInputType.text,
    helperText: 'Prompts device camera to connect to the Wi-Fi network.',
  ),
  email(
    label: 'Email',
    icon: Icons.alternate_email_rounded,
    hintText: 'user@example.com',
    keyboardType: TextInputType.emailAddress,
    helperText: 'Prompts scanner to compose an email.',
  ),
  phone(
    label: 'Phone Number',
    icon: Icons.phone_rounded,
    hintText: '+1 234 567 8900',
    keyboardType: TextInputType.phone,
    helperText: 'Prompts scanner to dial this phone number directly.',
  ),
  contact(
    label: 'Contact / vCard',
    icon: Icons.contact_page_rounded,
    hintText: 'John Doe',
    keyboardType: TextInputType.name,
    helperText: 'Universal vCard 3.0 format to save contact in address book.',
  ),
  sms(
    label: 'SMS',
    icon: Icons.sms_rounded,
    hintText: '+1 234 567 8900',
    keyboardType: TextInputType.phone,
    helperText: 'Prompts to draft an SMS message to this number.',
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
