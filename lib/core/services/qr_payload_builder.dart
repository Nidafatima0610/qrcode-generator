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

  /// Build payload for Business Card (vCard 3.0 with extended profile)
  static String buildBusinessCard({
    required String fullName,
    required String jobTitle,
    required String company,
    required String phone,
    required String email,
    required String website,
    required String address,
    required String socialUrl,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    final nameParts = fullName.trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    buffer.writeln('N:$lastName;$firstName;;;');
    buffer.writeln('FN:${fullName.trim()}');
    if (jobTitle.trim().isNotEmpty) buffer.writeln('TITLE:${jobTitle.trim()}');
    if (company.trim().isNotEmpty) buffer.writeln('ORG:${company.trim()}');
    if (phone.trim().isNotEmpty) buffer.writeln('TEL;TYPE=CELL,VOICE:${phone.trim()}');
    if (email.trim().isNotEmpty) buffer.writeln('EMAIL;TYPE=INTERNET:${email.trim()}');
    if (website.trim().isNotEmpty) {
      buffer.writeln('URL:${buildUrl(website.trim())}');
    }
    if (address.trim().isNotEmpty) {
      buffer.writeln('ADR;TYPE=WORK:;;${address.trim()};;;;');
    }
    if (socialUrl.trim().isNotEmpty) {
      buffer.writeln('X-SOCIALPROFILE:${buildUrl(socialUrl.trim())}');
    }
    buffer.write('END:VCARD');
    return buffer.toString();
  }

  /// Build payload for Business Information
  static String buildBusinessInfo({
    required String businessName,
    required String phone,
    required String email,
    required String website,
    required String address,
    required String description,
    required String businessHours,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    buffer.writeln('FN:${businessName.trim()}');
    buffer.writeln('ORG:${businessName.trim()}');
    if (phone.trim().isNotEmpty) buffer.writeln('TEL;TYPE=WORK,VOICE:${phone.trim()}');
    if (email.trim().isNotEmpty) buffer.writeln('EMAIL;TYPE=INTERNET:${email.trim()}');
    if (website.trim().isNotEmpty) {
      buffer.writeln('URL:${buildUrl(website.trim())}');
    }
    if (address.trim().isNotEmpty) {
      buffer.writeln('ADR;TYPE=WORK:;;${address.trim()};;;;');
    }
    final noteParts = <String>[];
    if (businessHours.trim().isNotEmpty) noteParts.add('Hours: ${businessHours.trim()}');
    if (description.trim().isNotEmpty) noteParts.add('About: ${description.trim()}');
    if (noteParts.isNotEmpty) {
      buffer.writeln('NOTE:${noteParts.join(' | ')}');
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

  /// Build payload for Location (Google Maps URL & Geo payload)
  static String buildLocation({
    required double latitude,
    required double longitude,
    String? name,
  }) {
    if (name != null && name.trim().isNotEmpty) {
      return 'https://maps.google.com/?q=${Uri.encodeComponent(name.trim())}&ll=$latitude,$longitude';
    }
    return 'https://maps.google.com/?q=$latitude,$longitude';
  }

  /// Build payload for Social Profile
  static String buildSocial({
    required String platform,
    required String usernameOrUrl,
  }) {
    final clean = usernameOrUrl.trim();
    if (clean.toLowerCase().startsWith('http://') || clean.toLowerCase().startsWith('https://')) {
      return clean;
    }
    final handle = clean.replaceAll('@', '');
    switch (platform.toLowerCase()) {
      case 'instagram':
        return 'https://instagram.com/$handle';
      case 'linkedin':
        return 'https://linkedin.com/in/$handle';
      case 'twitter':
      case 'x':
      case 'twitter/x':
        return 'https://x.com/$handle';
      case 'github':
        return 'https://github.com/$handle';
      case 'youtube':
        return 'https://youtube.com/@$handle';
      case 'facebook':
        return 'https://facebook.com/$handle';
      case 'tiktok':
        return 'https://tiktok.com/@$handle';
      default:
        return 'https://$clean';
    }
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

    // 2. Contact / Business Card / Business Info (vCard)
    if (trimmed.startsWith('BEGIN:VCARD') || trimmed.contains('VERSION:3.0')) {
      final details = <String, String>{};
      final fnMatch = RegExp(r'FN:(.+)', caseSensitive: false).firstMatch(trimmed);
      final titleMatch = RegExp(r'TITLE:(.+)', caseSensitive: false).firstMatch(trimmed);
      final telMatch = RegExp(r'TEL[^:]*:(.+)', caseSensitive: false).firstMatch(trimmed);
      final emailMatch = RegExp(r'EMAIL[^:]*:(.+)', caseSensitive: false).firstMatch(trimmed);
      final orgMatch = RegExp(r'ORG:(.+)', caseSensitive: false).firstMatch(trimmed);
      final adrMatch = RegExp(r'ADR[^:]*:(.+)', caseSensitive: false).firstMatch(trimmed);
      final urlMatch = RegExp(r'URL:(.+)', caseSensitive: false).firstMatch(trimmed);
      final socialMatch = RegExp(r'X-SOCIALPROFILE:(.+)', caseSensitive: false).firstMatch(trimmed);
      final noteMatch = RegExp(r'NOTE:(.+)', caseSensitive: false).firstMatch(trimmed);

      final fullName = fnMatch?.group(1)?.trim() ?? 'Contact Card';
      if (fullName.isNotEmpty) details['Name'] = fullName;
      if (titleMatch != null) details['Job Title'] = titleMatch.group(1)!.trim();
      if (orgMatch != null) details['Organization'] = orgMatch.group(1)!.trim();
      if (telMatch != null) details['Phone'] = telMatch.group(1)!.trim();
      if (emailMatch != null) details['Email'] = emailMatch.group(1)!.trim();
      if (adrMatch != null) {
        details['Address'] = adrMatch.group(1)!.replaceAll(';', ' ').trim();
      }
      if (urlMatch != null) details['Website'] = urlMatch.group(1)!.trim();
      if (socialMatch != null) details['Social Profile'] = socialMatch.group(1)!.trim();
      if (noteMatch != null) details['Notes'] = noteMatch.group(1)!.trim();

      final phone = details['Phone'] ?? '';
      final jobTitle = details['Job Title'] ?? '';
      final org = details['Organization'] ?? '';

      // Determine detected type conservatively
      QrType detectedType = QrType.contact;
      if (noteMatch != null && (noteMatch.group(1)!.contains('Hours:') || noteMatch.group(1)!.contains('About:'))) {
        detectedType = QrType.businessInfo;
      } else if (jobTitle.isNotEmpty || socialMatch != null) {
        detectedType = QrType.businessCard;
      }

      String subtitle = phone;
      if (subtitle.isEmpty && jobTitle.isNotEmpty && org.isNotEmpty) {
        subtitle = '$jobTitle at $org';
      } else if (subtitle.isEmpty) {
        subtitle = details['Email'] ?? (org.isNotEmpty ? org : 'vCard Contact');
      }

      return ParsedQrContent(
        type: detectedType,
        displayTitle: fullName,
        displaySubtitle: subtitle,
        rawPayload: trimmed,
        actionUrl: phone.isNotEmpty ? 'tel:$phone' : (details['Website'] != null ? buildUrl(details['Website']!) : null),
        details: details,
      );
    }

    // 3. Location (geo: URI or Google/Apple Maps URL)
    if (trimmed.startsWith('geo:') ||
        trimmed.contains('maps.google.com') ||
        trimmed.contains('google.com/maps') ||
        trimmed.contains('maps.apple.com')) {
      final details = <String, String>{};
      String title = 'Location / Map';
      String subtitle = trimmed;
      String actionUrl = trimmed;

      if (trimmed.startsWith('geo:')) {
        final geoPart = trimmed.substring(4);
        final parts = geoPart.split('?');
        final coords = parts[0].split(',');
        if (coords.length >= 2) {
          details['Latitude'] = coords[0].trim();
          details['Longitude'] = coords[1].trim();
          title = 'Map Coordinates';
          subtitle = 'Lat: ${coords[0]}, Lng: ${coords[1]}';
          actionUrl = 'https://maps.google.com/?q=${coords[0]},${coords[1]}';
        }
        if (parts.length > 1) {
          details['Query'] = Uri.decodeComponent(parts[1]);
        }
      } else {
        details['Map URL'] = trimmed;
        final qMatch = RegExp(r'[?&]q=([^&]+)').firstMatch(trimmed);
        if (qMatch != null) {
          final queryVal = Uri.decodeComponent(qMatch.group(1)!);
          title = queryVal;
          subtitle = 'Google Maps Location';
          details['Location'] = queryVal;
        }
      }

      return ParsedQrContent(
        type: QrType.location,
        displayTitle: title,
        displaySubtitle: subtitle,
        rawPayload: trimmed,
        actionUrl: actionUrl,
        details: details,
      );
    }

    // 4. Social Profile URL
    final lower = trimmed.toLowerCase();
    if (lower.contains('instagram.com/') ||
        lower.contains('linkedin.com/') ||
        lower.contains('twitter.com/') ||
        lower.contains('x.com/') ||
        lower.contains('github.com/') ||
        lower.contains('youtube.com/') ||
        lower.contains('tiktok.com/') ||
        lower.contains('facebook.com/')) {
      String platform = 'Social Profile';
      if (lower.contains('instagram.com/')) platform = 'Instagram';
      if (lower.contains('linkedin.com/')) platform = 'LinkedIn';
      if (lower.contains('twitter.com/') || lower.contains('x.com/')) platform = 'X (Twitter)';
      if (lower.contains('github.com/')) platform = 'GitHub';
      if (lower.contains('youtube.com/')) platform = 'YouTube';
      if (lower.contains('tiktok.com/')) platform = 'TikTok';
      if (lower.contains('facebook.com/')) platform = 'Facebook';

      final url = buildUrl(trimmed);
      return ParsedQrContent(
        type: QrType.social,
        displayTitle: '$platform Profile',
        displaySubtitle: url,
        rawPayload: url,
        actionUrl: url,
        details: {'Platform': platform, 'Profile URL': url},
      );
    }

    // 5. Standard Website URL
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
      final parsedUri = Uri.tryParse(url);
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

    // 6. Email
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

    // 7. Phone Call
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

    // 8. SMS
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

    // 9. Default: Plain Text
    return ParsedQrContent(
      type: QrType.text,
      displayTitle: trimmed.length > 30 ? '${trimmed.substring(0, 30)}...' : trimmed,
      displaySubtitle: trimmed,
      rawPayload: trimmed,
      details: {'Text': trimmed},
    );
  }
}
