import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/features/qr_generator/controllers/qr_generator_controller.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_payload_type.dart';

/// Interactive input card for selecting content type and entering data.
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
    final hasText = controller.textController.text.isNotEmpty;
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
          // Section Title & Char Count
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
                    'Content & Type',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              if (hasText)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${controller.textController.text.length} chars',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Payload Type Selector
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: QrPayloadType.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final type = QrPayloadType.values[index];
                final isSelected = type == payload;

                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type.icon,
                        size: 15,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? const Color(0xFF94A3B8)
                                : AppTheme.textSecondaryLight),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        type.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? const Color(0xFFE2E8F0)
                                  : AppTheme.textPrimaryLight),
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      controller.setPayloadType(type);
                    }
                  },
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  showCheckmark: false,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0)),
                      width: 1,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Text Input Field
          TextField(
            controller: controller.textController,
            keyboardType: payload.keyboardType,
            minLines: 2,
            maxLines: 5,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.generateQr(),
            style: TextStyle(
              fontSize: 14.5,
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: payload.hintText,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10, top: 12),
                child: Align(
                  alignment: Alignment.topCenter,
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: Icon(
                    payload.icon,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              suffixIcon: hasText
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        size: 19,
                      ),
                      tooltip: 'Clear input',
                      onPressed: () => controller.clearInput(),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),

          // Helper or Validation Error Text
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

          // Action Buttons: Generate & Clear
          Row(
            children: [
              if (hasText)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: OutlinedButton.icon(
                    onPressed: () => controller.clearInput(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    controller.generateQr();
                  },
                  icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                  label: Text(
                    controller.isQrGenerated
                        ? 'Update QR Code'
                        : 'Generate QR Code',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
