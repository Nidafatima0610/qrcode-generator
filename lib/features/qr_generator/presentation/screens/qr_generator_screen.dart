import 'package:flutter/material.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/features/qr_generator/controllers/qr_generator_controller.dart';
import 'package:qr_code_generator/features/qr_generator/presentation/widgets/qr_display_card.dart';
import 'package:qr_code_generator/features/qr_generator/presentation/widgets/qr_empty_state.dart';
import 'package:qr_code_generator/features/qr_generator/presentation/widgets/qr_input_card.dart';

/// Main screen of the QR Code Generator application.
class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  late final QrGeneratorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QrGeneratorController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showInfoDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF131B2E) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'About QR Generator',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A fast, private, and modern QR code generator built with Flutter.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            _buildFeatureBullet(
              icon: Icons.offline_bolt_rounded,
              title: '100% Offline & Private',
              desc: 'QR codes are generated locally on your device.',
            ),
            const SizedBox(height: 10),
            _buildFeatureBullet(
              icon: Icons.palette_rounded,
              title: 'Customizable Themes',
              desc: 'Select from curated accent colors and error levels.',
            ),
            const SizedBox(height: 10),
            _buildFeatureBullet(
              icon: Icons.ios_share_rounded,
              title: 'Save & Share',
              desc: 'Export high-definition PNG images or share directly.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Got It',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text('QR Generator'),
            ],
          ),
          actions: [
            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.hasContent || _controller.isQrGenerated) {
                  return IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Reset all',
                    onPressed: () => _controller.resetAll(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              tooltip: 'About app',
              onPressed: () => _showInfoDialog(context),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Subtitle Banner
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create & Export Custom QR Codes',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Generate crisp QR codes for links, text, Wi-Fi, and contact details with instant sharing.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Input Card
                        QrInputCard(controller: _controller),
                        const SizedBox(height: 20),

                        // Dynamic QR Display or Empty State
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _controller.isQrGenerated
                              ? QrDisplayCard(
                                  key: const ValueKey('display_card'),
                                  controller: _controller,
                                  config: _controller.currentQr!,
                                )
                              : QrEmptyState(
                                  key: const ValueKey('empty_state'),
                                  onSelectPreset: (text, type) {
                                    _controller.loadPreset(text, type);
                                  },
                                ),
                        ),
                        const SizedBox(height: 28),

                        // Footer Note
                        Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                              ),
                              Text(
                                'Privacy friendly • Runs 100% locally on your device',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
