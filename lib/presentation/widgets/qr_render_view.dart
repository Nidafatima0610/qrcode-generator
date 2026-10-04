import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qrcode_generator/core/models/qr_customization.dart';

class QrRenderView extends StatelessWidget {
  final String data;
  final QrCustomization customization;
  final double? size;
  final GlobalKey? repaintBoundaryKey;
  final bool showContainer;

  const QrRenderView({
    super.key,
    required this.data,
    this.customization = const QrCustomization(),
    this.size,
    this.repaintBoundaryKey,
    this.showContainer = true,
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

    Widget qrWidget = QrImageView(
      data: data.isEmpty ? ' ' : data,
      version: QrVersions.auto,
      size: effectiveSize,
      backgroundColor: bg,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: fg,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: fg,
      ),
      errorCorrectionLevel: errLevel,
      gapless: true,
    );

    if (repaintBoundaryKey != null) {
      qrWidget = RepaintBoundary(
        key: repaintBoundaryKey,
        child: Container(
          color: bg,
          padding: const EdgeInsets.all(16),
          child: qrWidget,
        ),
      );
    }

    if (!showContainer) {
      return qrWidget;
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
      child: qrWidget,
    );
  }
}
