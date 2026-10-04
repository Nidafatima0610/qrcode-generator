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
  bool _isSaving = false;
  bool _showRawPayload = false;
  late bool _isFavorite;
  bool _presentationMode = false; // false = QR Only, true = With Info Card (Requirement 8)

  @override
  void initState() {
    super.initState();
    // Check current favorite status from storage service
    final storedItem = widget.storageService.history
        .firstWhere((e) => e.id == widget.item.id, orElse: () => widget.item);
    _isFavorite = storedItem.isFavorite;
  }

  Future<void> _toggleFavorite() async {
    final newStatus = await widget.storageService.toggleFavorite(widget.item.id);
    setState(() => _isFavorite = newStatus);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Added "${widget.item.title}" to Favorites'
                : 'Removed "${widget.item.title}" from Favorites',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveQrImage() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final savedPath = await QrSharingService.saveQrImageToDevice(
        repaintBoundaryKey: _repaintBoundaryKey,
        title: widget.item.title,
      );

      if (!mounted) return;

      if (savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saved QR image successfully!\nLocation: $savedPath',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save QR image. Please check permissions.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

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
            content: Text('Failed to prepare QR image for sharing'),
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
        widget.item.type == QrType.social ||
        payload.startsWith('http://') ||
        payload.startsWith('https://')) {
      QrSharingService.launchExternalUrl(payload);
    } else if (widget.item.type == QrType.location ||
        payload.startsWith('geo:') ||
        payload.contains('maps.google.com')) {
      QrSharingService.launchExternalUrl(payload);
    } else if (widget.item.type == QrType.phone || payload.startsWith('tel:')) {
      QrSharingService.launchExternalUrl(payload);
    } else if (widget.item.type == QrType.email || payload.startsWith('mailto:')) {
      QrSharingService.launchExternalUrl(payload);
    } else if (widget.item.type == QrType.sms || payload.startsWith('smsto:')) {
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
        item.type == QrType.social ||
        item.type == QrType.location ||
        item.type == QrType.phone ||
        item.type == QrType.email ||
        item.type == QrType.sms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Preview'),
        actions: [
          // Favorite Action (Requirement 1)
          IconButton(
            icon: Icon(
              _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _isFavorite ? AppColors.error : null,
            ),
            tooltip: _isFavorite ? 'Remove Favorite' : 'Mark as Favorite',
            onPressed: _toggleFavorite,
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              const SizedBox(height: 12),

              // Title
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 4),

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
              const SizedBox(height: 16),

              // Export Presentation Mode Toggle (Requirement 8)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _modeButton(
                      label: 'QR Only',
                      icon: Icons.qr_code_2_rounded,
                      isActive: !_presentationMode,
                      onTap: () => setState(() => _presentationMode = false),
                    ),
                    _modeButton(
                      label: 'With Info Card',
                      icon: Icons.badge_outlined,
                      isActive: _presentationMode,
                      onTap: () => setState(() => _presentationMode = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Dynamic QR Presentation View (with RepaintBoundary)
              Center(
                child: QrRenderView(
                  data: item.rawPayload,
                  customization: item.customization,
                  size: 240,
                  repaintBoundaryKey: _repaintBoundaryKey,
                  showContainer: !_presentationMode,
                  presentationCard: _presentationMode,
                  cardTitle: item.title,
                  cardSubtitle: item.subtitle,
                  cardTypeLabel: item.type.label,
                  cardTypeIcon: item.type.icon,
                  cardTypeColor: item.type.color,
                ),
              ),
              const SizedBox(height: 16),

              // Customization Spec Chips
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
                  if (item.customization.dataModuleShape != 'square')
                    _infoChip(
                      context,
                      'Dots: ${item.customization.dataModuleShape}',
                    ),
                  if (item.customization.eyeShape != 'square')
                    _infoChip(
                      context,
                      'Eyes: ${item.customization.eyeShape}',
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Primary Export Actions (Save Image & Share Image)
              Row(
                children: [
                  // Save to Device / Gallery Button (Requirement 7)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isSaving ? null : _saveQrImage,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                      label: Text(_isSaving ? 'Saving...' : 'Save to Device'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Share Image Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isSharing ? null : _shareQrImage,
                      icon: _isSharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.share_rounded, size: 20),
                      label: Text(_isSharing ? 'Sharing...' : 'Share Image'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Smart Direct Action (if applicable)
              if (hasSmartAction) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46,
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
                    label: const Text('Edit / Re-generate Code'),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Content Payload Inspector Card
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
                          Row(
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(60, 28),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: _copyContent,
                                child: const Text('Copy', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(60, 28),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showRawPayload = !_showRawPayload;
                                  });
                                },
                                child: Text(
                                  _showRawPayload ? 'Summary' : 'View Raw',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
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

  Widget _modeButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppColors.primary : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? (isDark ? Colors.white : AppColors.primary)
                  : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? (isDark ? Colors.white : AppColors.primary)
                    : Colors.grey,
              ),
            ),
          ],
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
      case QrType.social:
        return 'Open in Browser';
      case QrType.location:
        return 'Open in Google Maps';
      case QrType.phone:
        return 'Call Number';
      case QrType.email:
        return 'Compose Email';
      case QrType.sms:
        return 'Send Text Message';
      default:
        return 'Open Link';
    }
  }
}
