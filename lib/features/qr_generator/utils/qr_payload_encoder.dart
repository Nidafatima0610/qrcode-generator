/// Utility responsible for encoding form data into RFC/standard QR code payloads
/// (e.g. vCard 3.0, Wi-Fi standard, mailto, tel, smsto).
class QrPayloadEncoder {
  /// Encodes plain text.
  static String encodeText(String text) {
    return text.trim();
  }

  /// Encodes and normalizes a Website URL.
  static String encodeUrl(String rawUrl) {
    var url = rawUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }

  /// Encodes Wi-Fi credentials into standard format:
  /// `WIFI:S:MySSID;T:WPA;P:password;H:false;;`
  static String encodeWifi({
    required String ssid,
    required String password,
    required String security,
    bool isHidden = false,
  }) {
    String escape(String value) {
      return value
          .replaceAll(r'\', r'\\')
          .replaceAll(';', r'\;')
          .replaceAll(',', r'\,')
          .replaceAll(':', r'\:');
    }

    final cleanSsid = escape(ssid.trim());
    final cleanPassword = escape(password.trim());

    final String secTag;
    switch (security.toUpperCase()) {
      case 'WEP':
        secTag = 'WEP';
        break;
      case 'NONE':
      case 'OPEN':
        secTag = 'nopass';
        break;
      case 'WPA':
      case 'WPA/WPA2':
      case 'WPA2':
      default:
        secTag = 'WPA';
        break;
    }

    final passTag = secTag == 'nopass' ? '' : cleanPassword;
    final hiddenTag = isHidden ? 'true' : 'false';

    return 'WIFI:S:$cleanSsid;T:$secTag;P:$passTag;H:$hiddenTag;;';
  }

  /// Encodes an Email address with optional subject and message body.
  static String encodeEmail({
    required String email,
    String? subject,
    String? body,
  }) {
    final cleanEmail = email.trim();
    final queryParams = <String>[];

    if (subject != null && subject.trim().isNotEmpty) {
      queryParams.add('subject=${Uri.encodeComponent(subject.trim())}');
    }
    if (body != null && body.trim().isNotEmpty) {
      queryParams.add('body=${Uri.encodeComponent(body.trim())}');
    }

    if (queryParams.isEmpty) {
      return 'mailto:$cleanEmail';
    }
    return 'mailto:$cleanEmail?${queryParams.join('&')}';
  }

  /// Encodes a Phone number for direct camera dialing.
  static String encodePhone(String phone) {
    final clean = phone.trim().replaceAll(' ', '');
    return 'tel:$clean';
  }

  /// Encodes an SMS message: `smsto:+123456789:Message`
  static String encodeSms({
    required String phone,
    required String message,
  }) {
    final cleanPhone = phone.trim().replaceAll(' ', '');
    return 'smsto:$cleanPhone:${message.trim()}';
  }

  /// Encodes a Contact card into universally recognized vCard 3.0 format.
  static String encodeContact({
    required String name,
    String? phone,
    String? email,
    String? organization,
  }) {
    final cleanName = name.trim();
    final parts = cleanName.split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    buffer.writeln('FN:$cleanName');
    buffer.writeln('N:$lastName;$firstName;;;');

    if (organization != null && organization.trim().isNotEmpty) {
      buffer.writeln('ORG:${organization.trim()}');
    }
    if (phone != null && phone.trim().isNotEmpty) {
      buffer.writeln('TEL:${phone.trim().replaceAll(' ', '')}');
    }
    if (email != null && email.trim().isNotEmpty) {
      buffer.writeln('EMAIL:${email.trim()}');
    }

    buffer.write('END:VCARD');
    return buffer.toString();
  }
}
