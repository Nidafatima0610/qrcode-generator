import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_customization.dart';

enum QrExportMode {
  qrOnly,
  titleQr,
  full,
  card;

  String get label {
    switch (this) {
      case QrExportMode.qrOnly:
        return 'QR Only';
      case QrExportMode.titleQr:
        return 'QR + Title';
      case QrExportMode.full:
        return 'QR + Title + Note';
      case QrExportMode.card:
        return 'Presentation Card';
    }
  }

  IconData get icon {
    switch (this) {
      case QrExportMode.qrOnly:
        return Icons.qr_code_2_rounded;
      case QrExportMode.titleQr:
        return Icons.title_rounded;
      case QrExportMode.full:
        return Icons.article_outlined;
      case QrExportMode.card:
        return Icons.badge_outlined;
    }
  }

  static QrExportMode fromString(String val) {
    switch (val.toLowerCase()) {
      case 'title_qr':
      case 'titleqr':
        return QrExportMode.titleQr;
      case 'full':
      case 'titlenote':
      case 'title_note':
        return QrExportMode.full;
      case 'card':
      case 'presentation':
        return QrExportMode.card;
      case 'qr_only':
      default:
        return QrExportMode.qrOnly;
    }
  }
}

class QrRenderView extends StatelessWidget {
  final String data;
  final QrCustomization customization;
  final double? size;
  final GlobalKey? repaintBoundaryKey;
  final bool showContainer;

  // Export modes
  final QrExportMode exportMode;
  final bool presentationCard; // Kept for backwards compatibility
  final String? cardTitle;
  final String? cardSubtitle;
  final String? note;
  final String? cardTypeLabel;
  final IconData? cardTypeIcon;
  final Color? cardTypeColor;

  const QrRenderView({
    super.key,
    required this.data,
    this.customization = const QrCustomization(),
    this.size,
    this.repaintBoundaryKey,
    this.showContainer = true,
    this.exportMode = QrExportMode.qrOnly,
    this.presentationCard = false,
    this.cardTitle,
    this.cardSubtitle,
    this.note,
    this.cardTypeLabel,
    this.cardTypeIcon,
    this.cardTypeColor,
  });

  static int getErrorCorrectionLevel(String level) {
    switch (level.toUpperCase()) {
      case 'L':
        return QrErrorCorrectLevel.L;
      case 'Q':
        return QrErrorCorrectLevel.Q;
      case 'H':
        return QrErrorCorrectLevel.H;
      case 'M':
      default:
        return QrErrorCorrectLevel.M;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? customization.size;
    final fg = customization.foregroundColor;
    final bg = customization.backgroundColor;
    final errLevel = getErrorCorrectionLevel(customization.errorCorrectionLevel);

    final eyeShape = customization.eyeShape == 'circle'
        ? QrEyeShape.circle
        : QrEyeShape.square;

    final dataModuleShape = customization.dataModuleShape == 'circle'
        ? QrDataModuleShape.circle
        : QrDataModuleShape.square;

    final effectiveMode = presentationCard ? QrExportMode.card : exportMode;

    Widget coreQr = QrImageView(
      data: data.isEmpty ? ' ' : data,
      version: QrVersions.auto,
      size: effectiveSize,
      backgroundColor: bg,
      eyeStyle: QrEyeStyle(
        eyeShape: eyeShape,
        color: fg,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: dataModuleShape,
        color: fg,
      ),
      errorCorrectionLevel: errLevel,
      gapless: true,
      padding: const EdgeInsets.all(8),
    );

    // 1. Presentation Card Mode
    if (effectiveMode == QrExportMode.card) {
      final badgeColor = cardTypeColor ?? AppColors.primary;

      Widget cardContent = Container(
        width: effectiveSize + 70,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Branding Banner
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cardTypeIcon != null) ...[
                        Icon(cardTypeIcon, size: 14, color: badgeColor),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        cardTypeLabel ?? 'QR STUDIO PRO',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // High readability QR with safe margin
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: coreQr,
            ),
            const SizedBox(height: 14),

            // Card Title
            if (cardTitle != null && cardTitle!.isNotEmpty)
              Text(
                cardTitle!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: fg,
                ),
              ),

            // Card Subtitle / Payload snippet
            if (cardSubtitle != null && cardSubtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                cardSubtitle!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: fg.withValues(alpha: 0.7),
                ),
              ),
            ],

            // Card Note if present
            if (note != null && note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Note: $note',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: fg.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),
            // Footer Brand pill
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_2_rounded,
                    size: 13, color: fg.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(
                  'Created with QR Studio Pro',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: fg.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      if (repaintBoundaryKey != null) {
        return RepaintBoundary(
          key: repaintBoundaryKey,
          child: Container(
            color: bg,
            padding: const EdgeInsets.all(12),
            child: cardContent,
          ),
        );
      }

      return cardContent;
    }

    // 2. QR + Title Mode
    if (effectiveMode == QrExportMode.titleQr) {
      Widget content = Container(
        width: effectiveSize + 50,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            coreQr,
            if (cardTitle != null && cardTitle!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                cardTitle!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ],
        ),
      );

      if (repaintBoundaryKey != null) {
        return RepaintBoundary(
          key: repaintBoundaryKey,
          child: Container(
            color: bg,
            padding: const EdgeInsets.all(8),
            child: content,
          ),
        );
      }
      return content;
    }

    // 3. QR + Title + Content Mode
    if (effectiveMode == QrExportMode.full) {
      Widget content = Container(
        width: effectiveSize + 60,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            coreQr,
            if (cardTitle != null && cardTitle!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                cardTitle!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
            if (note != null && note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  note!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: fg.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ] else if (cardSubtitle != null && cardSubtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                cardSubtitle!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: fg.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      );

      if (repaintBoundaryKey != null) {
        return RepaintBoundary(
          key: repaintBoundaryKey,
          child: Container(
            color: bg,
            padding: const EdgeInsets.all(8),
            child: content,
          ),
        );
      }
      return content;
    }

    // 4. Standard QR Only Mode
    if (repaintBoundaryKey != null) {
      coreQr = RepaintBoundary(
        key: repaintBoundaryKey,
        child: Container(
          color: bg,
          padding: const EdgeInsets.all(22),
          child: coreQr,
        ),
      );
    }

    if (!showContainer) {
      return coreQr;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: coreQr,
    );
  }
}
