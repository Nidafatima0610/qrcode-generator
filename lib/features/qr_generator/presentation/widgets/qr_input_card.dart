import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/features/qr_generator/controllers/qr_generator_controller.dart';
import 'qr_dynamic_form.dart';
import 'qr_type_selector.dart';

/// Card hosting the QR Type Selector, dynamic form fields, and generation action.
class QrInputCard extends StatelessWidget {
  final QrGeneratorController controller;

  const QrInputCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final payload = controller.payloadType;
    final hasContent = controller.hasContent;
    final hasError = controller.validationError != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasError
              ? AppTheme.errorColor
              : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
          width: hasError ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Type Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'QR Content Type',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              if (hasContent)
                TextButton.icon(
                  onPressed: () => controller.clearCurrentForm(),
                  icon: const Icon(Icons.clear_rounded, size: 14),
                  label: const Text('Clear Form', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 7-Type Selector Chips
          QrTypeSelector(
            selectedType: payload,
            onTypeSelected: (type) => controller.setPayloadType(type),
          ),
          const SizedBox(height: 16),

          // Dynamic Type-Specific Form
          QrDynamicForm(controller: controller),
          const SizedBox(height: 10),

          // Helper Note or Validation Error
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 15,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      controller.validationError!,
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                payload.helperText,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Generate / Update Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                FocusScope.of(context).unfocus();
                controller.generateQr();
              },
              icon: const Icon(Icons.qr_code_2_rounded, size: 20),
              label: Text(
                controller.isQrGenerated ? 'Update QR Code' : 'Generate QR Code',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
