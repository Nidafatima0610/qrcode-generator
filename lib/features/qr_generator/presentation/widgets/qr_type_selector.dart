import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_payload_type.dart';

/// Polished horizontal selector displaying all 7 supported QR content types.
class QrTypeSelector extends StatelessWidget {
  final QrPayloadType selectedType;
  final ValueChanged<QrPayloadType> onTypeSelected;

  const QrTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: QrPayloadType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = QrPayloadType.values[index];
          final isSelected = type == selectedType;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onTypeSelected(type),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: 1.1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type.icon,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFF94A3B8) : AppTheme.textSecondaryLight),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? const Color(0xFFE2E8F0) : AppTheme.textPrimaryLight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
