import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';
import 'package:qrcode_generator/core/services/qr_sharing_service.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/presentation/widgets/qr_render_view.dart';

class QrPreviewScreen extends StatefulWidget {
  final QrItem item;
  final StorageService storageService;
  final VoidCallback? onEdit;

  const QrPreviewScreen({
    super.key,
    required this.item,
    required this.storageService,
    this.onEdit,
  });

  @override
  State<QrPreviewScreen> createState() => _QrPreviewScreenState();
}

class _QrPreviewScreenState extends State<QrPreviewScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isSharing = false;
  bool _showRawPayload = false;

  Future<void> _shareQrImage() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final success = await QrSharingService.shareQrImage(
        repaintBoundaryKey: _repaintBoundaryKey,
        title: widget.item.title,
        additionalText: widget.item.subtitle,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export QR image for sharing'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _copyContent() {
    QrSharingService.copyToClipboard(
      context,
      widget.item.rawPayload,
      message: 'QR content copied to clipboard!',
    );
  }

  void _handleSmartAction() {
    final payload = widget.item.rawPayload;
    if (widget.item.type == QrType.url ||
        payload.startsWith('http://') ||
        payload.startsWith('https://')) {
      QrSharingService.launchExternalUrl(payload);
    } else if (widget.item.type == QrType.phone ||
        payload.startsWith('tel:')) {
      QrSharingService.launchExternalUrl(payload);
    } else if (widget.item.type == QrType.email ||
        payload.startsWith('mailto:')) {
      QrSharingService.launchExternalUrl(payload);
    } else if (widget.item.type == QrType.sms ||
        payload.startsWith('smsto:')) {
      QrSharingService.launchExternalUrl(payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.item;
    final typeColor = item.type.color;
    final formattedDate =
        DateFormat('MMMM d, y • h:mm a').format(item.createdAt);

    final hasSmartAction = item.type == QrType.url ||
        item.type == QrType.phone ||
        item.type == QrType.email ||
        item.type == QrType.sms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy Payload',
            onPressed: _copyContent,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Image',
            onPressed: _shareQrImage,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Type Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: typeColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.type.icon, size: 16, color: typeColor),
                    const SizedBox(width: 6),
                    Text(
                      item.type.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 6),

              // Date
              Text(
                'Created $formattedDate',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // QR Code Presentation with RepaintBoundary for high-res export
              Center(
                child: QrRenderView(
                  data: item.rawPayload,
                  customization: item.customization,
                  size: 240,
                  repaintBoundaryKey: _repaintBoundaryKey,
                  showContainer: true,
                ),
              ),
              const SizedBox(height: 12),

              // Customization Pills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _infoChip(
                    context,
                    'Error Correction: ${item.customization.errorCorrectionLevel}',
                  ),
                  _infoChip(
                    context,
                    'Format: ${item.type.shortName}',
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Primary Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSharing ? null : _shareQrImage,
                      icon: _isSharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share_rounded, size: 20),
                      label: Text(_isSharing ? 'Preparing...' : 'Share Image'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyContent,
                      icon: const Icon(Icons.copy_rounded, size: 19),
                      label: const Text('Copy Content'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Smart Direct Action (if applicable: Visit website, dial, email)
              if (hasSmartAction) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: typeColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _handleSmartAction,
                    icon: Icon(item.type.icon, size: 19),
                    label: Text(_smartActionLabel(item.type)),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Edit / Re-generate Action
              if (widget.onEdit != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onEdit!();
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: const Text('Edit / Re-generate'),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 12),

              // Summary / Raw Payload Inspector Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Content Payload',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(60, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              setState(() {
                                _showRawPayload = !_showRawPayload;
                              });
                            },
                            child: Text(
                              _showRawPayload ? 'Show Summary' : 'View Raw',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: SelectableText(
                          _showRawPayload
                              ? item.rawPayload
                              : (item.subtitle.isNotEmpty
                                  ? item.subtitle
                                  : item.rawPayload),
                          style: TextStyle(
                            fontFamily: _showRawPayload ? 'monospace' : null,
                            fontSize: 13,
                            height: 1.4,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard
            : AppColors.lightBorder.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  String _smartActionLabel(QrType type) {
    switch (type) {
      case QrType.url:
        return 'Open in Browser';
      case QrType.phone:
        return 'Call Number';
      case QrType.email:
        return 'Send Email';
      case QrType.sms:
        return 'Send Text Message';
      default:
        return 'Open Link';
    }
  }
}
