import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'qr_payload_type.dart';

/// Configuration data model for the generated QR code.
class QrConfig {
  final String content;
  final QrPayloadType payloadType;
  final Color foregroundColor;
  final Color backgroundColor;
  final double qrSize;
  final int errorCorrectionLevel;
  final QrEyeShape eyeShape;
  final QrDataModuleShape dataModuleShape;
  final DateTime createdAt;

  QrConfig({
    required this.content,
    required this.payloadType,
    this.foregroundColor = const Color(0xFF0F172A),
    this.backgroundColor = Colors.white,
    this.qrSize = 220.0,
    this.errorCorrectionLevel = QrErrorCorrectLevel.M,
    this.eyeShape = QrEyeShape.square,
    this.dataModuleShape = QrDataModuleShape.square,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  QrConfig copyWith({
    String? content,
    QrPayloadType? payloadType,
    Color? foregroundColor,
    Color? backgroundColor,
    double? qrSize,
    int? errorCorrectionLevel,
    QrEyeShape? eyeShape,
    QrDataModuleShape? dataModuleShape,
    DateTime? createdAt,
  }) {
    return QrConfig(
      content: content ?? this.content,
      payloadType: payloadType ?? this.payloadType,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      qrSize: qrSize ?? this.qrSize,
      errorCorrectionLevel: errorCorrectionLevel ?? this.errorCorrectionLevel,
      eyeShape: eyeShape ?? this.eyeShape,
      dataModuleShape: dataModuleShape ?? this.dataModuleShape,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Whether current foreground and background have sufficient contrast for scanning.
  bool get hasSafeContrast =>
      AppTheme.hasSufficientContrast(foregroundColor, backgroundColor);

  /// Calculated contrast ratio.
  double get contrastRatio =>
      AppTheme.calculateContrastRatio(foregroundColor, backgroundColor);

  /// Human-readable label for the error correction level.
  String get errorCorrectionLabel {
    switch (errorCorrectionLevel) {
      case QrErrorCorrectLevel.L:
        return 'Low (7%)';
      case QrErrorCorrectLevel.M:
        return 'Medium (15%)';
      case QrErrorCorrectLevel.Q:
        return 'Quartile (25%)';
      case QrErrorCorrectLevel.H:
        return 'High (30%)';
      default:
        return 'Standard';
    }
  }
}
