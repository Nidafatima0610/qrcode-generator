import 'dart:convert';
import 'package:qrcode_generator/core/models/qr_type.dart';
import 'package:qrcode_generator/core/models/qr_customization.dart';

class QrItem {
  final String id;
  final QrType type;
  final String title;
  final String subtitle;
  final String rawPayload;
  final DateTime createdAt;
  final QrCustomization customization;
  final bool isFavorite;

  const QrItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.rawPayload,
    required this.createdAt,
    this.customization = const QrCustomization(),
    this.isFavorite = false,
  });

  QrItem copyWith({
    String? id,
    QrType? type,
    String? title,
    String? subtitle,
    String? rawPayload,
    DateTime? createdAt,
    QrCustomization? customization,
    bool? isFavorite,
  }) {
    return QrItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      rawPayload: rawPayload ?? this.rawPayload,
      createdAt: createdAt ?? this.createdAt,
      customization: customization ?? this.customization,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'rawPayload': rawPayload,
      'createdAt': createdAt.toIso8601String(),
      'customization': customization.toMap(),
      'isFavorite': isFavorite,
    };
  }

  factory QrItem.fromMap(Map<String, dynamic> map) {
    return QrItem(
      id: map['id'] as String,
      type: QrType.fromString(map['type'] as String? ?? 'text'),
      title: map['title'] as String? ?? 'Untitled QR',
      subtitle: map['subtitle'] as String? ?? '',
      rawPayload: map['rawPayload'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      customization: map['customization'] != null
          ? QrCustomization.fromMap(map['customization'] as Map<String, dynamic>)
          : const QrCustomization(),
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory QrItem.fromJson(String source) =>
      QrItem.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
