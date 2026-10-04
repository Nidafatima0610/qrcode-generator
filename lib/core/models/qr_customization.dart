import 'package:flutter/material.dart';

class QrCustomization {
  final Color foregroundColor;
  final Color backgroundColor;
  final double size;
  final String errorCorrectionLevel; // 'L', 'M', 'Q', 'H'

  const QrCustomization({
    this.foregroundColor = const Color(0xFF000000),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.size = 240.0,
    this.errorCorrectionLevel = 'M',
  });

  QrCustomization copyWith({
    Color? foregroundColor,
    Color? backgroundColor,
    double? size,
    String? errorCorrectionLevel,
  }) {
    return QrCustomization(
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      size: size ?? this.size,
      errorCorrectionLevel: errorCorrectionLevel ?? this.errorCorrectionLevel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foregroundColor': foregroundColor.toARGB32(),
      'backgroundColor': backgroundColor.toARGB32(),
      'size': size,
      'errorCorrectionLevel': errorCorrectionLevel,
    };
  }

  factory QrCustomization.fromMap(Map<String, dynamic> map) {
    return QrCustomization(
      foregroundColor: map['foregroundColor'] != null
          ? Color(map['foregroundColor'] as int)
          : const Color(0xFF000000),
      backgroundColor: map['backgroundColor'] != null
          ? Color(map['backgroundColor'] as int)
          : const Color(0xFFFFFFFF),
      size: (map['size'] as num?)?.toDouble() ?? 240.0,
      errorCorrectionLevel: (map['errorCorrectionLevel'] as String?) ?? 'M',
    );
  }
}
