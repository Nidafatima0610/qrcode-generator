import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_payload_type.dart';

/// Welcoming empty state shown before the user generates their first QR code.
class QrEmptyState extends StatelessWidget {
  final void Function(String text, QrPayloadType type) onSelectPreset;

  const QrEmptyState({
    super.key,
    required this.onSelectPreset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Illustration / Icon Badge
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Ready to Generate',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Enter your content above or try one of these quick sample templates:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Preset Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildPresetChip(
                context,
                icon: Icons.language_rounded,
                label: 'https://flutter.dev',
                onTap: () => onSelectPreset(
                  'https://flutter.dev',
                  QrPayloadType.url,
                ),
              ),
              _buildPresetChip(
                context,
                icon: Icons.wifi_rounded,
                label: 'Guest Wi-Fi',
                onTap: () => onSelectPreset(
                  'WIFI:S:GuestNetwork;T:WPA;P:Welcome2026;;',
                  QrPayloadType.wifi,
                ),
              ),
              _buildPresetChip(
                context,
                icon: Icons.phone_rounded,
                label: '+1 800 555 0199',
                onTap: () => onSelectPreset(
                  '+1 800 555 0199',
                  QrPayloadType.phone,
                ),
              ),
              _buildPresetChip(
                context,
                icon: Icons.email_rounded,
                label: 'hello@example.com',
                onTap: () => onSelectPreset(
                  'hello@example.com',
                  QrPayloadType.email,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B)
                : AppTheme.primaryLight.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFC7D2FE),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isDark ? const Color(0xFFA5B4FC) : AppTheme.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF312E81),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
