import 'package:qrcode_generator/core/models/qr_type.dart';

class ParsedQrContent {
  final QrType type;
  final String displayTitle;
  final String displaySubtitle;
  final String rawPayload;
  final String? actionUrl;
  final Map<String, String> details;

  const ParsedQrContent({
    required this.type,
    required this.displayTitle,
    required this.displaySubtitle,
    required this.rawPayload,
    this.actionUrl,
    this.details = const {},
  });
}

class QrPayloadBuilder {
  /// Build payload for plain text
  static String buildText(String text) {
    return text.trim();
  }

  /// Build payload for Website URL
  static String buildUrl(String url) {
    String trimmed = url.trim();
    if (!trimmed.toLowerCase().startsWith('http://') &&
        !trimmed.toLowerCase().startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }
    return trimmed;
  }

  /// Build payload for Wi-Fi network
  /// Format: WIFI:T:WPA;S:NetworkName;P:Password;H:false;;
  static String buildWifi({
    required String ssid,
    required String password,
    required String security, // 'WPA', 'WEP', 'nopass'
    required bool hidden,
  }) {
    final cleanSsid = ssid.replaceAll(';', r'\;').replaceAll(':', r'\:');
    final cleanPassword = password.replaceAll(';', r'\;').replaceAll(':', r'\:');
    return 'WIFI:T:$security;S:$cleanSsid;P:$cleanPassword;H:$hidden;;';
  }

  /// Build payload for Contact (vCard 3.0)
  static String buildContact({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String company,
    required String address,
    required String website,
  }) {
    final fullName = '$firstName $lastName'.trim();
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    buffer.writeln('N:$lastName;$firstName;;;');
    buffer.writeln('FN:$fullName');
    if (company.isNotEmpty) buffer.writeln('ORG:$company');
    if (phone.isNotEmpty) buffer.writeln('TEL;TYPE=CELL:$phone');
    if (email.isNotEmpty) buffer.writeln('EMAIL:$email');
    if (address.isNotEmpty) buffer.writeln('ADR;TYPE=WORK:;;$address;;;;');
    if (website.isNotEmpty) {
      final formattedUrl = buildUrl(website);
      buffer.writeln('URL:$formattedUrl');
    }
    buffer.write('END:VCARD');
    return buffer.toString();
  }

  /// Build payload for Email
  static String buildEmail({
    required String email,
    required String subject,
    required String body,
  }) {
    final cleanEmail = email.trim();
    final queryParams = <String>[];
    if (subject.isNotEmpty) {
      queryParams.add('subject=${Uri.encodeComponent(subject)}');
    }
    if (body.isNotEmpty) {
      queryParams.add('body=${Uri.encodeComponent(body)}');
    }
    final query = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    return 'mailto:$cleanEmail$query';
  }

  /// Build payload for Phone
  static String buildPhone(String phone) {
    return 'tel:${phone.trim()}';
  }

  /// Build payload for SMS
  static String buildSms({
    required String phone,
    required String message,
  }) {
    return 'smsto:${phone.trim()}:${message.trim()}';
  }

  /// Parse any scanned or stored raw payload into structured data
  static ParsedQrContent parse(String raw) {
    final trimmed = raw.trim();

    // 1. Wi-Fi
    if (trimmed.startsWith('WIFI:') || trimmed.startsWith('wifi:')) {
      final details = <String, String>{};
      final ssidMatch = RegExp(r'S:([^;]+);').firstMatch(trimmed);
      final passMatch = RegExp(r'P:([^;]+);').firstMatch(trimmed);
      final typeMatch = RegExp(r'T:([^;]+);').firstMatch(trimmed);
      final hiddenMatch = RegExp(r'H:([^;]+);').firstMatch(trimmed);

      final ssid = ssidMatch?.group(1) ?? 'Unknown Wi-Fi';
      final pass = passMatch?.group(1) ?? 'None';
      final sec = typeMatch?.group(1) ?? 'WPA';
      final isHidden = hiddenMatch?.group(1) == 'true';

      details['SSID'] = ssid;
      details['Security'] = sec;
      details['Password'] = pass;
      details['Hidden'] = isHidden ? 'Yes' : 'No';

      return ParsedQrContent(
        type: QrType.wifi,
        displayTitle: ssid,
        displaySubtitle: 'Security: $sec • Password: $pass',
        rawPayload: trimmed,
        details: details,
      );
    }

    // 2. Contact / vCard
    if (trimmed.startsWith('BEGIN:VCARD') || trimmed.contains('VERSION:3.0')) {
      final details = <String, String>{};
      final fnMatch = RegExp(r'FN:(.+)', caseSensitive: false).firstMatch(trimmed);
      final telMatch = RegExp(r'TEL[^:]*:(.+)', caseSensitive: false).firstMatch(trimmed);
      final emailMatch = RegExp(r'EMAIL[^:]*:(.+)', caseSensitive: false).firstMatch(trimmed);
      final orgMatch = RegExp(r'ORG:(.+)', caseSensitive: false).firstMatch(trimmed);
      final adrMatch = RegExp(r'ADR[^:]*:(.+)', caseSensitive: false).firstMatch(trimmed);
      final urlMatch = RegExp(r'URL:(.+)', caseSensitive: false).firstMatch(trimmed);

      final fullName = fnMatch?.group(1)?.trim() ?? 'Contact Card';
      if (fullName.isNotEmpty) details['Name'] = fullName;
      if (telMatch != null) details['Phone'] = telMatch.group(1)!.trim();
      if (emailMatch != null) details['Email'] = emailMatch.group(1)!.trim();
      if (orgMatch != null) details['Organization'] = orgMatch.group(1)!.trim();
      if (adrMatch != null) {
        details['Address'] = adrMatch.group(1)!.replaceAll(';', ' ').trim();
      }
      if (urlMatch != null) details['Website'] = urlMatch.group(1)!.trim();

      final phone = details['Phone'] ?? '';
      return ParsedQrContent(
        type: QrType.contact,
        displayTitle: fullName,
        displaySubtitle: phone.isNotEmpty ? phone : (details['Email'] ?? 'vCard Contact'),
        rawPayload: trimmed,
        actionUrl: phone.isNotEmpty ? 'tel:$phone' : null,
        details: details,
      );
    }

    // 3. URL
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        (trimmed.contains('.') &&
            !trimmed.contains(' ') &&
            (trimmed.endsWith('.com') ||
                trimmed.endsWith('.org') ||
                trimmed.endsWith('.net') ||
                trimmed.endsWith('.io') ||
                trimmed.endsWith('.app') ||
                trimmed.endsWith('.dev')))) {
      final url = buildUrl(trimmed);
      Uri? parsedUri = Uri.tryParse(url);
      final domain = parsedUri?.host.isNotEmpty == true ? parsedUri!.host : url;

      return ParsedQrContent(
        type: QrType.url,
        displayTitle: domain,
        displaySubtitle: url,
        rawPayload: url,
        actionUrl: url,
        details: {'URL': url},
      );
    }

    // 4. Email
    if (trimmed.startsWith('mailto:') || trimmed.startsWith('MATMSG:')) {
      final details = <String, String>{};
      String email = '';
      String subject = '';
      String body = '';

      if (trimmed.startsWith('mailto:')) {
        final uri = Uri.tryParse(trimmed);
        if (uri != null) {
          email = uri.path;
          subject = uri.queryParameters['subject'] ?? '';
          body = uri.queryParameters['body'] ?? '';
        }
      } else {
        final toMatch = RegExp(r'TO:([^;]+);').firstMatch(trimmed);
        final subMatch = RegExp(r'SUB:([^;]+);').firstMatch(trimmed);
        final bodyMatch = RegExp(r'BODY:([^;]+);').firstMatch(trimmed);
        email = toMatch?.group(1) ?? '';
        subject = subMatch?.group(1) ?? '';
        body = bodyMatch?.group(1) ?? '';
      }

      details['To'] = email;
      if (subject.isNotEmpty) details['Subject'] = subject;
      if (body.isNotEmpty) details['Message'] = body;

      return ParsedQrContent(
        type: QrType.email,
        displayTitle: email.isNotEmpty ? email : 'Email Message',
        displaySubtitle: subject.isNotEmpty ? subject : 'Tap to compose email',
        rawPayload: trimmed,
        actionUrl: trimmed.startsWith('mailto:') ? trimmed : 'mailto:$email',
        details: details,
      );
    }

    // 5. Phone Call
    if (trimmed.startsWith('tel:') || trimmed.startsWith('TEL:')) {
      final phone = trimmed.substring(4);
      return ParsedQrContent(
        type: QrType.phone,
        displayTitle: phone,
        displaySubtitle: 'Phone Number',
        rawPayload: trimmed,
        actionUrl: 'tel:$phone',
        details: {'Phone': phone},
      );
    }

    // 6. SMS
    if (trimmed.toLowerCase().startsWith('smsto:')) {
      final parts = trimmed.substring(6).split(':');
      final phone = parts.isNotEmpty ? parts[0] : '';
      final message = parts.length > 1 ? parts.sublist(1).join(':') : '';

      final details = <String, String>{'Phone': phone};
      if (message.isNotEmpty) details['Message'] = message;

      return ParsedQrContent(
        type: QrType.sms,
        displayTitle: phone,
        displaySubtitle: message.isNotEmpty ? message : 'SMS Message',
        rawPayload: trimmed,
        actionUrl: 'sms:$phone',
        details: details,
      );
    }

    // Default: Plain Text
    return ParsedQrContent(
      type: QrType.text,
      displayTitle: trimmed.length > 30 ? '${trimmed.substring(0, 30)}...' : trimmed,
      displaySubtitle: trimmed,
      rawPayload: trimmed,
      details: {'Text': trimmed},
    );
  }
}
