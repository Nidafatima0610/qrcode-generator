import 'dart:convert';
import 'package:qrcode_generator/core/models/qr_type.dart';

class ScanItem {
  final String id;
  final String rawContent;
  final QrType detectedType;
  final String title;
  final String subtitle;
  final DateTime scannedAt;
  final Map<String, String> details;

  const ScanItem({
    required this.id,
    required this.rawContent,
    required this.detectedType,
    required this.title,
    required this.subtitle,
    required this.scannedAt,
    this.details = const {},
  });

  ScanItem copyWith({
    String? id,
    String? rawContent,
    QrType? detectedType,
    String? title,
    String? subtitle,
    DateTime? scannedAt,
    Map<String, String>? details,
  }) {
    return ScanItem(
      id: id ?? this.id,
      rawContent: rawContent ?? this.rawContent,
      detectedType: detectedType ?? this.detectedType,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      scannedAt: scannedAt ?? this.scannedAt,
      details: details ?? this.details,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rawContent': rawContent,
      'detectedType': detectedType.name,
      'title': title,
      'subtitle': subtitle,
      'scannedAt': scannedAt.toIso8601String(),
      'details': details,
    };
  }

  factory ScanItem.fromMap(Map<String, dynamic> map) {
    return ScanItem(
      id: map['id'] as String,
      rawContent: map['rawContent'] as String? ?? '',
      detectedType: QrType.fromString(map['detectedType'] as String? ?? 'text'),
      title: map['title'] as String? ?? 'Scanned Code',
      subtitle: map['subtitle'] as String? ?? '',
      scannedAt: map['scannedAt'] != null
          ? DateTime.tryParse(map['scannedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      details: (map['details'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ScanItem.fromJson(String source) =>
      ScanItem.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
