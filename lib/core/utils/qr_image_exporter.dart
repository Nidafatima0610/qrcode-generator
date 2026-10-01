import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Utility class for capturing, saving, and sharing generated QR code images.
class QrImageExporter {
  /// Captures a [RepaintBoundary] widget identified by [boundaryKey] as PNG bytes.
  static Future<Uint8List> capturePng(GlobalKey boundaryKey) async {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;

    if (boundary == null) {
      throw Exception('QR preview is not ready to capture. Please try again.');
    }

    // High pixel ratio produces crisp, sharp QR codes suitable for scanning & printing
    final ui.Image image = await boundary.toImage(pixelRatio: 3.5);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to generate PNG image data.');
    }

    return byteData.buffer.asUint8List();
  }

  /// Saves the QR code [bytes] to the device gallery or public storage.
  /// Returns a descriptive message of where the image was stored.
  static Future<String> saveImage(Uint8List bytes) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'qr_code_$timestamp.png';

    // 1. Try Gal (saves to Photos/Gallery on Android, iOS, Windows, macOS, Linux)
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          throw Exception('Permission to access photo gallery was denied.');
        }
      }

      await Gal.putImageBytes(bytes, name: fileName);
      return 'QR code saved to your Photo Gallery!';
    } catch (e) {
      // If Gal fails or platform fallback is needed, save to Downloads / Documents folder
      if (!kIsWeb) {
        try {
          Directory? targetDir;
          try {
            targetDir = await getDownloadsDirectory();
          } catch (_) {
            targetDir = null;
          }

          targetDir ??= await getApplicationDocumentsDirectory();

          final filePath = '${targetDir.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(bytes);
          return 'QR code saved to: ${targetDir.path}';
        } catch (_) {
          // If disk fallback also fails, rethrow with friendly message
          throw Exception('Unable to save image: ${e.toString()}');
        }
      }

      throw Exception('Unable to save image: ${e.toString()}');
    }
  }

  /// Shares the QR code image and payload text using the native system share sheet.
  static Future<void> shareQrCode({
    required Uint8List bytes,
    required String content,
  }) async {
    try {
      if (kIsWeb) {
        // Web fallback for share
        await SharePlus.instance.share(
          ShareParams(
            text: content,
            subject: 'Generated QR Code Content',
          ),
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/qr_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      final xFile = XFile(
        filePath,
        mimeType: 'image/png',
        name: 'qr_code.png',
      );

      final shareText = content.length > 80
          ? '${content.substring(0, 77)}...'
          : content;

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'QR Code for: $shareText',
          subject: 'Generated QR Code',
        ),
      );
    } catch (e) {
      throw Exception('Failed to share QR code: ${e.toString()}');
    }
  }

  /// Copies raw text to the device clipboard.
  static Future<void> copyToClipboard(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
  }
}
