import 'dart:math' as math;
import 'package:flutter/material.dart';

class QrCustomization {
  final Color foregroundColor;
  final Color backgroundColor;
  final double size;
  final String errorCorrectionLevel; // 'L', 'M', 'Q', 'H'
  final String eyeShape; // 'square', 'circle'
  final String dataModuleShape; // 'square', 'circle'

  const QrCustomization({
    this.foregroundColor = const Color(0xFF000000),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.size = 240.0,
    this.errorCorrectionLevel = 'M',
    this.eyeShape = 'square',
    this.dataModuleShape = 'square',
  });

  /// Calculate channel luminance using standard WCAG formula
  static double _channelLuminance(int channelValue) {
    final v = channelValue / 255.0;
    return (v <= 0.03928)
        ? (v / 12.92)
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Calculates relative luminance of any color
  static double relativeLuminance(Color color) {
    final argb = color.toARGB32();
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return 0.2126 * _channelLuminance(r) +
        0.7152 * _channelLuminance(g) +
        0.0722 * _channelLuminance(b);
  }

  /// Calculates the contrast ratio between foreground and background (1.0 to 21.0)
  double get contrastRatio {
    final l1 = relativeLuminance(foregroundColor);
    final l2 = relativeLuminance(backgroundColor);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Returns true if contrast meets the recommended threshold (>= 3.0) for reliable scanning
  bool get hasSufficientContrast => contrastRatio >= 3.0;

  QrCustomization copyWith({
    Color? foregroundColor,
    Color? backgroundColor,
    double? size,
    String? errorCorrectionLevel,
    String? eyeShape,
    String? dataModuleShape,
  }) {
    return QrCustomization(
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      size: size ?? this.size,
      errorCorrectionLevel: errorCorrectionLevel ?? this.errorCorrectionLevel,
      eyeShape: eyeShape ?? this.eyeShape,
      dataModuleShape: dataModuleShape ?? this.dataModuleShape,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foregroundColor': foregroundColor.toARGB32(),
      'backgroundColor': backgroundColor.toARGB32(),
      'size': size,
      'errorCorrectionLevel': errorCorrectionLevel,
      'eyeShape': eyeShape,
      'dataModuleShape': dataModuleShape,
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
      eyeShape: (map['eyeShape'] as String?) ?? 'square',
      dataModuleShape: (map['dataModuleShape'] as String?) ?? 'square',
    );
  }
}

/// Built-in visual design presets that change colors, shapes, and error correction
class QrDesignPreset {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final QrCustomization customization;

  const QrDesignPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.customization,
  });

  static const List<QrDesignPreset> builtInPresets = [
    QrDesignPreset(
      id: 'classic',
      name: 'Classic',
      description: 'Standard high-contrast monochrome with square modules',
      icon: Icons.qr_code_2_rounded,
      customization: QrCustomization(
        foregroundColor: Color(0xFF000000),
        backgroundColor: Color(0xFFFFFFFF),
        eyeShape: 'square',
        dataModuleShape: 'square',
        errorCorrectionLevel: 'M',
      ),
    ),
    QrDesignPreset(
      id: 'dark',
      name: 'Dark',
      description: 'Sleek dark mode with crisp white modules and rounded eyes',
      icon: Icons.dark_mode_rounded,
      customization: QrCustomization(
        foregroundColor: Color(0xFFFFFFFF),
        backgroundColor: Color(0xFF0F172A),
        eyeShape: 'circle',
        dataModuleShape: 'square',
        errorCorrectionLevel: 'Q',
      ),
    ),
    QrDesignPreset(
      id: 'soft',
      name: 'Soft',
      description: 'Gentle royal violet on soft lavender with circular dots',
      icon: Icons.bubble_chart_rounded,
      customization: QrCustomization(
        foregroundColor: Color(0xFF4C1D95),
        backgroundColor: Color(0xFFF5F3FF),
        eyeShape: 'circle',
        dataModuleShape: 'circle',
        errorCorrectionLevel: 'M',
      ),
    ),
    QrDesignPreset(
      id: 'business',
      name: 'Business',
      description: 'Executive midnight slate with maximum error resilience',
      icon: Icons.business_center_rounded,
      customization: QrCustomization(
        foregroundColor: Color(0xFF0F172A),
        backgroundColor: Color(0xFFF8FAFC),
        eyeShape: 'square',
        dataModuleShape: 'square',
        errorCorrectionLevel: 'H',
      ),
    ),
    QrDesignPreset(
      id: 'minimal',
      name: 'Minimal',
      description: 'Subtle emerald forest green on crisp mint background',
      icon: Icons.eco_rounded,
      customization: QrCustomization(
        foregroundColor: Color(0xFF064E3B),
        backgroundColor: Color(0xFFECFDF5),
        eyeShape: 'circle',
        dataModuleShape: 'square',
        errorCorrectionLevel: 'M',
      ),
    ),
    QrDesignPreset(
      id: 'high_contrast',
      name: 'High Contrast',
      description: 'Ultra-legible pure pitch black on pure white with Level H ECC',
      icon: Icons.contrast_rounded,
      customization: QrCustomization(
        foregroundColor: Color(0xFF000000),
        backgroundColor: Color(0xFFFFFFFF),
        eyeShape: 'square',
        dataModuleShape: 'square',
        errorCorrectionLevel: 'H',
      ),
    ),
  ];
}
