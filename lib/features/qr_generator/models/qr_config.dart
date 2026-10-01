import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'qr_payload_type.dart';

/// Configuration data model for the generated QR code.
class QrConfig {
  final String content;
  final QrPayloadType payloadType;
  final Color foregroundColor;
  final Color backgroundColor;
  final int errorCorrectionLevel;
  final DateTime createdAt;

  const QrConfig({
    required this.content,
    required this.payloadType,
    this.foregroundColor = const Color(0xFF0F172A),
    this.backgroundColor = Colors.white,
    this.errorCorrectionLevel = QrErrorCorrectLevel.M,
    required this.createdAt,
  });

  QrConfig copyWith({
    String? content,
    QrPayloadType? payloadType,
    Color? foregroundColor,
    Color? backgroundColor,
    int? errorCorrectionLevel,
    DateTime? createdAt,
  }) {
    return QrConfig(
      content: content ?? this.content,
      payloadType: payloadType ?? this.payloadType,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      errorCorrectionLevel: errorCorrectionLevel ?? this.errorCorrectionLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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
