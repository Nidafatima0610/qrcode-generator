import 'package:flutter/material.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_config.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_payload_type.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Represents a saved QR code record in local history and favorites.
class QrItem {
  final String id;
  final String content;
  final DateTime createdAt;
  final bool isFavorite;
  final QrPayloadType payloadType;
  final Color foregroundColor;
  final Color backgroundColor;
  final int errorCorrectionLevel;
  final double qrSize;
  final QrEyeShape eyeShape;
  final QrDataModuleShape dataModuleShape;

  const QrItem({
    required this.id,
    required this.content,
    required this.createdAt,
    this.isFavorite = false,
    this.payloadType = QrPayloadType.text,
    this.foregroundColor = const Color(0xFF0F172A),
    this.backgroundColor = Colors.white,
    this.errorCorrectionLevel = QrErrorCorrectLevel.M,
    this.qrSize = 220.0,
    this.eyeShape = QrEyeShape.square,
    this.dataModuleShape = QrDataModuleShape.square,
  });

  /// Converts this history record into a [QrConfig] for UI display.
  QrConfig toConfig() {
    return QrConfig(
      content: content,
      payloadType: payloadType,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      qrSize: qrSize,
      errorCorrectionLevel: errorCorrectionLevel,
      eyeShape: eyeShape,
      dataModuleShape: dataModuleShape,
      createdAt: createdAt,
    );
  }

  QrItem copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    bool? isFavorite,
    QrPayloadType? payloadType,
    Color? foregroundColor,
    Color? backgroundColor,
    int? errorCorrectionLevel,
    double? qrSize,
    QrEyeShape? eyeShape,
    QrDataModuleShape? dataModuleShape,
  }) {
    return QrItem(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      payloadType: payloadType ?? this.payloadType,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      errorCorrectionLevel: errorCorrectionLevel ?? this.errorCorrectionLevel,
      qrSize: qrSize ?? this.qrSize,
      eyeShape: eyeShape ?? this.eyeShape,
      dataModuleShape: dataModuleShape ?? this.dataModuleShape,
    );
  }

  /// Formatted date string for display (e.g. "Oct 1, 2026 • 12:05 PM").
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[createdAt.month - 1];
    final day = createdAt.day;
    final hour12 = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final period = createdAt.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, ${createdAt.year} • $hour12:$minute $period';
  }

  /// Short content preview for list tiles.
  String get titlePreview {
    final trimmed = content.trim();
    if (trimmed.length <= 45) return trimmed;
    return '${trimmed.substring(0, 42)}...';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
      'payloadType': payloadType.name,
      'foregroundColor': foregroundColor.toARGB32(),
      'backgroundColor': backgroundColor.toARGB32(),
      'errorCorrectionLevel': errorCorrectionLevel,
      'qrSize': qrSize,
      'eyeShape': eyeShape.name,
      'dataModuleShape': dataModuleShape.name,
    };
  }

  factory QrItem.fromJson(Map<String, dynamic> json) {
    QrPayloadType resolveType(String? name) {
      if (name == null) return QrPayloadType.text;
      try {
        return QrPayloadType.values.firstWhere(
          (t) => t.name.toLowerCase() == name.toLowerCase(),
          orElse: () => QrPayloadType.text,
        );
      } catch (_) {
        return QrPayloadType.text;
      }
    }

    DateTime resolveDate(String? raw) {
      if (raw == null) return DateTime.now();
      try {
        return DateTime.parse(raw);
      } catch (_) {
        return DateTime.now();
      }
    }

    return QrItem(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] as String? ?? '',
      createdAt: resolveDate(json['createdAt'] as String?),
      isFavorite: json['isFavorite'] as bool? ?? false,
      payloadType: resolveType(json['payloadType'] as String?),
      foregroundColor: json['foregroundColor'] != null
          ? Color(json['foregroundColor'] as int)
          : const Color(0xFF0F172A),
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : Colors.white,
      errorCorrectionLevel:
          json['errorCorrectionLevel'] as int? ?? QrErrorCorrectLevel.M,
      qrSize: (json['qrSize'] as num?)?.toDouble() ?? 220.0,
      eyeShape: json['eyeShape'] == 'circle'
          ? QrEyeShape.circle
          : QrEyeShape.square,
      dataModuleShape: json['dataModuleShape'] == 'circle'
          ? QrDataModuleShape.circle
          : QrDataModuleShape.square,
    );
  }
}
