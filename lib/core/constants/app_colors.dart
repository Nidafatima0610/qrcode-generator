import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accents
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color accent = Color(0xFF8B5CF6); // Purple

  // Functional / Status Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // QR Type Specific Badges
  static const Color typeText = Color(0xFF64748B); // Slate
  static const Color typeUrl = Color(0xFF3B82F6); // Blue
  static const Color typeWifi = Color(0xFF10B981); // Green
  static const Color typeContact = Color(0xFF8B5CF6); // Violet
  static const Color typeEmail = Color(0xFFF59E0B); // Amber
  static const Color typePhone = Color(0xFF06B6D4); // Cyan
  static const Color typeSms = Color(0xFFEC4899); // Pink
  static const Color typeLocation = Color(0xFFF43F5E); // Rose
  static const Color typeSocial = Color(0xFF8B5CF6); // Purple
  static const Color typeBusinessCard = Color(0xFF0D9488); // Teal
  static const Color typeBusinessInfo = Color(0xFFEA580C); // Orange

  // Light Theme Surfaces
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Dark Theme Surfaces
  static const Color darkBg = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // QR Color Presets
  static const List<QrColorPreset> presets = [
    QrColorPreset(
      name: 'Classic Black',
      foreground: Color(0xFF000000),
      background: Color(0xFFFFFFFF),
    ),
    QrColorPreset(
      name: 'Midnight Indigo',
      foreground: Color(0xFF1E1B4B),
      background: Color(0xFFEEF2FF),
    ),
    QrColorPreset(
      name: 'Emerald Forest',
      foreground: Color(0xFF064E3B),
      background: Color(0xFFECFDF5),
    ),
    QrColorPreset(
      name: 'Royal Violet',
      foreground: Color(0xFF4C1D95),
      background: Color(0xFFF5F3FF),
    ),
    QrColorPreset(
      name: 'Ocean Cyan',
      foreground: Color(0xFF164E63),
      background: Color(0xFFECFEFF),
    ),
    QrColorPreset(
      name: 'Sunset Ruby',
      foreground: Color(0xFF881337),
      background: Color(0xFFFFF1F2),
    ),
    QrColorPreset(
      name: 'Amber Glow',
      foreground: Color(0xFF78350F),
      background: Color(0xFFFFFBEB),
    ),
    QrColorPreset(
      name: 'Dark Inverted',
      foreground: Color(0xFFFFFFFF),
      background: Color(0xFF0F172A),
    ),
  ];
}

class QrColorPreset {
  final String name;
  final Color foreground;
  final Color background;

  const QrColorPreset({
    required this.name,
    required this.foreground,
    required this.background,
  });
}
