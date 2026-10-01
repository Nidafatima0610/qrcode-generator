import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/features/qr_generator/controllers/qr_generator_controller.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_config.dart';
import 'package:qr_code_generator/features/qr_generator/presentation/widgets/qr_action_buttons.dart';

/// Prominently displays the generated QR code with live customization,
/// content inspection, and export actions.
class QrDisplayCard extends StatefulWidget {
  final QrGeneratorController controller;
  final QrConfig config;

  const QrDisplayCard({
    super.key,
    required this.controller,
    required this.config,
  });

  @override
  State<QrDisplayCard> createState() => _QrDisplayCardState();
}

class _QrDisplayCardState extends State<QrDisplayCard> {
  bool _isContentExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final config = widget.config;
    final controller = widget.controller;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.successColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Generated QR Code',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  config.payloadType.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFA5B4FC)
                        : AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // QR Code Canvas (Inside RepaintBoundary for PNG Export)
          RepaintBoundary(
            key: controller.qrRepaintKey,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: config.content,
                version: QrVersions.auto,
                size: 210,
                backgroundColor: Colors.white,
                errorCorrectionLevel: config.errorCorrectionLevel,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: config.foregroundColor,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: config.foregroundColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // QR Color Customizer Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Color: ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: AppTheme.qrColorOptions.map((color) {
                  final isSelected = controller.foregroundColor == color;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => controller.setForegroundColor(color),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1.5,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Error Correction Level Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error Correction: ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
              ),
              const SizedBox(width: 6),
              _buildCorrectionChip(
                label: 'L',
                tooltip: 'Low (7% recovery)',
                level: QrErrorCorrectLevel.L,
                currentLevel: controller.errorCorrectionLevel,
                onSelected: () =>
                    controller.setErrorCorrectionLevel(QrErrorCorrectLevel.L),
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              _buildCorrectionChip(
                label: 'M',
                tooltip: 'Medium (15% recovery)',
                level: QrErrorCorrectLevel.M,
                currentLevel: controller.errorCorrectionLevel,
                onSelected: () =>
                    controller.setErrorCorrectionLevel(QrErrorCorrectLevel.M),
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              _buildCorrectionChip(
                label: 'Q',
                tooltip: 'Quartile (25% recovery)',
                level: QrErrorCorrectLevel.Q,
                currentLevel: controller.errorCorrectionLevel,
                onSelected: () =>
                    controller.setErrorCorrectionLevel(QrErrorCorrectLevel.Q),
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              _buildCorrectionChip(
                label: 'H',
                tooltip: 'High (30% recovery)',
                level: QrErrorCorrectLevel.H,
                currentLevel: controller.errorCorrectionLevel,
                onSelected: () =>
                    controller.setErrorCorrectionLevel(QrErrorCorrectLevel.H),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Encoded Content Container (Handles Long Text Gracefully)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ENCODED CONTENT',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                    Text(
                      '${config.content.length} characters',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  _isContentExpanded || config.content.length <= 120
                      ? config.content
                      : '${config.content.substring(0, 115)}...',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontFamily: 'monospace',
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
                ),
                if (config.content.length > 120) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isContentExpanded = !_isContentExpanded;
                      });
                    },
                    child: Text(
                      _isContentExpanded ? 'Show less' : 'Show full text',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons: Save, Share, Copy
          QrActionButtons(controller: controller),
        ],
      ),
    );
  }

  Widget _buildCorrectionChip({
    required String label,
    required String tooltip,
    required int level,
    required int currentLevel,
    required VoidCallback onSelected,
    required bool isDark,
  }) {
    final isSelected = level == currentLevel;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : (isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0)),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppTheme.textPrimaryLight),
            ),
          ),
        ),
      ),
    );
  }
}
