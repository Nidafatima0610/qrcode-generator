import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/features/qr_generator/controllers/qr_generator_controller.dart';
import 'package:qr_code_generator/features/qr_generator/models/qr_config.dart';
import 'package:qr_code_generator/features/qr_generator/presentation/widgets/qr_action_buttons.dart';
import 'package:qr_code_generator/features/qr_history/controllers/qr_history_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Prominently displays the generated QR code with live customization,
/// contrast detection, content inspection, and export actions.
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
          // Card Header with Type Badge and Favorite Toggle
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(config.payloadType.icon, size: 13, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          config.payloadType.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFA5B4FC)
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  ListenableBuilder(
                    listenable: QrHistoryController.instance,
                    builder: (context, _) {
                      final isFav = QrHistoryController.instance
                          .isContentFavorite(config.content);
                      return IconButton(
                        icon: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 20,
                          color: isFav ? const Color(0xFFE11D48) : null,
                        ),
                        tooltip: isFav
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                        onPressed: () {
                          QrHistoryController.instance
                              .toggleFavoriteForContent(config);
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Contrast Warning Alert (if combination is unsafe for scanner cameras)
          if (!config.hasSafeContrast) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFB45309),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Low scan contrast (${config.contrastRatio.toStringAsFixed(1)}:1). Darker foreground or lighter background recommended for reliable scanning.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // QR Code Canvas (Inside RepaintBoundary for PNG Export)
          RepaintBoundary(
            key: controller.qrRepaintKey,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: config.backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: config.content,
                version: QrVersions.auto,
                size: config.qrSize,
                backgroundColor: config.backgroundColor,
                errorCorrectionLevel: config.errorCorrectionLevel,
                eyeStyle: QrEyeStyle(
                  eyeShape: config.eyeShape,
                  color: config.foregroundColor,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: config.dataModuleShape,
                  color: config.foregroundColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Customization Section Divider
          _buildCustomizationControls(context, controller, config, isDark),
          const SizedBox(height: 20),

          // Encoded Content Container (Handles Long Text Gracefully)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
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

  // ==================== Customization Sub-section ====================
  Widget _buildCustomizationControls(
    BuildContext context,
    QrGeneratorController controller,
    QrConfig config,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              const Icon(Icons.palette_outlined, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                'Live QR Customization',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Foreground Color
          Text(
            'Dots & Eyes Color:',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppTheme.qrForegroundColors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final color = AppTheme.qrForegroundColors[index];
                final isSelected = controller.foregroundColor == color;
                return InkWell(
                  onTap: () => controller.setForegroundColor(color),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.black12,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 2. Background Color
          Text(
            'Canvas Background:',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppTheme.qrBackgroundColors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final color = AppTheme.qrBackgroundColors[index];
                final isSelected = controller.backgroundColor == color;
                return InkWell(
                  onTap: () => controller.setBackgroundColor(color),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : const Color(0xFFCBD5E1),
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: AppTheme.primaryColor, size: 16)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // 3. Size Slider & Shapes
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Size: ${controller.qrSize.toInt()}px',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: controller.qrSize,
                        min: 160.0,
                        max: 280.0,
                        divisions: 6,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) => controller.setQrSize(val),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Module Shape Toggle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dots Shape:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildShapeToggle(
                        label: 'Square',
                        isSelected: controller.dataModuleShape == QrDataModuleShape.square,
                        onTap: () {
                          controller.setDataModuleShape(QrDataModuleShape.square);
                          controller.setEyeShape(QrEyeShape.square);
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(width: 4),
                      _buildShapeToggle(
                        label: 'Circle',
                        isSelected: controller.dataModuleShape == QrDataModuleShape.circle,
                        onTap: () {
                          controller.setDataModuleShape(QrDataModuleShape.circle);
                          controller.setEyeShape(QrEyeShape.circle);
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4. Error Correction Level
          Row(
            children: [
              Text(
                'Recovery Level: ',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
              const SizedBox(width: 4),
              _buildCorrectionChip(
                label: 'L',
                tooltip: 'Low (7% recovery)',
                level: QrErrorCorrectLevel.L,
                currentLevel: controller.errorCorrectionLevel,
                onSelected: () => controller.setErrorCorrectionLevel(QrErrorCorrectLevel.L),
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              _buildCorrectionChip(
                label: 'M',
                tooltip: 'Medium (15% recovery)',
                level: QrErrorCorrectLevel.M,
                currentLevel: controller.errorCorrectionLevel,
                onSelected: () => controller.setErrorCorrectionLevel(QrErrorCorrectLevel.M),
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              _buildCorrectionChip(
                label: 'Q',
                tooltip: 'Quartile (25% recovery)',
                level: QrErrorCorrectLevel.Q,
                currentLevel: controller.errorCorrectionLevel,
                onSelected: () => controller.setErrorCorrectionLevel(QrErrorCorrectLevel.Q),
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              _buildCorrectionChip(
                label: 'H',
                tooltip: 'High (30% recovery)',
                level: QrErrorCorrectLevel.H,
                currentLevel: controller.errorCorrectionLevel,
                onSelected: () => controller.setErrorCorrectionLevel(QrErrorCorrectLevel.H),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShapeToggle({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : AppTheme.textPrimaryLight),
          ),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
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
