import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';

class QrSharingService {
  /// Captures widget from a RepaintBoundary and shares it as an image
  static Future<bool> shareQrImage({
    required GlobalKey repaintBoundaryKey,
    required String title,
    String? additionalText,
  }) async {
    try {
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return false;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return false;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final fileName = 'qr_${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      final shareText = additionalText != null && additionalText.isNotEmpty
          ? '$title\n$additionalText'
          : title;

      final shareParams = ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: shareText,
        subject: title,
      );
      await SharePlus.instance.share(shareParams);
      return true;
    } catch (e) {
      debugPrint('Error sharing QR image: $e');
      return false;
    }
  }

  /// Share raw text/URL
  static Future<void> shareText({required String text, String? subject}) async {
    final shareParams = ShareParams(text: text, subject: subject);
    await SharePlus.instance.share(shareParams);
  }

  /// Copy text to clipboard with SnackBar confirmation
  static Future<void> copyToClipboard(BuildContext context, String text,
      {String message = 'Copied to clipboard'}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Open external URL safely
  static Future<bool> launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('Error launching URL: $e');
      return false;
    }
  }
}
