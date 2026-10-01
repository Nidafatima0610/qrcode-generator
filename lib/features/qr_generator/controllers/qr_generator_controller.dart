import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/core/utils/qr_image_exporter.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_config.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_payload_type.dart';
import 'package:qr_code_generator/features/qr_generator/utils/qr_payload_encoder.dart';
import 'package:qr_code_generator/features/qr_history/controllers/qr_history_controller.dart';
import 'package:qr_code_generator/features/qr_history/models/qr_item.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Business logic controller for QR code creation, multi-type form handling,
/// real-time customization, live contrast checking, and exporting.
class QrGeneratorController extends ChangeNotifier {
  final GlobalKey qrRepaintKey = GlobalKey();

  // Active Type Selection
  QrPayloadType _payloadType = QrPayloadType.text;

  // Form Controllers: Text
  final TextEditingController textController = TextEditingController();

  // Form Controllers: URL
  final TextEditingController urlController = TextEditingController();

  // Form Controllers: Wi-Fi
  final TextEditingController wifiSsidController = TextEditingController();
  final TextEditingController wifiPasswordController = TextEditingController();
  String _wifiSecurity = 'WPA/WPA2';
  bool _wifiIsHidden = false;
  bool _wifiObscurePassword = true;

  // Form Controllers: Email
  final TextEditingController emailAddressController = TextEditingController();
  final TextEditingController emailSubjectController = TextEditingController();
  final TextEditingController emailBodyController = TextEditingController();

  // Form Controllers: Phone
  final TextEditingController phoneController = TextEditingController();

  // Form Controllers: SMS
  final TextEditingController smsPhoneController = TextEditingController();
  final TextEditingController smsMessageController = TextEditingController();

  // Form Controllers: Contact (vCard)
  final TextEditingController contactNameController = TextEditingController();
  final TextEditingController contactPhoneController = TextEditingController();
  final TextEditingController contactEmailController = TextEditingController();
  final TextEditingController contactOrgController = TextEditingController();

  // Styling & Customization State
  Color _foregroundColor = AppTheme.qrForegroundColors.first;
  Color _backgroundColor = Colors.white;
  double _qrSize = 220.0;
  int _errorCorrectionLevel = QrErrorCorrectLevel.M;
  QrEyeShape _eyeShape = QrEyeShape.square;
  QrDataModuleShape _dataModuleShape = QrDataModuleShape.square;

  // Output State
  QrConfig? _currentQr;
  String? _validationError;
  bool _isExporting = false;
  String? _exportStatusMessage;

  QrGeneratorController() {
    _attachListeners();
  }

  void _attachListeners() {
    textController.addListener(_onFieldChanged);
    urlController.addListener(_onFieldChanged);
    wifiSsidController.addListener(_onFieldChanged);
    wifiPasswordController.addListener(_onFieldChanged);
    emailAddressController.addListener(_onFieldChanged);
    emailSubjectController.addListener(_onFieldChanged);
    emailBodyController.addListener(_onFieldChanged);
    phoneController.addListener(_onFieldChanged);
    smsPhoneController.addListener(_onFieldChanged);
    smsMessageController.addListener(_onFieldChanged);
    contactNameController.addListener(_onFieldChanged);
    contactPhoneController.addListener(_onFieldChanged);
    contactEmailController.addListener(_onFieldChanged);
    contactOrgController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (_validationError != null && hasContent) {
      _validationError = null;
    }
    notifyListeners();
  }

  // Getters
  QrPayloadType get payloadType => _payloadType;
  Color get foregroundColor => _foregroundColor;
  Color get backgroundColor => _backgroundColor;
  double get qrSize => _qrSize;
  int get errorCorrectionLevel => _errorCorrectionLevel;
  QrEyeShape get eyeShape => _eyeShape;
  QrDataModuleShape get dataModuleShape => _dataModuleShape;
  QrConfig? get currentQr => _currentQr;
  String? get validationError => _validationError;
  bool get isExporting => _isExporting;
  String? get exportStatusMessage => _exportStatusMessage;
  bool get isQrGenerated => _currentQr != null;

  String get wifiSecurity => _wifiSecurity;
  bool get wifiIsHidden => _wifiIsHidden;
  bool get wifiObscurePassword => _wifiObscurePassword;

  /// Luminance contrast ratio check
  bool get hasSafeContrast =>
      AppTheme.hasSufficientContrast(_foregroundColor, _backgroundColor);
  double get contrastRatio =>
      AppTheme.calculateContrastRatio(_foregroundColor, _backgroundColor);

  /// Whether current active form has any input text
  bool get hasContent {
    switch (_payloadType) {
      case QrPayloadType.text:
        return textController.text.trim().isNotEmpty;
      case QrPayloadType.url:
        return urlController.text.trim().isNotEmpty;
      case QrPayloadType.wifi:
        return wifiSsidController.text.trim().isNotEmpty;
      case QrPayloadType.email:
        return emailAddressController.text.trim().isNotEmpty;
      case QrPayloadType.phone:
        return phoneController.text.trim().isNotEmpty;
      case QrPayloadType.contact:
        return contactNameController.text.trim().isNotEmpty;
      case QrPayloadType.sms:
        return smsPhoneController.text.trim().isNotEmpty;
    }
  }

  // ===================== State Mutation Methods =====================

  /// Switches active QR payload type.
  void setPayloadType(QrPayloadType type) {
    if (_payloadType == type) return;
    _payloadType = type;
    _validationError = null;
    notifyListeners();
  }

  /// Sets foreground dot/eye color.
  void setForegroundColor(Color color) {
    if (_foregroundColor == color) return;
    _foregroundColor = color;
    if (_currentQr != null) {
      _currentQr = _currentQr!.copyWith(foregroundColor: color);
    }
    notifyListeners();
  }

  /// Sets canvas background color.
  void setBackgroundColor(Color color) {
    if (_backgroundColor == color) return;
    _backgroundColor = color;
    if (_currentQr != null) {
      _currentQr = _currentQr!.copyWith(backgroundColor: color);
    }
    notifyListeners();
  }

  /// Sets preview QR size (between 160 and 300 logical px).
  void setQrSize(double size) {
    final clamped = size.clamp(160.0, 300.0);
    if (_qrSize == clamped) return;
    _qrSize = clamped;
    if (_currentQr != null) {
      _currentQr = _currentQr!.copyWith(qrSize: clamped);
    }
    notifyListeners();
  }

  /// Sets error correction level (L, M, Q, H).
  void setErrorCorrectionLevel(int level) {
    if (_errorCorrectionLevel == level) return;
    _errorCorrectionLevel = level;
    if (_currentQr != null) {
      _currentQr = _currentQr!.copyWith(errorCorrectionLevel: level);
    }
    notifyListeners();
  }

  /// Sets eye corners shape (square or circle).
  void setEyeShape(QrEyeShape shape) {
    if (_eyeShape == shape) return;
    _eyeShape = shape;
    if (_currentQr != null) {
      _currentQr = _currentQr!.copyWith(eyeShape: shape);
    }
    notifyListeners();
  }

  /// Sets data module shape (square or circle).
  void setDataModuleShape(QrDataModuleShape shape) {
    if (_dataModuleShape == shape) return;
    _dataModuleShape = shape;
    if (_currentQr != null) {
      _currentQr = _currentQr!.copyWith(dataModuleShape: shape);
    }
    notifyListeners();
  }

  // Wi-Fi Specific Mutators
  void setWifiSecurity(String security) {
    _wifiSecurity = security;
    notifyListeners();
  }

  void toggleWifiHidden(bool value) {
    _wifiIsHidden = value;
    notifyListeners();
  }

  void toggleWifiObscurePassword() {
    _wifiObscurePassword = !_wifiObscurePassword;
    notifyListeners();
  }

  // ===================== Validation & Generation =====================

  /// Validates the active type's form fields and compiles standard QR payload.
  bool generateQr() {
    String encodedPayload = '';

    switch (_payloadType) {
      case QrPayloadType.text:
        final text = textController.text.trim();
        if (text.isEmpty) {
          _validationError = 'Please enter some text to generate a QR code.';
          notifyListeners();
          return false;
        }
        encodedPayload = QrPayloadEncoder.encodeText(text);
        break;

      case QrPayloadType.url:
        final rawUrl = urlController.text.trim();
        if (rawUrl.isEmpty) {
          _validationError = 'Please enter a valid website link or URL.';
          notifyListeners();
          return false;
        }
        encodedPayload = QrPayloadEncoder.encodeUrl(rawUrl);
        urlController.text = encodedPayload;
        break;

      case QrPayloadType.wifi:
        final ssid = wifiSsidController.text.trim();
        final password = wifiPasswordController.text.trim();
        if (ssid.isEmpty) {
          _validationError = 'Please enter your Wi-Fi network name (SSID).';
          notifyListeners();
          return false;
        }
        if (_wifiSecurity != 'None' && password.isEmpty) {
          _validationError = 'Please enter the Wi-Fi password for secure network.';
          notifyListeners();
          return false;
        }
        encodedPayload = QrPayloadEncoder.encodeWifi(
          ssid: ssid,
          password: password,
          security: _wifiSecurity,
          isHidden: _wifiIsHidden,
        );
        break;

      case QrPayloadType.email:
        final email = emailAddressController.text.trim();
        if (email.isEmpty) {
          _validationError = 'Please enter recipient email address.';
          notifyListeners();
          return false;
        }
        final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
        if (!emailRegex.hasMatch(email)) {
          _validationError = 'Please enter a valid email address (e.g. name@domain.com).';
          notifyListeners();
          return false;
        }
        encodedPayload = QrPayloadEncoder.encodeEmail(
          email: email,
          subject: emailSubjectController.text,
          body: emailBodyController.text,
        );
        break;

      case QrPayloadType.phone:
        final phone = phoneController.text.trim();
        if (phone.isEmpty) {
          _validationError = 'Please enter a phone number.';
          notifyListeners();
          return false;
        }
        final digitCount = phone.replaceAll(RegExp(r'\D'), '').length;
        if (digitCount < 3) {
          _validationError = 'Please enter a valid phone number with at least 3 digits.';
          notifyListeners();
          return false;
        }
        encodedPayload = QrPayloadEncoder.encodePhone(phone);
        break;

      case QrPayloadType.sms:
        final phone = smsPhoneController.text.trim();
        final message = smsMessageController.text.trim();
        if (phone.isEmpty) {
          _validationError = 'Please enter recipient phone number.';
          notifyListeners();
          return false;
        }
        if (message.isEmpty) {
          _validationError = 'Please enter an SMS message body.';
          notifyListeners();
          return false;
        }
        encodedPayload = QrPayloadEncoder.encodeSms(phone: phone, message: message);
        break;

      case QrPayloadType.contact:
        final name = contactNameController.text.trim();
        final phone = contactPhoneController.text.trim();
        final email = contactEmailController.text.trim();
        final org = contactOrgController.text.trim();

        if (name.isEmpty) {
          _validationError = 'Please enter the contact name.';
          notifyListeners();
          return false;
        }
        if (phone.isEmpty && email.isEmpty) {
          _validationError = 'Please provide at least a phone number or email address.';
          notifyListeners();
          return false;
        }
        if (email.isNotEmpty && !RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email)) {
          _validationError = 'Please enter a valid email address.';
          notifyListeners();
          return false;
        }

        encodedPayload = QrPayloadEncoder.encodeContact(
          name: name,
          phone: phone.isNotEmpty ? phone : null,
          email: email.isNotEmpty ? email : null,
          organization: org.isNotEmpty ? org : null,
        );
        break;
    }

    _validationError = null;

    _currentQr = QrConfig(
      content: encodedPayload,
      payloadType: _payloadType,
      foregroundColor: _foregroundColor,
      backgroundColor: _backgroundColor,
      qrSize: _qrSize,
      errorCorrectionLevel: _errorCorrectionLevel,
      eyeShape: _eyeShape,
      dataModuleShape: _dataModuleShape,
      createdAt: DateTime.now(),
    );

    // Save/update in local history immediately
    QrHistoryController.instance.addOrUpdate(_currentQr!);

    notifyListeners();
    return true;
  }

  /// Clears only the active type's form fields.
  void clearCurrentForm() {
    switch (_payloadType) {
      case QrPayloadType.text:
        textController.clear();
        break;
      case QrPayloadType.url:
        urlController.clear();
        break;
      case QrPayloadType.wifi:
        wifiSsidController.clear();
        wifiPasswordController.clear();
        _wifiSecurity = 'WPA/WPA2';
        _wifiIsHidden = false;
        break;
      case QrPayloadType.email:
        emailAddressController.clear();
        emailSubjectController.clear();
        emailBodyController.clear();
        break;
      case QrPayloadType.phone:
        phoneController.clear();
        break;
      case QrPayloadType.sms:
        smsPhoneController.clear();
        smsMessageController.clear();
        break;
      case QrPayloadType.contact:
        contactNameController.clear();
        contactPhoneController.clear();
        contactEmailController.clear();
        contactOrgController.clear();
        break;
    }
    _validationError = null;
    notifyListeners();
  }

  /// Legacy alias
  void clearInput() => clearCurrentForm();

  /// Full reset restoring all forms, default styling, and initial state.
  void resetAll() {
    textController.clear();
    urlController.clear();
    wifiSsidController.clear();
    wifiPasswordController.clear();
    _wifiSecurity = 'WPA/WPA2';
    _wifiIsHidden = false;
    _wifiObscurePassword = true;

    emailAddressController.clear();
    emailSubjectController.clear();
    emailBodyController.clear();

    phoneController.clear();
    smsPhoneController.clear();
    smsMessageController.clear();

    contactNameController.clear();
    contactPhoneController.clear();
    contactEmailController.clear();
    contactOrgController.clear();

    _payloadType = QrPayloadType.text;
    _foregroundColor = AppTheme.qrForegroundColors.first;
    _backgroundColor = Colors.white;
    _qrSize = 220.0;
    _errorCorrectionLevel = QrErrorCorrectLevel.M;
    _eyeShape = QrEyeShape.square;
    _dataModuleShape = QrDataModuleShape.square;

    _validationError = null;
    _currentQr = null;
    notifyListeners();
  }

  /// Populates and regenerates a QR code from a historical item.
  void loadFromItem(QrItem item) {
    _payloadType = item.payloadType;
    _foregroundColor = item.foregroundColor;
    _backgroundColor = item.backgroundColor;
    _qrSize = item.qrSize;
    _errorCorrectionLevel = item.errorCorrectionLevel;
    _eyeShape = item.eyeShape;
    _dataModuleShape = item.dataModuleShape;

    // Fill appropriate form field based on payload
    switch (item.payloadType) {
      case QrPayloadType.text:
        textController.text = item.content;
        break;
      case QrPayloadType.url:
        urlController.text = item.content;
        break;
      case QrPayloadType.wifi:
        // Try parsing SSID from WIFI:S:<ssid>;...
        final ssidMatch = RegExp(r'S:(.*?);').firstMatch(item.content);
        if (ssidMatch != null) {
          wifiSsidController.text = ssidMatch.group(1) ?? '';
        }
        final passMatch = RegExp(r'P:(.*?);').firstMatch(item.content);
        if (passMatch != null) {
          wifiPasswordController.text = passMatch.group(1) ?? '';
        }
        break;
      case QrPayloadType.email:
        final clean = item.content.replaceFirst('mailto:', '');
        emailAddressController.text = clean.split('?').first;
        break;
      case QrPayloadType.phone:
        phoneController.text = item.content.replaceFirst('tel:', '');
        break;
      case QrPayloadType.sms:
        final clean = item.content.replaceFirst('smsto:', '');
        final parts = clean.split(':');
        smsPhoneController.text = parts.first;
        if (parts.length > 1) {
          smsMessageController.text = parts.sublist(1).join(':');
        }
        break;
      case QrPayloadType.contact:
        final fnMatch = RegExp(r'FN:(.*)').firstMatch(item.content);
        if (fnMatch != null) {
          contactNameController.text = fnMatch.group(1)?.trim() ?? '';
        }
        final telMatch = RegExp(r'TEL:(.*)').firstMatch(item.content);
        if (telMatch != null) {
          contactPhoneController.text = telMatch.group(1)?.trim() ?? '';
        }
        final emailMatch = RegExp(r'EMAIL:(.*)').firstMatch(item.content);
        if (emailMatch != null) {
          contactEmailController.text = emailMatch.group(1)?.trim() ?? '';
        }
        final orgMatch = RegExp(r'ORG:(.*)').firstMatch(item.content);
        if (orgMatch != null) {
          contactOrgController.text = orgMatch.group(1)?.trim() ?? '';
        }
        break;
    }

    _validationError = null;
    _currentQr = item.toConfig();
    notifyListeners();
  }

  /// Loads preset templates.
  void loadPreset(String sample, QrPayloadType type) {
    _payloadType = type;
    switch (type) {
      case QrPayloadType.text:
        textController.text = sample;
        break;
      case QrPayloadType.url:
        urlController.text = sample;
        break;
      case QrPayloadType.wifi:
        wifiSsidController.text = 'GuestNetwork';
        wifiPasswordController.text = 'Welcome2026';
        _wifiSecurity = 'WPA/WPA2';
        break;
      case QrPayloadType.email:
        emailAddressController.text = sample;
        emailSubjectController.text = 'Feedback on QR Generator';
        emailBodyController.text = 'Hello, this app is awesome!';
        break;
      case QrPayloadType.phone:
        phoneController.text = sample;
        break;
      case QrPayloadType.sms:
        smsPhoneController.text = sample;
        smsMessageController.text = 'Hello there!';
        break;
      case QrPayloadType.contact:
        contactNameController.text = 'Alex Morgan';
        contactPhoneController.text = '+1 800 555 0199';
        contactEmailController.text = 'alex@example.com';
        contactOrgController.text = 'Flutter Dev';
        break;
    }
    generateQr();
  }

  /// Exports the QR widget as high-res PNG and saves to photo gallery/storage.
  Future<String> saveQrImage() async {
    if (_currentQr == null) {
      throw Exception('Generate a QR code before saving.');
    }

    _setExporting(true, 'Preparing QR image...');
    try {
      final bytes = await QrImageExporter.capturePng(qrRepaintKey);
      _setExporting(true, 'Saving image to device...');
      final resultMessage = await QrImageExporter.saveImage(bytes);
      return resultMessage;
    } finally {
      _setExporting(false, null);
    }
  }

  /// Exports the QR widget as PNG and opens native sharing dialogue.
  Future<void> shareQrCode() async {
    if (_currentQr == null) {
      throw Exception('Generate a QR code before sharing.');
    }

    _setExporting(true, 'Preparing to share QR code...');
    try {
      final bytes = await QrImageExporter.capturePng(qrRepaintKey);
      await QrImageExporter.shareQrCode(
        bytes: bytes,
        content: _currentQr!.content,
      );
    } finally {
      _setExporting(false, null);
    }
  }

  /// Copies currently encoded text to the clipboard.
  Future<void> copyEncodedText() async {
    if (_currentQr == null) return;
    await QrImageExporter.copyToClipboard(_currentQr!.content);
  }

  void _setExporting(bool value, String? message) {
    _isExporting = value;
    _exportStatusMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    urlController.dispose();
    wifiSsidController.dispose();
    wifiPasswordController.dispose();
    emailAddressController.dispose();
    emailSubjectController.dispose();
    emailBodyController.dispose();
    phoneController.dispose();
    smsPhoneController.dispose();
    smsMessageController.dispose();
    contactNameController.dispose();
    contactPhoneController.dispose();
    contactEmailController.dispose();
    contactOrgController.dispose();
    super.dispose();
  }
}
