import 'dart:convert';
import 'package:qrcode_generator/core/models/qr_customization.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';

class QrPreset {
  final String id;
  final String name;
  final QrType type;
  final String defaultTitle;
  final QrCustomization customization;
  final Map<String, dynamic> fields;
  final DateTime createdAt;

  const QrPreset({
    required this.id,
    required this.name,
    required this.type,
    this.defaultTitle = '',
    this.customization = const QrCustomization(),
    this.fields = const {},
    required this.createdAt,
  });

  QrPreset copyWith({
    String? id,
    String? name,
    QrType? type,
    String? defaultTitle,
    QrCustomization? customization,
    Map<String, dynamic>? fields,
    DateTime? createdAt,
  }) {
    return QrPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      defaultTitle: defaultTitle ?? this.defaultTitle,
      customization: customization ?? this.customization,
      fields: fields ?? this.fields,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'defaultTitle': defaultTitle,
      'customization': customization.toMap(),
      'fields': fields,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QrPreset.fromMap(Map<String, dynamic> map) {
    return QrPreset(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Untitled Preset',
      type: QrType.fromString(map['type'] as String? ?? 'url'),
      defaultTitle: map['defaultTitle'] as String? ?? '',
      customization: map['customization'] != null
          ? QrCustomization.fromMap(map['customization'] as Map<String, dynamic>)
          : const QrCustomization(),
      fields: map['fields'] != null
          ? Map<String, dynamic>.from(map['fields'] as Map)
          : const {},
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory QrPreset.fromJson(String source) =>
      QrPreset.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
