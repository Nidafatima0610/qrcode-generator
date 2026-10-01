import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_payload_type.dart';

/// Horizontal templates section providing 1-tap presets that open the respective QR form.
class QuickTemplatesBar extends StatelessWidget {
  final ValueChanged<QrPayloadType> onSelectTemplate;
  final QrPayloadType activeType;

  const QuickTemplatesBar({
    super.key,
    required this.onSelectTemplate,
    required this.activeType,
  });

  static const List<({String label, IconData icon, QrPayloadType type, Color color})> _templates = [
    (
      label: 'Website',
      icon: Icons.language_rounded,
      type: QrPayloadType.url,
      color: Color(0xFF3B82F6),
    ),
    (
      label: 'Wi-Fi',
      icon: Icons.wifi_rounded,
      type: QrPayloadType.wifi,
      color: Color(0xFF10B981),
    ),
    (
      label: 'Contact',
      icon: Icons.contact_page_rounded,
      type: QrPayloadType.contact,
      color: Color(0xFF8B5CF6),
    ),
    (
      label: 'Email',
      icon: Icons.alternate_email_rounded,
      type: QrPayloadType.email,
      color: Color(0xFFF59E0B),
    ),
    (
      label: 'Phone',
      icon: Icons.phone_rounded,
      type: QrPayloadType.phone,
      color: Color(0xFF06B6D4),
    ),
    (
      label: 'SMS',
      icon: Icons.sms_rounded,
      type: QrPayloadType.sms,
      color: Color(0xFFEC4899),
    ),
    (
      label: 'Text',
      icon: Icons.text_fields_rounded,
      type: QrPayloadType.text,
      color: Color(0xFF64748B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 15, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  'Quick Templates',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _templates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _templates[index];
                final isSelected = item.type == activeType;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelectTemplate(item.type),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? item.color.withValues(alpha: isDark ? 0.3 : 0.15)
                            : (isDark ? AppTheme.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? item.color
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 16,
                            color: isSelected ? item.color : (isDark ? Colors.white70 : item.color),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected
                                  ? (isDark ? Colors.white : item.color)
                                  : (isDark ? Colors.white70 : AppTheme.textPrimaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
