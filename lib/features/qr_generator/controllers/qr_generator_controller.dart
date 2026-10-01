import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/core/utils/qr_image_exporter.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_config.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_payload_type.dart';

/// Business logic controller for the QR Code Generator.
/// Manages state, validation, real-time customization, and export actions.
class QrGeneratorController extends ChangeNotifier {
  final TextEditingController textController = TextEditingController();
  final GlobalKey qrRepaintKey = GlobalKey();

  QrPayloadType _payloadType = QrPayloadType.text;
  Color _foregroundColor = AppTheme.qrColorOptions.first;
  int _errorCorrectionLevel = QrErrorCorrectLevel.M;

  QrConfig? _currentQr;
  String? _validationError;
  bool _isExporting = false;
  String? _exportStatusMessage;

  QrGeneratorController() {
    textController.addListener(_onTextChanged);
  }

  // Getters
  QrPayloadType get payloadType => _payloadType;
  Color get foregroundColor => _foregroundColor;
  int get errorCorrectionLevel => _errorCorrectionLevel;
  QrConfig? get currentQr => _currentQr;
  String? get validationError => _validationError;
  bool get isExporting => _isExporting;
  String? get exportStatusMessage => _exportStatusMessage;
  bool get hasContent => textController.text.trim().isNotEmpty;
  bool get isQrGenerated => _currentQr != null;

  void _onTextChanged() {
    if (_validationError != null && textController.text.trim().isNotEmpty) {
      _validationError = null;
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  /// Changes the payload type and adjusts prefix/hints if needed.
  void setPayloadType(QrPayloadType type) {
    if (_payloadType == type) return;
    _payloadType = type;
    _validationError = null;

    // If current text is empty and type is URL, provide https:// convenience
    if (textController.text.isEmpty && type == QrPayloadType.url) {
      textController.text = 'https://';
      textController.selection = TextSelection.fromPosition(
        TextPosition(offset: textController.text.length),
      );
    }

    // If a QR code is already visible, update the config model
    if (_currentQr != null) {
      _currentQr = _currentQr!.copyWith(payloadType: type);
    }

    notifyListeners();
  }

  /// Sets foreground color for QR dots and eye frames.
  void setForegroundColor(Color color) {
    if (_foregroundColor == color) return;
    _foregroundColor = color;
    if (_currentQr != null) {
      _currentQr = _currentQr!.copyWith(foregroundColor: color);
    }
    notifyListeners();
  }

  /// Sets QR error correction level (L, M, Q, H).
  void setErrorCorrectionLevel(int level) {
    if (_errorCorrectionLevel == level) return;
    _errorCorrectionLevel = level;
    if (_currentQr != null) {
      _currentQr = _currentQr!.copyWith(errorCorrectionLevel: level);
    }
    notifyListeners();
  }

  /// Validates input and generates the QR code.
  bool generateQr() {
    final rawText = textController.text.trim();

    if (rawText.isEmpty) {
      _validationError = 'Please enter some text, a URL, or contact details.';
      notifyListeners();
      return false;
    }

    // Type-specific basic validation & normalization
    String processedText = rawText;
    if (_payloadType == QrPayloadType.url) {
      if (!processedText.startsWith('http://') &&
          !processedText.startsWith('https://')) {
        processedText = 'https://$processedText';
        textController.text = processedText;
      }
    }

    _validationError = null;
    _currentQr = QrConfig(
      content: processedText,
      payloadType: _payloadType,
      foregroundColor: _foregroundColor,
      backgroundColor: Colors.white,
      errorCorrectionLevel: _errorCorrectionLevel,
      createdAt: DateTime.now(),
    );

    notifyListeners();
    return true;
  }

  /// Clears only the text input.
  void clearInput() {
    textController.clear();
    _validationError = null;
    notifyListeners();
  }

  /// Resets everything back to fresh initial state.
  void resetAll() {
    textController.clear();
    _validationError = null;
    _currentQr = null;
    _payloadType = QrPayloadType.text;
    _foregroundColor = AppTheme.qrColorOptions.first;
    _errorCorrectionLevel = QrErrorCorrectLevel.M;
    notifyListeners();
  }

  /// Loads a predefined preset template for immediate testing & generation.
  void loadPreset(String sampleText, QrPayloadType type) {
    _payloadType = type;
    textController.text = sampleText;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: sampleText.length),
    );
    generateQr();
  }

  /// Exports the QR widget as PNG and saves to device gallery / storage.
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

  /// Copies the currently encoded text to the clipboard.
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
    textController.removeListener(_onTextChanged);
    textController.dispose();
    super.dispose();
  }
}
